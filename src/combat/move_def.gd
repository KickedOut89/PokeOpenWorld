class_name MoveDef
extends RefCounted
## Read-only view of a move record with real-time timing helpers.

var rec: Dictionary
var id: StringName


func _init(record: Dictionary) -> void:
	rec = record
	id = StringName(record.get("id", ""))


func windup(user_speed: int) -> float:
	if int(rec.get("priority", 0)) >= 1:
		return 0.05
	var base := float(rec.windup_s) if rec.has("windup_s") else 0.35 + (100 - float(rec.get("accuracy", 100))) * 0.02
	if rec.has("windup_s"):
		return base
	return base * clampf(1.25 - user_speed / 400.0, 0.6, 1.25)


func active_s() -> float:
	return float(rec.get("active_s", 0.15))


func recovery_s() -> float:
	return float(rec.get("recovery_s", 0.15))


func cooldown() -> float:
	return Cooldowns.for_move(rec)


func category() -> StringName:
	return StringName(rec.get("category", "physical"))


func type() -> StringName:
	return StringName(rec.get("type", "normal"))


func shape() -> StringName:
	return StringName(rec.get("shape", "melee_arc"))
