class_name Combatant
extends RefCounted
## A Creature during a fight: stat stages, status timers, stun, dodge i-frames, stamina.

const DODGE_COST := 25.0
const DODGE_IFRAMES := 0.25
const STAMINA_MAX := 100.0
const STAMINA_REGEN := 20.0
const REGEN_DELAY := 1.0

var creature: Creature
var stages: Dictionary = {&"atk": 0, &"def": 0, &"spa": 0, &"spd": 0, &"spe": 0, &"crit": 0}
var status: StringName = &""
var status_timer: float = INF
var stunned: float = 0.0
var invuln: float = 0.0
var stamina: float = STAMINA_MAX

var _since_dodge: float = 999.0
var _par_clock: float = 0.0
var _dot_clock: float = 0.0


func _init(c: Creature) -> void:
	creature = c
	status = c.status
	status_timer = INF


func effective(stat: StringName) -> int:
	var v := float(creature.stat(stat)) * Damage.stage_mult(int(stages.get(stat, 0)))
	if stat == &"spe" and status == &"par":
		v *= StatusEffects.PAR_SPEED
	return int(v)


func change_stage(stat: StringName, by: int) -> void:
	stages[stat] = clampi(int(stages.get(stat, 0)) + by, -6, 6)


func is_fainted() -> bool:
	return creature.hp <= 0


func burned() -> bool:
	return status == &"brn"


func can_act() -> bool:
	return not is_fainted() and status != &"slp" and status != &"frz" and stunned <= 0.0


## Returns false if the target already has a status (no overwrite).
func apply_status(id: StringName, rng: RandomNumberGenerator) -> bool:
	if status != &"" or is_fainted():
		return false
	status = id
	creature.status = id
	status_timer = StatusEffects.duration_for(id, rng)
	_par_clock = 0.0
	_dot_clock = 0.0
	return true


func clear_status() -> void:
	status = &""
	creature.status = &""
	status_timer = INF


func dodge() -> bool:
	if stamina < DODGE_COST or not can_act():
		return false
	stamina -= DODGE_COST
	invuln = DODGE_IFRAMES
	_since_dodge = 0.0
	return true


## Applies damage unless invulnerable. Returns true when the hit landed.
func take_hit(dmg: int, move_type: StringName) -> bool:
	if invuln > 0.0:
		return false
	creature.hp = maxi(0, creature.hp - dmg)
	if status == &"slp":
		clear_status()
	elif status == &"frz" and move_type == &"fire":
		clear_status()
	return true


func tick(delta: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	invuln = maxf(0.0, invuln - delta)
	stunned = maxf(0.0, stunned - delta)
	_since_dodge += delta
	if _since_dodge >= REGEN_DELAY:
		stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
	if status == &"" or is_fainted():
		return events
	if status_timer != INF:
		status_timer -= delta
		if status_timer <= 0.0:
			var ended := status
			clear_status()
			events.append({"type": "status_end", "status": ended})
			return events
	if status == &"par":
		_par_clock += delta
		while _par_clock >= StatusEffects.PAR_WINDOW:
			_par_clock -= StatusEffects.PAR_WINDOW
			if rng.randf() < StatusEffects.PAR_STUN_CHANCE:
				stunned = StatusEffects.PAR_STUN
				events.append({"type": "stun"})
	if status == &"psn" or status == &"brn":
		_dot_clock += delta
		while _dot_clock >= StatusEffects.DOT_INTERVAL - 0.0001:
			_dot_clock -= StatusEffects.DOT_INTERVAL
			var amount := StatusEffects.dot_damage(creature.max_hp())
			creature.hp = maxi(0, creature.hp - amount)
			events.append({"type": "dot", "amount": amount, "status": status})
	return events


func end_fight() -> void:
	for k in stages:
		stages[k] = 0
	stunned = 0.0
	invuln = 0.0
	stamina = STAMINA_MAX
	creature.status = status
