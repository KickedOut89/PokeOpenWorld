class_name Cooldowns
extends RefCounted
## PP is replaced by cooldowns: fewer PP means a longer wait between uses.

const BASE := 28.0
const MIN_S := 0.6
const MAX_S := 8.0


static func for_move(m: Dictionary) -> float:
	if m.has("cooldown_override"):
		return float(m.cooldown_override)
	return clampf(BASE / maxf(1.0, float(m.get("pp", 10))), MIN_S, MAX_S)
