class_name Inventory
extends RefCounted
## The Bag. Wraps (and mutates) the shared id -> count dictionary in GameState.items.

var items: Dictionary


func _init(backing: Dictionary) -> void:
	items = backing


func add(id: StringName, n: int = 1) -> void:
	items[id] = int(items.get(id, 0)) + n


func remove(id: StringName, n: int = 1) -> bool:
	if int(items.get(id, 0)) < n:
		return false
	items[id] = int(items[id]) - n
	if items[id] == 0:
		items.erase(id)
	return true


func count(id: StringName) -> int:
	return int(items.get(id, 0))
