extends GutTest

var mgr: InteriorManager
var player: Node3D
var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child_autofree(world)
	player = Node3D.new()
	world.add_child(player)
	mgr = InteriorManager.new()
	mgr.fade_seconds = 0.0
	world.add_child(mgr)
	mgr.setup(player, world, Data.db)


func test_enter_builds_interior_and_moves_player() -> void:
	player.global_position = Vector3(160, 0, 880)
	var door := {"id": "player_house_door", "interior": "player_house_int", "pos": [0, 0, 0]}
	await mgr.enter(door, Vector3(160, 0, 878))
	assert_true(mgr.is_inside())
	assert_not_null(mgr.current_interior)
	assert_gt(player.global_position.y, 500.0, "interiors live far above the overworld")


func test_exit_restores_outdoor_position() -> void:
	player.global_position = Vector3(160, 0, 880)
	var door := {"id": "player_house_door", "interior": "player_house_int", "pos": [0, 0, 0]}
	await mgr.enter(door, Vector3(160, 0, 878))
	await mgr.exit()
	assert_false(mgr.is_inside())
	assert_almost_eq(player.global_position.distance_to(Vector3(160, 0, 879.5)), 0.0, 0.01, "1.5 m south of the door")


func test_unknown_interior_does_not_enter() -> void:
	var ok := await mgr.enter({"id": "x", "interior": "no_such_int"}, Vector3.ZERO)
	assert_false(ok)
	assert_false(mgr.is_inside())
