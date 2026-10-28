class_name FightModel
extends RefCounted
## Rules of one overworld fight: the ring, escape, switching, and win/lose/caught.
## The controlled Pokémon's position decides escape (wild fights only).

const RING_RADIUS := 12.0
const ESCAPE_SECONDS := 3.0
const SWITCH_SECONDS := 1.5
const SWITCH_COOLDOWN := 5.0
const BLACKOUT_BASE := [8, 16, 24, 36, 48, 64, 80, 100, 120]

var kind: StringName
var center: Vector3
var party: Party
var foes: Array[Combatant]
var active_index: int = 0
var result: StringName = &"ongoing"
var escape_timer: float = 0.0
var switch_cooldown: float = 0.0
var participants: Dictionary = {}  # party index -> true (for EXP split)

var _combatants: Dictionary = {}   # party index -> Combatant
var _switch_to: int = -1
var _switch_t: float = 0.0
var _caught: bool = false


func _init(fight_kind: StringName, ring_center: Vector3, p: Party, opponents: Array[Combatant]) -> void:
	kind = fight_kind
	center = ring_center
	party = p
	foes = opponents
	active_index = maxi(0, p.first_able())
	participants[active_index] = true


static func blackout_money_loss(badges: int, highest_level: int) -> int:
	return BLACKOUT_BASE[clampi(badges, 0, BLACKOUT_BASE.size() - 1)] * highest_level


func combatant(i: int) -> Combatant:
	if not _combatants.has(i):
		_combatants[i] = Combatant.new(party.members[i])
	return _combatants[i]


func active() -> Combatant:
	return combatant(active_index)


func current_foe() -> Combatant:
	for f in foes:
		if not f.is_fainted():
			return f
	return null


func is_switching() -> bool:
	return _switch_to >= 0


func is_outside_ring(pos: Vector3) -> bool:
	return Vector2(pos.x - center.x, pos.z - center.z).length() > RING_RADIUS


func request_switch(index: int) -> bool:
	if is_switching() or switch_cooldown > 0.0 or index == active_index:
		return false
	if index < 0 or index >= party.members.size() or party.members[index].is_fainted():
		return false
	_switch_to = index
	_switch_t = 0.0
	return true


func mark_caught() -> void:
	_caught = true


func update(delta: float, controlled_pos: Vector3) -> StringName:
	if result != &"ongoing":
		return result
	switch_cooldown = maxf(0.0, switch_cooldown - delta)
	if is_switching():
		_switch_t += delta
		if _switch_t >= SWITCH_SECONDS:
			active_index = _switch_to
			participants[active_index] = true
			_switch_to = -1
			switch_cooldown = SWITCH_COOLDOWN
	if _caught:
		result = &"caught"
	elif party.all_fainted():
		result = &"lost"
	elif current_foe() == null:
		result = &"won"
	elif party.members[active_index].is_fainted() and not is_switching():
		_switch_to = party.first_able()
		_switch_t = 0.0
	elif kind == &"wild":
		escape_timer = escape_timer + delta if is_outside_ring(controlled_pos) else 0.0
		if escape_timer >= ESCAPE_SECONDS:
			result = &"escaped"
	return result


func pinned_chunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var lo := StreamingMath.chunk_of(center - Vector3(RING_RADIUS, 0, RING_RADIUS))
	var hi := StreamingMath.chunk_of(center + Vector3(RING_RADIUS, 0, RING_RADIUS))
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			out.append(Vector2i(x, y))
	return out


func end() -> void:
	for i in _combatants:
		(_combatants[i] as Combatant).end_fight()
	for f in foes:
		f.end_fight()
