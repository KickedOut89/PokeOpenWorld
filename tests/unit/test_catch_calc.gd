extends GutTest

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 31


func test_full_hp_no_status_formula() -> void:
	assert_almost_eq(CatchCalc.modified_rate(20, 20, 255, 1.0, &"", false), 85.0, 0.001)


func test_one_hp_status_sleep() -> void:
	assert_almost_eq(CatchCalc.modified_rate(20, 1, 45, 1.0, &"slp", false), 45.0 * 58.0 / 60.0 * 2.5, 0.5)


func test_status_multipliers() -> void:
	var base := CatchCalc.modified_rate(30, 30, 45, 1.0, &"", false)
	assert_almost_eq(CatchCalc.modified_rate(30, 30, 45, 1.0, &"frz", false), base * 2.5, 0.001)
	for s in [&"par", &"psn", &"brn"]:
		assert_almost_eq(CatchCalc.modified_rate(30, 30, 45, 1.0, s, false), base * 1.5, 0.001)


func test_sneak_multiplier() -> void:
	var base := CatchCalc.modified_rate(30, 30, 45, 1.0, &"", false)
	assert_almost_eq(CatchCalc.modified_rate(30, 30, 45, 1.0, &"", true), base * 1.5, 0.001)


func test_capped_at_255() -> void:
	assert_eq(CatchCalc.modified_rate(20, 1, 255, 2.0, &"slp", true), 255.0)


func test_cap_255_always_catches() -> void:
	for i in 200:
		var r := CatchCalc.attempt(255.0, 0, rng)
		assert_true(r.caught)
		assert_eq(r.shakes, 3)


func test_no_critical_under_31_caught() -> void:
	for i in 2000:
		assert_false(CatchCalc.attempt(100.0, 30, rng).critical)


func test_critical_capture_possible_with_big_dex() -> void:
	var crits := 0
	for i in 4000:
		if CatchCalc.attempt(100.0, 601, rng).critical:
			crits += 1
	# floor(100 * 2.5 / 6) = 41 -> 41/256 ~ 16%
	assert_almost_eq(crits / 4000.0, 41.0 / 256.0, 0.02)


func test_catch_rate_distribution() -> void:
	var caught := 0
	for i in 20000:
		if CatchCalc.attempt(45.0, 0, rng).caught:
			caught += 1
	var b := floorf(65536.0 / pow(255.0 / 45.0, 0.25))
	var expected := pow(b / 65536.0, 3.0)
	assert_almost_eq(caught / 20000.0, expected, 0.015, "closed form %.4f" % expected)


func test_shakes_count_passes_before_failure() -> void:
	for i in 500:
		var r := CatchCalc.attempt(30.0, 0, rng)
		assert_between(r.shakes, 0, 3)
		assert_eq(r.caught, r.shakes == 3 and not r.critical)
