class_name Rival
extends RefCounted
## The rival always takes the starter that beats yours.

const COUNTER := {&"bulbasaur": &"charmander", &"charmander": &"squirtle", &"squirtle": &"bulbasaur"}
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]


static func counter(player_starter: StringName) -> StringName:
	return COUNTER.get(player_starter, &"charmander")
