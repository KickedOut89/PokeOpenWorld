extends GutTest

var m: LightingModel


func before_each() -> void:
	m = LightingModel.from_db(DataDB.load_dir("res://data"))


func _elev(dir: Vector3) -> float:
	# sun_dir is the direction light travels; elevation of the sun is the negated y.
	return -dir.normalized().y


func test_noon_sun_highest() -> void:
	var noon := _elev(m.sample(720, &"clear", &"clear", 1.0).sun_dir)
	assert_gt(noon, _elev(m.sample(540, &"clear", &"clear", 1.0).sun_dir))
	assert_gt(noon, _elev(m.sample(900, &"clear", &"clear", 1.0).sun_dir))
	assert_gt(noon, 0.8)


func test_sunrise_and_sunset_at_horizon() -> void:
	assert_almost_eq(_elev(m.sample(300, &"clear", &"clear", 1.0).sun_dir), 0.0, 0.02)
	assert_almost_eq(_elev(m.sample(1170, &"clear", &"clear", 1.0).sun_dir), 0.0, 0.02)


func test_midnight_sun_below_horizon_moon_up() -> void:
	var s := m.sample(0, &"clear", &"clear", 1.0)
	assert_lt(_elev(s.sun_dir), 0.0)
	assert_eq(s.sun_energy, 0.0)
	assert_gt(s.moon_energy, 0.0)
	var noon := m.sample(720, &"clear", &"clear", 1.0)
	assert_eq(noon.moon_energy, 0.0)


func test_interpolates_between_keyframes() -> void:
	var a := m.sample(600, &"clear", &"clear", 1.0)
	var b := m.sample(660, &"clear", &"clear", 1.0)
	var mid := m.sample(630, &"clear", &"clear", 1.0)
	assert_almost_eq(mid.ambient_energy, (a.ambient_energy + b.ambient_energy) * 0.5, 0.001)


func test_rain_darkens_and_raises_fog() -> void:
	var clear := m.sample(720, &"clear", &"clear", 1.0)
	var rain := m.sample(720, &"rain", &"rain", 1.0)
	assert_lt(rain.sun_energy, clear.sun_energy)
	assert_gt(rain.fog_density, clear.fog_density)


func test_blend_half_between_weathers() -> void:
	var clear := m.sample(720, &"clear", &"clear", 1.0)
	var rain := m.sample(720, &"rain", &"rain", 1.0)
	var half := m.sample(720, &"clear", &"rain", 0.5)
	assert_almost_eq(half.sun_energy, (clear.sun_energy + rain.sun_energy) * 0.5, 0.001)


func test_lamps_on_window() -> void:
	assert_true(m.sample(1050, &"clear", &"clear", 1.0).lamps_on, "17:30")
	assert_true(m.sample(120, &"clear", &"clear", 1.0).lamps_on, "02:00")
	assert_false(m.sample(360, &"clear", &"clear", 1.0).lamps_on, "06:00")
	assert_false(m.sample(1049, &"clear", &"clear", 1.0).lamps_on)


func test_wraps_midnight_keyframes() -> void:
	var late := m.sample(1439, &"clear", &"clear", 1.0)
	var early := m.sample(0, &"clear", &"clear", 1.0)
	assert_almost_eq(late.ambient_energy, early.ambient_energy, 0.02)
