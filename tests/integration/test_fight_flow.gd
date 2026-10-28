extends GutTest
## Starting, winning, escaping and losing a wild fight in the real world scene.

var world: KantoWorld
var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 4
	State.party = Party.new()
	State.party.members.append(Creature.create(&"charmander", 10, rng, Data.db))
	State.money = 3000
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.spawner.enabled = false
	await wait_physics_frames(2)


func after_each() -> void:
	State.party = Party.new()


func _wild(species: StringName = &"caterpie", offset := Vector3(0, 0, -4)) -> WildPokemon:
	var w := WildPokemon.make(Creature.create(species, 3, rng, Data.db), world.player.global_position + offset, &"test")
	world.spawner.add_child(w)
	return w


func test_fight_starts_and_pins_ring() -> void:
	var w := _wild()
	await wait_physics_frames(1)
	assert_true(world.fights.start_wild(w))
	assert_true(world.fights.in_fight())
	assert_false(world.player.input_enabled)
	assert_true(world.camera.in_combat)
	assert_true(w.in_fight)
	assert_gt(world.streamer.pinned().size(), 0)
	assert_false(world.fights.start_wild(_wild()), "only one fight at a time")


func test_winning_removes_wild_and_restores_control() -> void:
	var w := _wild()
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	world.fights.model.current_foe().creature.hp = 0
	await wait_physics_frames(2)
	assert_false(world.fights.in_fight())
	assert_false(is_instance_valid(w), "defeated wild is removed")
	assert_eq(world.streamer.pinned().size(), 0)
	assert_true(world.player.input_enabled)
	assert_false(world.camera.in_combat)


func test_player_move_damages_foe() -> void:
	var w := _wild(&"caterpie", Vector3(0, 0, -2.0))
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	var foe := world.fights.model.current_foe()
	var hp := foe.creature.hp
	var me := world.fights.model.active()
	world.fights.player_actor.global_position = w.global_position + Vector3(0, 0, 1.6)
	world.fights.player_actor.facing = Vector3.FORWARD
	var move := me.creature.moves[0]
	for m in me.creature.moves:
		if int(Data.db.get_record(&"moves", m).get("power", 0)) > 0:
			move = m
	world.fights.forced = {"use": move}
	await wait_physics_frames(2)
	world.fights.forced = {}
	await wait_physics_frames(60)
	assert_lt(foe.creature.hp, hp, "used %s" % move)


func test_escape_by_leaving_ring() -> void:
	var w := _wild()
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	world.fights.player_actor.global_position = world.fights.model.center + Vector3(20, 0.5, 0)
	world.fights.forced = {"move": Vector3.ZERO}
	await wait_seconds(3.4)
	assert_false(world.fights.in_fight())
	assert_true(is_instance_valid(w), "the wild lives on")
	assert_false(w.in_fight)


func test_blackout_costs_money_and_heals() -> void:
	var w := _wild()
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	State.party.members[0].hp = 0
	await wait_physics_frames(2)
	assert_false(world.fights.in_fight())
	assert_eq(State.money, 3000 - 80, "0 badges x Lv10")
	assert_eq(State.party.members[0].hp, State.party.members[0].max_hp())
