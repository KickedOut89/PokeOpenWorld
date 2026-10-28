extends GutTest


func _run(attempt: Dictionary) -> Array:
	var s := CaptureSequence.new(attempt)
	var events := []
	for i in 400:
		for e in s.tick(0.01):
			events.append(e)
		if s.done:
			break
	return events


func test_sequence_shake_count_matches_attempt() -> void:
	for shakes in 4:
		var caught := shakes == 3
		var ev := _run({"caught": caught, "shakes": shakes, "critical": false})
		assert_eq(ev.count(&"shake"), shakes)
		assert_eq(ev[0], &"absorb")
		assert_eq(ev.back(), &"caught" if caught else &"breakout")


func test_shake_timing() -> void:
	var s := CaptureSequence.new({"caught": true, "shakes": 3, "critical": false})
	var t := 0.0
	while not s.done:
		s.tick(0.05)
		t += 0.05
	assert_almost_eq(t, CaptureSequence.ABSORB_S + 3 * CaptureSequence.SHAKE_S + CaptureSequence.RESULT_S, 0.06)


func test_critical_capture_single_shake() -> void:
	var ev := _run({"caught": true, "shakes": 1, "critical": true})
	assert_eq(ev.count(&"shake"), 1)
	assert_has(ev, &"critical")
	assert_eq(ev.back(), &"caught")
