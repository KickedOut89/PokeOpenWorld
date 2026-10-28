extends GutTest

const GOOD := "res://tests/fixtures/data_good"
const BAD := "res://tests/fixtures/data_bad"


func test_loads_records_by_kind() -> void:
	var db := DataDB.load_dir(GOOD)
	assert_eq(db.table(&"moves").size(), 2)
	assert_eq(db.get_record(&"species", &"pidgey").name, "Pidgey")
	assert_eq(db.errors.size(), 0)


func test_malformed_json_file_logged_and_skipped() -> void:
	var db := DataDB.load_dir(BAD)
	assert_eq(db.errors.size(), 1)
	assert_string_contains(db.errors[0], "broken.json")
	assert_true(db.table(&"species").has(&"spearow"), "other records still load")
	assert_false(db.table(&"species").has(&"rattata"))


func test_missing_record_returns_empty() -> void:
	var db := DataDB.load_dir(GOOD)
	assert_eq(db.get_record(&"species", &"mew"), {})
	assert_eq(db.table(&"quests"), {})
