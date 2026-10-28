extends Node
## Autoload `Clock`: drives a ClockModel and broadcasts its events on EventBus.

var model := ClockModel.new()


func _process(delta: float) -> void:
	var events: Array[StringName]
	if model.use_real_time:
		events = model.set_from_system(Time.get_time_dict_from_system())
	else:
		events = model.advance(delta)
	for e in events:
		var parts := String(e).split(":")
		if parts[0] == "hour":
			EventBus.hour_changed.emit(int(parts[1]))
		else:
			EventBus.period_changed.emit(StringName(parts[1]))
