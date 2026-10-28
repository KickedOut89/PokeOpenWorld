class_name Party
extends RefCounted
## The player's (or a trainer's) team of up to six Pokémon.

const MAX := 6

var members: Array[Creature] = []


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
