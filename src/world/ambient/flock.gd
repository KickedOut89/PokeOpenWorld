class_name Flock
extends RefCounted
## A group of resting birds that scatters when the player comes within 6 m, flies off
## for 8 s, then glides back and is resettled on its perches within 20 s of taking off.

const SCATTER_RANGE := 6.0
const FLY_SECONDS := 8.0
const RESETTLE_SECONDS := 20.0
const CLIMB := 4.0
const FLEE := 3.0
const RETURN_SPEED := 4.0

var homes: PackedVector3Array
var positions: PackedVector3Array
var flying: bool = false
var _airborne: float = 0.0
var _away: Vector3 = Vector3.ZERO


func _init(perches: PackedVector3Array) -> void:
	homes = perches
	positions = perches.duplicate()


func step(player_pos: Vector3, delta: float) -> PackedVector3Array:
	if not flying:
		for h in homes:
			if Vector2(h.x, h.z).distance_to(Vector2(player_pos.x, player_pos.z)) < SCATTER_RANGE:
				flying = true
				_airborne = 0.0
				var center := Vector3.ZERO
				for p in homes:
					center += p
				center /= maxi(1, homes.size())
				var away := center - player_pos
				away.y = 0
				_away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
				break
	if flying:
		_airborne += delta
		for i in positions.size():
			if _airborne < FLY_SECONDS:
				positions[i] += (Vector3.UP * CLIMB + _away * FLEE) * delta
			else:
				positions[i] = positions[i].move_toward(homes[i], RETURN_SPEED * delta)
		if _airborne >= FLY_SECONDS:
			var home := true
			for i in positions.size():
				if positions[i].distance_to(homes[i]) > 0.01:
					home = false
			if home:
				flying = false
	return positions
