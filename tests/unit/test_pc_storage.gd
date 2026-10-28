extends GutTest

var db: DataDB
var rng := RandomNumberGenerator.new()


func before_all() -> void:
	db = DataDB.load_dir("res://data")


func test_deposit_fills_boxes_in_order() -> void:
	var pc := PCStorage.new()
	for i in 31:
		pc.deposit(Creature.create(&"pidgey", 3, rng, db))
	assert_eq(pc.boxes[0].size(), 30)
	assert_eq(pc.boxes[1].size(), 1)


func test_box_full_returns_minus_one() -> void:
	var pc := PCStorage.new()
	for b in PCStorage.BOXES:
		for s in PCStorage.SLOTS:
			pc.boxes[b].append(Creature.create(&"pidgey", 3, rng, db))
	assert_eq(pc.deposit(Creature.create(&"rattata", 3, rng, db)), Vector2i(-1, -1))


func test_round_trip() -> void:
	var pc := PCStorage.new()
	pc.deposit(Creature.create(&"oddish", 9, rng, db))
	var back := PCStorage.from_array(JSON.parse_string(JSON.stringify(pc.to_array())), db)
	assert_eq(back.boxes[0][0].species, &"oddish")
	assert_eq(back.boxes[0][0].level, 9)
