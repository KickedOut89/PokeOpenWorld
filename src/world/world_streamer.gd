class_name WorldStreamer
extends Node3D
## Keeps the chunks around `target` built and in the tree.
## Must-load (3x3) chunks that are missing are built immediately (only happens on
## teleports); the 5x5 preload ring is built one chunk per frame, so a boundary
## crossing never pays for more than one build.
## Builds run on the main thread: physics/GridMap node setup is not thread-safe.

var target: Node3D
var last_update_usec: int = 0
var current_area: StringName = &""

var _planner: StreamingPlanner
var _builder: ChunkBuilder
var _records: Dictionary = {}   # Vector2i -> ChunkData
var _loaded: Dictionary = {}    # Vector2i -> Node3D
var _pins: Dictionary = {}      # owner id -> Array[Vector2i]


func setup_from_db(db: DataDB, seed_value: int) -> void:
	var lib := MeshLibraryBuilder.build(db.table(&"tileset"))
	_builder = ChunkBuilder.new(lib, seed_value)
	var coords: Array[Vector2i] = []
	for id in db.table(&"chunks"):
		var d := ChunkData.from_record(db.table(&"chunks")[id])
		_records[d.coord] = d
		coords.append(d.coord)
	_planner = StreamingPlanner.new(coords)


func has_record(c: Vector2i) -> bool:
	return _records.has(c)


func record(c: Vector2i) -> ChunkData:
	return _records.get(c, null)


func records() -> Dictionary:
	return _records


func is_loaded(c: Vector2i) -> bool:
	return _loaded.has(c)


func chunk_node(c: Vector2i) -> Node3D:
	return _loaded.get(c, null)


func loaded_coords() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_loaded.keys())
	return out


func pin(coords: Array[Vector2i], owner_id: int) -> void:
	_pins[owner_id] = coords.duplicate()


func unpin(owner_id: int) -> void:
	_pins.erase(owner_id)


func pinned() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in _pins:
		for c in _pins[k]:
			if not out.has(c):
				out.append(c)
	return out


func area_at(pos: Vector3) -> StringName:
	var d: ChunkData = _records.get(StreamingPlanner.chunk_of(pos), null)
	return d.area if d != null else &""


func _physics_process(_delta: float) -> void:
	if target != null and _planner != null:
		update_now()


func update_now() -> void:
	var t0 := Time.get_ticks_usec()
	var center := StreamingPlanner.chunk_of(target.global_position)
	var r := _planner.plan(center, loaded_coords(), pinned())
	for c in r.load:
		_attach(c)
	if r.load.is_empty() and not r.preload.is_empty():
		_attach(r.preload[0])
	for c in r.unload:
		var n: Node3D = _loaded[c]
		_loaded.erase(c)
		n.queue_free()
		EventBus.chunk_unloaded.emit(c)
	var a := area_at(target.global_position)
	if a != &"" and a != current_area:
		current_area = a
		EventBus.area_entered.emit(a)
	last_update_usec = Time.get_ticks_usec() - t0


func _attach(c: Vector2i) -> void:
	var n := _builder.build(_records[c])
	add_child(n)
	_loaded[c] = n
	EventBus.chunk_loaded.emit(c)
