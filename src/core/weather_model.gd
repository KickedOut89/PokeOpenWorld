class_name WeatherModel
extends RefCounted
## Weighted weather for one area, with a timed blend between current and target.

const KNOWN: Array[StringName] = [&"clear", &"cloudy", &"rain", &"thunderstorm", &"fog"]

var current: StringName = &"clear"
var target: StringName = &"clear"
var blend: float = 1.0
var reroll_hours: int = 3

var _weights: Dictionary = {}
var _rng: RandomNumberGenerator
var _duration: float = 30.0


func _init(table: Dictionary, rng: RandomNumberGenerator) -> void:
	_rng = rng
	reroll_hours = int(table.get("reroll_hours", 3))
	for id in table.get("weights", {}):
		if KNOWN.has(StringName(id)) and float(table.weights[id]) > 0.0:
			_weights[StringName(id)] = float(table.weights[id])


func roll() -> StringName:
	var total := 0.0
	for id in _weights:
		total += _weights[id]
	if total <= 0.0:
		return &"clear"
	var pick := _rng.randf() * total
	for id in _weights:
		pick -= _weights[id]
		if pick < 0.0:
			return id
	return _weights.keys().back()


func transition_seconds() -> float:
	return _rng.randf_range(20.0, 40.0)


func start_transition(to: StringName) -> void:
	target = to
	blend = 0.0
	_duration = transition_seconds()


func tick(delta: float) -> void:
	if blend >= 1.0:
		return
	blend = minf(1.0, blend + delta / _duration)
	if blend >= 1.0:
		current = target


func to_dict() -> Dictionary:
	return {"current": current, "target": target, "blend": blend}


func from_dict(d: Dictionary) -> void:
	current = StringName(d.get("current", "clear"))
	target = StringName(d.get("target", current))
	blend = float(d.get("blend", 1.0))
	if blend < 1.0:
		_duration = transition_seconds()
