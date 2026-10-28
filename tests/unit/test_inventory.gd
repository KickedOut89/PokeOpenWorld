extends GutTest


func test_add_count_remove() -> void:
	var inv := Inventory.new({})
	inv.add(&"potion", 3)
	assert_eq(inv.count(&"potion"), 3)
	assert_true(inv.remove(&"potion", 2))
	assert_eq(inv.count(&"potion"), 1)


func test_inventory_remove_insufficient_false() -> void:
	var inv := Inventory.new({&"potion": 1})
	assert_false(inv.remove(&"potion", 2))
	assert_eq(inv.count(&"potion"), 1)
	assert_false(inv.remove(&"poke_ball", 1))


func test_backs_shared_dictionary() -> void:
	var items := {}
	Inventory.new(items).add(&"poke_ball", 5)
	assert_eq(items[&"poke_ball"], 5)
