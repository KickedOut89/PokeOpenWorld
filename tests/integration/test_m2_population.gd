extends GutTest
## Milestone 2: the slice's towns and routes are populated per spec §7.

var db: DataDB
var area_of_place := {}


func before_all() -> void:
	db = DataDB.load_dir("res://data")
	for cid in db.table(&"chunks"):
		var c: Dictionary = db.table(&"chunks")[cid]
		for a in c.get("npc_anchors", []):
			area_of_place[StringName(a.id)] = StringName(a.get("area", c.area))
		for d in c.get("doors", []):
			area_of_place[StringName(d.id)] = StringName(d.get("area", c.area))


func _npcs_in(areas: Array) -> Array:
	var out := []
	for id in db.table(&"npcs"):
		var n: Dictionary = db.table(&"npcs")[id]
		if areas.has(area_of_place.get(StringName(n.get("home", "")), &"")):
			out.append(n)
	return out


func _active(npcs: Array, hour: float) -> int:
	var n := 0
	for rec in npcs:
		var s := Schedule.new(db.get_record(&"schedules", StringName(rec.schedule)), StringName(rec.home))
		if not s.resolve(hour, &"clear", rec.get("weather_behavior", {})).indoors:
			n += 1
	return n


func test_npc_counts_per_area() -> void:
	assert_between(_npcs_in([&"pallet_town"]).size(), 12, 15, "Pallet")
	assert_between(_npcs_in([&"route_1"]).size(), 6, 10, "Route 1")
	assert_between(_npcs_in([&"viridian_city"]).size(), 35, 45, "Viridian")
	assert_between(_npcs_in([&"route_2_south", &"viridian_forest"]).size(), 10, 15, "Route 2 + forest")


func test_bug_catcher_trainers_in_forest() -> void:
	var n := 0
	for rec in _npcs_in([&"route_2_south", &"viridian_forest"]):
		if rec.role == "trainer":
			n += 1
	assert_between(n, 3, 4)


func test_viridian_empties_at_night() -> void:
	var v := _npcs_in([&"viridian_city"])
	var day := _active(v, 12.0)
	var night := _active(v, 23.0)
	assert_gt(day, 0)
	assert_lt(night, day * 0.5, "%d at noon vs %d at 23:00" % [day, night])


func test_night_owls_only_at_night() -> void:
	var owls := _npcs_in([&"viridian_city"]).filter(func(r: Dictionary) -> bool: return r.get("night_owl", false))
	assert_gte(owls.size(), 3)
	assert_eq(_active(owls, 12.0), 0)
	assert_eq(_active(owls, 23.0), owls.size())
	assert_eq(_active(owls, 2.0), owls.size())


func test_viridian_building_count() -> void:
	var n := 0
	for cid in db.table(&"chunks"):
		for p in db.table(&"chunks")[cid].props:
			if p.get("area", "") == "viridian_city" and p.get("kind", "") == "building":
				n += 1
	assert_between(n, 25, 30)


func test_key_buildings_and_gates() -> void:
	var doors := {}
	for cid in db.table(&"chunks"):
		for d in db.table(&"chunks")[cid].doors:
			doors[d.id] = d
	assert_eq(doors["viridian_center_door"].unlock.type, "always")
	assert_eq(doors["viridian_mart_door"].unlock.type, "always")
	assert_eq((doors["viridian_mart_door"].hours as Array).map(func(h: Variant) -> int: return int(h)), [8, 21])
	assert_eq(doors["viridian_gym_door"].unlock, {"type": "flag", "flag": "viridian_gym_open"})


func test_every_door_resolves() -> void:
	var state := GameState.new()
	for cid in db.table(&"chunks"):
		for d in db.table(&"chunks")[cid].doors:
			var has := not db.get_record(&"interiors", StringName(d.interior)).is_empty()
			var r := DoorUnlock.evaluate(d, state, 12, has)
			assert_true(r.has("open") and r.has("text"), d.id)
	state.free()


func test_half_of_homes_enterable() -> void:
	var homes := 0
	var built := 0
	for cid in db.table(&"chunks"):
		for p in db.table(&"chunks")[cid].props:
			if p.get("kind", "") == "building" and String(p.get("template", "")).begins_with("house") and p.area in ["pallet_town", "viridian_city"]:
				homes += 1
				if not db.get_record(&"interiors", StringName(p.id + "_int")).is_empty():
					built += 1
	assert_between(float(built) / homes, 0.4, 0.6, "%d of %d homes" % [built, homes])
