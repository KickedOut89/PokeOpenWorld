extends GutTest


func test_flags() -> void:
	var s := GameState.new()
	assert_false(s.has_flag(&"got_pokedex"))
	s.set_flag(&"got_pokedex")
	assert_true(s.has_flag(&"got_pokedex"))
	s.free()


func test_game_state_round_trip() -> void:
	var s := GameState.new()
	s.set_flag(&"a")
	s.items[&"poke_ball"] = 5
	s.pokedex_caught[&"pidgey"] = true
	s.badges = 1
	s.friendship[&"berry_farmer"] = 3
	s.money = 3000
	s.last_center = &"viridian_center"
	var d := s.to_dict()
	var t := GameState.new()
	t.from_dict(JSON.parse_string(JSON.stringify(d)))
	assert_true(t.has_flag(&"a"))
	assert_eq(t.items[&"poke_ball"], 5)
	assert_true(t.pokedex_caught.has(&"pidgey"))
	assert_eq(t.badges, 1)
	assert_eq(t.friendship[&"berry_farmer"], 3)
	assert_eq(t.money, 3000)
	assert_eq(t.last_center, &"viridian_center")
	s.free()
	t.free()
