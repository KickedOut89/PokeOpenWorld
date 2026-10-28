class_name SpawnDirector
extends RefCounted
## Decides wild spawns/despawns around the player. Pure: the SpawnNode adapter feeds it
## zones and active wilds, and applies the result.
## Zone: {id, table: SpawnTable, rect: Rect2 (world x/z), y, point_ok?: Callable(Vector3)->bool}
## Active: {id: int, pos: Vector3, zone_id}. `game_minutes` is monotonic (day*1440 + minutes).

const ACTIVE_MIN := 8
const ACTIVE_MAX := 12
const ACTIVE_RADIUS := 60.0
const DESPAWN_RADIUS := 80.0
const MIN_SPAWN_DIST := 25.0
const RESPAWN_GAME_MIN := Vector2(1, 3)
const SHINY_ODDS := 8192
const MAX_POINT_TRIES := 8
const TOP_UP_CHANCE := 0.25  # between MIN and MAX, spawn on 1 in 4 ticks

var _rng: RandomNumberGenerator
var _blocked_until: Dictionary = {}  # zone id -> Array[float]


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func on_removed(zone_id: StringName, game_minutes: float) -> void:
	var list: Array = _blocked_until.get_or_add(zone_id, [])
	list.append(game_minutes + _rng.randf_range(RESPAWN_GAME_MIN.x, RESPAWN_GAME_MIN.y))


func timers_to_dict() -> Dictionary:
	var out := {}
	for z in _blocked_until:
		out[String(z)] = (_blocked_until[z] as Array).duplicate()
	return out


func timers_from_dict(d: Dictionary) -> void:
	_blocked_until = {}
	for z in d:
		_blocked_until[StringName(z)] = (d[z] as Array).map(func(t: Variant) -> float: return float(t))


func roll_shiny() -> bool:
	return _rng.randi_range(1, SHINY_ODDS) == 1


func tick(player_pos: Vector3, active: Array[Dictionary], zones: Array, period: StringName, weather: StringName, is_visible: Callable, game_minutes: float) -> Dictionary:
	var despawn: Array[int] = []
	var near := 0
	var flat := Vector2(player_pos.x, player_pos.z)
	for a in active:
		var d := flat.distance_to(Vector2(a.pos.x, a.pos.z))
		if a.get("in_fight", false):
			continue
		if d > DESPAWN_RADIUS:
			despawn.append(int(a.id))
			on_removed(StringName(a.get("zone_id", "")), game_minutes)
		elif d <= ACTIVE_RADIUS:
			near += 1
	var spawn: Array[Dictionary] = []
	var want := near < ACTIVE_MIN or (near < ACTIVE_MAX and _rng.randf() < TOP_UP_CHANCE)
	if want:
		var s := _try_spawn(flat, player_pos.y, zones, period, weather, is_visible, game_minutes)
		if not s.is_empty():
			spawn.append(s)
	return {"spawn": spawn, "despawn": despawn}


func _try_spawn(flat: Vector2, py: float, zones: Array, period: StringName, weather: StringName, is_visible: Callable, now: float) -> Dictionary:
	var candidates: Array = []
	for z in zones:
		if _is_blocked(StringName(z.id), now):
			continue
		var r: Rect2 = z.rect
		var closest := Vector2(clampf(flat.x, r.position.x, r.end.x), clampf(flat.y, r.position.y, r.end.y))
		if closest.distance_to(flat) <= ACTIVE_RADIUS:
			candidates.append(z)
	if candidates.is_empty():
		return {}
	var zone: Dictionary = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var pick: Dictionary = (zone.table as SpawnTable).pick(period, weather, _rng)
	if pick.is_empty():
		return {}
	var r: Rect2 = zone.rect
	for i in MAX_POINT_TRIES:
		var p2 := Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y))
		var dist := p2.distance_to(flat)
		if dist < MIN_SPAWN_DIST or dist > ACTIVE_RADIUS:
			continue
		var p := Vector3(p2.x, float(zone.get("y", py)), p2.y)
		if is_visible.call(p):
			continue
		if zone.has("point_ok") and not (zone.point_ok as Callable).call(p):
			continue
		return {"species": pick.species, "level": pick.level, "shiny": roll_shiny(), "pos": p, "zone_id": StringName(zone.id)}
	return {}


func _is_blocked(zone_id: StringName, now: float) -> bool:
	var list: Array = _blocked_until.get(zone_id, [])
	var still: Array = []
	for t in list:
		if t > now:
			still.append(t)
	_blocked_until[zone_id] = still
	return not still.is_empty()
