class_name WeatherFx
extends Node3D
## Rain/storm/fog visuals for the area the player is in: rain particles that follow
## the camera, lightning flashes with delayed thunder, a fog volume, and wet terrain
## (lower roughness, darker albedo on the tile materials).

const RAIN_BOX := 40.0

var camera: Camera3D
var lighting: LightingDirector
var area: StringName = &""
var wetness := Wetness.new()

var _rain: GPUParticles3D
var _fog: FogVolume
var _thunder: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _next_flash: float = -1.0
var _tile_mats: Array = []   # [StandardMaterial3D, base_color, base_roughness]


static func targets_for(weather: StringName) -> Dictionary:
	match weather:
		&"rain":
			return {"rain_rate": 1.0, "wet": true, "lightning_interval": Vector2.ZERO, "fog_volume": 0.0}
		&"thunderstorm":
			return {"rain_rate": 1.8, "wet": true, "lightning_interval": Vector2(6.0, 18.0), "fog_volume": 0.0}
		&"fog":
			return {"rain_rate": 0.0, "wet": false, "lightning_interval": Vector2.ZERO, "fog_volume": 0.06}
		_:
			return {"rain_rate": 0.0, "wet": false, "lightning_interval": Vector2.ZERO, "fog_volume": 0.0}


func _ready() -> void:
	_rng.randomize()
	_rain = GPUParticles3D.new()
	_rain.amount = 6000
	_rain.lifetime = 1.2
	_rain.visibility_aabb = AABB(Vector3(-RAIN_BOX, -RAIN_BOX, -RAIN_BOX), Vector3.ONE * RAIN_BOX * 2)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(RAIN_BOX * 0.5, 1.0, RAIN_BOX * 0.5)
	pm.direction = Vector3(0.1, -1, 0)
	pm.spread = 3.0
	pm.initial_velocity_min = 22.0
	pm.initial_velocity_max = 26.0
	pm.gravity = Vector3(0, -9.8, 0)
	_rain.process_material = pm
	var drop := QuadMesh.new()
	drop.size = Vector2(0.03, 0.6)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.75, 0.8, 0.9, 0.45)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	drop.material = dm
	_rain.draw_pass_1 = drop
	_rain.emitting = false
	add_child(_rain)
	_fog = FogVolume.new()
	_fog.size = Vector3(160, 30, 160)
	var fm := FogMaterial.new()
	fm.density = 0.0
	fm.albedo = Color(0.85, 0.88, 0.9)
	_fog.material = fm
	add_child(_fog)
	_thunder = AudioStreamPlayer.new()
	_thunder.stream = Assets.audio("sfx/thunder")
	add_child(_thunder)
	EventBus.area_entered.connect(func(a: StringName) -> void: area = a)


## Registers terrain tile materials so wetness can darken them (MeshLibraryBuilder stores them).
func track_library(lib: MeshLibrary) -> void:
	for id in lib.get_item_list():
		var mesh := lib.get_item_mesh(id)
		var mat := mesh.surface_get_material(0) as StandardMaterial3D if mesh != null else null
		if mat != null:
			_tile_mats.append([mat, mat.albedo_color, mat.roughness])


func _process(delta: float) -> void:
	var w: WeatherModel = Weather.model_for_area(area)
	var cur := w.current if w != null else &"clear"
	var tgt := w.target if w != null else &"clear"
	var blend := w.blend if w != null else 1.0
	var a := targets_for(cur)
	var b := targets_for(tgt)
	var rate := lerpf(a.rain_rate, b.rain_rate, blend)
	var inside := lighting != null and lighting.interior
	_rain.emitting = rate > 0.05 and not inside
	_rain.amount_ratio = clampf(rate / 1.8, 0.0, 1.0)
	if camera != null:
		_rain.global_position = camera.global_position.lerp(_focus(), 0.6) + Vector3(0, 18, 0)
		_fog.global_position = _focus()
	(_fog.material as FogMaterial).density = 0.0 if inside else lerpf(a.fog_volume, b.fog_volume, blend)
	wetness.tick(delta, (b.wet if blend > 0.5 else a.wet) and not inside)
	for entry in _tile_mats:
		var m: StandardMaterial3D = entry[0]
		m.albedo_color = (entry[1] as Color).darkened(0.18 * wetness.value)
		m.roughness = lerpf(entry[2], 0.25, wetness.value)
	_lightning(delta, b.lightning_interval if blend > 0.5 else a.lightning_interval, inside)


func _focus() -> Vector3:
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	return p.global_position if p != null else global_position


func _lightning(delta: float, interval: Vector2, inside: bool) -> void:
	if interval == Vector2.ZERO:
		_next_flash = -1.0
		return
	if _next_flash < 0.0:
		_next_flash = _rng.randf_range(interval.x, interval.y)
	_next_flash -= delta
	if _next_flash <= 0.0:
		_next_flash = _rng.randf_range(interval.x, interval.y)
		if lighting != null and not inside:
			lighting.flash()
		get_tree().create_timer(_rng.randf_range(0.5, 3.0)).timeout.connect(_thunder.play)
