class_name GameSettings
extends Node
## Player options persisted to user://settings.cfg. Autoloaded as `Settings`.
## Invalid or missing values fall back to defaults.

const PRESETS: Array[StringName] = [&"low", &"medium", &"high", &"ultra"]
const RATES := [12, 24, 48, 96]
const FEATURES := ["sdfgi", "ssao", "ssil", "volumetric", "glow", "dof"]
const DEFAULTS := {
	"graphics/preset": &"high", "graphics/dof": false,
	"time/rate": 24, "time/use_real_clock": false,
	"audio/master": 1.0, "audio/music": 1.0, "audio/sfx": 1.0, "audio/ambience": 1.0,
}

var path := "user://settings.cfg"
var _values: Dictionary = {}


func _ready() -> void:
	load_file()
	apply()


static func next_in(list: Array, current: Variant) -> Variant:
	var i := list.find(current)
	return list[(i + 1) % list.size()]


func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, v: Variant) -> void:
	_values[key] = v if _valid(key, v) else DEFAULTS.get(key)


func _valid(key: String, v: Variant) -> bool:
	match key:
		"graphics/preset":
			return (v is StringName or v is String) and PRESETS.has(StringName(v))
		"time/rate":
			return (v is int or v is float) and RATES.has(int(v))
		"time/use_real_clock":
			return v is bool
	if key.begins_with("audio/"):
		return (v is float or v is int) and float(v) >= 0.0 and float(v) <= 1.0
	if key.begins_with("graphics/"):
		return v is bool
	return false


func load_file() -> void:
	_values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for key in DEFAULTS:
		var parts: PackedStringArray = key.split("/")
		if cfg.has_section_key(parts[0], parts[1]):
			var v: Variant = cfg.get_value(parts[0], parts[1])
			if key == "graphics/preset" and v is String:
				v = StringName(v)
			if key == "time/rate" and v is float:
				v = int(v)
			set_value(key, v)
	for f in FEATURES:
		if cfg.has_section_key("graphics", f) and cfg.get_value("graphics", f) is bool:
			_values["graphics/" + f] = cfg.get_value("graphics", f)


func save_file() -> void:
	var cfg := ConfigFile.new()
	for key in _values:
		var parts: PackedStringArray = key.split("/")
		var v: Variant = _values[key]
		cfg.set_value(parts[0], parts[1], String(v) if v is StringName else v)
	cfg.save(path)


func apply() -> void:
	GraphicsPresets.current = StringName(get_value("graphics/preset"))
	var overrides := {}
	for f in FEATURES:
		if _values.has("graphics/" + f):
			overrides[f] = _values["graphics/" + f]
	GraphicsPresets.user_overrides = overrides
	var lighting := get_tree().get_first_node_in_group(&"lighting_director") as LightingDirector if is_inside_tree() else null
	if lighting != null:
		GraphicsPresets.apply(GraphicsPresets.current, lighting.env, get_viewport())
	Clock.model.rate = float(get_value("time/rate"))
	Clock.model.use_real_time = bool(get_value("time/use_real_clock"))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, float(get_value("audio/master")))))
