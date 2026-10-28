class_name InteriorManager
extends Node
## Moves the player between the overworld and interiors with a short fade.
## Interiors are built far above the overworld (INTERIOR_ORIGIN) while the
## overworld is hidden; its chunks stay pinned so returning is instant.

signal entered(interior_id: StringName)
signal exited(interior_id: StringName)

const INTERIOR_ORIGIN := Vector3(0, 1000, 0)
const PIN_OWNER := -1000
const EXIT_OFFSET := 1.5

var fade_seconds: float = 0.3
var current_interior: Node3D
var current_id: StringName = &""

var _player: Node3D
var _world: Node3D
var _db: DataDB
var _door_world_pos: Vector3
var current_door: Dictionary = {}
var _fade: ColorRect


func setup(player: Node3D, world: Node3D, db: DataDB) -> void:
	_player = player
	_world = world
	_db = db
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func is_inside() -> bool:
	return current_interior != null


func has_interior(id: StringName) -> bool:
	var rec := _db.get_record(&"interiors", id)
	return not rec.is_empty() and not _db.get_record(&"interior_templates", StringName(rec.get("template", ""))).is_empty()


## door_world_pos: the door's world position (outdoor return point is 1.5 m south of it).
func enter(door: Dictionary, door_world_pos: Vector3) -> bool:
	var id := StringName(door.get("interior", ""))
	if is_inside() or not has_interior(id):
		return false
	await _fade_to(1.0)
	var rec := _db.get_record(&"interiors", id)
	var tpl := _db.get_record(&"interior_templates", StringName(rec.template))
	current_interior = InteriorBuilder.build(rec, tpl)
	current_interior.position = INTERIOR_ORIGIN
	_world.add_child(current_interior)
	_spawn_interior_npcs(rec, tpl)
	current_id = id
	current_door = door
	_door_world_pos = door_world_pos
	var streamer := _streamer()
	if streamer != null:
		streamer.pin(streamer.loaded_coords(), PIN_OWNER)
		streamer.visible = false
		streamer.target = null
	_player.global_position = (current_interior.get_node("Spawn") as Node3D).global_position
	_set_interior_lighting(true)
	_set_overworld_active(false)
	entered.emit(id)
	await _fade_to(0.0)
	return true


## Interior residents stand at the template's npc_spots (default: behind the counter line).
func _spawn_interior_npcs(rec: Dictionary, tpl: Dictionary) -> void:
	var spots: Array = tpl.get("npc_spots", [[0, 0, -2.0], [-2.5, 0, -0.5], [2.5, 0, -0.5]])
	var i := 0
	for nid in rec.get("npcs", []):
		var nrec := _db.get_record(&"npcs", StringName(nid))
		if nrec.is_empty():
			continue
		var npc := NPC.make(nrec)
		current_interior.add_child(npc)
		var sp: Array = spots[i % spots.size()]
		npc.position = Vector3(float(sp[0]), 0.1, float(sp[2]))
		npc.goal = npc.global_position
		i += 1


func exit() -> void:
	if not is_inside():
		return
	await _fade_to(1.0)
	var id := current_id
	current_interior.queue_free()
	current_interior = null
	current_id = &""
	_player.global_position = _door_world_pos + Vector3(0, 0, EXIT_OFFSET)
	var streamer := _streamer()
	if streamer != null:
		streamer.visible = true
		streamer.target = _player
		streamer.unpin(PIN_OWNER)
	_set_interior_lighting(false)
	_set_overworld_active(true)
	exited.emit(id)
	await _fade_to(0.0)


func outdoor_return_point() -> Vector3:
	return _door_world_pos


func _streamer() -> WorldStreamer:
	return _world.get(&"streamer") as WorldStreamer if &"streamer" in _world else null


## Wild Pokémon (and later NPCs) outside pause and hide while the player is indoors.
func _set_overworld_active(on: bool) -> void:
	for prop in [&"spawner", &"npcs", &"ambient"]:
		var n: Variant = _world.get(prop) if prop in _world else null
		if n is Node3D:
			(n as Node3D).visible = on
			(n as Node).process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _set_interior_lighting(on: bool) -> void:
	var lighting: Variant = _world.get(&"lighting") if &"lighting" in _world else null
	if lighting is LightingDirector:
		(lighting as LightingDirector).interior = on


func _fade_to(alpha: float) -> void:
	if fade_seconds <= 0.0 or _fade == null:
		if _fade != null:
			_fade.color.a = alpha
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, fade_seconds * 0.5)
	await tw.finished
