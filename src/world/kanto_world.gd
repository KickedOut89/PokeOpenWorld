class_name KantoWorld
extends Node3D
## Root of the Kanto overworld: terrain chunks, the player, camera and lighting.
## Chunks stream in around the player through WorldStreamer.

const SEED := 1996

var streamer: WorldStreamer
var player: Player
var camera: HD2DCamera
var lighting: LightingDirector
var interiors: InteriorManager
var doors: DoorController
var toast: MessageToast
var weather_fx: WeatherFx
var spawner: SpawnNode
var npcs: NPCManager
var barks: BarkSystem
var dialogue: DialogueBox
var ambience: AmbiencePlayer
var _npc_t: float = 0.0


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
	interiors = InteriorManager.new()
	interiors.name = "Interiors"
	add_child(interiors)
	interiors.setup(player, self, Data.db)
	interiors.entered.connect(func(_id: StringName) -> void: camera.snap())
	interiors.exited.connect(func(_id: StringName) -> void: camera.snap())
	doors = DoorController.new()
	doors.name = "Doors"
	doors.player = player
	doors.interiors = interiors
	add_child(doors)
	weather_fx = WeatherFx.new()
	weather_fx.name = "WeatherFx"
	weather_fx.camera = camera
	weather_fx.lighting = lighting
	weather_fx.area = streamer.current_area
	add_child(weather_fx)
	weather_fx.track_library(streamer.library())
	spawner = SpawnNode.new()
	spawner.name = "Wilds"
	spawner.streamer = streamer
	spawner.camera = camera
	spawner.player = player
	add_child(spawner)
	npcs = NPCManager.new()
	npcs.name = "NPCs"
	add_child(npcs)
	npcs.cap = GraphicsPresets.npc_cap()
	npcs.setup(Data.db.table(&"npcs"), Data.db.table(&"schedules"), NPCManager.index_anchors(streamer.records()),
		func(rec: Dictionary) -> Node3D: return NPC.make(rec))
	update_npcs()
	barks = BarkSystem.new()
	barks.name = "Barks"
	barks.player = player
	add_child(barks)
	dialogue = DialogueBox.new()
	dialogue.name = "Dialogue"
	add_child(dialogue)
	dialogue.choice_made.connect(func(f: StringName) -> void: State.set_flag(f))
	dialogue.closed.connect(func() -> void: player.input_enabled = true)
	player.interacted.connect(_on_interact)
	ambience = AmbiencePlayer.new()
	ambience.name = "Ambience"
	ambience.area = streamer.current_area
	add_child(ambience)
	interiors.entered.connect(func(_id: StringName) -> void: ambience.indoors = true)
	interiors.exited.connect(func(_id: StringName) -> void: ambience.indoors = false)
	toast = MessageToast.new()
	toast.name = "Toast"
	add_child(toast)


func find_anchor(id: StringName) -> Vector3:
	for coord in streamer.records():
		var d: ChunkData = streamer.record(coord)
		for a in d.npc_anchors:
			if StringName(a.id) == id:
				return d.origin() + Vector3(float(a.pos[0]), float(a.pos[1]), float(a.pos[2]))
	return Vector3.ZERO


func _physics_process(delta: float) -> void:
	_npc_t -= delta
	if _npc_t <= 0.0:
		_npc_t = NPCManager.UPDATE_INTERVAL
		update_npcs()


func update_npcs() -> void:
	if npcs == null or interiors != null and interiors.is_inside():
		return
	npcs.cap = GraphicsPresets.npc_cap()
	var hour := Clock.model.minutes / 60.0
	npcs.update(player.global_position, hour, _weather_for_chunk, streamer.loaded_coords())


func _weather_for_chunk(c: Vector2i) -> StringName:
	var d := streamer.record(c)
	return Weather.weather_for_area(d.area) if d != null else &"clear"


func _on_interact(target: Node) -> void:
	if dialogue.is_open() or target == null:
		return
	var npc := target as NPC
	if npc == null:
		return
	talk_to(npc.record)


## Opens the NPC's context-picked talk line (and its branch, if any).
func talk_to(rec: Dictionary) -> void:
	var dlg := Data.db.get_record(&"dialogue", StringName(rec.get("dialogue", "")))
	var line := barks.selector.pick_line(dlg.get("talk", []), barks.context(), RandomNumberGenerator.new())
	if line.is_empty():
		return
	player.input_enabled = false
	dialogue.open(String(rec.get("name", "")), [line], dlg.get("branches", {}))
	EventBus.npc_talked.emit(StringName(rec.get("id", "")))
