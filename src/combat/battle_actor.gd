class_name BattleActor
extends CharacterBody3D
## A Pokémon body on the battlefield that isn't a roaming wild: the player's Pokémon
## or a trainer's. Movement is driven by FightController via `drive()`.

var creature: Creature
var sprite: BillboardSprite
var facing: Vector3 = Vector3.FORWARD


static func make(c: Creature, pos: Vector3) -> BattleActor:
	var a := BattleActor.new()
	a.creature = c
	a.position = pos
	a.name = "Battle_%s" % c.species
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.2
	shape.shape = cap
	shape.position.y = 0.6
	a.add_child(shape)
	a.collision_layer = 8
	a.collision_mask = 1
	a.sprite = BillboardSprite.new()
	a.add_child(a.sprite)
	return a


func _ready() -> void:
	add_to_group(&"battle_actor")
	var assets := get_node_or_null(^"/root/Assets")
	if assets != null:
		sprite.set_sheet(assets.texture("species/%s%s" % [creature.species, "_shiny" if creature.shiny else ""]))


func drive(dir: Vector3, speed: float, delta: float) -> void:
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	if dir.length() > 0.01:
		facing = dir.normalized()
		sprite.face(Vector2(dir.x, dir.z))
	sprite.walking = dir.length() > 0.01
	move_and_slide()
