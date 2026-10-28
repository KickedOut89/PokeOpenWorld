extends GutTest


func _grid(x0: int, y0: int, x1: int, y1: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			out.append(Vector2i(x, y))
	return out


func test_chunk_of_negative_coords() -> void:
	assert_eq(StreamingPlanner.chunk_of(Vector3(-1, 0, -1)), Vector2i(-1, -1))
	assert_eq(StreamingPlanner.chunk_of(Vector3(63.9, 5, 64.0)), Vector2i(0, 1))


func test_plan_initial_loads_3x3_preloads_ring() -> void:
	var p := StreamingPlanner.new(_grid(-5, -5, 5, 5))
	var r := p.plan(Vector2i.ZERO, [] as Array[Vector2i], [] as Array[Vector2i])
	assert_eq(r.load.size(), 9)
	assert_eq(r.preload.size(), 16)
	assert_eq(r.unload.size(), 0)
	assert_has(r.load, Vector2i(-1, 1))
	assert_has(r.preload, Vector2i(2, -2))


func test_plan_skips_already_loaded() -> void:
	var p := StreamingPlanner.new(_grid(-5, -5, 5, 5))
	var r := p.plan(Vector2i.ZERO, _grid(-1, -1, 1, 1), [] as Array[Vector2i])
	assert_eq(r.load.size(), 0)


func test_plan_unloads_beyond_5x5() -> void:
	var p := StreamingPlanner.new(_grid(-5, -5, 5, 5))
	var loaded: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 0), Vector2i(-2, 2)]
	var r := p.plan(Vector2i.ZERO, loaded, [] as Array[Vector2i])
	assert_eq(r.unload, [Vector2i(3, 0)] as Array[Vector2i])


func test_pinned_chunks_never_unloaded() -> void:
	var p := StreamingPlanner.new(_grid(-5, -5, 5, 5))
	var loaded: Array[Vector2i] = [Vector2i(4, 4)]
	var r := p.plan(Vector2i.ZERO, loaded, [Vector2i(4, 4)] as Array[Vector2i])
	assert_eq(r.unload.size(), 0)


func test_missing_chunk_records_ignored() -> void:
	var p := StreamingPlanner.new([Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i])
	var r := p.plan(Vector2i.ZERO, [] as Array[Vector2i], [] as Array[Vector2i])
	assert_eq(r.load.size(), 2)
	assert_eq(r.preload.size(), 0)
