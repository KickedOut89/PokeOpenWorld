class_name TrainerSight
extends Node
## Trainers challenge on sight: within `sight_range` in front of them (±25°) with a clear
## line, they shout "!", walk up to the player and start the battle. Beaten trainers
## (their defeated_flag set) never re-challenge.

const CONE_DEG := 25.0
const ENGAGE_DIST := 2.2
const FACINGS := {"down": Vector3(0, 0, 1), "up": Vector3(0, 0, -1), "left": Vector3(-1, 0, 0), "right": Vector3(1, 0, 0)}

var world: Node3D
var _approaching: Dictionary = {}  # npc id -> true


static func sees(trainer_pos: Vector3, facing: Vector3, player_pos: Vector3, sight: float) -> bool:
	var to := Vector2(player_pos.x - trainer_pos.x, player_pos.z - trainer_pos.z)
	if to.length() > sight or to.length() < 0.01:
		return to.length() < 0.01
	return rad_to_deg(absf(Vector2(facing.x, facing.z).angle_to(to))) <= CONE_DEG


static func trainer_for(npc_id: StringName) -> Dictionary:
	for id in Data.db.table(&"trainers"):
		var t: Dictionary = Data.db.table(&"trainers")[id]
		if StringName(t.get("npc", "")) == npc_id:
			return t
	return {}


func _physics_process(_delta: float) -> void:
	if world == null or world.fights.in_fight() or not world.player.input_enabled:
		return
	for n in get_tree().get_nodes_in_group(&"npc"):
		var npc := n as NPC
		if npc == null or npc.record.get("role", "") != "trainer":
			continue
		var id := StringName(npc.record.id)
		var t := trainer_for(id)
		if t.is_empty() or State.has_flag(StringName(t.defeated_flag)):
			continue
		var p: Vector3 = world.player.global_position
		if _approaching.has(id):
			npc.set_goal(p, {"activity": &"challenge"}, 0.0)
			if npc.global_position.distance_to(p) <= ENGAGE_DIST:
				_approaching.erase(id)
				EventBus.message.emit("%s: %s" % [npc.record.get("name", ""), t.get("intro", "Let's battle!")])
				world.fights.start_trainer(t, npc)
			continue
		var facing: Vector3 = FACINGS.get(String(npc.record.get("facing", "down")), Vector3(0, 0, 1))
		if sees(npc.global_position, facing, p, float(t.get("sight_range", 6))) and _clear_line(npc, p):
			_approaching[id] = true
			BarkSystem.bark(npc, "!")


func _clear_line(npc: Node3D, p: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(npc.global_position + Vector3(0, 1, 0), p + Vector3(0, 1, 0))
	q.exclude = [npc.get_rid(), world.player.get_rid()]
	q.collision_mask = 1
	return world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
