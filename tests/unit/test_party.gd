extends GutTest

var db: DataDB
var rng := RandomNumberGenerator.new()


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func _mon(sp: StringName = &"pidgey") -> Creature:
	return Creature.create(sp, 5, rng, db)


func test_catch_with_full_party_goes_to_box() -> void:
	var p := Party.new()
	var pc := PCStorage.new()
	for i in 6:
		assert_eq(p.add(_mon(), pc), &"party")
	assert_eq(p.add(_mon(&"rattata"), pc), &"box")
	assert_eq(p.members.size(), 6)
	assert_eq(pc.boxes[0][0].species, &"rattata")


func test_swap() -> void:
	var p := Party.new()
	p.members.append(_mon(&"pidgey"))
	p.members.append(_mon(&"rattata"))
	p.swap(0, 1)
	assert_eq(p.members[0].species, &"rattata")


func test_heal_all_clears_status() -> void:
	var p := Party.new()
	var c := _mon()
	c.hp = 1
	c.status = &"psn"
	p.members.append(c)
	p.heal_all()
	assert_eq(c.hp, c.max_hp())
	assert_eq(c.status, &"")
