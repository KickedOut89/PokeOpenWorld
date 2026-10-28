class_name Mart
extends RefCounted
## Viridian Mart stock and purchases. Poké Balls appear once the player has the Pokédex.

const BASE_STOCK: Array[StringName] = [&"potion", &"antidote", &"parlyz_heal", &"awakening"]


static func stock(state: GameState) -> Array[StringName]:
	var s: Array[StringName] = BASE_STOCK.duplicate()
	if state.has_flag(&"got_pokedex"):
		s.push_front(&"poke_ball")
	return s


static func buy(state: GameState, item: StringName, n: int, db: DataDB) -> bool:
	if not stock(state).has(item):
		return false
	var cost := int(db.get_record(&"items", item).get("price", 0)) * n
	if cost <= 0 or state.money < cost:
		return false
	state.money -= cost
	Inventory.new(state.items).add(item, n)
	return true
