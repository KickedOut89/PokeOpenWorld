extends GutTest
## Talking opens the box with a context line; a branch choice sets its flag.

func test_talk_and_branch_sets_flag() -> void:
	var world: KantoWorld = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(1)
	var rec := {"id": "tester", "name": "Tester", "dialogue": "t"}
	Data.db.table(&"dialogue")[&"t"] = {"id": "t", "talk": [{"text": "Pick one.", "branch": "q"}],
		"branches": {"q": {"text": "Which?", "choices": [{"text": "Yes", "set_flag": "said_yes"}, {"text": "No"}]}}}
	world.talk_to(rec)
	assert_true(world.dialogue.is_open())
	assert_eq(world.dialogue.current_text(), "Which?")
	assert_false(world.player.input_enabled)
	world.dialogue.choose(0)
	assert_true(State.has_flag(&"said_yes"))
	assert_false(world.dialogue.is_open())
	assert_true(world.player.input_enabled)
	Data.db.table(&"dialogue").erase(&"t")
	State.flags.erase(&"said_yes")
