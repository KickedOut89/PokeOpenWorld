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
	return out


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
