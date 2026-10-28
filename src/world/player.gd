class_name Player
extends CharacterBody3D
## Overworld trainer avatar. Camera is fixed facing north (-z), so "up" moves -z.
## Moving south into a ledge hops down one cell; ledges cannot be climbed.

signal interacted(target: Node)

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const HOP_DISTANCE := 4.6
const HOP_TIME := 0.35

var input_enabled: bool = true
var facing: Vector2 = Vector2(0, 1)
var _hopping: bool = false

@onready var sprite: BillboardSprite = $Sprite


func _ready() -> void:
	InputSetup.register()
	add_to_group(&"player")
	var assets := get_node_or_null(^"/root/Assets")
	if assets != null:
		sprite.set_sheet(assets.texture("npc/player"))


func move_input() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _physics_process(delta: float) -> void:
	if _hopping:
		return
	var dir := move_input()
	var speed := RUN_SPEED if Input.is_action_pressed(&"run") else WALK_SPEED
	velocity.x = dir.x * speed
	velocity.z = dir.y * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	sprite.face(facing)
	sprite.walking = dir != Vector2.ZERO
	move_and_slide()
	if dir.y > 0.5:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i).get_collider()
			if c is Node and (c as Node).is_in_group(&"ledge"):
				_hop()
				break
	if input_enabled and Input.is_action_just_pressed(&"interact"):
		interacted.emit(_interact_target())


func _hop() -> void:
	_hopping = true
	var start := global_position
	var end := start + Vector3(0, 0, HOP_DISTANCE)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		global_position = start.lerp(end, t) + Vector3(0, sin(t * PI) * 1.2, 0), 0.0, 1.0, HOP_TIME)
	tw.finished.connect(func() -> void: _hopping = false)


func _interact_target() -> Node:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 1, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(facing.x, 0, facing.y) * 2.0)
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	return hit.get("collider", null)
