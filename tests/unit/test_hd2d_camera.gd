extends GutTest


func test_camera_pitch_and_distance() -> void:
	var cam := HD2DCamera.new()
	var focus := Vector3(10, 2, -5)
	var t := cam.target_transform(focus, false)
	var expected := focus + Vector3(0, sin(deg_to_rad(35.0)) * 22.0, cos(deg_to_rad(35.0)) * 22.0)
	assert_almost_eq(t.origin.distance_to(expected), 0.0, 0.01)
	var fwd := -t.basis.z
	assert_almost_eq(fwd.dot((focus - t.origin).normalized()), 1.0, 0.001, "looks at focus")
	cam.free()


func test_camera_combat_distance() -> void:
	var cam := HD2DCamera.new()
	var t := cam.target_transform(Vector3.ZERO, true)
	assert_almost_eq(t.origin.length(), 16.0, 0.01)
	cam.free()


func test_camera_fov_default() -> void:
	var cam := HD2DCamera.new()
	assert_eq(cam.fov, 30.0)
	cam.free()
