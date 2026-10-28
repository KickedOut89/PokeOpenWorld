extends GutTest


func test_tackle_cooldown_0_8() -> void:
	assert_almost_eq(Cooldowns.for_move({"pp": 35}), 0.8, 0.001)


func test_hydro_pump_cooldown_5_6() -> void:
	assert_almost_eq(Cooldowns.for_move({"pp": 5}), 5.6, 0.001)


func test_cooldown_clamped() -> void:
	assert_almost_eq(Cooldowns.for_move({"pp": 40}), 0.7, 0.001)
	assert_eq(Cooldowns.for_move({"pp": 1}), 8.0)
	assert_eq(Cooldowns.for_move({"pp": 64}), 0.6)


func test_override_wins() -> void:
	assert_eq(Cooldowns.for_move({"pp": 35, "cooldown_override": 3.0}), 3.0)


func test_all_slice_moves_have_cooldowns_in_range() -> void:
	var db := DataDB.load_dir("res://data")
	for id in db.table(&"moves"):
		assert_between(Cooldowns.for_move(db.table(&"moves")[id]), 0.6, 8.0, String(id))
