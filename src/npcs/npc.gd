class_name NPC
extends CharacterBody3D
## A townsperson walking to its schedule anchor. Steering is direct with slide;
## if it gets stuck while off-camera it snaps to its goal (no navmesh in the slice).

const WALK := 2.2
const ARRIVE := 0.6
const STUCK_SECONDS := 4.0

var record: Dictionary
var goal: Vector3
var activity: StringName = &"idle"
var sprite: BillboardSprite
var umbrella: MeshInstance3D
var _think_interval: float = 0.0
var _think: float = 0.0
var _stuck: float = 0.0
var _last_pos: Vector3


static func make(rec: Dictionary) -> NPC:
	var n := NPC.new()
	n.record = rec
	n.name = "NPC_%s" % rec.get("id", "unknown")
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.8
	n.add_child(shape)
	n.collision_layer = 2
	n.collision_mask = 1
	n.sprite = BillboardSprite.new()
	n.add_child(n.sprite)
	n.umbrella = MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.8
	dome.height = 0.6
	dome.is_hemisphere = true
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(rec.get("umbrella_color", "#3a6ad0"))
	dome.material = m
	n.umbrella.mesh = dome
	n.umbrella.position.y = 2.7
	n.umbrella.visible = false
	n.add_child(n.umbrella)
	return n


func _ready() -> void:
	add_to_group(&"npc")
	var assets := get_node_or_null(^"/root/Assets")
	if assets != null:
		var key := "npc/%s" % record.get("sprite", "default")
		var tex: Texture2D = assets.texture(key)
		sprite.set_sheet(tex)
	_last_pos = global_position


func set_goal(pos: Vector3, res: Dictionary, think_interval: float) -> void:
	goal = pos
	activity = res.get("activity", &"idle")
	umbrella.visible = res.get("umbrella", false)
	_think_interval = think_interval


func _physics_process(delta: float) -> void:
	if _think_interval > 0.0:
		_think -= delta
		if _think > 0.0:
			move_and_slide()
			return
		_think = _think_interval
		delta = _think_interval
	var to := goal - global_position
	to.y = 0
	var dir := Vector3.ZERO
	if to.length() > ARRIVE:
		dir = to.normalized()
	velocity.x = dir.x * WALK
	velocity.z = dir.z * WALK
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	sprite.walking = dir != Vector3.ZERO
	if dir != Vector3.ZERO:
		sprite.face(Vector2(dir.x, dir.z))
	move_and_slide()
	if dir != Vector3.ZERO and global_position.distance_to(_last_pos) < 0.02:
		_stuck += delta
		var cam := get_viewport().get_camera_3d()
		if _stuck > STUCK_SECONDS and (cam == null or not cam.is_position_in_frustum(global_position)):
			global_position = goal
			_stuck = 0.0
	else:
		_stuck = 0.0
	_last_pos = global_position
