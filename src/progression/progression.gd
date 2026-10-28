class_name Progression
extends RefCounted
## EXP awards after a win, move learning (max four) and evolution cancelling.


## Gen 5: EXP is divided among the Pokémon that took part (no Exp. Share in the slice).
static func exp_for_defeat(foe: Creature, my_level: int, participants: int, trainer: bool) -> int:
	var total := Growth.gen5_exp_gain(int(foe.rec().get("base_exp", 50)), foe.level, my_level, trainer)
	return maxi(1, floori(total / float(maxi(1, participants))))


static func needs_prompt(c: Creature, move: StringName) -> bool:
	return c.moves.size() >= 4 and not c.moves.has(move)


## forget_index -1 = decline (when full) or just add (when there's room). Returns true if learned.
static func learn(c: Creature, move: StringName, forget_index: int) -> bool:
	if c.moves.has(move):
		return false
	if c.moves.size() < 4:
		c.moves.append(move)
		return true
	if forget_index < 0 or forget_index >= c.moves.size():
		return false
	c.moves[forget_index] = move
	return true


const EV_STAT_CAP := 255
const EV_TOTAL_CAP := 510


## Gen 5 effort values: the foe's yield, at most 255 per stat and 510 in total.
static func add_evs(c: Creature, yield_: Dictionary) -> void:
	var total := 0
	for s in c.evs:
		total += int(c.evs[s])
	for s in yield_:
		var room := mini(EV_STAT_CAP - int(c.evs.get(s, 0)), EV_TOTAL_CAP - total)
		var add := clampi(int(yield_[s]), 0, maxi(0, room))
		c.evs[s] = int(c.evs.get(s, 0)) + add
		total += add


## A cancelled evolution simply waits: the next level-up offers it again.
static func cancel_evolution(c: Creature) -> void:
	c.pending_evolution = &""


## Awards EXP for every defeated foe to each participant still standing.
## Returns [{creature, events}] for the UI to walk through.
static func award(model: FightModel, foes: Array, trainer: bool) -> Array:
	var out: Array = []
	var ids: Array = model.participants.keys().filter(func(i: int) -> bool: return not model.party.members[i].is_fainted())
	for i in ids:
		var c: Creature = model.party.members[i]
		var events: Array[Dictionary] = []
		for f in foes:
			add_evs(c, (f as Creature).rec().get("ev_yield", {}))
			events.append_array(c.add_exp(exp_for_defeat(f, c.level, ids.size(), trainer)))
		out.append({"creature": c, "events": events})
	return out
