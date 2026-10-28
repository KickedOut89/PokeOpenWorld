class_name InteriorBuilder
extends RefCounted
## Builds an interior room from a template (size, colors, default furniture) plus
## the interior record's own furnishing. The south wall is low so the camera sees in.
## Children: "Exit" Area3D (group interior_exit) and "Spawn" Marker3D.

const WALL_H := 3.2
const WALL_T := 0.3


static func build(rec: Dictionary, template: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Interior_%s" % rec.get("id", "unknown")
	var size: Array = template.get("size", [10, 8])
	var w := float(size[0])
	var d := float(size[1])
	var body := StaticBody3D.new()
	body.name = "Room"
	root.add_child(body)
	_box(body, Vector3(0, -0.25, 0), Vector3(w, 0.5, d), Color(template.get("floor", "#b08a5a")))
	var wall := Color(template.get("wall", "#e8dcc4"))
	_box(body, Vector3(0, WALL_H * 0.5, -d * 0.5), Vector3(w, WALL_H, WALL_T), wall)
	_box(body, Vector3(-w * 0.5, WALL_H * 0.5, 0), Vector3(WALL_T, WALL_H, d), wall)
	_box(body, Vector3(w * 0.5, WALL_H * 0.5, 0), Vector3(WALL_T, WALL_H, d), wall)
	var gap := 1.6
	var side := (w - gap) * 0.5
	_box(body, Vector3(-(gap + side) * 0.5, 0.4, d * 0.5), Vector3(side, 0.8, WALL_T), wall)
	_box(body, Vector3((gap + side) * 0.5, 0.4, d * 0.5), Vector3(side, 0.8, WALL_T), wall)
	for f in template.get("furniture", []) + rec.get("furnishing", []):
		var fs: Array = f.get("size", [1, 1, 1])
		var fp: Array = f.get("pos", [0, 0, 0])
		_box(body, Vector3(float(fp[0]), float(fp[1]) + float(fs[1]) * 0.5, float(fp[2])),
			Vector3(float(fs[0]), float(fs[1]), float(fs[2])), Color(f.get("color", "#8a6a45")))
	var light := OmniLight3D.new()
	light.position = Vector3(0, WALL_H - 0.4, 0)
	light.omni_range = maxf(w, d)
	light.light_color = Color(template.get("light", "#ffe2b0"))
	light.light_energy = 1.4
	light.shadow_enabled = true
	root.add_child(light)
	var exit := Area3D.new()
	exit.name = "Exit"
	exit.position = Vector3(0, 0, d * 0.5 + 0.2)
	exit.add_to_group(&"interior_exit")
	var col := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(gap, 2.0, 0.8)
	col.shape = s
	col.position.y = 1.0
	exit.add_child(col)
	root.add_child(exit)
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	var sp: Array = rec.get("spawn", [0, 0, d * 0.5 - 1.2])
	spawn.position = Vector3(float(sp[0]), float(sp[1]), float(sp[2]))
	root.add_child(spawn)
	return root


static func _box(body: StaticBody3D, center: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	m.material = mat
	mi.mesh = m
	mi.position = center
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	col.shape = s
	col.position = center
	body.add_child(col)
