extends GutTest

var world: KantoWorld
var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 9
	State.party = Party.new()
	State.pc = PCStorage.new()
	State.party.members.append(Creature.create(&"charmander", 15, rng, Data.db))
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.spawner.enabled = false
	world.interiors.fade_seconds = 0.0
	await wait_physics_frames(2)


func after_each() -> void:
	State.party = Party.new()
	State.pc = PCStorage.new()


func test_win_awards_exp_and_prompts_evolution() -> void:
	var c := State.party.members[0]
	c.exp = Growth.exp_for_level(&"medium_slow", 16) - 1
	var w := WildPokemon.make(Creature.create(&"pidgey", 8, rng, Data.db), world.player.global_position + Vector3(0, 0, -4), &"t")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	world.fights.model.current_foe().creature.hp = 0
	await wait_physics_frames(3)
	assert_eq(c.level, 16)
	assert_string_contains(world.prompts.question(), "Dragon Rage", "move prompt comes first, as in the main games")
	world.prompts.choose(0)  # forget the first move for Dragon Rage
	assert_has(c.moves, &"dragon_rage")
	assert_true(world.prompts.is_open(), "evolution prompt")
	assert_string_contains(world.prompts.question(), "evolving")
	world.prompts.choose(0)  # let it evolve
	await wait_physics_frames(2)
	assert_eq(c.species, &"charmeleon")


func test_cancelled_evolution_keeps_species() -> void:
	var c := State.party.members[0]
	c.exp = Growth.exp_for_level(&"medium_slow", 16) - 1
	var w := WildPokemon.make(Creature.create(&"pidgey", 8, rng, Data.db), world.player.global_position + Vector3(0, 0, -4), &"t")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	world.fights.model.current_foe().creature.hp = 0
	await wait_physics_frames(3)
	world.prompts.choose(4)  # don't learn Dragon Rage
	world.prompts.choose(1)  # stop the evolution
	await wait_physics_frames(2)
	assert_eq(c.species, &"charmander")
	assert_false(c.moves.has(&"dragon_rage"))


func test_nurse_joy_heals_inside_center() -> void:
	var c := State.party.members[0]
	c.hp = 1
	var door := world.find_child("Door_viridian_center_door", true, false)
	if door == null:
		world.teleport_to_anchor(&"v_center_front")
		await wait_physics_frames(2)
		door = world.find_child("Door_viridian_center_door", true, false)
	await world.interiors.enter(door.get_meta(&"door"), (door as Node3D).global_position)
	var joy: NPC = null
	for n in get_tree().get_nodes_in_group(&"npc"):
		if (n as NPC).record.get("id", "") == "nurse_joy":
			joy = n
	assert_not_null(joy, "Nurse Joy stands inside the Center")
	world.talk_to(joy.record)
	assert_eq(c.hp, c.max_hp())
	assert_eq(State.last_center, &"viridian_center")
