extends GutTest

var mgr: NPCManager
var made: Array = []


func _factory(npc: Dictionary) -> Node3D:
	var n := Node3D.new()
	n.name = String(npc.id)
	made.append(n)
	return n


func before_each() -> void:
	made.clear()
	mgr = NPCManager.new()
	add_child_autofree(mgr)
	var npcs := {}
	var schedules := {&"work": {"id": "work", "blocks": [{"from": 0, "to": 24, "at": "spot_a", "activity": "work"}]},
		&"far_work": {"id": "far_work", "blocks": [{"from": 0, "to": 24, "at": "spot_far", "activity": "work"}]}}
	for i in 10:
		npcs[StringName("npc_%d" % i)] = {"id": "npc_%d" % i, "home": "door_a", "schedule": "work", "role": "resident"}
	npcs[&"outsider"] = {"id": "outsider", "home": "door_a", "schedule": "far_work", "role": "resident"}
	var anchors := {&"spot_a": {"pos": Vector3(10, 0, 10), "chunk": Vector2i(0, 0)},
		&"spot_far": {"pos": Vector3(300, 0, 10), "chunk": Vector2i(4, 0)},
		&"door_a": {"pos": Vector3(5, 0, 5), "chunk": Vector2i(0, 0)}}
	mgr.setup(npcs, schedules, anchors, _factory)


func _weather(_area: Vector2i) -> StringName:
	return &"clear"


func test_manager_instances_only_in_loaded_chunks() -> void:
	mgr.cap = 60
	mgr.update(Vector3(10, 0, 10), 12.0, _weather, [Vector2i(0, 0)] as Array[Vector2i])
	assert_eq(mgr.actor_count(), 10, "outsider's anchor chunk is not loaded")
	assert_false(mgr.has_actor(&"outsider"))


func test_manager_respects_cap() -> void:
	mgr.cap = 4
	mgr.update(Vector3(10, 0, 10), 12.0, _weather, [Vector2i(0, 0)] as Array[Vector2i])
	assert_eq(mgr.actor_count(), 4)


func test_far_npcs_freed() -> void:
	mgr.cap = 60
	mgr.update(Vector3(10, 0, 10), 12.0, _weather, [Vector2i(0, 0), Vector2i(4, 0)] as Array[Vector2i])
	assert_eq(mgr.actor_count(), 10, "outsider is 290 m away: not simulated")
	mgr.update(Vector3(290, 0, 10), 12.0, _weather, [Vector2i(0, 0), Vector2i(4, 0)] as Array[Vector2i])
	assert_true(mgr.has_actor(&"outsider"))
	assert_eq(mgr.actor_count(), 1, "the 10 at spot_a are now 280 m away")


func test_actor_placed_at_anchor_on_spawn() -> void:
	mgr.update(Vector3(10, 0, 10), 12.0, _weather, [Vector2i(0, 0)] as Array[Vector2i])
	assert_eq((made[0] as Node3D).global_position, Vector3(10, 0, 10))


func test_indoor_npcs_have_no_actor() -> void:
	mgr.update(Vector3(10, 0, 10), 12.0, func(_c: Vector2i) -> StringName: return &"thunderstorm", [Vector2i(0, 0)] as Array[Vector2i])
	assert_eq(mgr.actor_count(), 0)


func test_think_rate_by_distance() -> void:
	assert_eq(NPCManager.think_interval(10.0), 0.0)
	assert_eq(NPCManager.think_interval(50.0), 0.25)
