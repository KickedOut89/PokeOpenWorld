class_name HD2DCamera
extends Camera3D
## Fixed-pitch follow camera for the HD-2D look: narrow FOV, high angle, smooth follow.

@export var pitch_deg: float = 35.0
@export var distance: float = 22.0
@export var combat_distance: float = 16.0
@export var follow_lerp: float = 8.0

var target: Node3D
var in_combat: bool = false


func _init() -> void:
	fov = 30.0
	far = 400.0


func target_transform(focus: Vector3, combat: bool) -> Transform3D:
	var d := combat_distance if combat else distance
	var p := deg_to_rad(pitch_deg)
	var origin := focus + Vector3(0, sin(p) * d, cos(p) * d)
	return Transform3D(Basis(), origin).looking_at(focus, Vector3.UP)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var want := target_transform(target.global_position + Vector3(0, 1.0, 0), in_combat)
	global_transform = global_transform.interpolate_with(want, clampf(follow_lerp * delta, 0.0, 1.0))


func snap() -> void:
	if target != null:
		global_transform = target_transform(target.global_position + Vector3(0, 1.0, 0), in_combat)
