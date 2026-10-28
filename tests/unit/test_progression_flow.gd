extends GutTest

var db: DataDB
var rng := RandomNumberGenerator.new()


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func before_each() -> void:
	rng.seed = 5


func test_exp_split_between_participants() -> void:
	var foe := Creature.create(&"pidgey", 10, rng, db)
	var whole := Progression.exp_for_defeat(foe, 10, 1, false)
	var half := Progression.exp_for_defeat(foe, 10, 2, false)
	assert_eq(half, maxi(1, floori(whole / 2.0)))


func test_learn_auto_when_room() -> void:
	var c := Creature.create(&"caterpie", 5, rng, db)
	assert_lt(c.moves.size(), 4)
	assert_true(Progression.learn(c, &"bug_bite", -1))
	assert_has(c.moves, &"bug_bite")


func test_fifth_move_decline_keeps_four() -> void:
	var c := Creature.create(&"pidgey", 17, rng, db)
	var before := c.moves.duplicate()
	assert_eq(before.size(), 4)
	assert_true(Progression.needs_prompt(c, &"twister"))
	assert_false(Progression.learn(c, &"twister", -1))
	assert_eq(c.moves, before)


func test_fifth_move_replace() -> void:
	var c := Creature.create(&"pidgey", 17, rng, db)
	assert_true(Progression.learn(c, &"twister", 0))
	assert_eq(c.moves[0], &"twister")
	assert_eq(c.moves.size(), 4)


func test_evolution_cancel_retriggers_next_level() -> void:
	var c := Creature.create(&"charmander", 15, rng, db)
	var ev := c.add_exp(Growth.exp_for_level(&"medium_slow", 16) - c.exp)
	assert_true(ev.any(func(e: Dictionary) -> bool: return e.type == "evolve"))
	Progression.cancel_evolution(c)
	assert_eq(c.species, &"charmander")
	var ev2 := c.add_exp(Growth.exp_for_level(&"medium_slow", 17) - c.exp)
	assert_true(ev2.any(func(e: Dictionary) -> bool: return e.type == "evolve" and e.to == &"charmeleon"))


func test_center_heals_and_sets_last_center() -> void:
	var s := GameState.new()
	var c := Creature.create(&"pidgey", 5, rng, db)
	c.hp = 1
	c.status = &"par"
	s.party.members.append(c)
	PokemonCenter.heal(s, &"viridian_center")
	assert_eq(c.hp, c.max_hp())
	assert_eq(c.status, &"")
	assert_eq(s.last_center, &"viridian_center")
	s.free()


func test_mart_gates_balls_on_pokedex() -> void:
	var s := GameState.new()
	assert_false(Mart.stock(s).has(&"poke_ball"))
	assert_true(Mart.stock(s).has(&"potion"))
	s.set_flag(&"got_pokedex")
	assert_true(Mart.stock(s).has(&"poke_ball"))
	s.free()


func test_mart_buy_spends_money() -> void:
	var s := GameState.new()
	s.money = 500
	assert_true(Mart.buy(s, &"potion", 1, db))
	assert_eq(s.money, 200)
	assert_eq(int(s.items[&"potion"]), 1)
	assert_false(Mart.buy(s, &"potion", 1, db), "not enough money")
	s.free()
