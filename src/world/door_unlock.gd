class_name DoorUnlock
extends RefCounted
## Decides whether a door opens. Types: always, flag, item, reward, time, pending.
## Any door may also carry "hours": [open, close] (wrapping midnight).

const DEFAULT_LOCKED := "It's locked."
const CLOSED_TEXT := "It's closed. Open %02d:00–%02d:00."


static func evaluate(door: Dictionary, state: GameState, hour: int, has_interior: bool = true) -> Dictionary:
	var locked: String = door.get("locked_text", DEFAULT_LOCKED)
	var unlock: Dictionary = door.get("unlock", {"type": "pending"})
	var t: String = unlock.get("type", "pending")
	if t == "pending" or not has_interior:
		return {"open": false, "text": locked}
	var ok := true
	match t:
		"always", "time":
			ok = true
		"flag":
			ok = state.has_flag(StringName(unlock.get("flag", "")))
		"item":
			ok = int(state.items.get(StringName(unlock.get("item", "")), 0)) > 0
		"reward":
			ok = _reward_met(unlock.get("reward", {}), state)
		_:
			ok = false
	if not ok:
		return {"open": false, "text": locked}
	if door.has("hours"):
		var h: Array = door.hours
		if not in_hours(hour, int(h[0]), int(h[1])):
			return {"open": false, "text": CLOSED_TEXT % [int(h[0]), int(h[1])]}
	return {"open": true, "text": ""}


static func in_hours(hour: int, open: int, close: int) -> bool:
	if open <= close:
		return hour >= open and hour < close
	return hour >= open or hour < close


static func _reward_met(reward: Dictionary, state: GameState) -> bool:
	var kind: String = reward.get("kind", "")
	var need := int(reward.get("count", 1))
	if kind == "pokedex_caught":
		return state.pokedex_caught.size() >= need
	if kind == "badges":
		return state.badges >= need
	if kind.begins_with("friendship:"):
		return int(state.friendship.get(StringName(kind.get_slice(":", 1)), 0)) >= need
	return false
