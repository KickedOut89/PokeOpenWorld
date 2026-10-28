class_name NPCManager
extends Node3D
## Tracks every NPC abstractly (where its schedule says it is) and keeps actors only
## for NPCs that are outdoors, in a loaded chunk, within SIM_RADIUS, up to `cap`.
## New actors appear directly at their anchor (abstract advancement).

const SIM_RADIUS := 80.0
const LOD_RADIUS := 40.0
const UPDATE_INTERVAL := 0.5

var cap: int = 60
var npcs: Dictionary = {}       # id -> record
var anchors: Dictionary = {}    # anchor id -> {pos: Vector3, chunk: Vector2i, area}
var _schedules: Dictionary = {} # npc id -> Schedule
var _actors: Dictionary = {}    # npc id -> Node3D
var _factory: Callable


static func think_interval(distance: float) -> float:
	return 0.25 if distance > LOD_RADIUS else 0.0


func setup(npc_records: Dictionary, schedule_records: Dictionary, anchor_index: Dictionary, factory: Callable) -> void:
	npcs = npc_records
	anchors = anchor_index
	_factory = factory
	for id in npcs:
		var rec: Dictionary = npcs[id]
		var sched: Dictionary = schedule_records.get(StringName(rec.get("schedule", "")), {})
		_schedules[id] = Schedule.new(sched, StringName(rec.get("home", "")))


func actor_count() -> int:
	return _actors.size()


func has_actor(id: StringName) -> bool:
	return _actors.has(id)


func actor(id: StringName) -> Node3D:
	return _actors.get(id, null)


func resolve(id: StringName, hour: float, weather_for: Callable) -> Dictionary:
	var rec: Dictionary = npcs[id]
	var sched: Schedule = _schedules[id]
	var first := sched.resolve(hour, &"clear", {})
	var a: Dictionary = anchors.get(first.anchor, {})
	var weather: StringName = weather_for.call(a.get("chunk", Vector2i.ZERO))
	return sched.resolve(hour, weather, rec.get("weather_behavior", {}))


## weather_for: Callable(chunk: Vector2i) -> StringName
func update(player_pos: Vector3, hour: float, weather_for: Callable, loaded: Array[Vector2i]) -> void:
	var wanted: Array = []
	for id in npcs:
		var r := resolve(id, hour, weather_for)
		var a: Dictionary = anchors.get(r.anchor, {})
		if r.indoors or a.is_empty() or not loaded.has(a.chunk):
			continue
		var d := Vector2(player_pos.x, player_pos.z).distance_to(Vector2(a.pos.x, a.pos.z))
		if d > SIM_RADIUS:
			continue
		wanted.append({"id": id, "dist": d, "res": r, "anchor": a})
	wanted.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.dist < y.dist)
	wanted = wanted.slice(0, cap)
	var keep := {}
	for w in wanted:
		keep[w.id] = true
		var n: Node3D = _actors.get(w.id, null)
		if n == null:
			n = _factory.call(npcs[w.id])
			add_child(n)
			n.global_position = w.anchor.pos
			_actors[w.id] = n
		if n.has_method(&"set_goal"):
			n.call(&"set_goal", w.anchor.pos, w.res, think_interval(w.dist))
	for id in _actors.keys():
		if not keep.has(id):
			(_actors[id] as Node3D).queue_free()
			_actors.erase(id)


## Builds the anchor index from chunk records: npc_anchors plus doors (a home is a door id).
static func index_anchors(records: Dictionary) -> Dictionary:
	var out := {}
	for c in records:
		var d: ChunkData = records[c]
		var o := d.origin()
		for a in d.npc_anchors:
			out[StringName(a.id)] = {"pos": o + Vector3(float(a.pos[0]), float(a.pos[1]), float(a.pos[2])), "chunk": d.coord, "area": d.area}
		for door in d.doors:
			out[StringName(door.id)] = {"pos": o + Vector3(float(door.pos[0]), float(door.pos[1]), float(door.pos[2]) + 1.2), "chunk": d.coord, "area": d.area}
	return out
