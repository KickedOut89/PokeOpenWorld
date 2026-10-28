class_name ChunkBaker
extends RefCounted
## Turns per-area ASCII blockouts (1 char = 4x4 m) and region-metre placements
## into chunk records (16x16 cells each). Pure; used by tools/bake_chunks.gd and tests.

const CELLS := ChunkData.CELLS
const PLACEMENT_KINDS := ["props", "doors", "spawn_zones", "npc_anchors"]


## Reads every <area>.txt (and optional <area>.height.txt) in a directory.
## Returns [{area, origin: Vector2i, rows: PackedStringArray, heights: PackedStringArray}].
static func read_blockouts(dir_path: String, _region: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var files := DirAccess.get_files_at(dir_path)
	files.sort()
	for f in files:
		if not f.ends_with(".txt") or f.ends_with(".height.txt"):
			continue
		var area := f.get_basename()
		var lines := FileAccess.get_file_as_string(dir_path.path_join(f)).split("\n")
		var origin := Vector2i.ZERO
		var rows: PackedStringArray = []
		for line in lines:
			if line.begins_with("@origin"):
				var p := line.split(" ", false)
				origin = Vector2i(int(p[1]), int(p[2]))
			elif line.length() > 0:
				rows.append(line)
		var heights: PackedStringArray = []
		var hpath := dir_path.path_join(area + ".height.txt")
		if FileAccess.file_exists(hpath):
			for line in FileAccess.get_file_as_string(hpath).split("\n"):
				if line.length() > 0 and not line.begins_with("@"):
					heights.append(line)
		out.append({"area": area, "origin": origin, "rows": rows, "heights": heights})
	return out


## Reads <area>.json placement files; returns {area: {props: [], doors: [], ...}}.
static func read_placements(dir_path: String) -> Dictionary:
	var out := {}
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".json"):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir_path.path_join(f)))
			if parsed is Dictionary:
				out[f.get_basename()] = parsed
	return out


## Returns {Vector2i chunk coord: chunk record}.
static func bake(region: StringName, blockouts: Array[Dictionary], placements: Dictionary) -> Dictionary:
	var chunks := {}
	var area_votes := {}  # coord -> {area: count}
	for b in blockouts:
		var rows: PackedStringArray = b.rows
		for y in rows.size():
			for x in rows[y].length():
				var ch := rows[y][x]
				if ch == " ":
					continue
				var g := Vector2i(b.origin.x + x, b.origin.y + y)
				var coord := Vector2i(floori(g.x / float(CELLS)), floori(g.y / float(CELLS)))
				var rec := _ensure(chunks, region, coord)
				var lx := g.x - coord.x * CELLS
				var ly := g.y - coord.y * CELLS
				rec.cells[ly] = _set_char(rec.cells[ly], lx, ch)
				var hrows: PackedStringArray = b.heights
				var hch := "0"
				if y < hrows.size() and x < hrows[y].length():
					hch = hrows[y][x]
				rec.heights[ly] = _set_char(rec.heights[ly], lx, hch)
				var votes: Dictionary = area_votes.get_or_add(coord, {})
				votes[b.area] = votes.get(b.area, 0) + 1
	for coord in chunks:
		var votes: Dictionary = area_votes.get(coord, {})
		var best := ""
		for a in votes:
			if best == "" or votes[a] > votes[best]:
				best = a
		chunks[coord].area = best
	for area in placements:
		var p: Dictionary = placements[area]
		for kind in PLACEMENT_KINDS:
			for item in p.get(kind, []):
				var pos := _anchor_pos(item, kind)
				var coord := Vector2i(floori(pos.x / ChunkData.SIZE_M), floori(pos.y / ChunkData.SIZE_M))
				var rec := _ensure(chunks, region, coord)
				var local: Dictionary = item.duplicate(true)
				var off := Vector2(coord.x * ChunkData.SIZE_M, coord.y * ChunkData.SIZE_M)
				if local.has("pos"):
					local.pos = [float(local.pos[0]) - off.x, float(local.pos[1]), float(local.pos[2]) - off.y]
				if local.has("rect"):
					local.rect = [float(local.rect[0]) - off.x, float(local.rect[1]) - off.y, local.rect[2], local.rect[3]]
				local.area = area
				rec[kind].append(local)
	return chunks


static func _anchor_pos(item: Dictionary, kind: String) -> Vector2:
	if kind == "spawn_zones":
		var r: Array = item.rect
		return Vector2(float(r[0]), float(r[1]))
	return Vector2(float(item.pos[0]), float(item.pos[2]))


static func _ensure(chunks: Dictionary, region: StringName, coord: Vector2i) -> Dictionary:
	if not chunks.has(coord):
		var blank := " ".repeat(CELLS)
		var zeros := "0".repeat(CELLS)
		var cells: Array = []
		var heights: Array = []
		for i in CELLS:
			cells.append(blank)
			heights.append(zeros)
		chunks[coord] = {
			"id": "%s_%d_%d" % [region, coord.x, coord.y], "region": String(region),
			"coord": [coord.x, coord.y], "area": "", "cells": cells, "heights": heights,
			"props": [], "doors": [], "spawn_zones": [], "npc_anchors": [],
		}
	return chunks[coord]


static func _set_char(s: String, i: int, ch: String) -> String:
	return s.substr(0, i) + ch + s.substr(i + 1)
