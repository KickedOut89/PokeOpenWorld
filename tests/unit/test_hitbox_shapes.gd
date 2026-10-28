extends GutTest


func test_melee_arc_hits_inside_only() -> void:
	var s := {"shape": "melee_arc", "range": 2.5, "arc_deg": 90, "accuracy": 100}
	assert_true(HitboxShapes.hits(s, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -2), 0.4))
	assert_false(HitboxShapes.hits(s, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 2), 0.4), "behind")
	assert_false(HitboxShapes.hits(s, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -3.5), 0.4), "out of range")
	assert_false(HitboxShapes.hits(s, Vector3.ZERO, Vector3.FORWARD, Vector3(2, 0, -0.5), 0.4), "outside the arc")


func test_low_accuracy_narrows_arc() -> void:
	var wide := {"shape": "melee_arc", "range": 2.5, "arc_deg": 100, "accuracy": 100}
	var narrow := {"shape": "melee_arc", "range": 2.5, "arc_deg": 100, "accuracy": 60}
	var target := Vector3(1.3, 0, -1.5)  # ~41 degrees off-axis
	assert_true(HitboxShapes.hits(wide, Vector3.ZERO, Vector3.FORWARD, target, 0.0))
	assert_false(HitboxShapes.hits(narrow, Vector3.ZERO, Vector3.FORWARD, target, 0.0))


func test_projectile_and_area_radius() -> void:
	var p := {"shape": "projectile", "radius": 0.6}
	assert_true(HitboxShapes.hits(p, Vector3(0, 0, -5), Vector3.FORWARD, Vector3(0.5, 0, -5), 0.4))
	assert_false(HitboxShapes.hits(p, Vector3(0, 0, -5), Vector3.FORWARD, Vector3(2, 0, -5), 0.4))
	var a := {"shape": "area", "radius": 3.0}
	assert_true(HitboxShapes.hits(a, Vector3.ZERO, Vector3.FORWARD, Vector3(2.5, 0, 0), 0.4))


func test_beam_hits_along_line() -> void:
	var b := {"shape": "beam", "range": 10.0, "radius": 0.5}
	assert_true(HitboxShapes.hits(b, Vector3.ZERO, Vector3.FORWARD, Vector3(0.3, 0, -8), 0.4))
	assert_false(HitboxShapes.hits(b, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -12), 0.4))
	assert_false(HitboxShapes.hits(b, Vector3.ZERO, Vector3.FORWARD, Vector3(2, 0, -5), 0.4))


func test_self_never_hits_others() -> void:
	assert_false(HitboxShapes.hits({"shape": "self"}, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -1), 1.0))


func test_projectile_travel_time() -> void:
	assert_almost_eq(HitboxShapes.travel_time({"shape": "projectile", "range": 12.0, "speed": 16.0}), 0.75, 0.001)
	assert_eq(HitboxShapes.travel_time({"shape": "melee_arc", "range": 2.5}), 0.0)
