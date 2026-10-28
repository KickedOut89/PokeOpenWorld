class_name KantoWorld
extends Node3D
## Root of the Kanto overworld: terrain chunks, the player, camera and lighting.
## Chunks stream in around the player through WorldStreamer.

const SEED := 1996

var streamer: WorldStreamer
var player: Player
var camera: HD2DCamera
var lighting: LightingDirector


func _ready() -> void:
	streamer = WorldStreamer.new()
	streamer.name = "Chunks"
	add_child(streamer)
	streamer.setup_from_db(Data.db, SEED)
	lighting = LightingDirector.new()
	lighting.name = "Lighting"
	add_child(lighting)
	player = load("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	add_child(player)
	player.global_position = find_anchor(&"player_spawn") + Vector3(0, 0.2, 0)
	streamer.target = player
	streamer.update_now()
	camera = HD2DCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.target = player
	camera.make_current()
	camera.snap()


func find_anchor(id: StringName) -> Vector3:
	for coord in streamer.records():
		var d: ChunkData = streamer.record(coord)
		for a in d.npc_anchors:
			if StringName(a.id) == id:
				return d.origin() + Vector3(float(a.pos[0]), float(a.pos[1]), float(a.pos[2]))
	return Vector3.ZERO
