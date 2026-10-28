class_name PropFactory
extends RefCounted
## Builds placeholder nodes for authored props (buildings, lamps, signs...).
## Lamps join group "lamp" and carry an OmniLight3D toggled by lamps_changed.

const BUILDING_COLORS := {
	"house_small": Color("e8dcc4"), "house_large": Color("ddd2bb"), "lab": Color("f2f2f2"),
	"center": Color("f0c8c8"), "mart": Color("c8d8f0"), "gym": Color("c9b98f"),
	"shop": Color("efe0b0"), "apartment": Color("d4ccc4"), "barn": Color("b5543c"),
	"greenhouse": Color("cfe8d8"), "gatehouse": Color("d8d0b8"),
}
const ROOF_COLORS := {
	"center": Color("d04040"), "mart": Color("3a6ad0"), "lab": Color("7a8a9a"),
}


static func make(prop: Dictionary) -> Node3D:
	var kind: String = prop.get("kind", "generic")
	var node: Node3D
	match kind:
		"building":
			node = _building(prop)
		"lamp":
			node = _lamp()
		"tree":
			node = tree(Vector3.ZERO, 1.0)
		_:
			node = _box(Vector3(float(prop.get("footprint", [1, 1])[0]), float(prop.get("height", 1.2)), float(prop.get("footprint", [1, 1])[1])), Color(prop.get("color", "#b08a5a")), prop.get("solid", true))
	node.name = "Prop_%s" % prop.get("id", "unnamed")
	var p: Array = prop.get("pos", [0, 0, 0])
	node.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	node.rotation_degrees.y = float(prop.get("rot", 0))
	node.set_meta(&"prop", prop)
	return node


static func tree(pos: Vector3, scale: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.25 * scale
	tm.bottom_radius = 0.35 * scale
	tm.height = 2.0 * scale
	tm.material = _mat(Color("6b4a2b"))
	trunk.mesh = tm
	trunk.position.y = 1.0 * scale
	body.add_child(trunk)
	var canopy := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 1.6 * scale
	cm.height = 3.0 * scale
	cm.material = _mat(Color("2f6b2f"))
	canopy.mesh = cm
	canopy.position.y = 3.0 * scale
	body.add_child(canopy)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.9 * scale
	shape.height = 3.0
	col.shape = shape
	col.position.y = 1.5
	body.add_child(col)
	return body


static func _building(prop: Dictionary) -> Node3D:
	var fp: Array = prop.get("footprint", [8, 6])
	var size := Vector3(float(fp[0]), float(prop.get("height", 4.0)), float(fp[1]))
	var template: String = prop.get("template", "house_small")
	var body := _box(size, BUILDING_COLORS.get(template, Color("e0d8c8")), true)
	var roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(size.x + 0.6, 1.8, size.z + 0.6)
	rm.material = _mat(ROOF_COLORS.get(template, Color("8c3b2e")))
	roof.mesh = rm
	roof.position.y = size.y + 0.9
	body.add_child(roof)
	# Windows on the south (front) face; they glow when lamps are on.
	var win := MeshInstance3D.new()
	var wm := QuadMesh.new()
	wm.size = Vector2(1.0, 0.8)
	var wmat := _mat(Color("2a3a4a"))
	wmat.emission_enabled = true
	wmat.emission = Color("ffcf7a")
	wmat.emission_energy_multiplier = 0.0
	wm.material = wmat
	win.mesh = wm
	win.position = Vector3(size.x * 0.25, size.y * 0.6, size.z * 0.5 + 0.01)
	win.add_to_group(&"window")
	body.add_child(win)
	return body


static func _lamp() -> Node3D:
	var root := _box(Vector3(0.2, 3.2, 0.2), Color("3a3a3a"), true)
	var light := OmniLight3D.new()
	light.position.y = 3.3
	light.omni_range = 9.0
	light.light_color = Color("ffd59a")
	light.light_energy = 0.0
	light.shadow_enabled = false
	root.add_child(light)
	root.add_to_group(&"lamp")
	return root


static func _box(size: Vector3, color: Color, solid: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	m.material = _mat(color)
	mi.mesh = m
	mi.position.y = size.y * 0.5
	root.add_child(mi)
	if solid:
		var col := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		col.shape = s
		col.position.y = size.y * 0.5
		root.add_child(col)
	return root


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m
