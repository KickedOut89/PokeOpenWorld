class_name DataDB
extends RefCounted
## Loads all JSON content under a root directory into id-keyed tables.
## Layout per kind: either `<root>/<kind>/<id>.json` (one record per file)
## or `<root>/<kind>.json` (an object keyed by id). Both may coexist.

const KINDS: Array[StringName] = [
	&"species", &"moves", &"types", &"natures", &"spawns", &"weather", &"areas",
	&"npcs", &"schedules", &"dialogue", &"quests", &"doors", &"interiors",
	&"items", &"chunks", &"trainers", &"lighting", &"ambience", &"schema",
]

var errors: PackedStringArray = []
var _tables: Dictionary = {}


static func load_dir(root: String) -> DataDB:
	var db := DataDB.new()
	for kind in KINDS:
		db._tables[kind] = {}
		db._load_kind_file(root.path_join(String(kind) + ".json"), kind)
		db._load_kind_dir(root.path_join(String(kind)), kind)
	return db


func table(kind: StringName) -> Dictionary:
	return _tables.get(kind, {})


func get_record(kind: StringName, id: StringName) -> Dictionary:
	return table(kind).get(id, {})


func _load_kind_file(path: String, kind: StringName) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = _parse(path)
	if parsed == null:
		return
	if not parsed is Dictionary:
		_error("%s: expected an object keyed by id" % path)
		return
	for id in parsed:
		if parsed[id] is Dictionary:
			_tables[kind][StringName(id)] = parsed[id]
		else:
			_error("%s: record '%s' is not an object" % [path, id])


func _load_kind_dir(dir_path: String, kind: StringName) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var files := DirAccess.get_files_at(dir_path)
	files.sort()
	for f in files:
		if not f.ends_with(".json"):
			continue
		var path := dir_path.path_join(f)
		var parsed: Variant = _parse(path)
		if parsed == null:
			continue
		if not parsed is Dictionary:
			_error("%s: expected an object" % path)
			continue
		var id := StringName(parsed.get("id", f.get_basename()))
		_tables[kind][id] = parsed


func _parse(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		_error("%s: line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _error(msg: String) -> void:
	errors.append(msg)
	push_warning("DataDB: " + msg)
