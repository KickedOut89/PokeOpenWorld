extends GutTest

var mixer: AmbienceMixer


func before_each() -> void:
	mixer = AmbienceMixer.new(Data.db.get_record(&"ambience", &"ambience"))


func test_night_forest_layers_include_crickets() -> void:
	var l := mixer.layers(&"forest", &"night", &"clear")
	assert_has(l, &"crickets")
	assert_false(l.has(&"birds"), "no daytime birdsong at night")


func test_day_route_has_birds() -> void:
	assert_has(mixer.layers(&"route", &"day", &"clear"), &"birds")


func test_rain_layer_added() -> void:
	var dry := mixer.layers(&"town", &"day", &"clear")
	var wet := mixer.layers(&"town", &"day", &"rain")
	assert_false(dry.has(&"rain"))
	assert_has(wet, &"rain")
	assert_lt(float(wet.get(&"birds", -80.0)), float(dry.get(&"birds", -80.0)), "birds quieter in rain")


func test_thunderstorm_louder_rain() -> void:
	assert_gt(float(mixer.layers(&"town", &"day", &"thunderstorm")[&"rain"]), float(mixer.layers(&"town", &"day", &"rain")[&"rain"]))


func test_unknown_ambience_is_silent() -> void:
	assert_eq(mixer.layers(&"space", &"day", &"clear"), {})
