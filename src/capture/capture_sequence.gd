class_name CaptureSequence
extends RefCounted
## Timeline after a ball hits: absorb, then one 0.6 s shake per passed check, then the result.
## Events: &"absorb", &"critical" (critical captures), &"shake" xN, &"caught" | &"breakout".

const ABSORB_S := 0.5
const SHAKE_S := 0.6
const RESULT_S := 0.4

var attempt: Dictionary
var done: bool = false
var t: float = 0.0
var _sent: int = 0
var _timeline: Array = []  # [time, event]


func _init(result: Dictionary) -> void:
	attempt = result
	_timeline.append([0.0, &"absorb"])
	if result.get("critical", false):
		_timeline.append([0.0, &"critical"])
	var at := ABSORB_S
	for i in int(result.get("shakes", 0)):
		at += SHAKE_S
		_timeline.append([at, &"shake"])
	at += RESULT_S
	_timeline.append([at, &"caught" if result.get("caught", false) else &"breakout"])


func tick(delta: float) -> Array[StringName]:
	t += delta
	var out: Array[StringName] = []
	while _sent < _timeline.size() and t >= float(_timeline[_sent][0]):
		out.append(_timeline[_sent][1])
		_sent += 1
	done = _sent >= _timeline.size()
	return out
