extends Node
## Autoload `Assets`: the game-wide AssetOverride, writing warnings to user://logs/assets.log.

var resolver: AssetOverride
var _logged := 0


func _ready() -> void:
	var user_dir := OS.get_executable_path().get_base_dir().path_join("user_assets")
	if OS.has_feature("editor"):
		user_dir = ProjectSettings.globalize_path("res://user_assets")
	resolver = AssetOverride.new(user_dir, "res://assets/placeholder")
	_flush()


func texture(key: String) -> Texture2D:
	var t := resolver.texture(key)
	_flush()
	return t


func audio(key: String) -> AudioStream:
	var a := resolver.audio(key)
	_flush()
	return a


func _flush() -> void:
	if resolver.warnings.size() == _logged:
		return
	DirAccess.make_dir_recursive_absolute("user://logs")
	var f := FileAccess.open("user://logs/assets.log", FileAccess.READ_WRITE if FileAccess.file_exists("user://logs/assets.log") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	for i in range(_logged, resolver.warnings.size()):
		f.store_line("%s %s" % [Time.get_datetime_string_from_system(), resolver.warnings[i]])
	_logged = resolver.warnings.size()
