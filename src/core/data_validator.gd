class_name DataValidator
extends RefCounted
## Checks schema field presence/types and cross-references between kinds.
## Returns human-readable error strings; empty means valid.

const TYPE_NAMES := {
	"string": TYPE_STRING, "number": TYPE_FLOAT, "array": TYPE_ARRAY,
	"dict": TYPE_DICTIONARY, "bool": TYPE_BOOL,
}


static func validate(db: DataDB) -> PackedStringArray:
	var out: PackedStringArray = []
	out.append_array(db.errors)
	_check_schemas(db, out)
	_check_species(db, out)
	_check_doors(db, out)
	_check_spawns(db, out)
	_check_npcs(db, out)
	_check_trainers(db, out)
	return out


static func _check_trainers(db: DataDB, out: PackedStringArray) -> void:
	for id in db.table(&"trainers"):
		var t: Dictionary = db.table(&"trainers")[id]
		if t.has("npc") and not db.table(&"npcs").has(StringName(t.npc)):
			out.append("trainers/%s: npc '%s' does not exist" % [id, t.npc])
		for p in t.get("party", []):
			if not db.table(&"species").has(StringName(p.get("species", ""))):
				out.append("trainers/%s: unknown species '%s'" % [id, p.get("species", "")])


const MIN_CONTEXT_LINES := 3


static func _check_npcs(db: DataDB, out: PackedStringArray) -> void:
	var places := {}  # anchor/door id -> area
	for cid in db.table(&"chunks"):
		var c: Dictionary = db.table(&"chunks")[cid]
		for a in c.get("npc_anchors", []):
			places[StringName(a.id)] = a.get("area", c.get("area", ""))
		for d in c.get("doors", []):
			places[StringName(d.id)] = d.get("area", c.get("area", ""))
	var residents := {}  # area -> [count, with companion]
	var check_places := not db.table(&"chunks").is_empty()
	for id in db.table(&"npcs"):
		var npc: Dictionary = db.table(&"npcs")[id]
		var dlg := db.get_record(&"dialogue", StringName(npc.get("dialogue", "")))
		if dlg.is_empty():
			out.append("npcs/%s: dialogue '%s' does not exist" % [id, npc.get("dialogue", "")])
		else:
			var contexts := {}
			for l in dlg.get("barks", []) + dlg.get("talk", []):
				contexts[JSON.stringify(l.get("when", {}))] = true
			if contexts.size() < MIN_CONTEXT_LINES:
				out.append("npcs/%s: needs lines for at least %d distinct contexts (has %d)" % [id, MIN_CONTEXT_LINES, contexts.size()])
		var role: String = npc.get("role", "resident")
		if role != "trainer" and not db.table(&"schedules").has(StringName(npc.get("schedule", ""))):
			out.append("npcs/%s: schedule '%s' does not exist" % [id, npc.get("schedule", "")])
		if check_places and not places.has(StringName(npc.get("home", ""))) and npc.has("home"):
			out.append("npcs/%s: home '%s' is not a door or anchor" % [id, npc.get("home", "")])
		if npc.has("companion") and not db.table(&"species").has(StringName(npc.companion)):
			out.append("npcs/%s: companion species '%s' does not exist" % [id, npc.companion])
		if role == "resident" and places.has(StringName(npc.get("home", ""))):
			var area: String = places[StringName(npc.home)]
			var tally: Array = residents.get_or_add(area, [0, 0])
			tally[0] += 1
			if npc.has("companion"):
				tally[1] += 1
	for area in residents:
		var area_rec := db.get_record(&"areas", StringName(area))
		var is_town: bool = area_rec.get("ambience", "town") == "town"
		if is_town and not Companion.share_ok(residents[area][1], residents[area][0]):
			out.append("npcs: area '%s' has %d/%d residents with a companion Pokémon (needs 30%%)" % [area, residents[area][1], residents[area][0]])
	for sid in db.table(&"schedules"):
		for b in db.table(&"schedules")[sid].get("blocks", []):
			if check_places and not places.has(StringName(b.get("at", ""))):
				out.append("schedules/%s: anchor '%s' does not exist" % [sid, b.get("at", "")])


static func _check_spawns(db: DataDB, out: PackedStringArray) -> void:
	var species := db.table(&"species")
	var tables := db.table(&"spawns")
	for id in tables:
		for e in tables[id].get("entries", []):
			if not species.has(StringName(e.get("species", ""))):
				out.append("spawns/%s: unknown species '%s'" % [id, e.get("species", "")])
			elif species[StringName(e.species)].get("ambient_only", false):
				out.append("spawns/%s: '%s' is ambient-only and cannot be a wild encounter" % [id, e.species])
	for cid in db.table(&"chunks"):
		for z in db.table(&"chunks")[cid].get("spawn_zones", []):
			if not tables.has(StringName(z.get("table", ""))):
				out.append("chunks/%s: spawn zone '%s' uses unknown table '%s'" % [cid, z.get("id", "?"), z.get("table", "")])


static func _check_schemas(db: DataDB, out: PackedStringArray) -> void:
	var schemas := db.table(&"schema")
	for kind in schemas:
		var required: Dictionary = schemas[kind].get("required", {})
		var records := db.table(StringName(kind))
		for id in records:
			for field in required:
				var rec: Dictionary = records[id]
				if not rec.has(field):
					out.append("%s/%s: missing required field '%s'" % [kind, id, field])
					continue
				var want: int = TYPE_NAMES.get(required[field], TYPE_NIL)
				var got := typeof(rec[field])
				if want == TYPE_FLOAT and got == TYPE_INT:
					got = TYPE_FLOAT
				if want != TYPE_NIL and got != want:
					out.append("%s/%s: field '%s' should be %s" % [kind, id, field, required[field]])


static func _check_species(db: DataDB, out: PackedStringArray) -> void:
	var moves := db.table(&"moves")
	var species := db.table(&"species")
	for id in species:
		var rec: Dictionary = species[id]
		for entry in rec.get("learnset", []):
			if entry is Array and entry.size() == 2 and not moves.has(StringName(entry[1])):
				out.append("species/%s: learnset move '%s' does not exist" % [id, entry[1]])
		for evo in rec.get("evolves", []):
			if not species.has(StringName(evo.get("to", ""))):
				out.append("species/%s: evolves to unknown species '%s'" % [id, evo.get("to", "")])


static func _check_doors(db: DataDB, out: PackedStringArray) -> void:
	var doors: Array = []
	for id in db.table(&"doors"):
		doors.append(db.table(&"doors")[id])
	for cid in db.table(&"chunks"):
		doors.append_array(db.table(&"chunks")[cid].get("doors", []))
	var interiors := db.table(&"interiors")
	for rec in doors:
		var unlock_type: String = rec.get("unlock", {}).get("type", "")
		if unlock_type == "pending":
			continue
		if not interiors.has(StringName(rec.get("interior", ""))):
			out.append("doors/%s: interior '%s' does not exist (use unlock type 'pending')" % [rec.get("id", "?"), rec.get("interior", "")])
	var templates := db.table(&"interior_templates")
	for id in interiors:
		var t := StringName(interiors[id].get("template", ""))
		if not templates.has(t):
			out.append("interiors/%s: template '%s' does not exist" % [id, t])
