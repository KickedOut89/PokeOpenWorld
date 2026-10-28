class_name ChimneySmoke
extends GPUParticles3D
## Soft smoke from a house chimney.


func _init() -> void:
	amount = 16
	lifetime = 5.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.3, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0.15, 0.1, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.85, 0.85, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	draw_pass_1 = q
	add_to_group(&"ambient")
