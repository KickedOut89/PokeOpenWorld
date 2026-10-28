extends GutTest

var world: KantoWorld
var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 6
	State.party = Party.new()
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	State.items = {}
	State.pokedex_caught = {}
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.spawner.enabled = false
	world.capture.fade_free = true
	await wait_physics_frames(2)


func after_each() -> void:
	State.party = Party.new()
	State.items = {}
	State.pokedex_caught = {}


func _wild(offset := Vector3(0, 0, -6)) -> WildPokemon:
	var w := WildPokemon.make(Creature.create(&"pidgey", 3, rng, Data.db), world.player.global_position + offset, &"test")
	world.spawner.add_child(w)
	return w


func _wait_capture() -> void:
	for i in 600:
		if not world.capture.busy():
			return
		await wait_physics_frames(1)


func test_no_balls_cannot_throw() -> void:
	var w := _wild()
	await wait_physics_frames(1)
	assert_false(world.capture.throw_at(w))
	assert_eq(world.toast.current_text(), "You don't have any Poké Balls!")


func test_out_of_range_cannot_throw() -> void:
	State.items[&"poke_ball"] = 3
	var w := _wild(Vector3(0, 0, -30))
	await wait_physics_frames(1)
	assert_false(world.capture.throw_at(w))
	assert_eq(State.items[&"poke_ball"], 3)


func test_sneak_catch_adds_to_party_and_dex() -> void:
	State.items[&"poke_ball"] = 3
	var w := _wild()
	await wait_physics_frames(1)
	world.capture.forced_attempt = {"caught": true, "shakes": 3, "critical": false}
	assert_true(world.capture.throw_at(w))
	assert_true(world.capture.last_sneak, "unengaged wild = sneak throw")
	assert_eq(State.items[&"poke_ball"], 2)
	await _wait_capture()
	assert_false(is_instance_valid(w))
	assert_eq(State.party.members.size(), 2)
	assert_eq(State.party.members[1].species, &"pidgey")
	assert_true(State.pokedex_caught.has(&"pidgey"))
	assert_false(world.fights.in_fight())


func test_breakout_starts_fight() -> void:
	State.items[&"poke_ball"] = 1
	var w := _wild()
	await wait_physics_frames(1)
	world.capture.forced_attempt = {"caught": false, "shakes": 1, "critical": false}
	world.capture.throw_at(w)
	await _wait_capture()
	assert_true(is_instance_valid(w))
	assert_true(world.fights.in_fight())


func test_catch_in_fight_ends_fight_caught() -> void:
	State.items[&"poke_ball"] = 1
	var w := _wild()
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	var result := [&""]
	world.fights.fight_finished.connect(func(r: StringName) -> void: result[0] = r)
	world.capture.forced_attempt = {"caught": true, "shakes": 3, "critical": false}
	assert_true(world.capture.throw_at(w))
	assert_false(world.capture.last_sneak)
	await _wait_capture()
	await wait_physics_frames(2)
	assert_eq(result[0], &"caught")
	assert_eq(State.party.members.size(), 2)


func test_trainer_pokemon_blocked() -> void:
	State.items[&"poke_ball"] = 2
	var npc := Node3D.new()
	world.add_child(npc)
	npc.global_position = world.player.global_position + Vector3(0, 0, -5)
	world.fights.start_trainer({"id": "t", "party": [{"species": "caterpie", "level": 3}], "skill": 0.3, "defeated_flag": "t_beaten"}, npc)
	await wait_physics_frames(1)
	assert_false(world.capture.throw_at(world.fights.foe_actor))
	assert_eq(State.items[&"poke_ball"], 2)
	assert_eq(world.toast.current_text(), "You can't catch a Trainer's Pokémon!")
