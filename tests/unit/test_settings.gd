extends GutTest

const PATH := "user://test_settings.cfg"
var s: GameSettings


func before_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	s = GameSettings.new()
	s.path = PATH


func after_each() -> void:
	s.free()


func test_defaults() -> void:
	s.load_file()
	assert_eq(s.get_value("graphics/preset"), &"high")
	assert_eq(s.get_value("time/rate"), 24)
	assert_eq(s.get_value("time/use_real_clock"), false)
	assert_eq(s.get_value("audio/master"), 1.0)
	assert_eq(s.get_value("graphics/dof"), false)


func test_persist_round_trip() -> void:
	s.load_file()
	s.set_value("graphics/preset", &"low")
	s.set_value("time/rate", 96)
	s.set_value("audio/ambience", 0.5)
	s.save_file()
	var t := GameSettings.new()
	t.path = PATH
	t.load_file()
	assert_eq(t.get_value("graphics/preset"), &"low")
	assert_eq(t.get_value("time/rate"), 96)
	assert_eq(t.get_value("audio/ambience"), 0.5)
	t.free()


func test_missing_file_uses_defaults() -> void:
	s.path = "user://definitely_missing.cfg"
	s.load_file()
	assert_eq(s.get_value("graphics/preset"), &"high")


func test_invalid_value_falls_back() -> void:
	s.load_file()
	s.set_value("graphics/preset", &"potato")
	assert_eq(s.get_value("graphics/preset"), &"high")
	s.set_value("time/rate", 7)
	assert_eq(s.get_value("time/rate"), 24)
	s.set_value("audio/master", 3.0)
	assert_eq(s.get_value("audio/master"), 1.0)
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "preset", 42)
	cfg.save(PATH)
	s.load_file()
	assert_eq(s.get_value("graphics/preset"), &"high", "garbage on disk ignored")


func test_cycle_values() -> void:
	s.load_file()
	assert_eq(GameSettings.next_in([12, 24, 48, 96], 24), 48)
	assert_eq(GameSettings.next_in([12, 24, 48, 96], 96), 12)


func test_apply_sets_clock_and_preset() -> void:
	s.load_file()
	s.set_value("time/rate", 48)
	s.set_value("graphics/preset", &"medium")
	s.apply()
	assert_eq(Clock.model.rate, 48.0)
	assert_eq(GraphicsPresets.current, &"medium")
	s.set_value("time/rate", 24)
	s.set_value("graphics/preset", &"high")
	s.apply()


func test_settings_menu_cycles_preset() -> void:
	var m := SettingsMenu.new()
	add_child_autofree(m)
	Settings.set_value("graphics/preset", &"high")
	m.change(1)
	assert_eq(Settings.get_value("graphics/preset"), &"ultra")
	m.change(1)
	assert_eq(Settings.get_value("graphics/preset"), &"low")
	Settings.set_value("graphics/preset", &"high")
	Settings.apply()
