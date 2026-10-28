class_name Temperament
extends RefCounted
## Overworld behaviour of wild Pokémon by temperament (from species data).

const TIMID_FLEE := 10.0
const AGGRO_RANGE := 8.0
const TERRITORY := 6.0
const TERRITORY_LEASH := 15.0
const FLEE_DISTANCE := 8.0


static func decide(kind: StringName, self_pos: Vector3, home: Vector3, player_pos: Vector3, attacked: bool) -> Dictionary:
	var to_player := _flat(player_pos - self_pos)
	match kind:
		&"timid":
			if to_player.length() < TIMID_FLEE:
				var away := -to_player.normalized() if to_player.length() > 0.01 else Vector3.FORWARD
				return {"action": &"flee", "target": self_pos + away * FLEE_DISTANCE}
		&"aggressive":
			if attacked or to_player.length() < AGGRO_RANGE:
				return {"action": &"charge", "target": player_pos}
		&"territorial":
			if _flat(self_pos - home).length() > TERRITORY_LEASH:
				return {"action": &"return", "target": home}
			if attacked or _flat(player_pos - home).length() < TERRITORY:
				return {"action": &"charge", "target": player_pos}
		&"passive":
			if attacked:
				return {"action": &"charge", "target": player_pos}
			return {"action": &"idle", "target": self_pos}
	return {"action": &"wander", "target": null}


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)
