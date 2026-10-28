class_name PCStorage
extends RefCounted
## Bill's PC: 8 boxes of 30.

const BOXES := 8
const SLOTS := 30

var boxes: Array = []  # Array[Array[Creature]]


func _init() -> void:
	for i in BOXES:
		boxes.append([])


func deposit(c: Creature) -> Vector2i:
	for b in BOXES:
		if boxes[b].size() < SLOTS:
			boxes[b].append(c)
			return Vector2i(b, boxes[b].size() - 1)
	return Vector2i(-1, -1)


func count() -> int:
	var n := 0
	for b in boxes:
		n += b.size()
	return n


func to_array() -> Array:
	return boxes.map(func(b: Array) -> Array: return b.map(func(c: Creature) -> Dictionary: return c.to_dict()))


static func from_array(a: Array, db: DataDB) -> PCStorage:
	var pc := PCStorage.new()
	for i in mini(a.size(), BOXES):
		for d in a[i]:
			pc.boxes[i].append(Creature.from_dict(d, db))
	return pc
