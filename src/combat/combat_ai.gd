class_name CombatAI
extends RefCounted
## Picks foe actions: scores ready moves (power x type x STAB, status value when the
## target is clean), then moves into that move's range. Ranged users keep distance.
## skill 0..1: below 1 the AI picks among the top few moves at random.

const CLOSE := 3.0
const STATUS_VALUE := 60.0
const STAT_VALUE := 12.0

var chart: TypeChart
var db: DataDB
var rng: RandomNumberGenerator


func _init(type_chart: TypeChart, data: DataDB, random: RandomNumberGenerator) -> void:
	chart = type_chart
	db = data
	rng = random


func score(rec: Dictionary, me: Combatant, foe: Combatant) -> float:
	var s := 0.0
	var power := float(rec.get("power", 0))
	if power > 0.0:
		var t := StringName(rec.get("type", "normal"))
		s = power * chart.mult(t, foe.creature.types()) * (1.5 if me.creature.types().has(String(t)) else 1.0)
	if rec.has("status") and foe.status == &"":
		s += STATUS_VALUE * float(rec.status.get("chance", 1.0))
	if rec.has("stat_change") and power <= 0.0:
		s += STAT_VALUE
	return s


static func reach(rec: Dictionary) -> float:
	match String(rec.get("shape", "melee_arc")):
		"area":
			return float(rec.get("range", 0.0)) + float(rec.get("radius", 2.0))
		"self":
			return INF
	return float(rec.get("range", 2.5)) + 0.5


static func is_ranged(rec: Dictionary) -> bool:
	return String(rec.get("shape", "")) in ["projectile", "beam"]


func decide(me: Combatant, my_pos: Vector3, foe: Combatant, foe_pos: Vector3, ready: Array[StringName], skill: float) -> Dictionary:
	var dist := Vector2(foe_pos.x - my_pos.x, foe_pos.z - my_pos.z).length()
	var ranked: Array = []
	for m in ready:
		var rec := db.get_record(&"moves", m)
		if rec.is_empty() or not me.creature.moves.has(m):
			continue
		ranked.append({"id": m, "rec": rec, "score": score(rec, me, foe)})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	ranked = ranked.filter(func(x: Dictionary) -> bool: return x.score > 0.0)
	var prefers_range := _mostly_ranged(me)
	if ranked.is_empty():
		if prefers_range and dist < CLOSE:
			return {"action": &"retreat"}
		return {"action": &"strafe"} if prefers_range else {"action": &"approach"}
	var k := 1 + int(round((1.0 - clampf(skill, 0.0, 1.0)) * 2.0))
	var choice: Dictionary = ranked[rng.randi_range(0, mini(k, ranked.size()) - 1)]
	if dist <= reach(choice.rec):
		return {"action": &"move", "move": choice.id}
	return {"action": &"approach", "target_pos": foe_pos}


func _mostly_ranged(me: Combatant) -> bool:
	var ranged := 0
	for m in me.creature.moves:
		if is_ranged(db.get_record(&"moves", m)):
			ranged += 1
	return ranged * 2 >= maxi(1, me.creature.moves.size())
