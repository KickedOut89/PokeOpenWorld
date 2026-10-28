extends Node
## Entry point. Loads the world scene and handles dev command-line options:
##   --screenshot=<path>  save a frame after --frames=<n> (default 90) and quit
##   --time=<HH:MM>       set the game clock
##   --weather=<id>       force weather everywhere
##   --preset=<name>      graphics preset (low/medium/high/ultra)
##   --off=<a,b>          disable preset features (sdfgi,ssao,ssil,volumetric,glow,dof)

const WORLD := "res://scenes/regions/kanto/kanto_world.tscn"

var _shot_path := ""
var _shot_frames := 90


func _ready() -> void:
	InputSetup.register()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_shot_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--time="):
			var hm := arg.get_slice("=", 1).split(":")
			Clock.model.minutes = int(hm[0]) * 60.0 + (int(hm[1]) if hm.size() > 1 else 0)
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
		add_child(load(WORLD).instantiate())


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
