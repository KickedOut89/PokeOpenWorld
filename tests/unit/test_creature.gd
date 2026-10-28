extends GutTest

var db: DataDB
var rng: RandomNumberGenerator


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 7


func test_create_picks_last_four_moves() -> void:
	var c := Creature.create(&"pidgey", 13, rng, db)
	assert_eq(c.moves, [&"tackle", &"sand_attack", &"gust", &"quick_attack"] as Array[StringName])
	var d := Creature.create(&"pidgey", 17, rng, db)
	assert_eq(d.moves, [&"sand_attack", &"gust", &"quick_attack", &"whirlwind"] as Array[StringName])


func test_create_rolls_ivs_and_nature() -> void:
	var c := Creature.create(&"rattata", 5, rng, db)
	for s in ["hp", "atk", "def", "spa", "spd", "spe"]:
		assert_between(int(c.ivs[s]), 0, 31)
	assert_true(db.table(&"natures").has(c.nature))
	assert_eq(c.hp, c.max_hp())
	assert_eq(c.exp, Growth.exp_for_level(&"medium_fast", 5))


func test_add_exp_emits_level_learn_evolve_in_order() -> void:
	var c := Creature.create(&"charmander", 15, rng, db)
	var need := Growth.exp_for_level(&"medium_slow", 16) - c.exp
	var events := c.add_exp(need)
	assert_eq(c.level, 16)
	var types := []
	for e in events:
		types.append(e.type)
	assert_eq(types, ["level", "learn", "evolve"])
	assert_eq(events[1].move, &"dragon_rage")
	assert_eq(events[2].to, &"charmeleon")


func test_add_exp_multiple_levels() -> void:
	var c := Creature.create(&"rattata", 2, rng, db)
	var events := c.add_exp(Growth.exp_for_level(&"medium_fast", 5) - c.exp)
	var levels := []
	for e in events:
		if e.type == "level":
			levels.append(e.level)
	assert_eq(levels, [3, 4, 5])


func test_level_100_cap() -> void:
	var c := Creature.create(&"rattata", 100, rng, db)
	assert_eq(c.add_exp(100000).size(), 0)
	assert_eq(c.level, 100)


func test_creature_round_trip() -> void:
	var c := Creature.create(&"pikachu", 12, rng, db)
	c.nickname = "Sparky"
	c.shiny = true
	c.status = &"par"
	c.hp = 3
	var d := Creature.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), db)
	assert_eq(d.species, &"pikachu")
	assert_eq(d.level, 12)
	assert_eq(d.moves, c.moves)
	assert_eq(d.ivs, c.ivs)
	assert_eq(d.nature, c.nature)
	assert_eq(d.nickname, "Sparky")
	assert_true(d.shiny)
	assert_eq(d.status, &"par")
	assert_eq(d.hp, 3)
	assert_eq(d.stat(&"spe"), c.stat(&"spe"))


func test_evolve_changes_species_keeps_hp_ratio() -> void:
	var c := Creature.create(&"charmander", 16, rng, db)
	var before := c.max_hp()
	c.evolve_to(&"charmeleon")
	assert_eq(c.species, &"charmeleon")
	assert_gt(c.max_hp(), before)
