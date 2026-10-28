extends GutTest

var db: DataDB
var rng := RandomNumberGenerator.new()


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func test_poison_types_cannot_be_poisoned() -> void:
	var c := Combatant.new(Creature.create(&"bulbasaur", 10, rng, db))
	assert_false(c.apply_status(&"psn", rng))
	assert_eq(c.status, &"")


func test_fire_types_cannot_be_burned() -> void:
	var c := Combatant.new(Creature.create(&"charmander", 10, rng, db))
	assert_false(c.apply_status(&"brn", rng))
	assert_true(c.apply_status(&"par", rng), "fire can still be paralysed")


func test_evs_awarded_and_capped() -> void:
	var p := Party.new()
	var me := Creature.create(&"squirtle", 10, rng, db)
	p.members.append(me)
	var foe := Creature.create(&"pidgey", 5, rng, db)  # Pidgey yields 1 Speed EV
	var m := FightModel.new(&"wild", Vector3.ZERO, p, [Combatant.new(foe)] as Array[Combatant])
	Progression.award(m, [foe], false)
	assert_eq(int(me.evs["spe"]), 1)
	me.evs["spe"] = 255
	Progression.award(m, [foe], false)
	assert_eq(int(me.evs["spe"]), 255, "per-stat cap")
	me.evs = {"hp": 255, "atk": 255, "def": 0, "spa": 0, "spd": 0, "spe": 0}
	Progression.award(m, [foe], false)
	assert_eq(int(me.evs["spe"]), 0, "510 total cap")


func test_spawn_director_does_not_restart_timer_for_fighting_wild() -> void:
	var d := SpawnDirector.new(rng)
	var table := SpawnTable.new({"id": "t", "entries": [{"species": "pidgey", "min_lvl": 2, "max_lvl": 5, "weight": 1, "periods": "all"}]})
	var zone := {"id": &"z", "table": table, "rect": Rect2(-50, -50, 100, 100), "y": 0.0}
	var active: Array[Dictionary] = [{"id": 1, "pos": Vector3(200, 0, 0), "zone_id": &"z", "in_fight": true}]
	for i in 20:
		var r := d.tick(Vector3.ZERO, active, [zone], &"day", &"clear", func(_p: Vector3) -> bool: return false, 100.0 + i)
		assert_eq(r.despawn.size(), 0)
	assert_eq(d.timers_to_dict().get("z", []).size(), 0)
