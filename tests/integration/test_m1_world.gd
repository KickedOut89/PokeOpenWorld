extends GutTest
## Milestone 1: Pallet Town and Route 1 content is present and builds.

var _db: DataDB
var _chunks: Array[ChunkData] = []


func before_all() -> void:
	_db = DataDB.load_dir("res://data")
	for id in _db.table(&"chunks"):
		var d := ChunkData.from_record(_db.table(&"chunks")[id])
		if d.area in [&"pallet_town", &"route_1"]:
			_chunks.append(d)


func _props(area: StringName, kind: String) -> Array:
	var out := []
	for c in _chunks:
		for p in c.props:
			if p.get("area", "") == String(area) and p.get("kind", "") == kind:
				out.append(p)
	return out


func test_pallet_and_route1_chunks_exist() -> void:
	assert_gte(_chunks.size(), 8, "about 2x2 Pallet + 2x3 Route 1")


func test_pallet_building_count() -> void:
	var n := _props(&"pallet_town", "building").size()
	assert_between(n, 10, 12)


func test_pallet_landmarks_exist() -> void:
	var ids := []
	for p in _props(&"pallet_town", "building"):
		ids.append(p.id)
	for want in ["player_house", "rival_house", "oaks_lab"]:
		assert_has(ids, want)


func test_every_pallet_building_has_a_door() -> void:
	var doors := {}
	for c in _chunks:
		for d in c.doors:
			doors[d.get("building", "")] = true
	for p in _props(&"pallet_town", "building"):
		assert_true(doors.has(p.id), "door for %s" % p.id)


func test_route1_grass_zones_and_ledges() -> void:
	var zones := 0
	var ledges := 0
	for c in _chunks:
		for z in c.spawn_zones:
			if z.area == "route_1":
				zones += 1
		if c.area == &"route_1":
			for row in c.cells:
				ledges += row.count("^")
	assert_gte(zones, 2)
	assert_gte(ledges, 3)


func test_route1_has_rest_stop_and_cottage() -> void:
	var ids := []
	for p in _props(&"route_1", "building") + _props(&"route_1", "stall"):
		ids.append(p.id)
	assert_has(ids, "route1_vendor_stall")
	assert_has(ids, "berry_farmer_cottage")


func test_player_spawn_anchor_exists() -> void:
	var found := false
	for c in _chunks:
		for a in c.npc_anchors:
			if a.id == "player_spawn":
				found = true
	assert_true(found)


func test_world_scene_builds_all_chunks() -> void:
	var world: Node3D = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(2)
	var chunk_nodes := world.find_children("Chunk_*", "Node3D", true, false)
	assert_gte(chunk_nodes.size(), 8)
	assert_not_null(world.find_child("Player", true, false))
