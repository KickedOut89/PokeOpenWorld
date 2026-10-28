class_name CaptureController
extends Node3D
## Aim + throw Poké Balls. Holding `aim` shows the arc to the wild nearest the aim
## direction; `throw` (or throw_at) lobs a ball. Throwing at an unengaged wild is a
## sneak throw (x1.5). A breakout starts a fight; a catch ends one as "caught".

const AIM_CONE_DEG := 35.0
const BALL := &"poke_ball"

var world: Node3D
var rng := RandomNumberGenerator.new()
var forced_attempt: Dictionary = {}  # tests
var last_sneak: bool = false
var fade_free: bool = false          # tests: skip waiting on visuals

var _ball: MeshInstance3D
var _flight: Dictionary = {}
var _seq: CaptureSequence
var _target: WildPokemon
var _preview: MeshInstance3D


func _ready() -> void:
	rng.randomize()
	_preview = MeshInstance3D.new()
	_preview.mesh = ImmediateMesh.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.8)
	_preview.material_override = m
	add_child(_preview)


func busy() -> bool:
	return not _flight.is_empty() or _seq != null


func aim_target() -> WildPokemon:
	var p: Player = world.player
	var origin: Vector3 = p.global_position
	var aim := Vector2(p.facing.x, p.facing.y)
	if world.fights.in_fight() and world.fights.foe_wild != null:
		return world.fights.foe_wild
	var best: WildPokemon = null
	var best_d := ThrowAim.MAX_RANGE
	for n in get_tree().get_nodes_in_group(&"wild"):
		var w := n as WildPokemon
		var to := Vector2(w.global_position.x - origin.x, w.global_position.z - origin.z)
		if to.length() <= best_d and rad_to_deg(absf(aim.angle_to(to))) <= AIM_CONE_DEG:
			best = w
			best_d = to.length()
	return best


func _physics_process(delta: float) -> void:
	_tick_flight(delta)
	_tick_sequence(delta)
	var aiming := Input.is_action_pressed(&"aim") and not busy()
	(_preview.mesh as ImmediateMesh).clear_surfaces()
	if aiming:
		var t := aim_target()
		if t != null:
			_draw_arc(world.player.global_position + Vector3(0, 1.5, 0), t.global_position + Vector3(0, 0.6, 0))
		if Input.is_action_just_pressed(&"throw") and t != null:
			throw_at(t)


func throw_at(target: Node3D) -> bool:
	if busy():
		return false
	if target is BattleActor:
		EventBus.message.emit("You can't catch a Trainer's Pokémon!")
		return false
	var w := target as WildPokemon
	if w == null:
		return false
	if int(State.items.get(BALL, 0)) <= 0:
		EventBus.message.emit("You don't have any Poké Balls!")
		return false
	var origin: Vector3 = world.player.global_position + Vector3(0, 1.5, 0)
	var arc := ThrowAim.arc(origin, w.global_position + Vector3(0, 0.6, 0))
	if not arc.ok:
		EventBus.message.emit("It's too far away to throw!")
		return false
	State.items[BALL] = int(State.items[BALL]) - 1
	last_sneak = not world.fights.in_fight() and not w.in_fight
	_target = w
	_flight = {"pos": origin, "vel": arc.velocity, "t": 0.0, "time": arc.time if not fade_free else 0.0}
	_ball = _make_ball()
	return true


func _tick_flight(delta: float) -> void:
	if _flight.is_empty():
		return
	_flight.t += delta
	_flight.vel.y -= ThrowAim.GRAVITY * delta
	_flight.pos += _flight.vel * delta
	_ball.global_position = _flight.pos
	if _flight.t < _flight.time:
		return
	_flight = {}
	if _target == null or not is_instance_valid(_target):
		_ball.queue_free()
		return
	var c: Creature = _target.creature
	var a := CatchCalc.modified_rate(c.max_hp(), c.hp, int(c.rec().get("catch_rate", 45)),
		float(Data.db.get_record(&"items", BALL).get("ball_bonus", 1.0)), c.status, last_sneak)
	var attempt := forced_attempt if not forced_attempt.is_empty() else CatchCalc.attempt(a, State.pokedex_caught.size(), rng)
	_seq = CaptureSequence.new(attempt)
	_target.visible = false
	_target.in_fight = true


func _tick_sequence(delta: float) -> void:
	if _seq == null:
		return
	for e in _seq.tick(delta if not fade_free else 10.0):
		match e:
			&"shake":
				var tw := create_tween()
				tw.tween_property(_ball, "rotation:z", 0.4, 0.15)
				tw.tween_property(_ball, "rotation:z", -0.4, 0.3)
				tw.tween_property(_ball, "rotation:z", 0.0, 0.15)
			&"caught":
				_on_caught()
			&"breakout":
				_on_breakout()
	if _seq != null and _seq.done:
		_seq = null
		if _ball != null:
			_ball.queue_free()
			_ball = null


func _on_caught() -> void:
	var w := _target
	if w == null or not is_instance_valid(w):
		_target = null
		return
	var c: Creature = w.creature
	State.pokedex_caught[c.species] = true
	State.pokedex_seen[c.species] = true
	var where := State.give_pokemon(c)
	EventBus.pokemon_caught.emit(c.species)
	EventBus.message.emit("Gotcha! %s was caught!%s" % [c.display_name(), "" if where == &"party" else " It was sent to the PC."])
	if world.fights.in_fight() and world.fights.foe_wild == w:
		world.fights.model.mark_caught()
	w.remove(&"caught")
	_target = null


func _on_breakout() -> void:
	var w := _target
	_target = null
	if w == null or not is_instance_valid(w):
		return
	w.visible = true
	w.in_fight = world.fights.in_fight() and world.fights.foe_wild == w
	w.attacked = true
	EventBus.message.emit("Oh no! It broke free!")
	if not world.fights.in_fight():
		world.fights.start_wild(w)


func _make_ball() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.18
	s.height = 0.36
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("e03030")
	s.material = m
	mi.mesh = s
	add_child(mi)
	return mi


func _draw_arc(origin: Vector3, target: Vector3) -> void:
	var arc := ThrowAim.arc(origin, target)
	if not arc.ok:
		return
	var im := _preview.mesh as ImmediateMesh
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var steps := 24
	for i in steps + 1:
		var t: float = arc.time * i / steps
		var v: Vector3 = arc.velocity
		im.surface_add_vertex(origin + Vector3(v.x * t, v.y * t - 0.5 * ThrowAim.GRAVITY * t * t, v.z * t))
	im.surface_end()
