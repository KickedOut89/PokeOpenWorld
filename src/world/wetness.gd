class_name Wetness
extends RefCounted
## Surface wetness 0..1: soaks in over 60 s of rain, dries over 120 s.

const WET_SECONDS := 60.0
const DRY_SECONDS := 120.0

var value: float = 0.0


func tick(delta: float, raining: bool) -> void:
	if raining:
		value = minf(1.0, value + delta / WET_SECONDS)
	else:
		value = maxf(0.0, value - delta / DRY_SECONDS)
