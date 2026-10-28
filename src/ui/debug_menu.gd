class_name DebugMenu
extends CanvasLayer
## F3 (debug builds or --debug-menu): live tuning so the owner can find good lighting
## values on real hardware and report them. Values print to the log too.
##   PgUp/PgDn  time +/- 1 h      W  cycle weather      X/Z  exposure +/-
##   F/V        fog +/-           S  spawn a Pidgey     T    teleport to next town anchor

const WEATHERS: Array[StringName] = [&"clear", &"cloudy", &"rain", &"thunderstorm", &"fog"]
const TELEPORTS: Array[StringName] = [&"player_spawn", &"route1_vendor", &"v_plaza_n", &"r2_camp", &"f_ranger_desk"]

var world: Node3D
var _panel: PanelContainer
var _label: Label
var _tp := 0


static func enabled() -> bool:
	return OS.is_debug_build() or OS.get_cmdline_user_args().has("--debug-menu")


func _ready() -> void:
	layer = 48
	_panel = PanelContainer.new()
	_panel.position = Vector2(20, 300)
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_panel.add_child(_label)
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled() or not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	var k := (event as InputEventKey).physical_keycode
	if k == KEY_F3:
		_panel.visible = not _panel.visible
	if not _panel.visible:
		return
	var lighting: LightingDirector = world.lighting
	match k:
		KEY_PAGEUP:
			Clock.model.minutes = fposmod(Clock.model.minutes + 60.0, 1440.0)
		KEY_PAGEDOWN:
			Clock.model.minutes = fposmod(Clock.model.minutes - 60.0, 1440.0)
		KEY_W:
			var m: WeatherModel = Weather.model_for_area(world.streamer.current_area)
			if m != null:
				m.current = WEATHERS[(WEATHERS.find(m.current) + 1) % WEATHERS.size()]
				m.target = m.current
				m.blend = 1.0
		KEY_X:
			lighting.overrides["exposure"] = float(lighting.overrides.get("exposure", lighting.current_state().exposure)) + 0.05
		KEY_Z:
			lighting.overrides["exposure"] = float(lighting.overrides.get("exposure", lighting.current_state().exposure)) - 0.05
		KEY_F:
			lighting.overrides["fog_density"] = float(lighting.overrides.get("fog_density", lighting.current_state().fog_density)) + 0.001
		KEY_V:
			lighting.overrides["fog_density"] = maxf(0.0, float(lighting.overrides.get("fog_density", lighting.current_state().fog_density)) - 0.001)
		KEY_S:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var w := WildPokemon.make(Creature.create(&"pidgey", 5, rng, Data.db), world.player.global_position + Vector3(0, 0.5, -5), &"debug")
			world.spawner.add_child(w)
		KEY_T:
			_tp = (_tp + 1) % TELEPORTS.size()
			world.teleport_to_anchor(TELEPORTS[_tp])
	_refresh(lighting)


func _refresh(lighting: LightingDirector) -> void:
	var s := lighting.current_state()
	var text := "DEBUG  %02d:%02d  area=%s  weather=%s\nexposure=%.2f fog=%.4f vol=%.3f sun=%.2f ambient=%.2f\noverrides=%s" % [
		int(Clock.model.minutes / 60), int(Clock.model.minutes) % 60, world.streamer.current_area,
		Weather.weather_for_area(world.streamer.current_area), s.exposure, s.fog_density, s.volumetric_density,
		s.sun_energy, s.ambient_energy, lighting.overrides]
	_label.text = text
	print(text)
