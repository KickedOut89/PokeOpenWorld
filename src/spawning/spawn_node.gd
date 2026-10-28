class_name SpawnNode
extends Node3D
## Adapter between SpawnDirector and the scene: gathers tall-grass zones from loaded
## chunks, ticks the director every 0.5 s and instances/frees WildPokemon.

const TICK := 0.5

var streamer: WorldStreamer
var camera: Camera3D
var player: Node3D
var director: SpawnDirector
var enabled: bool = true

var _rng := RandomNumberGenerator.new()
var _tables: Dictionary = {}
var _wilds: Dictionary = {}  # spawn id -> WildPokemon
var _next_id: int = 0
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	director = SpawnDirector.new(_rng)
	var nocturnal := {}
	for id in Data.db.table(&"species"):
		if Data.db.table(&"species")[id].get("nocturnal", false):
			nocturnal[id] = true
	for id in Data.db.table(&"spawns"):
		_tables[id] = SpawnTable.new(Data.db.table(&"spawns")[id], nocturnal)


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = TICK
		tick_now()


func game_minutes() -> float:
	return Clock.model.day * 1440.0 + Clock.model.minutes


func tick_now() -> void:
	if not enabled or player == null or streamer == null or not streamer.visible:
		return
	var active: Array[Dictionary] = []
	for id in _wilds.keys():
		var w: WildPokemon = _wilds[id]
		if not is_instance_valid(w):
			_wilds.erase(id)
			continue
		active.append({"id": id, "pos": w.global_position, "zone_id": w.zone_id})
	var area := streamer.area_at(player.global_position)
	var r := director.tick(player.global_position, active, _zones(), Clock.model.period(),
		Weather.weather_for_area(area), _is_visible, game_minutes())
	for id in r.despawn:
		var w: WildPokemon = _wilds.get(id, null)
		_wilds.erase(id)
		if is_instance_valid(w) and not w.in_fight:
			w.queue_free()
	for s in r.spawn:
		var c := Creature.create(s.species, s.level, _rng, Data.db)
		c.shiny = s.shiny
		var w := WildPokemon.make(c, s.pos + Vector3(0, 0.3, 0), s.zone_id)
		w.spawn_id = _next_id
		_wilds[_next_id] = w
		_next_id += 1
		w.removed.connect(_on_removed)
		add_child(w)


func wilds() -> Array:
	return _wilds.values().filter(func(w: Variant) -> bool: return is_instance_valid(w))


func _on_removed(w: WildPokemon, _reason: StringName) -> void:
	_wilds.erase(w.spawn_id)
	director.on_removed(w.zone_id, game_minutes())


func _is_visible(p: Vector3) -> bool:
	return camera != null and camera.is_inside_tree() and camera.is_position_in_frustum(p)


func _zones() -> Array:
	var out: Array = []
	for c in streamer.loaded_coords():
		var data := streamer.record(c)
		var origin := data.origin()
		for z in data.spawn_zones:
			if not _tables.has(StringName(z.table)):
				continue
			var r: Array = z.rect
			var chunk := data
			out.append({
				"id": StringName(z.id), "table": _tables[StringName(z.table)],
				"rect": Rect2(origin.x + float(r[0]), origin.z + float(r[1]), float(r[2]), float(r[3])),
				"y": chunk.height_at(Vector2(float(r[0]) + float(r[2]) * 0.5, float(r[1]) + float(r[3]) * 0.5)),
				"point_ok": func(p: Vector3) -> bool: return _tall_grass_at(p),
			})
	return out


func _tall_grass_at(p: Vector3) -> bool:
	var data := streamer.record(StreamingPlanner.chunk_of(p))
	if data == null:
		return false
	var local := p - data.origin()
	return data.is_tall_grass(Vector2(local.x, local.z))
