class_name Drifters
extends Node3D
## Decorative Pokémon that drift and bob in place: Butterfree by day,
## glowing Volbeat/Illumise by night (with a small light).

const DAY_SPECIES: Array[StringName] = [&"butterfree"]
const NIGHT_SPECIES: Array[StringName] = [&"volbeat", &"illumise"]

var count: int = 3
var _items: Array = []  # [sprite, base pos, phase]
var _night: bool = false
var _lights: Array[OmniLight3D] = []
var _t: float = 0.0


func _ready() -> void:
	add_to_group(&"ambient")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for i in count:
		var s := BillboardSprite.new()
		s.pixel_size = 0.022
		var base := Vector3(rng.randf_range(-4, 4), rng.randf_range(1.2, 2.4), rng.randf_range(-4, 4))
		s.position = base
		add_child(s)
		var l := OmniLight3D.new()
		l.light_color = Color("c8ff7a")
		l.omni_range = 3.0
		l.light_energy = 0.0
		s.add_child(l)
		_lights.append(l)
		_items.append([s, base, rng.randf() * TAU])
	_apply_period(Clock.model.period())
	EventBus.period_changed.connect(_apply_period)


func _apply_period(period: StringName) -> void:
	_night = period == &"night"
	var day := period == &"day" or period == &"morning"
	var assets := get_node_or_null(^"/root/Assets")
	for i in _items.size():
		var s: BillboardSprite = _items[i][0]
		s.visible = _night or day
		var list := NIGHT_SPECIES if _night else DAY_SPECIES
		if assets != null:
			s.set_sheet(assets.texture("species/%s" % list[i % list.size()]))
		_lights[i].light_energy = 0.8 if _night else 0.0


func _process(delta: float) -> void:
	_t += delta
	for it in _items:
		var s: BillboardSprite = it[0]
		var base: Vector3 = it[1]
		var ph: float = it[2]
		s.position = base + Vector3(sin(_t * 0.6 + ph) * 1.2, sin(_t * 2.0 + ph) * 0.25, cos(_t * 0.5 + ph) * 1.2)
