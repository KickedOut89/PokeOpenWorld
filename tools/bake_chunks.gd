extends SceneTree
## Bakes data/regions/<region>/{blockout,placements} into data/chunks/<region>_<cx>_<cy>.json.
## Usage: godot --headless --path . -s tools/bake_chunks.gd [-- region]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var region := StringName(args[0] if args.size() > 0 else "kanto")
	var base := "res://data/regions/%s" % region
	var blockouts := ChunkBaker.read_blockouts(base.path_join("blockout"), region)
	var chunks := ChunkBaker.bake(region, blockouts, ChunkBaker.read_placements(base.path_join("placements")))
	var out_dir := "res://data/chunks"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	for f in DirAccess.get_files_at(out_dir):
		if f.begins_with(String(region) + "_") and f.ends_with(".json"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(out_dir.path_join(f)))
	for coord in chunks:
		var rec: Dictionary = chunks[coord]
		var f := FileAccess.open(out_dir.path_join(rec.id + ".json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(rec, " ", false))
	print("bake_chunks: %s -> %d chunks from %d blockouts" % [region, chunks.size(), blockouts.size()])
	quit(0)
