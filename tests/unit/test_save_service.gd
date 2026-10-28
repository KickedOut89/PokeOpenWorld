extends GutTest

var svc: SaveService
var rng := RandomNumberGenerator.new()
const DIR := "user://test_saves"


func before_each() -> void:
	rng.seed = 3
	svc = SaveService.new()
	svc.dir = DIR
	add_child_autofree(svc)
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	State.from_dict({})
	State.party = Party.new()
	State.pc = PCStorage.new()


func after_each() -> void:
	State.from_dict({})
	State.party = Party.new()
	State.pc = PCStorage.new()


func _world(extra: Dictionary = {}) -> Dictionary:
	var w := {"player": {"pos": [10.5, 2.0, 700.25], "area": "route_1"}, "spawns_respawn_timers": {"route1_mid_grass": [123.5]}, "quests": {"oaks_parcel": {"stage": 1}}}
	w.merge(extra, true)
	return w


func test_round_trip_full_state() -> void:
	State.set_flag(&"got_starter")
	State.items[&"poke_ball"] = 4
	State.money = 1234
	State.party.members.append(Creature.create(&"bulbasaur", 7, rng, Data.db))
	State.pc.deposit(Creature.create(&"pidgey", 3, rng, Data.db))
	Clock.model.minutes = 615.0
	Clock.model.day = 3
	assert_eq(svc.save(1, svc.snapshot(_world())), OK)
	State.from_dict({})
	State.party = Party.new()
	State.pc = PCStorage.new()
	Clock.model.minutes = 0.0
	var r := svc.load_slot(1)
	assert_true(r.ok)
	var player := svc.apply(r.data)
	assert_true(State.has_flag(&"got_starter"))
	assert_eq(State.items[&"poke_ball"], 4)
	assert_eq(State.money, 1234)
	assert_eq(State.party.members[0].species, &"bulbasaur")
	assert_eq(State.pc.boxes[0][0].species, &"pidgey")
	assert_almost_eq(Clock.model.minutes, 615.0, 0.001)
	assert_eq(Clock.model.day, 3)
	assert_eq(player.pos, Vector3(10.5, 2.0, 700.25))
	assert_eq(int(r.data.quests.oaks_parcel.stage), 1)
	assert_eq(r.data.spawns_respawn_timers.route1_mid_grass, [123.5])


func test_interior_position_round_trip() -> void:
	var w := _world({"player": {"pos": [0.0, 1000.1, 2.8], "area": "pallet_town", "interior": {"id": "player_house_int", "door": "player_house_door", "outdoor_pos": [150.0, 0.0, 878.0]}}})
	svc.save(1, svc.snapshot(w))
	var player := svc.apply(svc.load_slot(1).data)
	assert_eq(player.interior.id, "player_house_int")
	assert_eq(player.interior.outdoor_pos, Vector3(150, 0, 878))


func test_weather_mid_transition() -> void:
	var m: WeatherModel = Weather.models[&"kanto_route"]
	m.current = &"clear"
	m.target = &"rain"
	m.blend = 0.4
	svc.save(1, svc.snapshot(_world()))
	m.current = &"fog"
	m.target = &"fog"
	m.blend = 1.0
	svc.apply(svc.load_slot(1).data)
	assert_eq(m.current, &"clear")
	assert_eq(m.target, &"rain")
	assert_almost_eq(m.blend, 0.4, 0.001)


func test_save_refused_in_fight() -> void:
	svc.in_fight = func() -> bool: return true
	assert_eq(svc.save(1, svc.snapshot(_world())), ERR_BUSY)
	assert_false(FileAccess.file_exists(DIR.path_join("slot_1.json")))


func test_corrupt_main_loads_backup() -> void:
	State.money = 111
	svc.save(1, svc.snapshot(_world()))
	State.money = 222
	svc.save(1, svc.snapshot(_world()))
	var f := FileAccess.open(DIR.path_join("slot_1.json"), FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()
	var r := svc.load_slot(1)
	assert_true(r.ok)
	assert_true(r.used_backup)
	svc.apply(r.data)
	assert_eq(State.money, 111, "previous save")


func test_both_corrupt_returns_not_ok() -> void:
	for name in ["slot_1.json", "slot_1.json.bak"]:
		var f := FileAccess.open(DIR.path_join(name), FileAccess.WRITE)
		f.store_string("garbage")
		f.close()
	assert_false(svc.load_slot(1).ok)


func test_missing_slot_not_ok() -> void:
	assert_false(svc.load_slot(5).ok)
	assert_false(svc.has_save(5))


func test_future_version_rejected() -> void:
	var d := svc.snapshot(_world())
	d.version = SaveService.CURRENT_VERSION + 1
	var f := FileAccess.open(DIR.path_join("slot_1.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	assert_false(svc.load_slot(1).ok)


func test_atomic_write_leaves_no_tmp() -> void:
	svc.save(1, svc.snapshot(_world()))
	svc.save(1, svc.snapshot(_world()))
	assert_false(FileAccess.file_exists(DIR.path_join("slot_1.json.tmp")))
	assert_true(FileAccess.file_exists(DIR.path_join("slot_1.json")))
	assert_true(FileAccess.file_exists(DIR.path_join("slot_1.json.bak")))
