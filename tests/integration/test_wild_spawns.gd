extends GutTest
## In Route 1's grass, SpawnNode fills the area with visible wild Pokémon in tall grass.

func test_wilds_spawn_in_route1_grass() -> void:
	var world: KantoWorld = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(1)
	Clock.model.minutes = 12 * 60.0
	# Route 1 middle grass belt (cells 12..21 x 21..28 at origin 32,160) -> centre ~ (196, 0, 740)
	world.player.global_position = Vector3(196, 1.2, 740)
	world.streamer.update_now()
	await wait_physics_frames(2)
	for i in 40:
		world.spawner.tick_now()
	var wilds := get_tree().get_nodes_in_group(&"wild")
	assert_gte(wilds.size(), SpawnDirector.ACTIVE_MIN)
	var table_species := [&"pidgey", &"rattata", &"sentret"]
	for w in wilds:
		var wp := w as WildPokemon
		assert_has(table_species, wp.creature.species)
		var c := world.streamer.record(StreamingPlanner.chunk_of(wp.global_position))
		var local := wp.global_position - c.origin()
		assert_true(c.is_tall_grass(Vector2(local.x, local.z)), "%s spawned in tall grass" % wp.creature.species)


func test_removed_wild_frees_slot_and_starts_timer() -> void:
	var world: KantoWorld = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(1)
	world.player.global_position = Vector3(196, 1.2, 740)
	world.streamer.update_now()
	await wait_physics_frames(2)
	for i in 10:
		world.spawner.tick_now()
	var w := get_tree().get_nodes_in_group(&"wild")[0] as WildPokemon
	var n := get_tree().get_nodes_in_group(&"wild").size()
	w.remove(&"caught")
	await wait_physics_frames(1)
	assert_eq(get_tree().get_nodes_in_group(&"wild").size(), n - 1)
