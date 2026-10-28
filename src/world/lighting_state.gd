class_name LightingState
extends RefCounted
## One frame's lighting targets, produced by LightingModel.sample().

var sun_dir: Vector3 = Vector3.DOWN
var sun_color: Color = Color.WHITE
var sun_energy: float = 1.0
var moon_dir: Vector3 = Vector3.DOWN
var moon_energy: float = 0.0
var sky_top: Color = Color.SKY_BLUE
var sky_horizon: Color = Color.WHITE
var ambient_energy: float = 1.0
var fog_density: float = 0.0
var volumetric_density: float = 0.0
var exposure: float = 1.0
var lut: StringName = &"day"
var lamps_on: bool = false
