extends GutTest
## Starter -> rival battle -> parcel from the Viridian clerk -> Pokédex and 5 Poké Balls from Oak.

var world: KantoWorld


func before_each() -> void:
	State.from_dict({})
	State.party = Party.new()
	State.pc = PCStorage.new()
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.spawner.enabled = false
	world.interiors.fade_seconds = 0.0
	await wait_physics_frames(2)


func after_each() -> void:
	State.from_dict({})
	State.party = Party.new()


func _npc(rec_id: String) -> Dictionary:
	return Data.db.get_record(&"npcs", StringName(rec_id))


func test_blocked_from_leaving_without_pokemon() -> void:
	world.player.global_position = world.find_anchor(&"pallet_north_path") + Vector3(0, 0.3, -6)
	await wait_physics_frames(2)
	assert_gt(world.player.global_position.z, world.find_anchor(&"pallet_north_path").z - 3.0, "pushed back into Pallet")
	assert_string_contains(world.toast.current_text(), "Pokémon")


func test_full_oaks_parcel_flow() -> void:
	# 1. Talk to Oak in his lab and pick Charmander.
	world.talk_to(_npc("professor_oak"))
	assert_true(world.prompts.is_open())
	world.prompts.choose(1)
	assert_true(State.has_flag(&"got_starter"))
	assert_eq(State.party.members[0].species, &"charmander")
	assert_eq(State.party.members[0].level, 5)
	# 2. The rival picks Squirtle and battles; finish it.
	await wait_physics_frames(2)
	assert_true(world.fights.in_fight())
	assert_eq(world.fights.model.current_foe().creature.species, &"squirtle")
	world.fights.model.current_foe().creature.hp = 0
	await wait_physics_frames(3)
	assert_true(State.has_flag(&"rival_lab_done"))
	# 3. The Viridian Mart clerk hands over the parcel.
	assert_false(Mart.stock(State).has(&"poke_ball"))
	world.talk_to(_npc("mart_clerk"))
	assert_eq(int(State.items.get(&"oaks_parcel", 0)), 1)
	# 4. Oak takes it and gives the Pokédex + 5 Poké Balls.
	world.talk_to(_npc("professor_oak"))
	assert_true(State.has_flag(&"got_pokedex"))
	assert_eq(int(State.items.get(&"poke_ball", 0)), 5)
	assert_false(State.items.has(&"oaks_parcel"))
	assert_true(Mart.stock(State).has(&"poke_ball"))
	assert_true(world.quests.get_quest(&"oaks_parcel").is_complete())


func test_losing_the_rival_battle_does_not_black_out() -> void:
	world.talk_to(_npc("professor_oak"))
	world.prompts.choose(0)
	await wait_physics_frames(2)
	var pos := world.player.global_position
	State.party.members[0].hp = 0
	await wait_physics_frames(3)
	assert_false(world.fights.in_fight())
	assert_true(State.has_flag(&"rival_lab_done"), "story continues after a loss")
	assert_eq(State.money, 3000, "no money lost")
	assert_almost_eq(world.player.global_position.distance_to(pos), 0.0, 3.0, "not teleported away")


func test_quest_state_round_trip() -> void:
	world.talk_to(_npc("professor_oak"))
	world.prompts.choose(2)
	var d := world.quest_state()
	world.quests.get_quest(&"starter").stage_index = 0
	world.restore_quests(JSON.parse_string(JSON.stringify(d)))
	assert_eq(world.quests.get_quest(&"starter").stage_index, 1)
