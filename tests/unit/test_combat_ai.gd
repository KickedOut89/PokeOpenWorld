extends GutTest

var db: DataDB
var rng: RandomNumberGenerator
var ai: CombatAI


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 8
	ai = CombatAI.new(TypeChart.from_db(db), db, rng)


func _c(sp: StringName, moves: Array) -> Combatant:
	var cr := Creature.create(sp, 15, rng, db)
	var mv: Array[StringName] = []
	for m in moves:
		mv.append(StringName(m))
	cr.moves = mv
	return Combatant.new(cr)


func test_prefers_super_effective() -> void:
	var me := _c(&"pikachu", ["thunder_shock", "quick_attack"])
	var foe := _c(&"pidgey", ["tackle"])
	var d := ai.decide(me, Vector3.ZERO, foe, Vector3(0, 0, -5), [&"thunder_shock", &"quick_attack"] as Array[StringName], 1.0)
	assert_eq(d.action, &"move")
	assert_eq(d.move, &"thunder_shock")


func test_uses_status_when_foe_clean() -> void:
	var me := _c(&"caterpie", ["string_shot", "tackle"])
	var foe := _c(&"pidgey", ["tackle"])
	var oddish := _c(&"oddish", ["stun_spore", "absorb"])
	var d := ai.decide(oddish, Vector3.ZERO, foe, Vector3(0, 0, -3), [&"stun_spore", &"absorb"] as Array[StringName], 1.0)
	assert_eq(d.move, &"stun_spore")
	foe.apply_status(&"psn", rng)
	var d2 := ai.decide(oddish, Vector3.ZERO, foe, Vector3(0, 0, -3), [&"stun_spore", &"absorb"] as Array[StringName], 1.0)
	assert_eq(d2.move, &"absorb", "no point paralysing a poisoned foe")


func test_melee_approaches_when_out_of_range() -> void:
	var me := _c(&"rattata", ["tackle"])
	var foe := _c(&"pidgey", ["tackle"])
	var d := ai.decide(me, Vector3.ZERO, foe, Vector3(0, 0, -8), [&"tackle"] as Array[StringName], 1.0)
	assert_eq(d.action, &"approach")


func test_keeps_range_for_projectiles() -> void:
	var me := _c(&"charmander", ["ember"])
	var foe := _c(&"bulbasaur", ["tackle"])
	var close := ai.decide(me, Vector3.ZERO, foe, Vector3(0, 0, -1.5), [] as Array[StringName], 1.0)
	assert_true(close.action in [&"retreat", &"strafe"], "backs off while Ember recharges")
	var ok := ai.decide(me, Vector3.ZERO, foe, Vector3(0, 0, -7), [&"ember"] as Array[StringName], 1.0)
	assert_eq(ok.action, &"move")


func test_low_skill_still_legal_moves() -> void:
	var me := _c(&"pidgey", ["tackle", "sand_attack", "gust"])
	var foe := _c(&"rattata", ["tackle"])
	var ready: Array[StringName] = [&"tackle", &"gust"]
	for i in 200:
		var d := ai.decide(me, Vector3.ZERO, foe, Vector3(0, 0, -2), ready, 0.0)
		if d.action == &"move":
			assert_has(ready, d.move)


func test_nothing_ready_does_not_use_move() -> void:
	var me := _c(&"pidgey", ["tackle"])
	var foe := _c(&"rattata", ["tackle"])
	var d := ai.decide(me, Vector3.ZERO, foe, Vector3(0, 0, -2), [] as Array[StringName], 1.0)
	assert_ne(d.action, &"move")
