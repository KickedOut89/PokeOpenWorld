class_name BarkSystem
extends Node
## NPCs say a short context line when the player passes within 4 m (30 s cooldown each).

const RANGE := 4.0
const COOLDOWN := 30.0
const SHOW := 3.0

var player: Node3D
var selector := DialogueSelector.new()
var _rng := RandomNumberGenerator.new()
var _last: Dictionary = {}  # npc id -> time


func _ready() -> void:
	_rng.randomize()


func context() -> Dictionary:
	var area: StringName = &""
	var streamer: WorldStreamer = get_parent().get(&"streamer") if &"streamer" in get_parent() else null
	if streamer != null and player != null:
		area = streamer.area_at(player.global_position)
	return {"period": Clock.model.period(), "weather": Weather.weather_for_area(area), "flags": State.flags}


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	for n in get_tree().get_nodes_in_group(&"npc"):
		var npc := n as NPC
		if npc == null or npc.global_position.distance_to(player.global_position) > RANGE:
			continue
		var id := StringName(npc.record.get("id", ""))
		if now - float(_last.get(id, -1000.0)) < COOLDOWN:
			continue
		_last[id] = now
		var dlg := Data.db.get_record(&"dialogue", StringName(npc.record.get("dialogue", "")))
		var text := selector.pick(dlg.get("barks", []), context(), _rng)
		if text != "":
			bark(npc, text)


static func bark(npc: Node3D, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 40
	l.outline_size = 10
	l.position.y = 3.2
	l.no_depth_test = true
	l.add_to_group(&"bark")
	npc.add_child(l)
	npc.get_tree().create_timer(SHOW).timeout.connect(l.queue_free)
