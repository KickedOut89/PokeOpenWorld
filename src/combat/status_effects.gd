class_name StatusEffects
extends RefCounted
## Real-time versions of the main-series status conditions.

const PAR_SPEED := 0.25
const PAR_WINDOW := 2.0
const PAR_STUN_CHANCE := 0.25
const PAR_STUN := 0.75
const SLEEP_RANGE := Vector2(3.0, 6.0)
const FREEZE_RANGE := Vector2(2.0, 5.0)
const DOT_INTERVAL := 4.0
const IDS: Array[StringName] = [&"par", &"slp", &"psn", &"brn", &"frz"]


static func duration_for(id: StringName, rng: RandomNumberGenerator) -> float:
	match id:
		&"slp":
			return rng.randf_range(SLEEP_RANGE.x, SLEEP_RANGE.y)
		&"frz":
			return rng.randf_range(FREEZE_RANGE.x, FREEZE_RANGE.y)
	return INF


static func dot_damage(max_hp: int) -> int:
	return maxi(1, floori(max_hp / 8.0))
