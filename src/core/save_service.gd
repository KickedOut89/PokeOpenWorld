class_name SaveService
extends Node
## Versioned JSON saves in user://saves (on Windows: %APPDATA%\Godot\app_userdata\Open World Remake\saves).
## Writes are atomic: write slot_N.json.tmp, keep the old file as slot_N.json.bak, then rename.
## Loading falls back to the .bak when the main file is unreadable. Autoloaded as `Saves`.

const CURRENT_VERSION := 1
const AUTOSAVE_SLOT := 0

var dir := "user://saves"
var in_fight: Callable = func() -> bool: return false


func path(slot: int) -> String:
	return dir.path_join("slot_%d.json" % slot)


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(path(slot)) or FileAccess.file_exists(path(slot) + ".bak")


## world: {player: {pos, area, interior?}, spawns_respawn_timers, quests}
func snapshot(world: Dictionary) -> Dictionary:
	var weather := {}
	for id in Weather.models:
		weather[String(id)] = (Weather.models[id] as WeatherModel).to_dict()
	return {
		"version": CURRENT_VERSION, "saved_at": Time.get_datetime_string_from_system(),
		"clock": {"minutes": Clock.model.minutes, "day": Clock.model.day},
		"weather": weather, "player": world.get("player", {}),
		"game_state": State.to_dict(), "party": State.party.to_array(), "pc": State.pc.to_array(),
		"quests": world.get("quests", {}), "spawns_respawn_timers": world.get("spawns_respawn_timers", {}),
	}


func save(slot: int, data: Dictionary) -> Error:
	if in_fight.call():
		return ERR_BUSY
	DirAccess.make_dir_recursive_absolute(dir)
	var main := path(slot)
	var tmp := main + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, " "))
	f.close()
	if FileAccess.file_exists(main):
		if FileAccess.file_exists(main + ".bak"):
			DirAccess.remove_absolute(main + ".bak")
		DirAccess.rename_absolute(main, main + ".bak")
	return DirAccess.rename_absolute(tmp, main)


func load_slot(slot: int) -> Dictionary:
	var d := _read(path(slot))
	if not d.is_empty():
		return {"ok": true, "data": d, "used_backup": false}
	d = _read(path(slot) + ".bak")
	if not d.is_empty():
		push_warning("Saves: slot %d was damaged; loaded the backup" % slot)
		return {"ok": true, "data": d, "used_backup": true}
	return {"ok": false, "data": {}, "used_backup": false}


func _read(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(p)) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or not (parsed as Dictionary).has("version"):
		return {}
	return SaveMigrations.migrate(parsed)


## Restores global state; returns the player block (pos as Vector3, interior.outdoor_pos too)
## for the world to place the player.
func apply(d: Dictionary) -> Dictionary:
	Clock.model.minutes = float(d.get("clock", {}).get("minutes", 480.0))
	Clock.model.day = int(d.get("clock", {}).get("day", 0))
	for id in d.get("weather", {}):
		if Weather.models.has(StringName(id)):
			(Weather.models[StringName(id)] as WeatherModel).from_dict(d.weather[id])
	State.from_dict(d.get("game_state", {}))
	State.party = Party.from_array(d.get("party", []), Data.db)
	State.pc = PCStorage.from_array(d.get("pc", []), Data.db)
	var player: Dictionary = d.get("player", {}).duplicate(true)
	if player.has("pos"):
		player.pos = _v3(player.pos)
	if player.has("interior") and player.interior.has("outdoor_pos"):
		player.interior.outdoor_pos = _v3(player.interior.outdoor_pos)
	return player


static func _v3(a: Variant) -> Vector3:
	if a is Vector3:
		return a
	var arr: Array = a
	return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
