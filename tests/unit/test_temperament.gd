extends GutTest

const HOME := Vector3.ZERO


func test_timid_flees_inside_10m() -> void:
	var r := Temperament.decide(&"timid", Vector3.ZERO, HOME, Vector3(9, 0, 0), false)
	assert_eq(r.action, &"flee")
	assert_lt((r.target as Vector3).x, 0.0, "runs away from the player")


func test_timid_wanders_outside_10m() -> void:
	assert_eq(Temperament.decide(&"timid", Vector3.ZERO, HOME, Vector3(11, 0, 0), false).action, &"wander")


func test_aggressive_charges_inside_8m() -> void:
	var r := Temperament.decide(&"aggressive", Vector3.ZERO, HOME, Vector3(0, 0, 7), false)
	assert_eq(r.action, &"charge")
	assert_eq(r.target, Vector3(0, 0, 7))
	assert_eq(Temperament.decide(&"aggressive", Vector3.ZERO, HOME, Vector3(0, 0, 9), false).action, &"wander")


func test_territorial_charges_near_home() -> void:
	var r := Temperament.decide(&"territorial", Vector3(3, 0, 0), HOME, Vector3(5, 0, 0), false)
	assert_eq(r.action, &"charge")
	assert_eq(Temperament.decide(&"territorial", Vector3(3, 0, 0), HOME, Vector3(7, 0, 0), false).action, &"wander")


func test_territorial_returns_when_far_from_home() -> void:
	var r := Temperament.decide(&"territorial", Vector3(16, 0, 0), HOME, Vector3(40, 0, 0), false)
	assert_eq(r.action, &"return")
	assert_eq(r.target, HOME)


func test_passive_idles() -> void:
	assert_eq(Temperament.decide(&"passive", Vector3.ZERO, HOME, Vector3(1, 0, 0), false).action, &"idle")


func test_attacked_passive_charges() -> void:
	assert_eq(Temperament.decide(&"passive", Vector3.ZERO, HOME, Vector3(1, 0, 0), true).action, &"charge")


func test_unknown_kind_wanders() -> void:
	assert_eq(Temperament.decide(&"grumpy", Vector3.ZERO, HOME, Vector3(1, 0, 0), false).action, &"wander")
