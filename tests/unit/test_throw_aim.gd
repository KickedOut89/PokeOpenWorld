extends GutTest


func _land(origin: Vector3, arc: Dictionary, floor_y: float) -> Vector3:
	var p := origin
	var v: Vector3 = arc.velocity
	var t := 0.0
	var dt := 1.0 / 600.0
	while t < arc.time:
		v.y -= ThrowAim.GRAVITY * dt
		p += v * dt
		t += dt
	return p


func test_arc_lands_on_target() -> void:
	var origin := Vector3(0, 1.5, 0)
	for target in [Vector3(0, 0.5, -10), Vector3(6, 0.5, -3), Vector3(-12, 2.5, 8)]:
		var a := ThrowAim.arc(origin, target)
		assert_true(a.ok)
		assert_almost_eq(_land(origin, a, target.y).distance_to(target), 0.0, 0.1, str(target))


func test_out_of_range_rejected() -> void:
	assert_false(ThrowAim.arc(Vector3.ZERO, Vector3(0, 0, -21)).ok)
	assert_true(ThrowAim.arc(Vector3.ZERO, Vector3(0, 0, -19.9)).ok)
