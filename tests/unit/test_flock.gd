extends GutTest


func _flock() -> Flock:
	return Flock.new(PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]))


func test_flock_rests_when_player_far() -> void:
	var f := _flock()
	var p := f.step(Vector3(50, 0, 0), 0.5)
	assert_eq(p[0], Vector3.ZERO)
	assert_false(f.flying)


func test_flock_scatters_inside_6m() -> void:
	var f := _flock()
	var p := f.step(Vector3(5, 0, 0), 0.5)
	assert_true(f.flying)
	for i in 10:
		p = f.step(Vector3(5, 0, 0), 0.1)
	assert_gt(p[0].y, 1.0, "birds climb")
	assert_lt(p[0].x, 0.0, "and move away from the player")


func test_flock_resettles() -> void:
	var f := _flock()
	f.step(Vector3(5, 0, 0), 0.1)
	for i in 230:
		f.step(Vector3(50, 0, 0), 0.1)
	assert_false(f.flying, "resettled after 20 s")
	var p := f.step(Vector3(50, 0, 0), 0.1)
	assert_almost_eq(p[1].distance_to(Vector3(1, 0, 0)), 0.0, 0.05)
