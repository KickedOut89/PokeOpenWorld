class_name GameState
extends Node
## Persistent story state: flags, items, Pokédex, badges, friendship, money.
## Autoloaded as `State` (an autoload may not share its class_name).

var flags: Dictionary = {}           # StringName -> true
var items: Dictionary = {}           # StringName -> int
var pokedex_caught: Dictionary = {}  # StringName -> true
var pokedex_seen: Dictionary = {}    # StringName -> true
var badges: int = 0
var friendship: Dictionary = {}      # npc id -> int
var money: int = 3000
var last_center: StringName = &"pallet_home"


func set_flag(f: StringName) -> void:
	if flags.has(f):
		return
	flags[f] = true
	if is_inside_tree():
		EventBus.flag_set.emit(f)


func has_flag(f: StringName) -> bool:
	return flags.has(f)


func to_dict() -> Dictionary:
	return {
		"flags": flags.keys(), "items": items, "pokedex_caught": pokedex_caught.keys(),
		"pokedex_seen": pokedex_seen.keys(), "badges": badges, "friendship": friendship,
		"money": money, "last_center": last_center,
	}


func from_dict(d: Dictionary) -> void:
	flags = {}
	for f in d.get("flags", []):
		flags[StringName(f)] = true
	items = {}
	for k in d.get("items", {}):
		items[StringName(k)] = int(d.items[k])
	pokedex_caught = {}
	for k in d.get("pokedex_caught", []):
		pokedex_caught[StringName(k)] = true
	pokedex_seen = {}
	for k in d.get("pokedex_seen", []):
		pokedex_seen[StringName(k)] = true
	badges = int(d.get("badges", 0))
	friendship = {}
	for k in d.get("friendship", {}):
		friendship[StringName(k)] = int(d.friendship[k])
	money = int(d.get("money", 3000))
	last_center = StringName(d.get("last_center", "pallet_home"))
