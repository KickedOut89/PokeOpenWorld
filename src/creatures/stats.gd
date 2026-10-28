class_name Stats
extends RefCounted
## Gen 3+ stat formulas (unchanged through Gen 5).

const NAMES: Array[StringName] = [&"hp", &"atk", &"def", &"spa", &"spd", &"spe"]


static func hp(base: int, iv: int, ev: int, lvl: int) -> int:
	return int(floor((2 * base + iv + floor(ev / 4.0)) * lvl / 100.0)) + lvl + 10


static func other(base: int, iv: int, ev: int, lvl: int, nature_mult: float) -> int:
	var raw := int(floor((2 * base + iv + floor(ev / 4.0)) * lvl / 100.0)) + 5
	return int(floor(raw * nature_mult))


static func nature_mult(nature: Dictionary, stat: StringName) -> float:
	if nature.get("plus", "") == String(stat):
		return 1.1
	if nature.get("minus", "") == String(stat):
		return 0.9
	return 1.0
