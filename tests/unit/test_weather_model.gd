extends GutTest


func _model(weights: Dictionary, seed_value: int = 1) -> WeatherModel:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return WeatherModel.new({"id": "t", "weights": weights, "reroll_hours": 3}, rng)


func test_roll_respects_weights() -> void:
	var m := _model({"clear": 3, "rain": 1})
	var rain := 0
	for i in 10000:
		if m.roll() == &"rain":
			rain += 1
	assert_almost_eq(rain / 10000.0, 0.25, 0.02)


func test_fog_never_rolled_when_absent() -> void:
	var m := _model({"clear": 1, "cloudy": 1, "rain": 1})
	for i in 2000:
		assert_ne(m.roll(), &"fog")


func test_unknown_weather_ids_ignored() -> void:
	var m := _model({"clear": 1, "hail": 50})
	for i in 200:
		assert_eq(m.roll(), &"clear")


func test_transition_seconds_in_range() -> void:
	var m := _model({"clear": 1})
	for i in 500:
		var t := m.transition_seconds()
		assert_between(t, 20.0, 40.0)


func test_blend_reaches_one_after_transition() -> void:
	var m := _model({"clear": 1, "rain": 1})
	m.current = &"clear"
	m.start_transition(&"rain")
	assert_eq(m.target, &"rain")
	assert_eq(m.blend, 0.0)
	for i in 50:
		m.tick(1.0)
	assert_eq(m.blend, 1.0)
	assert_eq(m.current, &"rain")


func test_reroll_hours_default() -> void:
	var rng := RandomNumberGenerator.new()
	var m := WeatherModel.new({"id": "t", "weights": {"clear": 1}}, rng)
	assert_eq(m.reroll_hours, 3)
