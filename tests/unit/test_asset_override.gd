extends GutTest

const USER := "res://tests/fixtures/user_assets"
const PH := "res://tests/fixtures/placeholder"


func test_manifest_entry_used() -> void:
	var a := AssetOverride.new(USER, PH)
	var t := a.texture("species/pidgey")
	assert_eq(t.get_width(), 8)
	assert_eq(t.get_height(), 4)
	assert_eq(a.warnings.size(), 0)


func test_missing_file_falls_back_and_warns() -> void:
	var a := AssetOverride.new(USER, PH)
	var t := a.texture("species/rattata")
	assert_eq(t.get_width(), 6, "placeholder rattata")
	assert_eq(a.warnings.size(), 1)
	assert_string_contains(a.warnings[0], "species/rattata")


func test_corrupt_png_falls_back_and_warns() -> void:
	var a := AssetOverride.new(USER, PH)
	var t := a.texture("species/caterpie")
	assert_eq(t.get_width(), 2, "no caterpie placeholder -> missing.png")
	assert_eq(a.warnings.size(), 1)


func test_missing_manifest_uses_placeholders_silently() -> void:
	var a := AssetOverride.new("res://tests/fixtures/no_such_dir", PH)
	assert_eq(a.texture("species/rattata").get_width(), 6)
	assert_eq(a.warnings.size(), 0)


func test_unknown_key_returns_missing_texture() -> void:
	var a := AssetOverride.new(USER, PH)
	assert_eq(a.texture("tiles/lava").get_width(), 2)


func test_no_missing_png_still_returns_texture() -> void:
	var a := AssetOverride.new("res://nowhere", "res://nowhere_either")
	assert_not_null(a.texture("species/x"))


func test_missing_audio_returns_stream() -> void:
	var a := AssetOverride.new(USER, PH)
	assert_not_null(a.audio("sfx/thunder"))
