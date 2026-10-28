class_name Schedule
extends RefCounted
## An NPC's day: blocks {from, to, at: anchor, activity}; blocks may wrap midnight.
## Outside any block the NPC is at home (indoors). Weather behaviour:
## {rain: indoors|umbrella|awning, thunderstorm: indoors|umbrella|awning}.

const DEFAULT_BEHAVIOR := {"rain": "umbrella", "thunderstorm": "indoors", "fog": "outdoors"}

var _blocks: Array = []
var _home: StringName


func _init(record: Dictionary, home_anchor: StringName) -> void:
	_blocks = record.get("blocks", [])
	_home = home_anchor


func resolve(hour: float, weather: StringName, behavior: Dictionary) -> Dictionary:
	var out := {"anchor": _home, "activity": &"home", "indoors": true, "umbrella": false}
	for b in _blocks:
		if DoorUnlock.in_hours(int(floor(hour)), int(b.from), int(b.to)) or (int(b.from) == 0 and int(b.to) == 24):
			out = {"anchor": StringName(b.at), "activity": StringName(b.get("activity", "idle")), "indoors": false, "umbrella": false}
			break
	if out.indoors:
		return out
	var rule: String = behavior.get(String(weather), DEFAULT_BEHAVIOR.get(String(weather), "outdoors"))
	match rule:
		"indoors":
			return {"anchor": _home, "activity": &"home", "indoors": true, "umbrella": false}
		"umbrella":
			out.umbrella = true
		"awning":
			out.activity = &"shelter"
	return out
