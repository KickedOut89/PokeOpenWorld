class_name Growth
extends RefCounted
## Experience curves and the Gen 5 scaled experience formula.

const MAX_LEVEL := 100


static func exp_for_level(curve: StringName, lvl: int) -> int:
	if lvl <= 1:
		return 0
	var n := float(lvl)
	var n3 := n * n * n
	match curve:
		&"erratic":
			if lvl < 50:
				return int(floor(n3 * (100 - n) / 50.0))
			if lvl < 68:
				return int(floor(n3 * (150 - n) / 100.0))
			if lvl < 98:
				return int(floor(n3 * floor((1911 - 10 * n) / 3.0) / 500.0))
			return int(floor(n3 * (160 - n) / 100.0))
		&"fast":
			return int(floor(4.0 * n3 / 5.0))
		&"medium_fast":
			return int(n3)
		&"medium_slow":
			return int(floor(1.2 * n3 - 15.0 * n * n + 100.0 * n - 140.0))
		&"slow":
			return int(floor(5.0 * n3 / 4.0))
		&"fluctuating":
			if lvl < 15:
				return int(floor(n3 * (floor((n + 1) / 3.0) + 24) / 50.0))
			if lvl < 36:
				return int(floor(n3 * (n + 14) / 50.0))
			return int(floor(n3 * (floor(n / 2.0) + 32) / 50.0))
	return int(n3)


static func level_for_exp(curve: StringName, total: int) -> int:
	var lvl := 1
	while lvl < MAX_LEVEL and exp_for_level(curve, lvl + 1) <= total:
		lvl += 1
	return lvl


## Gen 5: floor(floor(b*Lf/5) * trainer * ((2Lf+10)/(Lf+Lp+10))^2.5) + 1
static func gen5_exp_gain(base_exp: int, foe_lvl: int, my_lvl: int, trainer: bool) -> int:
	var a := floorf(base_exp * foe_lvl / 5.0)
	var t := 1.5 if trainer else 1.0
	var ratio := pow((2.0 * foe_lvl + 10.0) / (foe_lvl + my_lvl + 10.0), 2.5)
	return int(floor(a * t * ratio)) + 1
