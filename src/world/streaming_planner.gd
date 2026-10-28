class_name StreamingPlanner
extends RefCounted
## Decides which chunks to load (3x3 around the player), preload (the 5x5 ring)
## and unload (outside 5x5, unless pinned). Only coords with a chunk record are planned.

const LOAD_RADIUS := 1
const PRELOAD_RADIUS := 2

var _existing: Dictionary = {}


func _init(existing: Array[Vector2i]) -> void:
	for c in existing:
		_existing[c] = true


static func chunk_of(pos: Vector3) -> Vector2i:
	return StreamingMath.chunk_of(pos)


func exists(c: Vector2i) -> bool:
	return _existing.has(c)


func plan(center: Vector2i, loaded: Array[Vector2i], pinned: Array[Vector2i]) -> Dictionary:
	var to_load: Array[Vector2i] = []
	var to_preload: Array[Vector2i] = []
	var to_unload: Array[Vector2i] = []
	var loaded_set := {}
	for c in loaded:
		loaded_set[c] = true
	for dy in range(-PRELOAD_RADIUS, PRELOAD_RADIUS + 1):
		for dx in range(-PRELOAD_RADIUS, PRELOAD_RADIUS + 1):
			var c := center + Vector2i(dx, dy)
			if not _existing.has(c) or loaded_set.has(c):
				continue
			if absi(dx) <= LOAD_RADIUS and absi(dy) <= LOAD_RADIUS:
				to_load.append(c)
			else:
				to_preload.append(c)
	for c in loaded:
		var d := c - center
		if (absi(d.x) > PRELOAD_RADIUS or absi(d.y) > PRELOAD_RADIUS) and not pinned.has(c):
			to_unload.append(c)
	return {"load": to_load, "preload": to_preload, "unload": to_unload}
