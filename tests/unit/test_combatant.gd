extends GutTest

var db: DataDB
var rng: RandomNumberGenerator


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 11


func _c(sp: StringName = &"pikachu", lvl: int = 20) -> Combatant:
	return Combatant.new(Creature.create(sp, lvl, rng, db))


func test_stage_changes_effective_stat() -> void:
	var c := _c()
	var base := c.effective(&"atk")
	c.change_stage(&"atk", 2)
	assert_eq(c.effective(&"atk"), int(base * 2.0))
	c.change_stage(&"atk", 9)
	assert_eq(c.stages[&"atk"], 6, "clamped")


func test_stages_reset_on_end() -> void:
	var c := _c()
	c.change_stage(&"def", -2)
	c.apply_status(&"brn", rng)
	c.end_fight()
	assert_eq(c.stages[&"def"], 0)
	assert_eq(c.creature.status, &"brn", "status persists on the creature")


func test_dodge_stamina_and_iframes() -> void:
	var c := _c()
	assert_true(c.dodge())
	assert_eq(c.stamina, 75.0)
	assert_almost_eq(c.invuln, 0.25, 0.001)
	assert_false(c.take_hit(10, &"normal"), "invulnerable")
	for i in 3:
		c.dodge()
	assert_eq(c.stamina, 0.0)
	assert_false(c.dodge(), "no stamina")
	c.tick(0.5, rng)
	assert_eq(c.stamina, 0.0, "no regen within 1 s of dodging")
	c.tick(1.0, rng)
	assert_gt(c.stamina, 0.0)


func test_take_hit_reduces_hp_and_faints() -> void:
	var c := _c()
	c.take_hit(5, &"normal")
	assert_eq(c.creature.hp, c.creature.max_hp() - 5)
	c.take_hit(9999, &"normal")
	assert_eq(c.creature.hp, 0)
	assert_true(c.is_fainted())
	assert_false(c.can_act())
