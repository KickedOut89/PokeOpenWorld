class_name KantoWorld
extends Node3D
## Root of the Kanto overworld: terrain chunks, the player, camera and lighting.
## Milestone 1 builds every chunk up front; WorldStreamer (Task 10) replaces that.

const SEED := 1996

var lib: MeshLibrary
var builder: ChunkBuilder
var player: Player
var camera: HD2DCamera
var lighting: LightingDirector
var current_area: StringName = &""
var chunk_records: Dictionary = {}  # Vector2i -> ChunkData

@onready var chunks_root: Node3D = $Chunks


func _ready() -> void:
	lib = MeshLibraryBuilder.build(Data.db.table(&"tileset"))
	builder = ChunkBuilder.new(lib, SEED)
	for id in Data.db.table(&"chunks"):
		var d := ChunkData.from_record(Data.db.table(&"chunks")[id])
		chunk_records[d.coord] = d
	_load_initial_chunks()
	lighting = LightingDirector.new()
	lighting.name = "Lighting"
	add_child(lighting)
	player = load("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	add_child(player)
	player.global_position = find_anchor(&"player_spawn") + Vector3(0, 0.2, 0)
	camera = HD2DCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.target = player
	camera.make_current()
	camera.snap()


func _load_initial_chunks() -> void:
	for coord in chunk_records:
		chunks_root.add_child(builder.build(chunk_records[coord]))


func find_anchor(id: StringName) -> Vector3:
	for coord in chunk_records:
		var d: ChunkData = chunk_records[coord]
		for a in d.npc_anchors:
			if StringName(a.id) == id:
				return d.origin() + Vector3(float(a.pos[0]), float(a.pos[1]), float(a.pos[2]))
	return Vector3.ZERO


func area_at(pos: Vector3) -> StringName:
	var d: ChunkData = chunk_records.get(StreamingMath.chunk_of(pos), null)
	return d.area if d != null else &""


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var a := area_at(player.global_position)
	if a != &"" and a != current_area:
		current_area = a
		EventBus.area_entered.emit(a)
