class_name LightingDirector
extends Node3D
## Applies LightingModel output every frame to the sun, moon, sky, fog, exposure and color grade.
## Also owns the tilt-shift depth of field and switches lamps/windows on at dusk.

@export var area: StringName = &"pallet_town"

var model: LightingModel
var env: Environment
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var world_env: WorldEnvironment
var lamps_on: bool = false
var overrides: Dictionary = {}  # debug menu: field -> value

var _sky_mat: ProceduralSkyMaterial
var _grades: Dictionary = {}


func _ready() -> void:
	model = LightingModel.from_db(Data.db)
	_build()
	var rec := Data.db.get_record(&"lighting", &"periods")
	for g in rec.get("grades", {}):
		var grad := Gradient.new()
		var cols: Array = rec.grades[g]
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		grad.colors = PackedColorArray([Color(cols[0]), Color(cols[1]), Color(cols[2])])
		var tex := GradientTexture1D.new()
		tex.gradient = grad
		tex.width = 256
		_grades[StringName(g)] = tex
	GraphicsPresets.apply(GraphicsPresets.current, env, get_viewport())
	EventBus.area_entered.connect(func(a: StringName) -> void: area = a)


func _build() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = _sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.fog_enabled = true
	env.fog_light_color = Color("c8d4e0")
	env.volumetric_fog_enabled = true
	env.volumetric_fog_length = 96.0
	env.adjustment_enabled = true
	world_env = WorldEnvironment.new()
	world_env.environment = env
	var cam_attr := CameraAttributesPractical.new()
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = 30.0
	cam_attr.dof_blur_far_transition = 25.0
	cam_attr.dof_blur_near_enabled = true
	cam_attr.dof_blur_near_distance = 8.0
	cam_attr.dof_blur_near_transition = 4.0
	cam_attr.dof_blur_amount = 0.08
	world_env.camera_attributes = cam_attr
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color("9fb4ff")
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)


func current_state() -> LightingState:
	var w: WeatherModel = Weather.model_for_area(area)
	var cur := w.current if w != null else &"clear"
	var tgt := w.target if w != null else &"clear"
	var blend := w.blend if w != null else 1.0
	return model.sample(Clock.model.minutes, cur, tgt, blend)


func _process(_delta: float) -> void:
	var s := current_state()
	for k in overrides:
		s.set(k, overrides[k])
	_orient(sun, s.sun_dir)
	sun.light_color = s.sun_color
	sun.light_energy = s.sun_energy
	sun.visible = s.sun_energy > 0.001
	_orient(moon, s.moon_dir)
	moon.light_energy = s.moon_energy
	moon.visible = s.moon_energy > 0.001
	_sky_mat.sky_top_color = s.sky_top
	_sky_mat.sky_horizon_color = s.sky_horizon
	_sky_mat.ground_horizon_color = s.sky_horizon
	env.ambient_light_energy = s.ambient_energy
	env.fog_density = s.fog_density
	env.volumetric_fog_density = s.volumetric_density
	env.tonemap_exposure = s.exposure
	if _grades.has(s.lut):
		env.adjustment_color_correction = _grades[s.lut]
	if world_env.camera_attributes is CameraAttributesPractical:
		var ca := world_env.camera_attributes as CameraAttributesPractical
		ca.dof_blur_far_enabled = GraphicsPresets.dof_enabled()
		ca.dof_blur_near_enabled = GraphicsPresets.dof_enabled()
	if s.lamps_on != lamps_on:
		lamps_on = s.lamps_on
		EventBus.lamps_changed.emit(lamps_on)
		apply_lamps(get_tree(), lamps_on)


## Switches every lamp light and building window in the tree.
static func apply_lamps(tree: SceneTree, on: bool) -> void:
	for lamp in tree.get_nodes_in_group(&"lamp"):
		for c in lamp.get_children():
			if c is OmniLight3D:
				(c as OmniLight3D).light_energy = 1.6 if on else 0.0
	for w in tree.get_nodes_in_group(&"window"):
		var mi := w as MeshInstance3D
		if mi != null and mi.mesh != null and mi.mesh.surface_get_material(0) is StandardMaterial3D:
			(mi.mesh.surface_get_material(0) as StandardMaterial3D).emission_energy_multiplier = 2.0 if on else 0.0


func _orient(light: DirectionalLight3D, dir: Vector3) -> void:
	var up := Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.FORWARD
	light.basis = Basis.looking_at(dir, up)
