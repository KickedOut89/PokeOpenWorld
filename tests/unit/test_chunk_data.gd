extends GutTest

var _chunks: Dictionary


func before_all() -> void:
	var blockouts := ChunkBaker.read_blockouts("res://tests/fixtures/blockout", &"test")
	var placements := ChunkBaker.read_placements("res://tests/fixtures/placements")
	_chunks = ChunkBaker.bake(&"kanto", blockouts, placements)


func test_bake_splits_into_16x16_cells() -> void:
	assert_eq(_chunks.size(), 2)
	var c0: Dictionary = _chunks[Vector2i(0, 0)]
	assert_eq(c0.cells.size(), 16)
	assert_eq(String(c0.cells[0]).length(), 16)
	assert_eq(c0.id, "kanto_0_0")
	assert_eq(c0.area, "test_area")


func test_placement_assigned_to_owning_chunk() -> void:
	var c1: Dictionary = _chunks[Vector2i(1, 0)]
	assert_eq(c1.props.size(), 1)
	assert_almost_eq(float(c1.props[0].pos[0]), 6.0, 0.001)
	assert_eq(_chunks[Vector2i(0, 0)].props.size(), 0)
	assert_eq(_chunks[Vector2i(0, 0)].doors.size(), 1)
	assert_eq(c1.npc_anchors.size(), 1)


func test_tall_grass_lookup() -> void:
	var d := ChunkData.from_record(_chunks[Vector2i(0, 0)])
	assert_true(d.is_tall_grass(Vector2(3 * 4 + 1, 8 * 4 + 1)))
	assert_false(d.is_tall_grass(Vector2(1, 1)))


func test_height_at_returns_cell_level() -> void:
	var d := ChunkData.from_record(_chunks[Vector2i(0, 0)])
	assert_eq(d.height_at(Vector2(2, 2)), 1.0)
	assert_eq(d.height_at(Vector2(2, 30)), 0.0)


func test_cell_out_of_range_is_void() -> void:
	var d := ChunkData.from_record(_chunks[Vector2i(0, 0)])
	assert_eq(d.cell(-1, 0), " ")
	assert_eq(d.cell(0, 99), " ")
