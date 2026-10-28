extends GutTest

var rng: RandomNumberGenerator
var table := SpawnTable.new({"id": "t", "entries": [{"species": "pidgey", "min_lvl": 2, "max_lvl": 5, "weight": 1, "periods": "all"}]})


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 5


func _zone(rect := Rect2(-50, -50, 100, 100)) -> Dictionary:
	return {"id": &"z", "table": table, "rect": rect, "y": 0.0}


func _never_visible(_p: Vector3) -> bool:
	return false


func _run(d: SpawnDirector, active: Array[Dictionary], ticks: int, minutes: float = 0.0) -> Array[Dictionary]:
	for i in ticks:
		var r := d.tick(Vector3.ZERO, active, [_zone()], &"day", &"clear", _never_visible, minutes)
		for s in r.spawn:
			active.append({"id": active.size(), "pos": s.pos, "zone_id": s.zone_id})
	return active


func test_fills_to_min_then_caps_at_max() -> void:
	var d := SpawnDirector.new(rng)
	var active: Array[Dictionary] = []
	_run(d, active, SpawnDirector.ACTIVE_MIN)
	assert_eq(active.size(), SpawnDirector.ACTIVE_MIN, "one spawn per tick until min")
	_run(d, active, 400)
	assert_eq(active.size(), SpawnDirector.ACTIVE_MAX)


func test_at_most_one_spawn_per_tick() -> void:
	var d := SpawnDirector.new(rng)
	var r := d.tick(Vector3.ZERO, [] as Array[Dictionary], [_zone()], &"day", &"clear", _never_visible, 0.0)
	assert_eq(r.spawn.size(), 1)


func test_despawns_beyond_80m() -> void:
	var d := SpawnDirector.new(rng)
	var active: Array[Dictionary] = [{"id": 1, "pos": Vector3(81, 0, 0), "zone_id": &"z"}, {"id": 2, "pos": Vector3(70, 0, 0), "zone_id": &"z"}]
	var r := d.tick(Vector3.ZERO, active, [_zone()], &"day", &"clear", _never_visible, 0.0)
	assert_eq(r.despawn, [1])


func test_never_spawns_within_25m_or_visible() -> void:
	var d := SpawnDirector.new(rng)
	var visible := func(p: Vector3) -> bool: return p.x > 0.0
	for i in 300:
		var r := d.tick(Vector3.ZERO, [] as Array[Dictionary], [_zone()], &"day", &"clear", visible, 0.0)
		for s in r.spawn:
			assert_gte(Vector2(s.pos.x, s.pos.z).length(), 25.0)
			assert_lte(Vector2(s.pos.x, s.pos.z).length(), 60.0)
			assert_lte(s.pos.x, 0.0)


func test_no_valid_point_skips() -> void:
	var d := SpawnDirector.new(rng)
	var calls := [0]
	var always := func(_p: Vector3) -> bool:
		calls[0] += 1
		return true
	var r := d.tick(Vector3.ZERO, [] as Array[Dictionary], [_zone()], &"day", &"clear", always, 0.0)
	assert_eq(r.spawn.size(), 0)
	assert_lte(calls[0], SpawnDirector.MAX_POINT_TRIES)


func test_empty_table_for_period_skips() -> void:
	var d := SpawnDirector.new(rng)
	var night_only := SpawnTable.new({"id": "n", "entries": [{"species": "hoothoot", "min_lvl": 1, "max_lvl": 2, "weight": 1, "periods": ["night"]}]})
	var z := {"id": &"z", "table": night_only, "rect": Rect2(-50, -50, 100, 100), "y": 0.0}
	var r := d.tick(Vector3.ZERO, [] as Array[Dictionary], [z], &"day", &"clear", _never_visible, 0.0)
	assert_eq(r.spawn.size(), 0)


func test_zone_out_of_range_ignored() -> void:
	var d := SpawnDirector.new(rng)
	var far := {"id": &"far", "table": table, "rect": Rect2(500, 500, 50, 50), "y": 0.0}
	var r := d.tick(Vector3.ZERO, [] as Array[Dictionary], [far], &"day", &"clear", _never_visible, 0.0)
	assert_eq(r.spawn.size(), 0)


func test_respawn_waits_1_to_3_game_minutes() -> void:
	var d := SpawnDirector.new(rng)
	d.on_removed(&"z", 100.0)
	var early := d.tick(Vector3.ZERO, [] as Array[Dictionary], [_zone()], &"day", &"clear", _never_visible, 100.9)
	assert_eq(early.spawn.size(), 0, "blocked under 1 game minute")
	var late := d.tick(Vector3.ZERO, [] as Array[Dictionary], [_zone()], &"day", &"clear", _never_visible, 103.01)
	assert_eq(late.spawn.size(), 1, "free after 3 game minutes")


func test_respawn_handles_midnight_wrap() -> void:
	var d := SpawnDirector.new(rng)
	d.on_removed(&"z", 1439.5)
	var r := d.tick(Vector3.ZERO, [] as Array[Dictionary], [_zone()], &"day", &"clear", _never_visible, 3.0 + 1440.0)
	assert_eq(r.spawn.size(), 1)


func test_shiny_rate_seeded() -> void:
	var d := SpawnDirector.new(rng)
	var n := 0
	for i in 819200:
		if d.roll_shiny():
			n += 1
	assert_between(n, 70, 130)
