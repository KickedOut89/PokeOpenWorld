class_name Damage
extends RefCounted
## Gen 5 damage formula, applied in Gen 5 order with flooring at each step.

const CRIT_MULT := 2.0
const STAB_MULT := 1.5
const CRIT_TABLE := [1.0 / 16.0, 1.0 / 8.0, 1.0 / 4.0, 1.0 / 3.0, 1.0 / 2.0]


## p: {level, power, atk, def, stab, type_mult, crit, burn_physical, weather_mult, roll (85-100)}
static func calc(p: Dictionary) -> int:
	var type_mult := float(p.get("type_mult", 1.0))
	if type_mult == 0.0:
		return 0
	var lvl := int(p.level)
	var base := floori(floori(floori(2.0 * lvl / 5.0 + 2.0) * int(p.power) * int(p.atk) / float(maxi(1, int(p.def)))) / 50.0) + 2
	var d := base
	d = floori(d * float(p.get("weather_mult", 1.0)))
	if p.get("crit", false):
		d = floori(d * CRIT_MULT)
	d = floori(d * int(p.get("roll", 100)) / 100.0)
	if p.get("stab", false):
		d = floori(d * STAB_MULT)
	d = floori(d * type_mult)
	if p.get("burn_physical", false):
		d = floori(d * 0.5)
	return maxi(1, d)


static func crit_chance(stage: int) -> float:
	return CRIT_TABLE[clampi(stage, 0, CRIT_TABLE.size() - 1)]


static func stage_mult(stage: int) -> float:
	var s := clampi(stage, -6, 6)
	return (2.0 + s) / 2.0 if s >= 0 else 2.0 / (2.0 - s)


## Rain (and thunderstorms) boost Water x1.5 and weaken Fire x0.5; harsh sun is the reverse.
static func weather_mult(move_type: StringName, weather: StringName) -> float:
	var rainy := weather == &"rain" or weather == &"thunderstorm"
	if rainy:
		return 1.5 if move_type == &"water" else (0.5 if move_type == &"fire" else 1.0)
	if weather == &"sun":
		return 1.5 if move_type == &"fire" else (0.5 if move_type == &"water" else 1.0)
	return 1.0
