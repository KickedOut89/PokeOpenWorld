class_name LightingModel
extends RefCounted
## Pure function from (game minutes, weather blend) to LightingState.
## Hourly keyframes and weather multipliers come from data/lighting.json ("periods").
## Sun rises at 05:00 in the east (+x), peaks at 12:00 in the south (+z), sets 19:30 in the west.

const SUNRISE := 300.0
const NOON := 720.0
const SUNSET := 1170.0
const PEAK_ELEVATION_DEG := 65.0
const LAMPS_ON := 1050.0  # 17:30
const LAMPS_OFF := 360.0  # 06:00

var _hours: Dictionary = {}
var _weather: Dictionary = {}
var _moon_energy: float = 0.35


static func from_db(db: DataDB) -> LightingModel:
	var m := LightingModel.new()
	var rec := db.get_record(&"lighting", &"periods")
	m._hours = rec.get("hours", {})
	m._weather = rec.get("weather", {})
	m._moon_energy = float(rec.get("moon_energy", 0.35))
	return m


func sample(minutes: float, weather: StringName, weather_to: StringName, blend: float) -> LightingState:
	var s := LightingState.new()
	minutes = fposmod(minutes, 1440.0)
	var h := int(minutes / 60.0)
	var t := (minutes - h * 60.0) / 60.0
	var a: Dictionary = _hours.get(str(h), {})
	var b: Dictionary = _hours.get(str((h + 1) % 24), a)
	s.sun_color = _col(a, b, "sun_color", t)
	s.sky_top = _col(a, b, "sky_top", t)
	s.sky_horizon = _col(a, b, "sky_horizon", t)
	s.sun_energy = _num(a, b, "sun_energy", t)
	s.ambient_energy = _num(a, b, "ambient_energy", t)
	s.fog_density = _num(a, b, "fog_density", t)
	s.volumetric_density = _num(a, b, "volumetric_density", t)
	s.exposure = _num(a, b, "exposure", t)
	s.lut = StringName(a.get("grade", "day"))
	var elev := _sun_elevation_deg(minutes)
	var az := _sun_azimuth_deg(minutes)
	s.sun_dir = -_dir_from(elev, az)
	s.moon_dir = -_dir_from(absf(elev) * 0.8 + 10.0, az + 180.0)
	if elev <= 0.0:
		s.sun_energy = 0.0
		s.moon_energy = _moon_energy * clampf(-elev / 10.0, 0.0, 1.0)
	var w0: Dictionary = _weather.get(String(weather), {})
	var w1: Dictionary = _weather.get(String(weather_to), w0)
	for f in ["sun_energy", "ambient_energy", "fog_density", "volumetric_density", "exposure"]:
		var mul := lerpf(float(w0.get(f, 1.0)), float(w1.get(f, 1.0)), blend)
		s.set(f, float(s.get(f)) * mul)
	s.moon_energy *= lerpf(float(w0.get("sun_energy", 1.0)), float(w1.get("sun_energy", 1.0)), blend)
	var sky_mul := Color(w0.get("sky_mul", "#ffffff")).lerp(Color(w1.get("sky_mul", "#ffffff")), blend)
	s.sky_top *= sky_mul
	s.sky_horizon *= sky_mul
	s.lamps_on = minutes >= LAMPS_ON or minutes < LAMPS_OFF
	return s



static func _sun_elevation_deg(m: float) -> float:
	if m >= SUNRISE and m <= NOON:
		return PEAK_ELEVATION_DEG * sin((m - SUNRISE) / (NOON - SUNRISE) * PI * 0.5)
	if m > NOON and m <= SUNSET:
		return PEAK_ELEVATION_DEG * sin((SUNSET - m) / (SUNSET - NOON) * PI * 0.5)
	# Night: dip below the horizon, deepest around 00:45.
	var night_len := 1440.0 - SUNSET + SUNRISE
	var into := fposmod(m - SUNSET, 1440.0)
	return -40.0 * sin(into / night_len * PI)


static func _sun_azimuth_deg(m: float) -> float:
	# 90 = east at sunrise, 180 = south at noon, 270 = west at sunset.
	if m <= NOON:
		return lerpf(90.0, 180.0, clampf((m - SUNRISE) / (NOON - SUNRISE), 0.0, 1.0))
	return lerpf(180.0, 270.0, clampf((m - NOON) / (SUNSET - NOON), 0.0, 1.0))


## Unit vector toward a body at elevation/azimuth (azimuth 0 = north (-z), 90 = east (+x)).
static func _dir_from(elev_deg: float, az_deg: float) -> Vector3:
	var e := deg_to_rad(elev_deg)
	var a := deg_to_rad(az_deg)
	return Vector3(sin(a) * cos(e), sin(e), -cos(a) * cos(e)).normalized()


static func _num(a: Dictionary, b: Dictionary, k: String, t: float) -> float:
	return lerpf(float(a.get(k, 0.0)), float(b.get(k, a.get(k, 0.0))), t)


static func _col(a: Dictionary, b: Dictionary, k: String, t: float) -> Color:
	return Color(a.get(k, "#ffffff")).lerp(Color(b.get(k, a.get(k, "#ffffff"))), t)
