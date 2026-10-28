class_name PokemonCenter
extends RefCounted
## Nurse Joy: full heal and a new blackout return point.


static func heal(state: GameState, center_id: StringName) -> void:
	state.party.heal_all()
	state.last_center = center_id
