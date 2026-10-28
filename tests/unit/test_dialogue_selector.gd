extends GutTest

var rng: RandomNumberGenerator
var sel := DialogueSelector.new()


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 3


func _ctx(period: StringName = &"day", weather: StringName = &"clear", flags: Dictionary = {}) -> Dictionary:
	return {"period": period, "weather": weather, "flags": flags}


func test_specific_line_beats_generic() -> void:
	var lines := [{"text": "Hello."}, {"text": "Rainy morning!", "when": {"periods": ["morning"], "weather": ["rain"]}},
		{"text": "Good morning.", "when": {"periods": ["morning"]}}]
	assert_eq(sel.pick(lines, _ctx(&"morning", &"rain"), rng), "Rainy morning!")
	assert_eq(sel.pick(lines, _ctx(&"morning", &"clear"), rng), "Good morning.")
	assert_eq(sel.pick(lines, _ctx(&"night", &"clear"), rng), "Hello.")


func test_flag_and_not_flag() -> void:
	var lines := [{"text": "Go see Oak!", "when": {"not_flag": "got_starter"}},
		{"text": "How's your partner?", "when": {"flag": "got_starter"}}]
	assert_eq(sel.pick(lines, _ctx(), rng), "Go see Oak!")
	assert_eq(sel.pick(lines, _ctx(&"day", &"clear", {&"got_starter": true}), rng), "How's your partner?")


func test_weather_accepts_string() -> void:
	var lines := [{"text": "Storm!", "when": {"weather": "thunderstorm"}}, {"text": "Hi."}]
	assert_eq(sel.pick(lines, _ctx(&"day", &"thunderstorm"), rng), "Storm!")


func test_no_match_returns_empty() -> void:
	var lines := [{"text": "Night only.", "when": {"periods": ["night"]}}]
	assert_eq(sel.pick(lines, _ctx(), rng), "")
	assert_eq(sel.pick([], _ctx(), rng), "")


func test_weighted_among_equals() -> void:
	var lines := [{"text": "A", "weight": 3}, {"text": "B", "weight": 1}]
	var a := 0
	for i in 4000:
		if sel.pick(lines, _ctx(), rng) == "A":
			a += 1
	assert_almost_eq(a / 4000.0, 0.75, 0.03)


func test_pick_line_returns_whole_line() -> void:
	var lines := [{"text": "Choose!", "branch": "oak_start"}]
	assert_eq(sel.pick_line(lines, _ctx(), rng).branch, "oak_start")
