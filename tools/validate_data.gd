extends SceneTree
## CI gate: loads res://data, prints every problem, exits 1 if any.


func _init() -> void:
	var errors := DataValidator.validate(DataDB.load_dir("res://data"))
	for e in errors:
		printerr("DATA ERROR: " + e)
	print("validate_data: %d error(s)" % errors.size())
	quit(1 if errors.size() > 0 else 0)
