class_name AssetOverride
extends RefCounted
## Resolves art/audio keys (e.g. "species/pidgey") to the owner's user_assets
## files, falling back to repo placeholders, then to a "missing" asset.
## Never fails: problems are collected in `warnings`.

var warnings: PackedStringArray = []

var _user_dir: String
var _placeholder_dir: String
var _manifest: Dictionary = {}
var _cache: Dictionary = {}


func _init(user_dir: String, placeholder_dir: String) -> void:
	_user_dir = user_dir
	_placeholder_dir = placeholder_dir
	var path := user_dir.path_join("manifest.json")
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			_manifest = parsed
		else:
			_warn("user_assets/manifest.json is not a valid JSON object; ignoring it")


func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	if _manifest.has(key):
		var file := _user_dir.path_join(str(_manifest[key]))
		var img := Image.new()
		if _looks_like_image(file) and img.load(file) == OK:
			tex = ImageTexture.create_from_image(img)
		else:
			_warn("%s: could not load '%s'; using placeholder" % [key, file])
	if tex == null:
		tex = _placeholder_texture(key)
	_cache[key] = tex
	return tex


func audio(key: String) -> AudioStream:
	if _manifest.has(key):
		var file := _user_dir.path_join(str(_manifest[key]))
		var stream: AudioStream = null
		if FileAccess.file_exists(file):
			if file.ends_with(".ogg"):
				stream = AudioStreamOggVorbis.load_from_file(file)
			elif file.ends_with(".wav"):
				stream = AudioStreamWAV.load_from_file(file)
		if stream != null:
			return stream
		_warn("%s: could not load '%s'; using placeholder" % [key, file])
	for ext in [".ogg", ".wav"]:
		var ph := _placeholder_dir.path_join(key + ext)
		if ResourceLoader.exists(ph):
			return load(ph)
	return AudioStreamWAV.new()  # silent


static func _looks_like_image(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var head := FileAccess.get_file_as_bytes(path).slice(0, 12)
	if head.size() < 12:
		return false
	var png := head.slice(0, 8) == PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
	var jpg := head[0] == 0xFF and head[1] == 0xD8
	var webp := head.slice(0, 4).get_string_from_ascii() == "RIFF" and head.slice(8, 12).get_string_from_ascii() == "WEBP"
	return png or jpg or webp


func _placeholder_texture(key: String) -> Texture2D:
	for path in [_placeholder_dir.path_join(key + ".png"), _placeholder_dir.path_join("missing.png")]:
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is Texture2D:
				return res
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	return ImageTexture.create_from_image(img)


func _warn(msg: String) -> void:
	warnings.append(msg)
	push_warning("Assets: " + msg)
