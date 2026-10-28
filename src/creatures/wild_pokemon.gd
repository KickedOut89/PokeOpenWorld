class_name WildPokemon
extends CharacterBody3D
## A visible wild Pokémon roaming near its spawn point.
## Emits `engaged` when its charge reaches the player (or the player hits it),
## and `removed` when caught/defeated so the spawner can start a respawn timer.

signal engaged(wild: WildPokemon)
signal removed(wild: WildPokemon, reason: StringName)

const THINK_INTERVAL := 0.4
const CONTACT_RANGE := 1.6
const WANDER_RADIUS := 6.0

var creature: Creature
var zone_id: StringName
var home: Vector3
var spawn_id: int = -1
var attacked: bool = false
var in_fight: bool = false

var sprite: BillboardSprite
var _target: Variant = null
var _think: float = 0.0
var _pause: float = 0.0
var _rng := RandomNumberGenerator.new()


static func make(c: Creature, pos: Vector3, zone: StringName) -> WildPokemon:
	var w := WildPokemon.new()
	w.creature = c
	w.zone_id = zone
	w.home = pos
	w.position = pos
	w.name = "Wild_%s" % c.species
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.2
	shape.shape = cap
	shape.position.y = 0.6
	w.add_child(shape)
	w.collision_layer = 4
	w.collision_mask = 1
	w.sprite = BillboardSprite.new()
	w.sprite.name = "Sprite"
	w.add_child(w.sprite)
	return w


func _ready() -> void:
	add_to_group(&"wild")
	_rng.randomize()
	var assets := get_node_or_null(^"/root/Assets")
	if assets != null:
		var key := "species/%s%s" % [creature.species, "_shiny" if creature.shiny else ""]
		sprite.set_sheet(assets.texture(key))
	if creature.shiny:
		_add_sparkle()


func speed() -> float:
	return 2.0 + creature.stat(&"spe") / 40.0


func _physics_process(delta: float) -> void:
	if in_fight:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	_think -= delta
	if _think <= 0.0 and player != null:
		_think = THINK_INTERVAL
		var kind := StringName(creature.rec().get("temperament", "passive"))
		var d := Temperament.decide(kind, global_position, home, player.global_position, attacked)
		match d.action:
			&"wander":
				if _target == null and _pause <= 0.0:
					var off := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized() * _rng.randf_range(1.0, WANDER_RADIUS)
					_target = home + Vector3(off.x, 0, off.y)
			&"idle":
				_target = null
			_:
				_target = d.target
		if d.action == &"charge" and player.global_position.distance_to(global_position) < CONTACT_RANGE:
			engaged.emit(self)
	_pause -= delta
	var dir := Vector3.ZERO
	if _target != null:
		var to: Vector3 = (_target as Vector3) - global_position
		to.y = 0
		if to.length() < 0.4:
			_target = null
			_pause = _rng.randf_range(2.0, 5.0)
		else:
			dir = to.normalized()
	velocity.x = dir.x * speed()
	velocity.z = dir.z * speed()
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	sprite.walking = dir != Vector3.ZERO
	if dir != Vector3.ZERO:
		sprite.face(Vector2(dir.x, dir.z))
	move_and_slide()


func remove(reason: StringName) -> void:
	removed.emit(self, reason)
	queue_free()


func _add_sparkle() -> void:
	var p := GPUParticles3D.new()
	p.amount = 12
	p.lifetime = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.8
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 0.5
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.15, 0.15)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1, 0.95, 0.5)
	m.emission_enabled = true
	m.emission = Color(1, 0.9, 0.4)
	m.emission_energy_multiplier = 3.0
	q.material = m
	p.draw_pass_1 = q
	p.position.y = 1.0
	add_child(p)
