extends Node
## Autoload `EventBus`: global signals that let systems talk without references.

signal period_changed(period: StringName)
signal hour_changed(hour: int)
signal weather_changed(area: StringName, weather: StringName)
signal lamps_changed(on: bool)
signal chunk_loaded(coord: Vector2i)
signal chunk_unloaded(coord: Vector2i)
signal area_entered(area: StringName)
signal fight_started(fight_id: int)
signal fight_ended(fight_id: int, result: StringName)
signal flag_set(flag: StringName)
signal pokemon_caught(species: StringName)
## Short on-screen notice (locked doors, item pickups...). UI shows it.
signal message(text: String)
signal npc_talked(npc_id: StringName)
