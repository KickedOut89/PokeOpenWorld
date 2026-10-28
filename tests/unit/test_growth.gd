extends GutTest


func test_medium_slow_level_5() -> void:
	assert_eq(Growth.exp_for_level(&"medium_slow", 5), 135)


func test_medium_fast_level_100() -> void:
	assert_eq(Growth.exp_for_level(&"medium_fast", 100), 1000000)


func test_fluctuating_level_100() -> void:
	assert_eq(Growth.exp_for_level(&"fluctuating", 100), 1640000)


func test_erratic_level_100() -> void:
	assert_eq(Growth.exp_for_level(&"erratic", 100), 600000)


func test_slow_and_fast_level_100() -> void:
	assert_eq(Growth.exp_for_level(&"slow", 100), 1250000)
	assert_eq(Growth.exp_for_level(&"fast", 100), 800000)


func test_level_one_is_zero() -> void:
	for c in [&"erratic", &"fast", &"medium_fast", &"medium_slow", &"slow", &"fluctuating"]:
		assert_eq(Growth.exp_for_level(c, 1), 0, String(c))


func test_curves_are_increasing() -> void:
	for c in [&"erratic", &"fast", &"medium_fast", &"medium_slow", &"slow", &"fluctuating"]:
		for lvl in range(2, 101):
			assert_gt(Growth.exp_for_level(c, lvl), Growth.exp_for_level(c, lvl - 1), "%s %d" % [c, lvl])


func test_level_for_exp() -> void:
	assert_eq(Growth.level_for_exp(&"medium_fast", 999), 9)
	assert_eq(Growth.level_for_exp(&"medium_fast", 1000), 10)


func test_exp_gain_scales_with_level_gap() -> void:
	var low := Growth.gen5_exp_gain(50, 10, 5, false)
	var high := Growth.gen5_exp_gain(50, 10, 15, false)
	assert_gt(low, high)
	assert_gt(Growth.gen5_exp_gain(50, 10, 10, true), Growth.gen5_exp_gain(50, 10, 10, false), "trainer bonus")


func test_exp_gain_equal_levels_known_value() -> void:
	# b=50, L=10 vs 10: floor(50*10/5)=100; (30/30)^2.5 = 1 -> 100 + 1
	assert_eq(Growth.gen5_exp_gain(50, 10, 10, false), 101)
