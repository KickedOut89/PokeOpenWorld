extends Node
## Entry point. Loads the world scene and handles dev command-line options:
##   --screenshot=<path>  save a frame after --frames=<n> (default 90) and quit
##   --time=<HH:MM>       set the game clock
##   --weather=<id>       force weather everywhere
##   --selftest           print content counts from the packed data and quit
##   --perf               120 s benchmark flight over Viridian -> user://logs/perf.json
##   --at=<anchor>        start at a named anchor (e.g. v_plaza_n)
##   --preset=<name>      graphics preset (low/medium/high/ultra)
##   --off=<a,b>          disable preset features (sdfgi,ssao,ssil,volumetric,glow,dof)

const WORLD := "res://scenes/regions/kanto/kanto_world.tscn"

var _shot_path := ""
var _start_anchor := &""
var _perf := false
var _shot_frames := 90


func _ready() -> void:
	InputSetup.register()
	if OS.get_cmdline_user_args().has("--selftest"):
		var db: DataDB = Data.db
		print("selftest: species=%d moves=%d chunks=%d npcs=%d interiors=%d errors=%d validator=%d" % [
			db.table(&"species").size(), db.table(&"moves").size(), db.table(&"chunks").size(),
			db.table(&"npcs").size(), db.table(&"interiors").size(), db.errors.size(), DataValidator.validate(db).size()])
		get_tree().quit()
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_shot_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--time="):
			var hm := arg.get_slice("=", 1).split(":")
			Clock.model.minutes = int(hm[0]) * 60.0 + (int(hm[1]) if hm.size() > 1 else 0)
		elif arg == "--perf":
			_perf = true
		elif arg.begins_with("--at="):
			_start_anchor = StringName(arg.get_slice("=", 1))
		elif arg.begins_with("--off="):
			for f in arg.get_slice("=", 1).split(","):
				GraphicsPresets.user_overrides[f] = false
		elif arg.begins_with("--preset="):
			GraphicsPresets.current = StringName(arg.get_slice("=", 1))
		elif arg.begins_with("--weather="):
			var w := StringName(arg.get_slice("=", 1))
			for id in Weather.models:
				var m: WeatherModel = Weather.models[id]
				m.current = w
				m.target = w
				m.blend = 1.0
	if ResourceLoader.exists(WORLD):
		var world: KantoWorld = load(WORLD).instantiate()
		add_child(world)
		if _perf:
			var probe := PerfProbe.new()
			probe.world = world
			add_child(probe)
		elif _start_anchor != &"":
			world.teleport_to_anchor(_start_anchor)
		elif _shot_path == "" and Saves.has_save(SaveService.AUTOSAVE_SLOT):
			world.player.input_enabled = false
			world.prompts.ask("Welcome back!", ["Continue", "New Game"], func(i: int) -> void:
				world.player.input_enabled = true
				if i == 0:
					world.continue_from_save(SaveService.AUTOSAVE_SLOT))


func _process(_delta: float) -> void:
	if _shot_path == "":
		return
	_shot_frames -= 1
	if _shot_frames <= 0:
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_shot_path.get_base_dir())
		img.save_png(_shot_path)
		print("screenshot saved: ", _shot_path)
		get_tree().quit()
