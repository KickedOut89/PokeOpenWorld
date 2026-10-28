extends GutTest


func _def(rec: Dictionary) -> MoveDef:
	return MoveDef.new(rec)


func test_priority_windup() -> void:
	assert_eq(_def({"priority": 1, "accuracy": 100}).windup(50), 0.05)


func test_low_accuracy_longer_windup() -> void:
	var sure := _def({"accuracy": 100}).windup(100)
	var shaky := _def({"accuracy": 70}).windup(100)
	assert_gt(shaky, sure)
	assert_almost_eq(sure, 0.35, 0.001, "spe 100 -> x1.0")


func test_speed_shortens_windup() -> void:
	assert_lt(_def({"accuracy": 100}).windup(200), _def({"accuracy": 100}).windup(20))
	assert_almost_eq(_def({"accuracy": 100}).windup(400), 0.35 * 0.6, 0.001, "clamped at 0.6x")


func test_windup_override() -> void:
	assert_eq(_def({"windup_s": 0.9, "accuracy": 100}).windup(100), 0.9)


func test_executor_phases() -> void:
	var ex := MoveExecutor.new(_def({"accuracy": 100, "active_s": 0.2, "pp": 35}), 100)
	var seen: Array = []
	for i in 200:
		for e in ex.tick(0.01):
			seen.append(e)
	assert_eq(seen, [&"active_start", &"active_end", &"done"])
	assert_true(ex.is_done())


func test_no_rng_miss() -> void:
	var rec := {"accuracy": 50, "active_s": 0.15, "pp": 35, "shape": "melee_arc", "range": 2.5, "arc_deg": 100}
	var hits := 0
	for i in 1000:
		var ex := MoveExecutor.new(_def(rec), 60)
		var hit := false
		while not ex.is_done():
			ex.tick(0.02)
			if ex.is_active() and HitboxShapes.hits(rec, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -1.5), 0.4):
				hit = true
		if hit:
			hits += 1
	assert_eq(hits, 1000)
