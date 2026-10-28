class_name ThrowAim
extends RefCounted
## Ballistic throw solve: a lob that peaks `apex` m above the higher end and lands on target.

const GRAVITY := 9.8
const MAX_RANGE := 20.0


static func arc(origin: Vector3, target: Vector3, apex: float = 2.0) -> Dictionary:
	var flat := Vector2(target.x - origin.x, target.z - origin.z)
	if flat.length() > MAX_RANGE:
		return {"ok": false, "velocity": Vector3.ZERO, "time": 0.0}
	var peak := maxf(origin.y, target.y) + apex
	var vy := sqrt(2.0 * GRAVITY * (peak - origin.y))
	var t_up := vy / GRAVITY
	var t_down := sqrt(2.0 * (peak - target.y) / GRAVITY)
	var t := t_up + t_down
	var vxz := flat / t
	return {"ok": true, "velocity": Vector3(vxz.x, vy, vxz.y), "time": t}
