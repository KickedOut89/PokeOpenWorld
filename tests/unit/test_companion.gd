extends GutTest


func test_companion_excluded_from_spawner() -> void:
	var owner_npc := Node3D.new()
	add_child_autofree(owner_npc)
	var c := Companion.make(&"meowth", owner_npc)
	owner_npc.add_child(c)
	assert_true(c.is_in_group(&"ambient"))
	assert_false(c.is_in_group(&"wild"))
	assert_false(c is CollisionObject3D)
	assert_eq(c.find_children("*", "CollisionObject3D", true, false).size(), 0)


func test_companion_follows_within_range() -> void:
	var owner_npc := Node3D.new()
	add_child_autofree(owner_npc)
	var c := Companion.make(&"meowth", owner_npc)
	owner_npc.add_child(c)
	owner_npc.global_position = Vector3(20, 0, 0)
	for i in 120:
		c.step(1.0 / 30.0)
	var d := Vector2(c.global_position.x, c.global_position.z).distance_to(Vector2(20, 0))
	assert_between(d, 1.0, 2.6)


func test_companion_share_check() -> void:
	assert_true(Companion.share_ok(3, 10))
	assert_false(Companion.share_ok(2, 10))
	assert_true(Companion.share_ok(0, 0))
