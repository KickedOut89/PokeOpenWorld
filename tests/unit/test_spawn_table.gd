extends GutTest

var rng: RandomNumberGenerator
const REC := {"id": "t", "entries": [
	{"species": "pidgey", "min_lvl": 2, "max_lvl": 5, "weight": 50, "periods": "all"},
	{"species": "hoothoot", "min_lvl": 3, "max_lvl": 5, "weight": 25, "periods": ["night"]},
	{"species": "pikachu", "min_lvl": 4, "max_lvl": 6, "weight": 5, "periods": "all", "weather_mult": {"thunderstorm": 3.0}},
	{"species": "caterpie", "min_lvl": 3, "max_lvl": 4, "weight": 20, "periods": ["morning", "day"], "weather_mult": {"rain": 0.5}},
]}


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 99


func _share(t: SpawnTable, species: String, period: StringName, weather: StringName, n: int = 10000) -> float:
	var hits := 0
	for i in n:
		if t.pick(period, weather, rng).get("species", &"") == StringName(species):
			hits += 1
	return hits / float(n)


func test_pick_filters_by_period() -> void:
	var t := SpawnTable.new(REC)
	assert_eq(_share(t, "hoothoot", &"day", &"clear", 2000), 0.0)
	assert_gt(_share(t, "hoothoot", &"night", &"clear", 2000), 0.2)


func test_level_in_range() -> void:
	var t := SpawnTable.new(REC)
	for i in 500:
		var p := t.pick(&"day", &"clear", rng)
		if p.species == &"pidgey":
			assert_between(int(p.level), 2, 5)


func test_weather_multiplier_applied() -> void:
	var t := SpawnTable.new(REC)
	var clear := _share(t, "pikachu", &"night", &"clear")
	var storm := _share(t, "pikachu", &"night", &"thunderstorm")
	# night: pidgey 50 + hoothoot 25 + pikachu 5 = 80 -> 6.25%; storm: 15/90 = 16.7%
	assert_almost_eq(clear, 5.0 / 80.0, 0.01)
	assert_almost_eq(storm, 15.0 / 90.0, 0.015)


func test_empty_table_for_period() -> void:
	var t := SpawnTable.new({"id": "x", "entries": [{"species": "hoothoot", "min_lvl": 1, "max_lvl": 2, "weight": 1, "periods": ["night"]}]})
	assert_eq(t.pick(&"day", &"clear", rng), {})


func test_nocturnal_species_only_at_night() -> void:
	var t := SpawnTable.new({"id": "x", "entries": [{"species": "oddish", "min_lvl": 1, "max_lvl": 2, "weight": 1, "periods": "all"}]}, {&"oddish": true})
	assert_eq(t.pick(&"day", &"clear", rng), {})
	assert_eq(t.pick(&"night", &"clear", rng).species, &"oddish")
