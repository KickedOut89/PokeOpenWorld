extends GutTest


func test_hp_formula() -> void:
	assert_eq(Stats.hp(35, 31, 0, 50), 110, "Pikachu Lv50 IV31")


func test_hp_with_evs() -> void:
	assert_eq(Stats.hp(35, 31, 252, 50), 142, "floor((70+31+63)*50/100)+60")


func test_other_formula_with_nature() -> void:
	assert_eq(Stats.other(55, 31, 0, 50, 1.1), 82)
	assert_eq(Stats.other(55, 31, 0, 50, 1.0), 75)
	assert_eq(Stats.other(55, 31, 0, 50, 0.9), 67)
