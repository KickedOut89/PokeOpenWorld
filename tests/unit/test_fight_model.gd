extends GutTest

var db: DataDB
var rng: RandomNumberGenerator


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 2


func _party(n: int = 2) -> Party:
	var p := Party.new()
	for i in n:
		p.members.append(Creature.create([&"charmander", &"pidgey", &"rattata"][i % 3], 10, rng, db))
	return p


func _foes() -> Array[Combatant]:
	return [Combatant.new(Creature.create(&"caterpie", 3, rng, db))] as Array[Combatant]


func test_wild_escape_after_3s_outside() -> void:
	var f := FightModel.new(&"wild", Vector3.ZERO, _party(), _foes())
	assert_eq(f.update(1.0, Vector3(5, 0, 0)), &"ongoing")
	for i in 29:
		assert_eq(f.update(0.1, Vector3(13, 0, 0)), &"ongoing")
	assert_eq(f.update(0.11, Vector3(13, 0, 0)), &"escaped")


func test_reentering_resets_escape_timer() -> void:
	var f := FightModel.new(&"wild", Vector3.ZERO, _party(), _foes())
	f.update(2.5, Vector3(13, 0, 0))
	f.update(0.1, Vector3(5, 0, 0))
	assert_eq(f.update(2.5, Vector3(13, 0, 0)), &"ongoing")


func test_trainer_cannot_escape() -> void:
	var f := FightModel.new(&"trainer", Vector3.ZERO, _party(), _foes())
	assert_eq(f.update(10.0, Vector3(30, 0, 0)), &"ongoing")
	assert_true(f.is_outside_ring(Vector3(30, 0, 0)))


func test_switch_timing_and_cooldown() -> void:
	var f := FightModel.new(&"wild", Vector3.ZERO, _party(), _foes())
	assert_eq(f.active_index, 0)
	assert_true(f.request_switch(1))
	assert_true(f.is_switching())
	assert_false(f.active().can_act() and not f.is_switching())
	f.update(1.49, Vector3.ZERO)
	assert_eq(f.active_index, 0, "still swapping")
	f.update(0.02, Vector3.ZERO)
	assert_eq(f.active_index, 1)
	assert_false(f.request_switch(0), "5 s cooldown")
	f.update(5.0, Vector3.ZERO)
	assert_true(f.request_switch(0))


func test_cannot_switch_to_fainted_or_same() -> void:
	var p := _party()
	p.members[1].hp = 0
	var f := FightModel.new(&"wild", Vector3.ZERO, p, _foes())
	assert_false(f.request_switch(1))
	assert_false(f.request_switch(0))


func test_lost_when_all_fainted() -> void:
	var p := _party()
	var f := FightModel.new(&"wild", Vector3.ZERO, p, _foes())
	for m in p.members:
		m.hp = 0
	assert_eq(f.update(0.1, Vector3.ZERO), &"lost")


func test_fainted_lead_sends_next() -> void:
	var p := _party()
	var f := FightModel.new(&"wild", Vector3.ZERO, p, _foes())
	p.members[0].hp = 0
	f.update(0.1, Vector3.ZERO)
	assert_true(f.is_switching(), "next Pokémon is sent out")
	f.update(FightModel.SWITCH_SECONDS + 0.01, Vector3.ZERO)
	assert_eq(f.active_index, 1)


func test_won_when_foes_fainted() -> void:
	var foes := _foes()
	var f := FightModel.new(&"wild", Vector3.ZERO, _party(), foes)
	foes[0].creature.hp = 0
	assert_eq(f.update(0.1, Vector3.ZERO), &"won")


func test_caught_result() -> void:
	var f := FightModel.new(&"wild", Vector3.ZERO, _party(), _foes())
	f.mark_caught()
	assert_eq(f.update(0.1, Vector3.ZERO), &"caught")


func test_pinned_chunks_cover_ring_at_chunk_corner() -> void:
	var f := FightModel.new(&"wild", Vector3(64, 0, 64), _party(), _foes())
	var pins := f.pinned_chunks()
	for c in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		assert_has(pins, c)
	assert_eq(pins.size(), 4)


func test_blackout_loss() -> void:
	assert_eq(FightModel.blackout_money_loss(0, 10), 80)
	assert_eq(FightModel.blackout_money_loss(8, 50), 6000)
