extends GutTest

var chart: TypeChart


func before_all() -> void:
	chart = TypeChart.from_db(DataDB.load_dir("res://data"))


func test_gen5_has_no_fairy() -> void:
	assert_eq(chart.types().size(), 17)
	assert_false(chart.types().has(&"fairy"))


func test_steel_resists_ghost_and_dark() -> void:
	assert_eq(chart.mult(&"ghost", [&"steel"]), 0.5)
	assert_eq(chart.mult(&"dark", [&"steel"]), 0.5)


func test_dual_type_multiplies() -> void:
	assert_eq(chart.mult(&"electric", [&"water", &"flying"]), 4.0)
	assert_eq(chart.mult(&"fire", [&"bug", &"steel"]), 4.0)
	assert_eq(chart.mult(&"grass", [&"bug", &"poison"]), 0.25)


func test_ground_immune_to_electric() -> void:
	assert_eq(chart.mult(&"electric", [&"ground"]), 0.0)
	assert_eq(chart.mult(&"ground", [&"flying"]), 0.0)
	assert_eq(chart.mult(&"normal", [&"ghost"]), 0.0)
	assert_eq(chart.mult(&"ghost", [&"normal"]), 0.0)


func test_classic_matchups() -> void:
	assert_eq(chart.mult(&"water", [&"fire"]), 2.0)
	assert_eq(chart.mult(&"fire", [&"grass"]), 2.0)
	assert_eq(chart.mult(&"grass", [&"water"]), 2.0)
	assert_eq(chart.mult(&"bug", [&"poison"]), 0.5, "Gen 2+")
	assert_eq(chart.mult(&"poison", [&"bug"]), 1.0, "Gen 2+")
	assert_eq(chart.mult(&"ice", [&"fire"]), 0.5)
	assert_eq(chart.mult(&"psychic", [&"dark"]), 0.0)
	assert_eq(chart.mult(&"normal", [&"normal"]), 1.0)


func test_unknown_type_neutral() -> void:
	assert_eq(chart.mult(&"sound", [&"normal"]), 1.0)
