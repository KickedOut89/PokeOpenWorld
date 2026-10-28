class_name PerfProbe
extends Node
## Run the game with `-- --perf`: flies the player over Viridian at noon in the rain for
## 120 s and writes min/avg/p99 frame times to user://logs/perf.json, then quits.

var duration := 120.0
const PATH: Array[StringName] = [&"v_south_gate", &"v_plaza_s", &"v_market_c", &"v_plaza_n", &"v_park_bench", &"v_gym_front", &"v_cafe_tables"]

var world: KantoWorld
var _frames: PackedFloat32Array = []
var _t: float = 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-seconds="):
			duration = float(arg.get_slice("=", 1))
	Clock.model.minutes = 12 * 60.0
	for id in Weather.models:
		var m: WeatherModel = Weather.models[id]
		m.current = &"rain"
		m.target = &"rain"
		m.blend = 1.0
	world.teleport_to_anchor(PATH[0])
	print("perf: probe started")


func _process(delta: float) -> void:
	_t += delta
	_frames.append(delta * 1000.0)
	if _frames.size() % 50 == 0:
		print("perf: t=%.1f frames=%d last=%.1fms" % [_t, _frames.size(), delta * 1000.0])
	var seg := _t / duration * (PATH.size() - 1)
	var i := clampi(int(seg), 0, PATH.size() - 2)
	var a := world.find_anchor(PATH[i])
	var b := world.find_anchor(PATH[i + 1])
	world.player.global_position = a.lerp(b, seg - i) + Vector3(0, 0.3, 0)
	if _t >= duration:
		_write()
		get_tree().quit()


func _write() -> void:
	var sorted := _frames.duplicate()
	sorted.sort()
	var total := 0.0
	for f in _frames:
		total += f
	var report := {
		"frames": _frames.size(), "min_ms": sorted[0], "avg_ms": total / _frames.size(),
		"p99_ms": sorted[int(sorted.size() * 0.99)], "max_ms": sorted[sorted.size() - 1],
		"avg_fps": 1000.0 / (total / _frames.size()), "preset": String(GraphicsPresets.current),
		"gpu": RenderingServer.get_video_adapter_name(), "resolution": str(get_viewport().get_visible_rect().size),
	}
	DirAccess.make_dir_recursive_absolute("user://logs")
	var f := FileAccess.open("user://logs/perf.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, " "))
	print("perf: ", report)
