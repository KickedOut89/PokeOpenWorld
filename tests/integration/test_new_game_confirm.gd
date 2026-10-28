extends GutTest
## Choosing New Game over an existing save asks before it can be overwritten.

const DIR := "user://test_newgame_saves"


func before_each() -> void:
	Saves.dir = DIR
	DirAccess.make_dir_recursive_absolute(DIR)
	var w := {"player": {"pos": [150.0, 0.2, 870.0], "area": "pallet_town"}}
	State.money = 4321
	Saves.save(SaveService.AUTOSAVE_SLOT, Saves.snapshot(w))
	State.money = 3000


func after_each() -> void:
	Saves.dir = "user://saves"
	State.from_dict({})


func test_new_game_asks_and_no_keeps_save() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_physics_frames(3)
	var world := main.get_child(0) as KantoWorld
	assert_eq(world.prompts.question(), "Welcome back!")
	world.prompts.choose(1)
	assert_string_contains(world.prompts.question(), "overwritten")
	world.prompts.choose(1)  # No, continue my save
	await wait_physics_frames(3)
	assert_eq(State.money, 4321, "save was loaded, not discarded")
