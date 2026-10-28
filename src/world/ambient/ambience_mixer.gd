class_name AmbienceMixer
extends RefCounted
## Which ambient sound layers play (layer -> volume dB) for an ambience type, period
## and weather. Data: data/ambience.json {types: {type: {period: {layer: db}}}, weather: {...}}.

var _types: Dictionary
var _weather: Dictionary


func _init(record: Dictionary) -> void:
	_types = record.get("types", {})
	_weather = record.get("weather", {})


func layers(ambience: StringName, period: StringName, weather: StringName) -> Dictionary:
	var t: Dictionary = _types.get(String(ambience), {})
	if t.is_empty():
		return {}
	var out := {}
	var base: Dictionary = t.get(String(period), {})
	for k in base:
		out[StringName(k)] = float(base[k])
	var w: Dictionary = _weather.get(String(weather), {})
	for k in w.get("add", {}):
		out[StringName(k)] = float(w.add[k])
	for k in w.get("duck", {}):
		if out.has(StringName(k)):
			out[StringName(k)] = float(out[StringName(k)]) + float(w.duck[k])
	return out
