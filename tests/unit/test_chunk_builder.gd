extends GutTest

var _record: Dictionary
var _lib: MeshLibrary


func before_all() -> void:
	var blockouts := ChunkBaker.read_blockouts("res://tests/fixtures/blockout", &"test")
	var chunks := ChunkBaker.bake(&"kanto", blockouts, ChunkBaker.read_placements("res://tests/fixtures/placements"))
	_record = chunks[Vector2i(0, 0)]
	_lib = MeshLibraryBuilder.build(DataDB.load_dir("res://data").table(&"tileset"))


func _grid(root: Node3D) -> GridMap:
	return root.get_node("Ground") as GridMap


func test_build_is_deterministic() -> void:
	var a := ChunkBuilder.new(_lib, 42).build(ChunkData.from_record(_record))
	var b := ChunkBuilder.new(_lib, 42).build(ChunkData.from_record(_record))
	var ca := _grid(a).get_used_cells()
	var cb := _grid(b).get_used_cells()
	assert_eq(ca.size(), cb.size())
	assert_eq(ca.size(), 64 * 64)
	var same := true
	for c in ca:
		if _grid(a).get_cell_item(c) != _grid(b).get_cell_item(c):
			same = false
	assert_true(same)
	a.free()
	b.free()


func test_chunk_root_positioned_at_origin() -> void:
	var rec := _record.duplicate(true)
	rec.coord = [1, 2]
	var n := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(rec))
	assert_eq(n.position, Vector3(64, 0, 128))
	n.free()


func test_ledge_blocks_northward_only() -> void:
	var n := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(_record))
	var ledges := n.find_children("Ledge*", "StaticBody3D", true, false)
	assert_eq(ledges.size(), 4, "one per ledge cell")
	var first := ledges[0] as StaticBody3D
	var shape := first.get_child(0) as CollisionShape3D
	# ledge cell (2,5) spans z 20..24; wall sits on its north edge (z=20)
	assert_almost_eq(first.position.z + shape.position.z, 20.0, 0.31)
	assert_true(first.is_in_group(&"ledge"))
	n.free()


func test_doors_and_zones_become_areas() -> void:
	var n := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(_record))
	var door := n.find_child("Door_test_door", true, false) as Area3D
	assert_not_null(door)
	assert_eq(door.get_meta(&"door_id"), &"test_door")
	assert_not_null(n.find_child("Zone_test_grass", true, false))
	n.free()


func test_trees_are_solid() -> void:
	var n := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(_record))
	assert_eq(n.find_children("Tree*", "StaticBody3D", true, false).size(), 16, "row 0 has 16 tree cells")
	n.free()


func _blank_record() -> Dictionary:
	var cells: Array = []
	var heights: Array = []
	for i in 16:
		cells.append(".".repeat(16))
		heights.append("0".repeat(16))
	return {"id": "t", "region": "kanto", "coord": [0, 0], "area": "t", "cells": cells, "heights": heights}


func test_stairs_ramp_rises_north() -> void:
	var rec := _blank_record()
	rec.cells[5] = "....S..........."
	rec.heights[4] = "1".repeat(16)
	var n := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(rec))
	var ramp := n.find_child("Stairs_4_5", true, false) as StaticBody3D
	assert_not_null(ramp)
	assert_gt(ramp.rotation.x, 0.0, "north (-z) end raised")
	assert_almost_eq(ramp.rotation.x, atan(1.0 / 4.0), 0.001)
	assert_eq(n.get_node("Ground").get_cell_item(Vector3i(17, 0, 21)), GridMap.INVALID_CELL_ITEM, "no flat tile under the ramp")
	n.free()


func test_tall_grass_is_ground_level_with_tufts() -> void:
	var n := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(_record))
	var grass := n.find_child("TallGrass", true, false) as MultiMeshInstance3D
	assert_not_null(grass, "tall grass cells get a tuft MultiMesh")
	assert_gt(grass.multimesh.instance_count, 100, "fixture has 12 tall-grass cells")
	var items: PackedInt32Array = _lib.get_meta(&"char_items")["\""]
	var mesh := _lib.get_item_mesh(items[0]) as BoxMesh
	assert_eq(mesh.size.y, 1.0, "the grass tile itself is flat, not a raised slab")
	var root2 := ChunkBuilder.new(_lib, 1).build(ChunkData.from_record(_record))
	var again := root2.find_child("TallGrass", true, false) as MultiMeshInstance3D
	assert_eq(grass.multimesh.get_instance_transform(7), again.multimesh.get_instance_transform(7), "deterministic placement")
	n.free()
	root2.free()
