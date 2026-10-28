class_name QuestRunner
extends Node
## Owns every quest's progress, re-checks quests when flags change or the player talks
## to someone, and persists progress through the save.

signal quest_advanced(quest_id: StringName, payload: Dictionary)

var quests: Dictionary = {}  # id -> QuestModel


func _ready() -> void:
	for id in Data.db.table(&"quests"):
		quests[id] = QuestModel.new(Data.db.table(&"quests")[id])
	EventBus.flag_set.connect(func(_f: StringName) -> void: check_all({}))
	EventBus.pokemon_caught.connect(func(_s: StringName) -> void: check_all({}))


func get_quest(id: StringName) -> QuestModel:
	return quests.get(id, null)


func check_all(event: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in quests:
		for p in (quests[id] as QuestModel).check(State, event):
			out.append(p)
			quest_advanced.emit(id, p)
	return out


## Returns true when the conversation completed a quest stage.
func on_talk(npc_id: StringName) -> bool:
	return not check_all({"type": "talk", "npc": npc_id}).is_empty()


func objectives() -> Array[String]:
	var out: Array[String] = []
	for id in quests:
		var q: QuestModel = quests[id]
		if q.is_active(State):
			out.append(q.objective())
	return out


func to_dict() -> Dictionary:
	var d := {}
	for id in quests:
		d[String(id)] = (quests[id] as QuestModel).to_dict()
	return d


func from_dict(d: Dictionary) -> void:
	for id in d:
		if quests.has(StringName(id)):
			(quests[StringName(id)] as QuestModel).from_dict(d[id])
