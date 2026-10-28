extends GutTest
## Walk a stub player across chunk boundaries; the 3x3 around it must always be loaded
## and the streamer must never stall a frame for more than 100 ms.

func test_streaming_walk() -> void:
	var streamer := WorldStreamer.new()
	add_child_autofree(streamer)
	streamer.setup_from_db(Data.db, 1996)
	var target := Node3D.new()
	add_child_autofree(target)
	# Pallet (2,13) -> north to Route 1 (2,10), zig-zagging between x=2 and x=3.
	var path: Array[Vector3] = [Vector3(150, 0, 880), Vector3(200, 0, 840), Vector3(150, 0, 780),
		Vector3(210, 0, 720), Vector3(140, 0, 660), Vector3(200, 0, 650)]
	streamer.target = target
	target.global_position = path[0]
	streamer.update_now()
	var crossings := 0
	var last := StreamingPlanner.chunk_of(target.global_position)
	var worst := 0
	for frame in 600:
		var seg := clampi(frame / 100, 0, path.size() - 2)
		var t := (frame % 100) / 100.0
		target.global_position = path[seg].lerp(path[seg + 1], t)
		await wait_physics_frames(1)
		worst = maxi(worst, streamer.last_update_usec)
		var c := StreamingPlanner.chunk_of(target.global_position)
		if c != last:
			crossings += 1
			last = c
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var want := c + Vector2i(dx, dy)
				if streamer.has_record(want):
					assert_true(streamer.is_loaded(want), "frame %d: %s loaded" % [frame, want])
	assert_gte(crossings, 6)
	assert_lt(worst, 100_000, "worst streamer frame %d usec" % worst)
