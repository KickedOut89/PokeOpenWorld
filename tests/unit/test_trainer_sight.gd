extends GutTest


func test_sees_in_front_within_range() -> void:
	assert_true(TrainerSight.sees(Vector3.ZERO, Vector3(0, 0, 1), Vector3(0, 0, 5), 6.0))
	assert_true(TrainerSight.sees(Vector3.ZERO, Vector3(0, 0, 1), Vector3(1.5, 0, 5), 6.0), "inside the 25° cone")


func test_blind_behind_and_beyond_range() -> void:
	assert_false(TrainerSight.sees(Vector3.ZERO, Vector3(0, 0, 1), Vector3(0, 0, -3), 6.0))
	assert_false(TrainerSight.sees(Vector3.ZERO, Vector3(0, 0, 1), Vector3(0, 0, 7), 6.0))
	assert_false(TrainerSight.sees(Vector3.ZERO, Vector3(0, 0, 1), Vector3(4, 0, 4), 6.0), "45° off-axis")


func test_bug_catchers_have_trainer_records() -> void:
	for i in 4:
		var t := TrainerSight.trainer_for(StringName("bug_catcher_%d" % i))
		assert_false(t.is_empty())
		assert_gt(t.party.size(), 0)
