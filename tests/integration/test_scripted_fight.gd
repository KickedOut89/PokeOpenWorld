extends GutTest
## Lv10 Charmander vs Lv3 Caterpie, Ember spammed on cooldown: must win within 30 sim-seconds.

func test_scripted_fight() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	State.party = Party.new()
	State.party.members.append(Creature.create(&"charmander", 10, rng, Data.db))
	var world: KantoWorld = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.spawner.enabled = false
	await wait_physics_frames(2)
	var w := WildPokemon.make(Creature.create(&"caterpie", 3, rng, Data.db), world.player.global_position + Vector3(0, 0, -6), &"test")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	assert_true(world.fights.start_wild(w))
	Engine.time_scale = 5.0
	var result := [&"ongoing"]
	world.fights.fight_finished.connect(func(r: StringName) -> void: result[0] = r)
	var sim := 0.0
	while result[0] == &"ongoing" and sim < 30.0:
		if world.fights.in_fight() and is_instance_valid(w):
			var to := w.global_position - world.fights.player_actor.global_position
			to.y = 0
			world.fights.player_actor.facing = to.normalized()
			world.fights.forced = {"use": &"ember", "move": Vector3.ZERO}
		await wait_physics_frames(1)
		sim += get_physics_process_delta_time() * Engine.time_scale
	Engine.time_scale = 1.0
	assert_eq(result[0], &"won", "after %.1f simulated seconds" % sim)
	State.party = Party.new()
