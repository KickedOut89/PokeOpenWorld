extends GutTest

var db: DataDB
var rng: RandomNumberGenerator


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 21


func _c() -> Combatant:
	return Combatant.new(Creature.create(&"pikachu", 30, rng, db))


func test_paralysis_quarter_speed() -> void:
	var c := _c()
	var spe := c.effective(&"spe")
	c.apply_status(&"par", rng)
	assert_eq(c.effective(&"spe"), int(spe * 0.25))


func test_paralysis_stun_rate() -> void:
	var c := _c()
	c.apply_status(&"par", rng)
	var stuns := 0
	for i in 10000 * 10:  # 10,000 s at 0.1 s steps
		var was := c.stunned > 0.0
		c.tick(0.1, rng)
		if c.stunned > 0.0 and not was:
			stuns += 1
	assert_almost_eq(stuns / 5000.0, 0.25, 0.03, "share of 2 s windows that stun")


func test_sleep_duration_bounds() -> void:
	for i in 50:
		var c := _c()
		c.apply_status(&"slp", rng)
		var t := 0.0
		while c.status == &"slp" and t < 10.0:
			c.tick(0.05, rng)
			t += 0.05
		assert_between(t, 2.95, 6.06)


func test_damage_wakes() -> void:
	var c := _c()
	c.apply_status(&"slp", rng)
	assert_false(c.can_act())
	c.take_hit(1, &"normal")
	assert_eq(c.status, &"")
	assert_true(c.can_act())


func test_poison_tick_eighth() -> void:
	var c := _c()
	c.apply_status(&"psn", rng)
	var hp := c.creature.hp
	var events := c.tick(4.0, rng)
	assert_eq(c.creature.hp, hp - floori(c.creature.max_hp() / 8.0))
	assert_eq(events[0].type, "dot")


func test_burn_flag_for_physical() -> void:
	var c := _c()
	c.apply_status(&"brn", rng)
	assert_true(c.burned())


func test_freeze_bounds_and_fire_thaws() -> void:
	var c := _c()
	c.apply_status(&"frz", rng)
	assert_false(c.can_act())
	c.take_hit(1, &"fire")
	assert_eq(c.status, &"")
	var d := _c()
	d.apply_status(&"frz", rng)
	d.tick(5.01, rng)
	assert_eq(d.status, &"", "thaws within 5 s")


func test_second_status_does_not_overwrite() -> void:
	var c := _c()
	c.apply_status(&"psn", rng)
	assert_false(c.apply_status(&"par", rng))
	assert_eq(c.status, &"psn")
