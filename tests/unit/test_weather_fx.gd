extends GutTest


func test_clear_has_no_rain() -> void:
	var t := WeatherFx.targets_for(&"clear")
	assert_eq(t.rain_rate, 0.0)
	assert_eq(t.lightning_interval, Vector2.ZERO)


func test_rain_has_rain_no_lightning() -> void:
	var t := WeatherFx.targets_for(&"rain")
	assert_gt(t.rain_rate, 0.0)
	assert_eq(t.lightning_interval, Vector2.ZERO)
	assert_true(t.wet)


func test_thunderstorm_has_lightning_interval() -> void:
	var t := WeatherFx.targets_for(&"thunderstorm")
	assert_gt(t.rain_rate, WeatherFx.targets_for(&"rain").rain_rate)
	assert_gt(t.lightning_interval.x, 0.0)
	assert_gt(t.lightning_interval.y, t.lightning_interval.x)


func test_fog_has_fog_volume() -> void:
	assert_gt(WeatherFx.targets_for(&"fog").fog_volume, 0.0)
	assert_eq(WeatherFx.targets_for(&"clear").fog_volume, 0.0)


func test_wetness_ramps_and_dries() -> void:
	var w := Wetness.new()
	for i in 30:
		w.tick(1.0, true)
	assert_almost_eq(w.value, 0.5, 0.01, "30 s of rain = half wet")
	for i in 30:
		w.tick(1.0, true)
	assert_almost_eq(w.value, 1.0, 0.01)
	for i in 60:
		w.tick(1.0, false)
	assert_almost_eq(w.value, 0.5, 0.01, "dries over 120 s")
	for i in 100:
		w.tick(1.0, false)
	assert_eq(w.value, 0.0)
