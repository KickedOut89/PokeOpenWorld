extends GutTest

var s: GameState


func before_each() -> void:
	s = GameState.new()


func after_each() -> void:
	s.free()


func _door(unlock: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": "d", "interior": "i", "unlock": unlock, "locked_text": "Locked tight."}
	d.merge(extra, true)
	return d


func test_always_open() -> void:
	assert_true(DoorUnlock.evaluate(_door({"type": "always"}), s, 12).open)


func test_flag_gate() -> void:
	var d := _door({"type": "flag", "flag": "side_quest_done"})
	var r := DoorUnlock.evaluate(d, s, 12)
	assert_false(r.open)
	assert_eq(r.text, "Locked tight.")
	s.set_flag(&"side_quest_done")
	assert_true(DoorUnlock.evaluate(d, s, 12).open)


func test_item_gate() -> void:
	var d := _door({"type": "item", "item": "storehouse_key"})
	assert_false(DoorUnlock.evaluate(d, s, 12).open)
	s.items[&"storehouse_key"] = 1
	assert_true(DoorUnlock.evaluate(d, s, 12).open)


func test_reward_pokedex_count() -> void:
	var d := _door({"type": "reward", "reward": {"kind": "pokedex_caught", "count": 10}})
	for i in 9:
		s.pokedex_caught[StringName("mon%d" % i)] = true
	assert_false(DoorUnlock.evaluate(d, s, 12).open)
	s.pokedex_caught[&"mon9"] = true
	assert_true(DoorUnlock.evaluate(d, s, 12).open)


func test_reward_badges_and_friendship() -> void:
	assert_false(DoorUnlock.evaluate(_door({"type": "reward", "reward": {"kind": "badges", "count": 1}}), s, 12).open)
	s.badges = 1
	assert_true(DoorUnlock.evaluate(_door({"type": "reward", "reward": {"kind": "badges", "count": 1}}), s, 12).open)
	var f := _door({"type": "reward", "reward": {"kind": "friendship:berry_farmer", "count": 3}})
	s.friendship[&"berry_farmer"] = 2
	assert_false(DoorUnlock.evaluate(f, s, 12).open)
	s.friendship[&"berry_farmer"] = 3
	assert_true(DoorUnlock.evaluate(f, s, 12).open)


func test_time_hours_wrap_midnight() -> void:
	var d := _door({"type": "time"}, {"hours": [18, 2]})
	assert_true(DoorUnlock.evaluate(d, s, 1).open)
	assert_true(DoorUnlock.evaluate(d, s, 18).open)
	assert_false(DoorUnlock.evaluate(d, s, 3).open)
	assert_false(DoorUnlock.evaluate(d, s, 12).open)


func test_hours_combine_with_other_types() -> void:
	var d := _door({"type": "always"}, {"hours": [8, 21]})
	assert_true(DoorUnlock.evaluate(d, s, 9).open)
	var closed := DoorUnlock.evaluate(d, s, 22)
	assert_false(closed.open)
	assert_string_contains(closed.text, "closed")


func test_pending_always_closed_with_text() -> void:
	var r := DoorUnlock.evaluate(_door({"type": "pending"}), s, 12)
	assert_false(r.open)
	assert_eq(r.text, "Locked tight.")


func test_default_locked_text() -> void:
	var r := DoorUnlock.evaluate({"id": "d", "unlock": {"type": "pending"}}, s, 12)
	assert_eq(r.text, "It's locked.")


func test_missing_interior_record_treated_as_pending() -> void:
	var r := DoorUnlock.evaluate(_door({"type": "always"}), s, 12, false)
	assert_false(r.open)
