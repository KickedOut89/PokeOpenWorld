extends GutTest


func _p(extra: Dictionary = {}) -> Dictionary:
	var p := {"level": 50, "power": 80, "atk": 100, "def": 100, "stab": false, "type_mult": 1.0,
		"crit": false, "burn_physical": false, "weather_mult": 1.0, "roll": 100}
	p.merge(extra, true)
	return p


func test_damage_known_values() -> void:
	# base = floor(floor(22*80*100/100)/50)+2 = 37; STAB 55; x2 = 110. Roll 85: 31 -> 46 -> 92.
	assert_eq(Damage.calc(_p({"stab": true, "type_mult": 2.0})), 110)
	assert_eq(Damage.calc(_p({"stab": true, "type_mult": 2.0, "roll": 85})), 92)
	assert_eq(Damage.calc(_p()), 37)


func test_immune_deals_zero() -> void:
	assert_eq(Damage.calc(_p({"type_mult": 0.0})), 0)


func test_min_damage_one() -> void:
	assert_eq(Damage.calc(_p({"level": 2, "power": 10, "atk": 5, "def": 200, "type_mult": 0.25, "roll": 85})), 1)


func test_burn_halves() -> void:
	assert_eq(Damage.calc(_p({"burn_physical": true})), 18)


func test_crit_doubles() -> void:
	assert_eq(Damage.calc(_p({"crit": true})), 74)


func test_weather_mult() -> void:
	assert_eq(Damage.calc(_p({"weather_mult": 1.5})), 55)
	assert_eq(Damage.calc(_p({"weather_mult": 0.5})), 18)


func test_crit_chances() -> void:
	assert_eq(Damage.crit_chance(0), 1.0 / 16.0)
	assert_eq(Damage.crit_chance(1), 1.0 / 8.0)
	assert_eq(Damage.crit_chance(2), 1.0 / 4.0)
	assert_eq(Damage.crit_chance(3), 1.0 / 3.0)
	assert_eq(Damage.crit_chance(4), 1.0 / 2.0)
	assert_eq(Damage.crit_chance(9), 1.0 / 2.0)


func test_stage_mults() -> void:
	assert_eq(Damage.stage_mult(6), 4.0)
	assert_eq(Damage.stage_mult(-6), 0.25)
	assert_eq(Damage.stage_mult(1), 1.5)
	assert_eq(Damage.stage_mult(-1), 2.0 / 3.0)
	assert_eq(Damage.stage_mult(0), 1.0)
	assert_eq(Damage.stage_mult(9), 4.0, "clamped")


func test_weather_mult_lookup() -> void:
	assert_eq(Damage.weather_mult(&"water", &"rain"), 1.5)
	assert_eq(Damage.weather_mult(&"fire", &"rain"), 0.5)
	assert_eq(Damage.weather_mult(&"fire", &"sun"), 1.5)
	assert_eq(Damage.weather_mult(&"water", &"sun"), 0.5)
	assert_eq(Damage.weather_mult(&"fire", &"thunderstorm"), 0.5, "storms count as rain")
	assert_eq(Damage.weather_mult(&"grass", &"rain"), 1.0)
