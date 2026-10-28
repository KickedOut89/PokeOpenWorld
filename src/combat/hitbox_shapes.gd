class_name HitboxShapes
extends RefCounted
## Aim-based hit tests replacing accuracy rolls. Lower accuracy shrinks arcs and radii
## (to 50% at accuracy 0), so shaky moves are easier to dodge but never miss at random.


static func accuracy_scale(shape: Dictionary) -> float:
	return 0.5 + 0.5 * clampf(float(shape.get("accuracy", 100)) / 100.0, 0.0, 1.0)


## origin: user position (melee/beam) or projectile/area centre; facing: unit aim direction.
static func hits(shape: Dictionary, origin: Vector3, facing: Vector3, target: Vector3, target_radius: float) -> bool:
	var to := Vector2(target.x - origin.x, target.z - origin.z)
	var f := Vector2(facing.x, facing.z).normalized()
	var k := accuracy_scale(shape)
	match String(shape.get("shape", "melee_arc")):
		"melee_arc":
			var r := float(shape.get("range", 2.5))
			if to.length() > r + target_radius:
				return false
			if to.length() < 0.001:
				return true
			var half := deg_to_rad(float(shape.get("arc_deg", 90.0)) * k * 0.5)
			return absf(f.angle_to(to)) <= half
		"projectile", "area":
			return to.length() <= float(shape.get("radius", 0.6)) * k + target_radius
		"beam":
			var length := float(shape.get("range", 10.0))
			var along := to.dot(f)
			if along < 0.0 or along > length + target_radius:
				return false
			var perp := absf(to.cross(f))
			return perp <= float(shape.get("radius", 0.5)) * k + target_radius
	return false


static func travel_time(shape: Dictionary) -> float:
	if String(shape.get("shape", "")) != "projectile":
		return 0.0
	return float(shape.get("range", 12.0)) / maxf(0.1, float(shape.get("speed", 16.0)))
