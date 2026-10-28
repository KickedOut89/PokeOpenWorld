class_name Creature
extends RefCounted
## One Pokémon instance: species, level/EXP, IVs/EVs, nature, moves, HP and status.

var species: StringName
var level: int = 1
var exp: int = 0
var ivs: Dictionary = {}
var evs: Dictionary = {}
var nature: StringName = &"hardy"
var moves: Array[StringName] = []
var hp: int = 1
var status: StringName = &""
var shiny: bool = false
var nickname: String = ""
var pending_evolution: StringName = &""  # a cancelled evolution retries next level-up
var db: DataDB


static func create(species_id: StringName, lvl: int, rng: RandomNumberGenerator, data: DataDB) -> Creature:
	var c := Creature.new()
	c.db = data
	c.species = species_id
	c.level = clampi(lvl, 1, Growth.MAX_LEVEL)
	c.exp = Growth.exp_for_level(StringName(c.rec().get("growth", "medium_fast")), c.level)
	for s in Stats.NAMES:
		c.ivs[String(s)] = rng.randi_range(0, 31)
		c.evs[String(s)] = 0
	var natures := data.table(&"natures").keys()
	if not natures.is_empty():
		c.nature = natures[rng.randi_range(0, natures.size() - 1)]
	var known: Array[StringName] = []
	for entry in c.rec().get("learnset", []):
		if int(entry[0]) <= c.level and not known.has(StringName(entry[1])):
			known.append(StringName(entry[1]))
	c.moves = known.slice(maxi(0, known.size() - 4))
	c.hp = c.max_hp()
	return c


func rec() -> Dictionary:
	return db.get_record(&"species", species)


func display_name() -> String:
	return nickname if nickname != "" else String(rec().get("name", species))


func types() -> Array:
	return rec().get("types", ["normal"])


func stat(name: StringName) -> int:
	var base: Dictionary = rec().get("base", {})
	var b := int(base.get(String(name), 50))
	var iv := int(ivs.get(String(name), 0))
	var ev := int(evs.get(String(name), 0))
	if name == &"hp":
		return Stats.hp(b, iv, ev, level)
	return Stats.other(b, iv, ev, level, Stats.nature_mult(db.get_record(&"natures", nature), name))


func max_hp() -> int:
	return stat(&"hp")


func is_fainted() -> bool:
	return hp <= 0


## Adds EXP; returns events in order: {type:"level",level}, {type:"learn",move}, {type:"evolve",to}.
func add_exp(amount: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if level >= Growth.MAX_LEVEL:
		return events
	var curve := StringName(rec().get("growth", "medium_fast"))
	exp += amount
	while level < Growth.MAX_LEVEL and exp >= Growth.exp_for_level(curve, level + 1):
		var old_max := max_hp()
		level += 1
		hp = mini(max_hp(), hp + (max_hp() - old_max))
		events.append({"type": "level", "level": level})
		for entry in rec().get("learnset", []):
			if int(entry[0]) == level and not moves.has(StringName(entry[1])):
				events.append({"type": "learn", "move": StringName(entry[1])})
		var evo := _evolution_for(level)
		if evo != &"":
			events.append({"type": "evolve", "to": evo})
	if level >= Growth.MAX_LEVEL:
		exp = mini(exp, Growth.exp_for_level(curve, Growth.MAX_LEVEL))
	return events


func _evolution_for(lvl: int) -> StringName:
	if pending_evolution != &"":
		return pending_evolution
	for e in rec().get("evolves", []):
		if lvl >= int(e.get("level", 999)):
			return StringName(e.to)
	return &""


func evolve_to(to: StringName) -> void:
	var ratio := float(hp) / maxf(1.0, max_hp())
	species = to
	pending_evolution = &""
	hp = maxi(1, int(round(ratio * max_hp()))) if hp > 0 else 0


func to_dict() -> Dictionary:
	return {"species": species, "level": level, "exp": exp, "ivs": ivs, "evs": evs, "nature": nature,
		"moves": moves, "hp": hp, "status": status, "shiny": shiny, "nickname": nickname,
		"pending_evolution": pending_evolution}


static func from_dict(d: Dictionary, data: DataDB) -> Creature:
	var c := Creature.new()
	c.db = data
	c.species = StringName(d.get("species", "pidgey"))
	c.level = int(d.get("level", 1))
	c.exp = int(d.get("exp", 0))
	for s in Stats.NAMES:
		c.ivs[String(s)] = int(d.get("ivs", {}).get(String(s), 0))
		c.evs[String(s)] = int(d.get("evs", {}).get(String(s), 0))
	c.nature = StringName(d.get("nature", "hardy"))
	var mv: Array[StringName] = []
	for m in d.get("moves", []):
		mv.append(StringName(m))
	c.moves = mv
	c.hp = int(d.get("hp", c.max_hp()))
	c.status = StringName(d.get("status", ""))
	c.shiny = bool(d.get("shiny", false))
	c.nickname = String(d.get("nickname", ""))
	c.pending_evolution = StringName(d.get("pending_evolution", ""))
	return c
