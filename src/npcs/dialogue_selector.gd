class_name DialogueSelector
extends RefCounted
## Picks the most context-specific matching line. Line: {text, when?: {periods?, weather?,
## flag?, not_flag?}, weight?, branch?}. ctx: {period, weather, flags: Dictionary}.


func pick(lines: Array, ctx: Dictionary, rng: RandomNumberGenerator) -> String:
	return pick_line(lines, ctx, rng).get("text", "")


func pick_line(lines: Array, ctx: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var best := -1
	var pool: Array = []
	for l in lines:
		var w: Dictionary = l.get("when", {})
		if not matches(w, ctx):
			continue
		if w.size() > best:
			best = w.size()
			pool = [l]
		elif w.size() == best:
			pool.append(l)
	if pool.is_empty():
		return {}
	var total := 0.0
	for l in pool:
		total += float(l.get("weight", 1))
	var roll := rng.randf() * total
	for l in pool:
		roll -= float(l.get("weight", 1))
		if roll < 0.0:
			return l
	return pool.back()


static func matches(w: Dictionary, ctx: Dictionary) -> bool:
	var flags: Dictionary = ctx.get("flags", {})
	if w.has("periods") and not _in(w.periods, ctx.get("period", &"")):
		return false
	if w.has("weather") and not _in(w.weather, ctx.get("weather", &"")):
		return false
	if w.has("flag") and not flags.has(StringName(w.flag)):
		return false
	if w.has("not_flag") and flags.has(StringName(w.not_flag)):
		return false
	return true


static func _in(spec: Variant, value: StringName) -> bool:
	if spec is Array:
		return (spec as Array).has(String(value))
	return String(spec) == String(value)
