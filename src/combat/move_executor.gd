class_name MoveExecutor
extends RefCounted
## Timeline of one move use: wind-up -> active -> recovery. tick() returns phase events
## (&"active_start", &"active_end", &"done"). Hits are checked by the caller while active.

var move: MoveDef
var t: float = 0.0
var _windup: float
var _events_sent: Dictionary = {}


func _init(m: MoveDef, user_speed: int) -> void:
	move = m
	_windup = m.windup(user_speed)


func is_active() -> bool:
	return t >= _windup and t < _windup + move.active_s()


func is_winding_up() -> bool:
	return t < _windup


func is_done() -> bool:
	return t >= _windup + move.active_s() + move.recovery_s()


func tick(delta: float) -> Array[StringName]:
	t += delta
	var out: Array[StringName] = []
	if t >= _windup and not _events_sent.has(&"active_start"):
		_events_sent[&"active_start"] = true
		out.append(&"active_start")
	if t >= _windup + move.active_s() and not _events_sent.has(&"active_end"):
		_events_sent[&"active_end"] = true
		out.append(&"active_end")
	if is_done() and not _events_sent.has(&"done"):
		_events_sent[&"done"] = true
		out.append(&"done")
	return out
