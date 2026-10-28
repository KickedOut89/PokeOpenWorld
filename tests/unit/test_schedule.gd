extends GutTest

const REC := {"id": "baker", "blocks": [
	{"from": 6, "to": 8, "at": "market", "activity": "walk"},
	{"from": 8, "to": 17, "at": "bakery_stall", "activity": "work"},
	{"from": 17, "to": 19, "at": "park", "activity": "relax"},
]}


func _s(rec: Dictionary = REC) -> Schedule:
	return Schedule.new(rec, &"baker_house_door")


func test_block_lookup() -> void:
	var r := _s().resolve(9.5, &"clear", {})
	assert_eq(r.anchor, &"bakery_stall")
	assert_eq(r.activity, &"work")
	assert_false(r.indoors)
	assert_eq(_s().resolve(17.0, &"clear", {}).anchor, &"park")


func test_block_wrapping_midnight() -> void:
	var night := {"id": "owl", "blocks": [{"from": 20, "to": 7, "at": "plaza", "activity": "night_walk"}]}
	assert_eq(_s(night).resolve(23.0, &"clear", {}).anchor, &"plaza")
	assert_eq(_s(night).resolve(3.0, &"clear", {}).anchor, &"plaza")
	assert_true(_s(night).resolve(12.0, &"clear", {}).indoors, "outside the block -> home")


func test_gap_falls_back_home() -> void:
	var r := _s().resolve(22.0, &"clear", {})
	assert_eq(r.anchor, &"baker_house_door")
	assert_true(r.indoors)
	assert_eq(r.activity, &"home")


func test_rain_indoors_override() -> void:
	var r := _s().resolve(9.0, &"rain", {"rain": "indoors"})
	assert_true(r.indoors)
	assert_eq(r.anchor, &"baker_house_door")


func test_thunderstorm_defaults_indoors() -> void:
	assert_true(_s().resolve(9.0, &"thunderstorm", {}).indoors)


func test_umbrella_flag() -> void:
	var r := _s().resolve(9.0, &"rain", {"rain": "umbrella"})
	assert_false(r.indoors)
	assert_true(r.umbrella)
	assert_eq(r.anchor, &"bakery_stall")


func test_awning_keeps_place_without_umbrella() -> void:
	var r := _s().resolve(9.0, &"rain", {"rain": "awning"})
	assert_false(r.indoors)
	assert_false(r.umbrella)
	assert_eq(r.activity, &"shelter")


func test_default_rain_behavior_is_umbrella() -> void:
	assert_true(_s().resolve(9.0, &"rain", {}).umbrella)
