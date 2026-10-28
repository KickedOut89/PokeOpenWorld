class_name FlockNode
extends Node3D
## Scene side of Flock: a few Pidgey billboards perched around this node.

var flock: Flock
var _sprites: Array[BillboardSprite] = []


static func make(count: int, seed_value: int) -> FlockNode:
	var n := FlockNode.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var perches := PackedVector3Array()
	for i in count:
		perches.append(Vector3(rng.randf_range(-2.5, 2.5), 0, rng.randf_range(-2.5, 2.5)))
	n.flock = Flock.new(perches)
	for i in count:
		var s := BillboardSprite.new()
		s.pixel_size = 0.022
		s.position = perches[i]
		n.add_child(s)
		n._sprites.append(s)
	return n


func _ready() -> void:
	add_to_group(&"ambient")
	var assets := get_node_or_null(^"/root/Assets")
	if assets != null:
		for s in _sprites:
			s.set_sheet(assets.texture("species/pidgey"))


func _physics_process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	if p == null:
		return
	var local := to_local(p.global_position)
	var pos := flock.step(local, delta)
	for i in _sprites.size():
		_sprites[i].position = pos[i]
		_sprites[i].walking = flock.flying
