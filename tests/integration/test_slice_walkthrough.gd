extends GutTest
## End-to-end: new game -> starter -> rival -> Pallet to Viridian -> Center -> parcel ->
## Oak -> forest -> catch -> save/reload -> night.

const DIR := "user://test_walkthrough_saves"
var world: KantoWorld
var areas: Array[StringName] = []


func before_all() -> void:
	Saves.dir = DIR
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	State.from_dict({})
	State.party = Party.new()
	State.pc = PCStorage.new()
	Clock.model.minutes = 9 * 60.0
	EventBus.area_entered.connect(_on_area)


func after_all() -> void:
	EventBus.area_entered.disconnect(_on_area)
	Saves.dir = "user://saves"
	State.from_dict({})
	State.party = Party.new()


func _on_area(a: StringName) -> void:
	areas.append(a)


func _go(anchor: StringName) -> void:
	world.teleport_to_anchor(anchor)
	await wait_physics_frames(3)


func _talk(id: String) -> void:
	world.talk_to(Data.db.get_record(&"npcs", StringName(id)))


func _enter(door_id: String) -> void:
	var door := world.find_child("Door_" + door_id, true, false) as Area3D
	assert_not_null(door, door_id)
	await world.interiors.enter(door.get_meta(&"door"), door.global_position)


func test_slice_walkthrough() -> void:
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.interiors.fade_seconds = 0.0
	world.capture.fade_free = true
	await wait_physics_frames(3)
	# Starter + rival in Oak's Lab.
	await _enter("oaks_lab_door")
	_talk("professor_oak")
	world.prompts.choose(0)
	await wait_physics_frames(2)
	assert_eq(State.party.members[0].species, &"bulbasaur")
	assert_true(world.fights.in_fight())
	assert_eq(world.fights.model.current_foe().creature.species, &"charmander", "rival counter-picks")
	world.fights.model.current_foe().creature.hp = 0
	await wait_physics_frames(3)
	while world.prompts.is_open():
		world.prompts.choose(0)
	assert_true(State.has_flag(&"rival_lab_done"))
	await world.interiors.exit()
	# Pallet -> Route 1 -> Viridian.
	await _go(&"pallet_north_path")
	await _go(&"route1_south_end")
	await _go(&"route1_north_end")
	await _go(&"v_south_gate")
	for a in [&"route_1", &"viridian_city"]:
		assert_has(areas, a)
	# Pokémon Center in and out.
	await _go(&"v_center_front")
	State.party.members[0].hp = 1
	await _enter("viridian_center_door")
	_talk("nurse_joy")
	assert_eq(State.party.members[0].hp, State.party.members[0].max_hp())
	await world.interiors.exit()
	assert_false(world.interiors.is_inside())
	# Parcel from the Mart, back to Oak.
	_talk("mart_clerk")
	assert_eq(int(State.items.get(&"oaks_parcel", 0)), 1)
	await _go(&"pallet_lab_front")
	_talk("professor_oak")
	assert_true(State.has_flag(&"got_pokedex"))
	assert_eq(int(State.items.get(&"poke_ball", 0)), 5)
	# Up Route 2 into the forest and catch something.
	await _go(&"r2_path_mid")
	await _go(&"f_trail_south")
	assert_has(areas, &"viridian_forest")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var w := WildPokemon.make(Creature.create(&"caterpie", 4, rng, Data.db), world.player.global_position + Vector3(0, 0, -6), &"forest_grass_south")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	world.capture.forced_attempt = {"caught": true, "shakes": 3, "critical": false}
	assert_true(world.capture.throw_at(w))
	for i in 120:
		if not world.capture.busy():
			break
		await wait_physics_frames(1)
	assert_eq(State.party.members.size(), 2)
	assert_true(State.pokedex_caught.has(&"caterpie"))
	# Save, wipe, reload.
	assert_eq(Saves.save(1, world.snapshot_world()), OK)
	var snapshot := JSON.stringify([State.to_dict(), State.party.to_array(), world.quest_state()])
	State.from_dict({})
	State.party = Party.new()
	var r := Saves.load_slot(1)
	assert_true(r.ok)
	Saves.apply(r.data)
	world.restore_quests(r.data.quests)
	assert_eq(JSON.stringify([State.to_dict(), State.party.to_array(), world.quest_state()]), snapshot)
	# Night: night table and an emptier Viridian.
	await _go(&"v_plaza_n")
	Clock.model.minutes = 12 * 60.0
	world.update_npcs()
	var noon := world.npcs.actor_count()
	Clock.model.minutes = 23 * 60.0
	world.update_npcs()
	var night := world.npcs.actor_count()
	assert_lt(night, noon, "%d at noon vs %d at 23:00" % [noon, night])
	var table := SpawnTable.new(Data.db.get_record(&"spawns", &"route_1"), {&"hoothoot": true})
	var seen := {}
	for i in 300:
		seen[table.pick(&"night", &"clear", rng).species] = true
	assert_true(seen.has(&"hoothoot"))
	assert_false(seen.has(&"sentret"))
