extends GutTest


func test_period_boundaries() -> void:
	var cases := {4: &"morning", 9: &"morning", 10: &"day", 16: &"day",
		17: &"evening", 19: &"evening", 20: &"night", 3: &"night"}
	for h in cases:
		assert_eq(ClockModel.period_for(h), cases[h], "hour %d" % h)


func test_night_wraps_midnight() -> void:
	assert_eq(ClockModel.period_for(23), &"night")
	assert_eq(ClockModel.period_for(0), &"night")


func test_default_rate_one_real_hour_is_one_day() -> void:
	var c := ClockModel.new()
	c.minutes = 8 * 60.0
	var d0 := c.day
	c.advance(3600.0)
	assert_eq(c.day, d0 + 1)
	assert_almost_eq(c.minutes, 8 * 60.0, 0.01)


func test_advance_reports_crossed_hours_in_order() -> void:
	var c := ClockModel.new()
	c.minutes = 9 * 60.0 + 50.0
	# 20 game minutes at 24x = 50 real seconds
	var events := c.advance(50.0)
	assert_eq(events, [&"hour:10", &"period:day"] as Array[StringName])
	events = c.advance(1.0)
	assert_eq(events.size(), 0)


func test_advance_across_midnight_increments_day() -> void:
	var c := ClockModel.new()
	c.minutes = 23 * 60.0 + 30.0
	var events := c.advance(75.0) # 30 game minutes
	assert_eq(c.day, 1)
	assert_true(events.has(&"hour:0"))
	assert_eq(c.hour(), 0)


func test_real_time_mode_tracks_system_dict() -> void:
	var c := ClockModel.new()
	c.use_real_time = true
	c.set_from_system({"hour": 23, "minute": 59, "second": 0})
	var d0 := c.day
	var events := c.set_from_system({"hour": 0, "minute": 1, "second": 0})
	assert_eq(c.day, d0 + 1)
	assert_true(events.has(&"hour:0"))
	assert_eq(c.advance(100.0).size(), 0, "advance is ignored in real-time mode")
