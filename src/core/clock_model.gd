class_name ClockModel
extends RefCounted
## Game time. `rate` is game-seconds per real-second (24 => 1 real hour = 1 game day).

const MINUTES_PER_DAY := 1440.0

var minutes: float = 8 * 60.0
var day: int = 0
var rate: float = 24.0
var use_real_time: bool = false


static func period_for(hour: int) -> StringName:
	if hour >= 4 and hour < 10:
		return &"morning"
	if hour >= 10 and hour < 17:
		return &"day"
	if hour >= 17 and hour < 20:
		return &"evening"
	return &"night"


func hour() -> int:
	return int(minutes / 60.0) % 24


func period() -> StringName:
	return period_for(hour())


## Advances by real seconds; returns crossed events in order ("hour:<n>", "period:<name>").
func advance(real_delta: float) -> Array[StringName]:
	if use_real_time:
		return [] as Array[StringName]
	return _move_by(real_delta * rate / 60.0)


## Real-clock mode: jump to the system time. Returns crossed events like advance().
func set_from_system(dt: Dictionary) -> Array[StringName]:
	var target: float = dt.get("hour", 0) * 60.0 + dt.get("minute", 0) + dt.get("second", 0) / 60.0
	var delta := target - minutes
	if delta < 0.0:
		delta += MINUTES_PER_DAY
	return _move_by(delta)


func _move_by(game_minutes: float) -> Array[StringName]:
	var events: Array[StringName] = []
	var remaining := game_minutes
	while remaining > 0.0:
		var to_next_hour := 60.0 - fmod(minutes, 60.0)
		if remaining < to_next_hour:
			minutes += remaining
			break
		remaining -= to_next_hour
		var before := period()
		minutes += to_next_hour
		if minutes >= MINUTES_PER_DAY - 0.0001:
			minutes = 0.0
			day += 1
		minutes = roundf(minutes / 60.0) * 60.0
		events.append(StringName("hour:%d" % hour()))
		if period() != before:
			events.append(StringName("period:%s" % period()))
	return events
