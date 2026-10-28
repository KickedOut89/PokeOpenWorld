class_name Companion
extends Node3D
## A resident's Pokémon that trots after its owner. Purely decorative: no collision,
## never fought or caught (group "ambient", not "wild").

const MIN_DIST := 1.5
const MAX_DIST := 2.5
const SPEED := 3.0
const REQUIRED_SHARE := 0.3

var species: StringName
var owner_node: Node3D
var sprite: BillboardSprite
var _side: float = 1.0


static func make(sp: StringName, owner_npc: Node3D) -> Companion:
	var c := Companion.new()
	c.species = sp
	c.owner_node = owner_npc
	c.top_level = true
	c.name = "Companion_%s" % sp
	c.sprite = BillboardSprite.new()
	c.sprite.pixel_size = 0.03
	c.add_child(c.sprite)
	return c


## True when at least 30% of a town's residents walk with a companion.
static func share_ok(with_companion: int, residents: int) -> bool:
	return residents == 0 or float(with_companion) / residents >= REQUIRED_SHARE - 0.0001


func _ready() -> void:
	add_to_group(&"ambient")
	_side = 1.0 if randf() < 0.5 else -1.0
	var assets := get_node_or_null(^"/root/Assets")
	if assets != null:
		sprite.set_sheet(assets.texture("species/%s" % species))
	if owner_node != null:
		global_position = owner_node.global_position + Vector3(_side * MIN_DIST, 0, 0.5)


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if owner_node == null or not is_instance_valid(owner_node):
		return
	var want := owner_node.global_position + Vector3(_side * 1.8, 0, 0.8)
	var to := want - global_position
	to.y = 0
	var dir := Vector3.ZERO
	var dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(owner_node.global_position.x, owner_node.global_position.z))
	if dist > MAX_DIST or (dist > MIN_DIST and to.length() > 0.3):
		dir = to.normalized()
		global_position += dir * SPEED * maxf(1.0, dist / MAX_DIST) * delta
	global_position.y = owner_node.global_position.y
	sprite.walking = dir != Vector3.ZERO
	if dir != Vector3.ZERO:
		sprite.face(Vector2(dir.x, dir.z))
