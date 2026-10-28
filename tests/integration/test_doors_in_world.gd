extends GutTest
## Walking north into the player's house door enters it; a pending door shows its text.

var world: KantoWorld


func before_each() -> void:
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.interiors.fade_seconds = 0.0
	await wait_physics_frames(2)


func _door_node(id: String) -> Area3D:
	return world.find_child("Door_%s" % id, true, false) as Area3D


func _walk_into(door: Area3D) -> void:
	world.player.global_position = door.global_position + Vector3(0, 0.2, 0.3)
	world.player.forced_input = Vector2(0, -1)


func test_open_door_enters_interior() -> void:
	_walk_into(_door_node("player_house_door"))
	await wait_physics_frames(3)
	assert_true(world.interiors.is_inside())
	assert_eq(world.interiors.current_id, &"player_house_int")
	world.player.forced_input = Vector2(0, 1)
	var exit := world.interiors.current_interior.get_node("Exit") as Area3D
	world.player.global_position = exit.global_position + Vector3(0, 0.2, -0.2)
	await wait_physics_frames(3)
	assert_false(world.interiors.is_inside(), "walking south through the exit leaves")


func test_pending_door_shows_locked_text() -> void:
	_walk_into(_door_node("pallet_house_1_door"))
	await wait_physics_frames(3)
	assert_false(world.interiors.is_inside())
	assert_eq(world.toast.current_text(), "No one's home.")
