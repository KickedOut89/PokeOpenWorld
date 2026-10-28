extends Node
## Autoload `Data`: the game's loaded content database.

var db: DataDB


func _ready() -> void:
	db = DataDB.load_dir("res://data")
	for e in db.errors:
		push_warning("Data: " + e)
