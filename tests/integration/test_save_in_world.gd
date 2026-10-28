extends GutTest

const DIR := "user://test_world_saves"


func before_each() -> void:
	Saves.dir = DIR
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_each() -> void:
	Saves.dir = "user://saves"


func _world() -> KantoWorld:
	var w: KantoWorld = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(w)
	w.spawner.enabled = false
	w.interiors.fade_seconds = 0.0
	return w


func test_autosave_on_area_change_and_restore_position() -> void:
	var w := _world()
	await wait_physics_frames(2)
	w.teleport_to_anchor(&"route1_vendor")
	await wait_physics_frames(2)
	assert_true(Saves.has_save(0), "entering Route 1 autosaved")
	var pos := w.player.global_position
	w.queue_free()
	await wait_physics_frames(1)
	var w2 := _world()
	await wait_physics_frames(2)
	assert_true(await w2.continue_from_save(0))
	await wait_physics_frames(2)
	assert_almost_eq(w2.player.global_position.distance_to(pos), 0.0, 0.6)


func test_save_inside_interior_restores_inside() -> void:
	var w := _world()
	await wait_physics_frames(2)
	var door := w.find_child("Door_player_house_door", true, false) as Area3D
	var door_pos := door.global_position
	await w.interiors.enter(door.get_meta(&"door"), door_pos)
	assert_eq(Saves.save(0, w.snapshot_world()), OK)
	w.queue_free()
	await wait_physics_frames(1)
	var w2 := _world()
	await wait_physics_frames(2)
	assert_true(await w2.continue_from_save(0))
	await wait_physics_frames(2)
	assert_true(w2.interiors.is_inside())
	assert_eq(w2.interiors.current_id, &"player_house_int")
	await w2.interiors.exit()
	assert_almost_eq(w2.player.global_position.distance_to(door_pos + Vector3(0, 0, 1.5)), 0.0, 0.6)


func test_no_autosave_during_fight() -> void:
	var w := _world()
	await wait_physics_frames(2)
	var rng := RandomNumberGenerator.new()
	State.party = Party.new()
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	var wild := WildPokemon.make(Creature.create(&"pidgey", 3, rng, Data.db), w.player.global_position + Vector3(0, 0, -4), &"t")
	w.spawner.add_child(wild)
	await wait_physics_frames(1)
	w.fights.start_wild(wild)
	assert_eq(Saves.save(0, w.snapshot_world()), ERR_BUSY)
	State.party = Party.new()
