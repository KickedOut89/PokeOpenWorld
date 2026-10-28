class_name SpawnTable
extends RefCounted
## Weighted wild encounter table for one zone, filtered by period and scaled by weather.
## Entry: {species, min_lvl, max_lvl, weight, periods: "all" | [..], weather_mult: {weather: x}}

var id: StringName
var _entries: Array = []
var _nocturnal: Dictionary


func _init(record: Dictionary, nocturnal: Dictionary = {}) -> void:
	id = StringName(record.get("id", ""))
	_entries = record.get("entries", [])
	_nocturnal = nocturnal


func pick(period: StringName, weather: StringName, rng: RandomNumberGenerator) -> Dictionary:
	var eligible: Array = []
	var weights: Array[float] = []
	var total := 0.0
	for e in _entries:
		var sp := StringName(e.species)
		if _nocturnal.has(sp) and period != &"night":
			continue
		var periods: Variant = e.get("periods", "all")
		if periods is Array and not (periods as Array).has(String(period)):
			continue
		var w := float(e.get("weight", 1)) * float(e.get("weather_mult", {}).get(String(weather), 1.0))
		if w <= 0.0:
			continue
		eligible.append(e)
		weights.append(w)
		total += w
	if eligible.is_empty():
		return {}
	var roll := rng.randf() * total
	for i in eligible.size():
		roll -= weights[i]
		if roll < 0.0 or i == eligible.size() - 1:
			var e: Dictionary = eligible[i]
			return {"species": StringName(e.species), "level": rng.randi_range(int(e.min_lvl), int(e.max_lvl))}
	return {}
