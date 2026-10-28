class_name DoorController
extends Node
## Walking north into a door tries it: open doors enter their interior, others show
## their locked text once per approach. Walking south into an interior exit leaves.

var interiors: InteriorManager
var player: Player
var _busy: bool = false
var _last_locked: StringName = &""


func _physics_process(_delta: float) -> void:
	if player == null or interiors == null or _busy:
		return
	if interiors.is_inside():
		if player.last_input.y > 0.5 and _overlapping(&"interior_exit") != null:
			_busy = true
			await interiors.exit()
			_busy = false
		return
	var door := _overlapping(&"door")
	if door == null:
		_last_locked = &""
		return
	if player.last_input.y > -0.5:
		return
	var rec: Dictionary = door.get_meta(&"door")
	var result := DoorUnlock.evaluate(rec, State, Clock.model.hour(), interiors.has_interior(StringName(rec.get("interior", ""))))
	if result.open:
		_busy = true
		await interiors.enter(rec, door.global_position)
		_busy = false
	elif _last_locked != StringName(rec.id):
		_last_locked = StringName(rec.id)
		EventBus.message.emit(result.text)


func _overlapping(group: StringName) -> Area3D:
	for n in get_tree().get_nodes_in_group(group):
		var a := n as Area3D
		if a == null or not a.is_inside_tree():
			continue
		var local := a.to_local(player.global_position)
		var shape := a.get_child(0) as CollisionShape3D
		if shape == null or not shape.shape is BoxShape3D:
			continue
		var half := (shape.shape as BoxShape3D).size * 0.5 + Vector3(0.4, 0, 0.4)
		var p := local - shape.position
		if absf(p.x) <= half.x and absf(p.z) <= half.z and absf(p.y) <= half.y + 1.0:
			return a
	return null
