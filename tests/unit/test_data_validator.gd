extends GutTest

const GOOD := "res://tests/fixtures/data_good"
const BAD := "res://tests/fixtures/data_bad"


func _has_error(errors: PackedStringArray, parts: Array) -> bool:
	for e in errors:
		var all := true
		for p in parts:
			if not e.contains(p):
				all = false
		if all:
			return true
	return false


func test_validator_passes_good_fixture() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(GOOD))
	assert_eq(errors.size(), 0, "\n".join(errors))


func test_validator_flags_unknown_move_in_learnset() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["spearow", "peck"]), "\n".join(errors))


func test_validator_flags_door_to_missing_interior() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["lost_door", "nowhere_int"]), "\n".join(errors))


func test_validator_flags_missing_required_field() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["nameless", "name"]), "\n".join(errors))


func test_validator_flags_chunk_door_to_missing_interior() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["chunk_door", "ghost_int"]), "\n".join(errors))
	assert_false(_has_error(errors, ["ok_pending"]), "pending doors may point at unbuilt interiors")


func test_validator_flags_interior_with_unknown_template() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["no_template_int", "castle"]), "\n".join(errors))


func test_validator_flags_unknown_spawn_species_and_zone_table() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["bad_table", "missingno"]), "\n".join(errors))
	assert_true(_has_error(errors, ["zone_x", "nope"]), "\n".join(errors))


func test_validator_flags_npc_references() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["mute", "missing_dialogue"]), "\n".join(errors))
	assert_true(_has_error(errors, ["mute", "none_sched"]), "\n".join(errors))


func test_validator_requires_three_context_lines() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["terse", "3"]), "\n".join(errors))


func test_validator_requires_companion_share_per_town() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["area 't'", "companion"]), "\n".join(errors))


func test_validator_flags_bad_trainer() -> void:
	var errors := DataValidator.validate(DataDB.load_dir(BAD))
	assert_true(_has_error(errors, ["bad_trainer", "missingno"]), "\n".join(errors))
	assert_true(_has_error(errors, ["bad_trainer", "ghost_npc"]), "\n".join(errors))
