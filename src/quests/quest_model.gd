class_name QuestModel
extends RefCounted
## A linear quest: stages complete when their condition holds; each stage's on_complete
## payload (set_flags, give_items, take_items, money) is applied once.
## complete_when: {flag?, item?, talk_to?, caught_count?} — all given keys must hold.

var record: Dictionary
var id: StringName
var stage_index: int = 0


func _init(rec: Dictionary) -> void:
	record = rec
	id = StringName(rec.get("id", ""))


func stages() -> Array:
	return record.get("stages", [])


func is_active(state: GameState) -> bool:
	var req: String = record.get("requires_flag", "")
	return (req == "" or state.has_flag(StringName(req))) and not is_complete()


func is_complete() -> bool:
	return stage_index >= stages().size()


func current_stage() -> Dictionary:
	return {} if is_complete() else stages()[stage_index]


func objective() -> String:
	return current_stage().get("objective_text", "")


## event: {} for passive checks, or {type: "talk", npc} etc. Returns applied payloads.
func check(state: GameState, event: Dictionary) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	while is_active(state) and _met(current_stage().get("complete_when", {}), state, event):
		var payload: Dictionary = current_stage().get("on_complete", {})
		_apply(payload, state)
		applied.append(payload)
		stage_index += 1
		event = {}  # a single talk only completes one stage
	return applied


func _met(w: Dictionary, state: GameState, event: Dictionary) -> bool:
	if w.is_empty():
		return false
	if w.has("flag") and not state.has_flag(StringName(w.flag)):
		return false
	if w.has("item") and int(state.items.get(StringName(w.item), 0)) <= 0:
		return false
	if w.has("talk_to") and not (event.get("type", "") == "talk" and StringName(event.get("npc", "")) == StringName(w.talk_to)):
		return false
	if w.has("caught_count") and state.pokedex_caught.size() < int(w.caught_count):
		return false
	return true


static func _apply(p: Dictionary, state: GameState) -> void:
	var inv := Inventory.new(state.items)
	for item in p.get("take_items", {}):
		inv.remove(StringName(item), int(p.take_items[item]))
	for item in p.get("give_items", {}):
		inv.add(StringName(item), int(p.give_items[item]))
	for f in p.get("set_flags", []):
		state.set_flag(StringName(f))
	state.money += int(p.get("money", 0))


func to_dict() -> Dictionary:
	return {"stage": stage_index}


func from_dict(d: Dictionary) -> void:
	stage_index = int(d.get("stage", 0))
