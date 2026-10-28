class_name Party
extends RefCounted
## The player's (or a trainer's) team of up to six Pokémon.

const MAX := 6

var members: Array[Creature] = []


## Adds to the party, or to the first free PC slot when the party is full.
func add(c: Creature, pc: PCStorage) -> StringName:
	if members.size() < MAX:
		members.append(c)
		return &"party"
	if pc != null and pc.deposit(c) != Vector2i(-1, -1):
		return &"box"
	return &"none"


func swap(i: int, j: int) -> void:
	if i >= 0 and j >= 0 and i < members.size() and j < members.size():
		var t := members[i]
		members[i] = members[j]
		members[j] = t


func to_array() -> Array:
	return members.map(func(c: Creature) -> Dictionary: return c.to_dict())


static func from_array(a: Array, db: DataDB) -> Party:
	var p := Party.new()
	for d in a:
		p.members.append(Creature.from_dict(d, db))
	return p


func lead() -> Creature:
	var i := first_able()
	return members[i] if i >= 0 else null


func first_able() -> int:
	for i in members.size():
		if not members[i].is_fainted():
			return i
	return -1


func all_fainted() -> bool:
	return first_able() < 0


func highest_level() -> int:
	var h := 1
	for m in members:
		h = maxi(h, m.level)
	return h


func heal_all() -> void:
	for m in members:
		m.hp = m.max_hp()
		m.status = &""
