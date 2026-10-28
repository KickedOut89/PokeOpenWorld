class_name ClothSway
extends Node3D
## Laundry line: a few cloth quads that sway in the wind (stronger in storms).

var _cloths: Array[MeshInstance3D] = []
var _t: float = 0.0


func _ready() -> void:
	add_to_group(&"ambient")
	var colors := [Color("f0f0f0"), Color("d05050"), Color("5080d0"), Color("e0c050")]
	for i in 4:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.8, 1.0)
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[i]
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		q.material = m
		mi.mesh = q
		mi.position = Vector3(-1.5 + i, 1.6, 0)
		add_child(mi)
		_cloths.append(mi)


func _process(delta: float) -> void:
	_t += delta
	var gust := 1.0
	var area := Weather.models.keys()
	if not area.is_empty() and Weather.models[area[0]].current == &"thunderstorm":
		gust = 2.5
	for i in _cloths.size():
		_cloths[i].rotation.x = sin(_t * 2.2 + i) * 0.25 * gust
