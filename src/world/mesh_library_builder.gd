class_name MeshLibraryBuilder
extends RefCounted
## Builds the placeholder MeshLibrary for terrain tiles from data/tileset.json.
## Each tile char gets `variants` items with slightly shifted colors.
## Mapping is stored as lib meta "char_items": {char: PackedInt32Array}.

const WATER_DROP := 0.35


static func build(tileset: Dictionary) -> MeshLibrary:
	var lib := MeshLibrary.new()
	var mapping := {}
	var next_id := 0
	var chars := tileset.keys()
	chars.sort()
	for ch in chars:
		var def: Dictionary = tileset[ch]
		var ids := PackedInt32Array()
		var base := Color(def.get("color", "#ff00ff"))
		for v in int(def.get("variants", 1)):
			var mesh := BoxMesh.new()
			var height := 1.0
			if def.get("water", false):
				height = 1.0 - WATER_DROP
			mesh.size = Vector3(1, height, 1)
			var mat := StandardMaterial3D.new()
			var shift := (v - 1) * 0.04
			mat.albedo_color = base.lightened(shift) if shift > 0 else base.darkened(-shift)
			mat.roughness = 0.2 if def.get("water", false) else 0.9
			if def.get("water", false):
				mat.metallic_specular = 0.8
			mesh.material = mat
			lib.create_item(next_id)
			lib.set_item_name(next_id, "%s_%d" % [def.get("tile", ch), v])
			lib.set_item_mesh(next_id, mesh)
			# Keep the top of every tile at the cell top: offset the box down by its shortfall.
			lib.set_item_mesh_transform(next_id, Transform3D(Basis(), Vector3(0, (height - 1.0) * 0.5, 0)))
			ids.append(next_id)
			next_id += 1
		mapping[ch] = ids
	lib.set_meta(&"char_items", mapping)
	lib.set_meta(&"tileset", tileset)
	return lib
