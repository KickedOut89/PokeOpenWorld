class_name SettingsMenu
extends CanvasLayer
## F2: options. Number keys change a line; changes apply immediately and are saved on close.

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 47
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_left = -380
	_panel.offset_right = 380
	_panel.offset_top = -220
	_panel.offset_bottom = 220
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 24)
	_panel.add_child(_label)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func toggle() -> void:
	_panel.visible = not _panel.visible
	if not _panel.visible:
		Settings.save_file()
	refresh()


func refresh() -> void:
	_label.text = "\n".join([
		"SETTINGS  (F2 to close)",
		"1. Graphics preset: %s" % String(Settings.get_value("graphics/preset")).capitalize(),
		"2. Tilt-shift depth of field: %s" % ("On" if Settings.get_value("graphics/dof") else "Off"),
		"3. Day length: %s" % _rate_text(int(Settings.get_value("time/rate"))),
		"4. Follow PC clock: %s" % ("On" if Settings.get_value("time/use_real_clock") else "Off"),
		"5. Master volume: %d%%" % int(round(float(Settings.get_value("audio/master")) * 100)),
		"6. Ambience volume: %d%%" % int(round(float(Settings.get_value("audio/ambience")) * 100)),
	])


static func _rate_text(rate: int) -> String:
	return "%d real minutes per game day" % int(round(1440.0 / rate))


func change(line: int) -> void:
	match line:
		1:
			Settings.set_value("graphics/preset", GameSettings.next_in(GameSettings.PRESETS, StringName(Settings.get_value("graphics/preset"))))
		2:
			Settings.set_value("graphics/dof", not bool(Settings.get_value("graphics/dof")))
		3:
			Settings.set_value("time/rate", GameSettings.next_in(GameSettings.RATES, int(Settings.get_value("time/rate"))))
		4:
			Settings.set_value("time/use_real_clock", not bool(Settings.get_value("time/use_real_clock")))
		5, 6:
			var key := "audio/master" if line == 5 else "audio/ambience"
			var steps := [1.0, 0.75, 0.5, 0.25, 0.0]
			var cur := float(Settings.get_value(key))
			var i := 0
			for k in steps.size():
				if absf(steps[k] - cur) < 0.01:
					i = k
			Settings.set_value(key, steps[(i + 1) % steps.size()])
	Settings.apply()
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	var k := (event as InputEventKey).physical_keycode
	if k == KEY_F2:
		toggle()
		get_viewport().set_input_as_handled()
	elif _panel.visible and k >= KEY_1 and k <= KEY_6:
		change(k - KEY_1 + 1)
		get_viewport().set_input_as_handled()
