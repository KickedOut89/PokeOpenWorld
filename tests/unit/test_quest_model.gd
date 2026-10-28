extends GutTest

const REC := {"id": "q", "requires_flag": "got_starter", "stages": [
	{"id": "get", "objective_text": "Get the thing", "complete_when": {"flag": "got_thing"}, "on_complete": {"give_items": {"thing": 1}}},
	{"id": "give", "objective_text": "Give it to Oak", "complete_when": {"talk_to": "professor_oak", "item": "thing"},
	 "on_complete": {"take_items": {"thing": 1}, "give_items": {"poke_ball": 5}, "set_flags": ["got_pokedex"], "money": 100}},
]}

var s: GameState


func before_each() -> void:
	s = GameState.new()


func after_each() -> void:
	s.free()


func test_inactive_until_required_flag() -> void:
	var q := QuestModel.new(REC)
	s.flags[&"got_thing"] = true
	assert_eq(q.check(s, {}).size(), 0)
	assert_false(q.is_active(s))


func test_stage_advances_on_flag() -> void:
	var q := QuestModel.new(REC)
	s.flags[&"got_starter"] = true
	assert_eq(q.current_stage().id, "get")
	s.flags[&"got_thing"] = true
	var applied := q.check(s, {})
	assert_eq(applied.size(), 1)
	assert_eq(q.current_stage().id, "give")


func test_on_complete_gives_and_takes_items() -> void:
	var q := QuestModel.new(REC)
	s.flags[&"got_starter"] = true
	s.flags[&"got_thing"] = true
	q.check(s, {})
	assert_eq(int(s.items[&"thing"]), 1)
	assert_eq(q.check(s, {"type": "talk", "npc": &"lab_aide_ken"}).size(), 0, "wrong NPC")
	q.check(s, {"type": "talk", "npc": &"professor_oak"})
	assert_false(s.items.has(&"thing"))
	assert_eq(int(s.items[&"poke_ball"]), 5)
	assert_true(s.has_flag(&"got_pokedex"))
	assert_eq(s.money, 3100)
	assert_true(q.is_complete())


func test_talk_needs_item() -> void:
	var q := QuestModel.new(REC)
	s.flags[&"got_starter"] = true
	s.flags[&"got_thing"] = true
	q.check(s, {})
	s.items.erase(&"thing")
	assert_eq(q.check(s, {"type": "talk", "npc": &"professor_oak"}).size(), 0)


func test_caught_count() -> void:
	var q := QuestModel.new({"id": "c", "stages": [{"id": "a", "complete_when": {"caught_count": 2}}]})
	s.pokedex_caught[&"pidgey"] = true
	assert_eq(q.check(s, {}).size(), 0)
	s.pokedex_caught[&"rattata"] = true
	assert_eq(q.check(s, {}).size(), 1)


func test_quest_round_trip() -> void:
	var q := QuestModel.new(REC)
	s.flags[&"got_starter"] = true
	s.flags[&"got_thing"] = true
	q.check(s, {})
	var q2 := QuestModel.new(REC)
	q2.from_dict(JSON.parse_string(JSON.stringify(q.to_dict())))
	assert_eq(q2.current_stage().id, "give")


func test_rival_counterpick() -> void:
	assert_eq(Rival.counter(&"bulbasaur"), &"charmander")
	assert_eq(Rival.counter(&"charmander"), &"squirtle")
	assert_eq(Rival.counter(&"squirtle"), &"bulbasaur")
