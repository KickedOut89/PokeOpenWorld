class_name FightController
extends Node3D
## Runs overworld fights: spawns the player's Pokémon, reads combat input, executes
## moves (wind-up/active/recovery), resolves hits with the Gen 5 formula, drives the
## foe's AI, and hands results (won/lost/escaped/caught) back to the world.

signal fight_won(model: FightModel, foe_creatures: Array)
signal fight_finished(result: StringName)

const ENGAGE_COOLDOWN := 5.0
const PLAYER_START_OFFSET := 2.5

var world: Node3D            # KantoWorld (player, camera, streamer)
var model: FightModel
var fight_id: int = 0
var rng := RandomNumberGenerator.new()
var chart: TypeChart
var ai_brain: Callable       # (side_state: Dictionary) -> {action, move?, target_pos?}
var input_enabled: bool = true
var forced: Dictionary = {}  # tests: {"move": Vector3, "use": StringName, "dodge": bool}

var player_actor: BattleActor
var foe_actor: Node3D
var foe_wild: WildPokemon
var trainer: Dictionary = {}
var hud: CombatHUD

var _cooldowns := {&"player": {}, &"foe": {}}
var _exec := {&"player": null, &"foe": null}
var _projectiles: Array = []
var _ring: MeshInstance3D
var _no_engage_until: float = 0.0


func _ready() -> void:
	rng.randomize()
	chart = TypeChart.from_db(Data.db)
	hud = CombatHUD.new()
	hud.name = "CombatHUD"
	add_child(hud)
	hud.visible_hud(false)


func in_fight() -> bool:
	return model != null


func can_engage() -> bool:
	return not in_fight() and Time.get_ticks_msec() / 1000.0 >= _no_engage_until and not State.party.all_fainted()


## Wild fight: the wild that engaged (or that the player attacked) becomes the foe.
func start_wild(w: WildPokemon) -> bool:
	if not can_engage():
		return false
	foe_wild = w
	w.in_fight = true
	foe_actor = w
	var foes: Array[Combatant] = [Combatant.new(w.creature)]
	_begin(&"wild", w.global_position, foes)
	return true


## Trainer fight: the trainer's party fights one at a time.
func start_trainer(rec: Dictionary, trainer_node: Node3D) -> bool:
	if not can_engage():
		return false
	trainer = rec
	var foes: Array[Combatant] = []
	for p in rec.get("party", []):
		var c := Creature.create(StringName(p.species), int(p.level), rng, Data.db)
		if p.has("moves"):
			var mv: Array[StringName] = []
			for m in p.moves:
				mv.append(StringName(m))
			c.moves = mv
		foes.append(Combatant.new(c))
	var center: Vector3 = (trainer_node.global_position + world.player.global_position) * 0.5
	_begin(&"trainer", center, foes)
	_spawn_trainer_foe()
	return true


func _begin(kind: StringName, center: Vector3, foes: Array[Combatant]) -> void:
	fight_id += 1
	model = FightModel.new(kind, center, State.party, foes)
	_cooldowns = {&"player": {}, &"foe": {}}
	_exec = {&"player": null, &"foe": null}
	_projectiles.clear()
	var p: Player = world.player
	p.input_enabled = false
	player_actor = BattleActor.make(model.active().creature, p.global_position + Vector3(p.facing.x, 0, p.facing.y) * PLAYER_START_OFFSET + Vector3(0, 0.3, 0))
	add_child(player_actor)
	world.camera.target = player_actor
	world.camera.in_combat = true
	world.streamer.pin(model.pinned_chunks(), fight_id)
	_show_ring(center)
	hud.visible_hud(true)
	EventBus.fight_started.emit(fight_id)
	State.pokedex_seen[current_foe_creature().species] = true


func current_foe_creature() -> Creature:
	var f := model.current_foe()
	return f.creature if f != null else null


func _spawn_trainer_foe() -> void:
	if foe_actor != null and is_instance_valid(foe_actor) and foe_actor is BattleActor:
		foe_actor.queue_free()
	var f := model.current_foe()
	if f == null:
		return
	var pos := model.center + (model.center - player_actor.global_position).normalized() * 3.0
	foe_actor = BattleActor.make(f.creature, pos + Vector3(0, 0.3, 0))
	add_child(foe_actor)


func _physics_process(delta: float) -> void:
	if model == null:
		return
	if foe_actor != null and not is_instance_valid(foe_actor):
		foe_actor = null  # e.g. caught by CaptureController this frame
	if foe_wild != null and not is_instance_valid(foe_wild):
		foe_wild = null
	var me := model.active()
	var foe := model.current_foe()
	for c in [me, foe]:
		if c != null:
			for e in c.tick(delta, rng):
				hud.flash_event(e)
	_player_input(me, delta)
	if foe != null and foe_actor != null and is_instance_valid(foe_actor) and foe_actor.visible:
		_foe_think(foe, delta)
	_tick_side(&"player", me, foe, delta)
	if foe != null:
		_tick_side(&"foe", foe, me, delta)
	_tick_projectiles(delta)
	for side in _cooldowns:
		for m in _cooldowns[side]:
			_cooldowns[side][m] = maxf(0.0, _cooldowns[side][m] - delta)
	var was_index := model.active_index
	var r := model.update(delta, player_actor.global_position)
	if model.active_index != was_index:
		player_actor.creature = model.active().creature
		player_actor._ready()
	if trainer.size() > 0 and r == &"ongoing" and foe_actor != null and foe_actor is BattleActor and (foe_actor as BattleActor).creature != current_foe_creature():
		_spawn_trainer_foe()
	hud.refresh(self)
	if r != &"ongoing":
		_finish(r)


func cooldown_left(side: StringName, move: StringName) -> float:
	return float(_cooldowns[side].get(move, 0.0))


func _player_input(me: Combatant, delta: float) -> void:
	var dir := Vector3.ZERO
	var use := &""
	var dodge := false
	if forced.size() > 0:
		dir = forced.get("move", Vector3.ZERO)
		use = forced.get("use", &"")
		dodge = forced.get("dodge", false)
	elif input_enabled:
		var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		dir = Vector3(v.x, 0, v.y)
		dodge = Input.is_action_just_pressed(&"dodge")
		for i in 4:
			if Input.is_action_just_pressed(StringName("move_%d" % (i + 1))) and i < me.creature.moves.size():
				use = me.creature.moves[i]
		if Input.is_action_just_pressed(&"switch"):
			var n := (model.active_index + 1) % model.party.members.size()
			for k in model.party.members.size():
				if model.request_switch(n):
					break
				n = (n + 1) % model.party.members.size()
	var busy: bool = _exec[&"player"] != null or model.is_switching() or not me.can_act()
	if dodge and not busy and me.dodge():
		dir = player_actor.facing * 3.0
	player_actor.drive(dir if not busy else Vector3.ZERO, move_speed(me), delta)
	if use != &"" and not busy:
		try_use(&"player", me, use)


static func move_speed(c: Combatant) -> float:
	return clampf(3.0 + c.effective(&"spe") / 25.0, 3.0, 9.0)


## Starts a move if it is known, off cooldown and the user can act.
func try_use(side: StringName, user: Combatant, move: StringName) -> bool:
	if not user.creature.moves.has(move) or cooldown_left(side, move) > 0.0 or not user.can_act() or _exec[side] != null:
		return false
	var rec := Data.db.get_record(&"moves", move)
	if rec.is_empty():
		return false
	var def := MoveDef.new(rec)
	_exec[side] = MoveExecutor.new(def, user.effective(&"spe"))
	_cooldowns[side][move] = def.cooldown()
	return true


func _tick_side(side: StringName, user: Combatant, target: Combatant, delta: float) -> void:
	var ex: MoveExecutor = _exec[side]
	if ex == null:
		return
	if user.is_fainted():
		_exec[side] = null
		return
	var actor: Node3D = player_actor if side == &"player" else foe_actor
	var other: Node3D = foe_actor if side == &"player" else player_actor
	if actor == null:
		_exec[side] = null
		return
	for e in ex.tick(delta):
		if e == &"active_start":
			_on_active(side, ex.move, user, target, actor, other)
		elif e == &"done":
			_exec[side] = null


func _facing_of(actor: Node3D, toward: Node3D) -> Vector3:
	if actor is BattleActor:
		var f := (actor as BattleActor).facing
		if toward != null and is_instance_valid(toward):
			var to := toward.global_position - actor.global_position
			to.y = 0
			# Gentle aim assist: snap to the foe when it is within 30 degrees of facing.
			if to.length() > 0.01 and rad_to_deg(Vector2(f.x, f.z).angle_to(Vector2(to.x, to.z))) < 30.0:
				return to.normalized()
		return f
	var d := (toward.global_position - actor.global_position) if toward != null and is_instance_valid(toward) else Vector3.FORWARD
	d.y = 0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


func _on_active(side: StringName, move: MoveDef, user: Combatant, target: Combatant, actor: Node3D, other: Node3D) -> void:
	var rec := move.rec
	var facing := _facing_of(actor, other)
	match String(rec.get("shape", "melee_arc")):
		"self":
			_apply_secondary(rec, user, user)
		"projectile":
			_projectiles.append({"side": side, "rec": rec, "pos": actor.global_position + Vector3(0, 0.8, 0), "dir": facing,
				"left": float(rec.get("range", 12.0)), "user": user, "target": target, "node": _projectile_node(rec)})
		"area":
			var center := actor.global_position + facing * float(rec.get("range", 0.0))
			if target != null and other != null and HitboxShapes.hits(rec, center, facing, other.global_position, 0.45):
				resolve_hit(rec, user, target, side)
		_:
			if target != null and other != null and HitboxShapes.hits(rec, actor.global_position, facing, other.global_position, 0.45):
				resolve_hit(rec, user, target, side)


func _projectile_node(rec: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.25
	s.height = 0.5
	var m := StandardMaterial3D.new()
	var col: Color = {"fire": Color("ff7a30"), "water": Color("4a8af0"), "electric": Color("ffe040"), "grass": Color("6ad040"),
		"poison": Color("a040c0"), "bug": Color("a8b820"), "flying": Color("c0d0ff")}.get(String(rec.get("type", "")), Color.WHITE)
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 2.0
	s.material = m
	mi.mesh = s
	add_child(mi)
	return mi


func _tick_projectiles(delta: float) -> void:
	for p in _projectiles.duplicate():
		var speed: float = float(p.rec.get("speed", 15.0))
		p.pos += p.dir * speed * delta
		p.left -= speed * delta
		(p.node as Node3D).global_position = p.pos
		var other: Node3D = foe_actor if p.side == &"player" else player_actor
		var hit := false
		if other != null and is_instance_valid(other) and p.target != null:
			var t: Vector3 = other.global_position + Vector3(0, 0.8, 0)
			if HitboxShapes.hits({"shape": "projectile", "radius": p.rec.get("radius", 0.7), "accuracy": p.rec.get("accuracy", 100)}, p.pos, p.dir, t, 0.45):
				resolve_hit(p.rec, p.user, p.target, p.side)
				hit = true
		if hit or p.left <= 0.0:
			(p.node as Node).queue_free()
			_projectiles.erase(p)


## Applies one landed move: Gen 5 damage, then status/stat side effects.
func resolve_hit(rec: Dictionary, user: Combatant, target: Combatant, side: StringName) -> int:
	if side == &"player" and foe_wild != null and is_instance_valid(foe_wild):
		foe_wild.attacked = true
	var dmg := 0
	if int(rec.get("power", 0)) > 0:
		var physical: bool = rec.get("category", "physical") == "physical"
		var mtype := StringName(rec.get("type", "normal"))
		var area: StringName = world.streamer.area_at(world.player.global_position) if world != null else &""
		dmg = Damage.calc({
			"level": user.creature.level, "power": int(rec.power),
			"atk": user.effective(&"atk" if physical else &"spa"), "def": target.effective(&"def" if physical else &"spd"),
			"stab": user.creature.types().has(String(mtype)),
			"type_mult": chart.mult(mtype, target.creature.types()),
			"crit": rng.randf() < Damage.crit_chance(int(user.stages.get(&"crit", 0))),
			"burn_physical": physical and user.burned(),
			"weather_mult": Damage.weather_mult(mtype, Weather.weather_for_area(area)),
			"roll": rng.randi_range(85, 100)})
		if not target.take_hit(dmg, mtype):
			return 0
		hud.show_damage(dmg, chart.mult(mtype, target.creature.types()), side)
	_apply_secondary(rec, user, target)
	return dmg


func _apply_secondary(rec: Dictionary, user: Combatant, target: Combatant) -> void:
	if rec.has("status") and rng.randf() < float(rec.status.get("chance", 1.0)):
		target.apply_status(StringName(rec.status.id), rng)
	if rec.has("stat_change"):
		var sc: Dictionary = rec.stat_change
		var who := user if sc.get("target", "foe") == "self" else target
		who.change_stage(StringName(sc.stat), int(sc.stages))


func _foe_think(foe: Combatant, delta: float) -> void:
	var ready: Array[StringName] = []
	for m in foe.creature.moves:
		if cooldown_left(&"foe", m) <= 0.0:
			ready.append(m)
	var decision: Dictionary
	if ai_brain.is_valid():
		decision = ai_brain.call({"me": foe, "my_pos": foe_actor.global_position, "foe": model.active(), "foe_pos": player_actor.global_position, "ready": ready, "skill": float(trainer.get("skill", 0.3))})
	else:
		decision = {"action": &"approach"}
	var busy: bool = _exec[&"foe"] != null or not foe.can_act()
	var to := player_actor.global_position - foe_actor.global_position
	to.y = 0
	var dir := Vector3.ZERO
	match decision.get("action", &"approach"):
		&"approach":
			dir = to.normalized() if to.length() > 1.5 else Vector3.ZERO
		&"retreat":
			dir = -to.normalized()
		&"strafe":
			dir = to.normalized().cross(Vector3.UP) * (1.0 if fight_id % 2 == 0 else -1.0)
		&"move":
			if not busy:
				try_use(&"foe", foe, decision.move)
	if busy:
		dir = Vector3.ZERO
	if foe_actor is BattleActor:
		(foe_actor as BattleActor).drive(dir, move_speed(foe), delta)
	elif foe_actor is WildPokemon:
		var w := foe_actor as WildPokemon
		w.velocity = Vector3(dir.x, 0, dir.z) * move_speed(foe)
		w.velocity.y = 0.0 if w.is_on_floor() else -9.8
		if dir != Vector3.ZERO:
			w.sprite.face(Vector2(dir.x, dir.z))
		w.sprite.walking = dir != Vector3.ZERO
		w.move_and_slide()


func _finish(r: StringName) -> void:
	var foes_c: Array = model.foes.map(func(f: Combatant) -> Creature: return f.creature)
	model.end()
	world.streamer.unpin(fight_id)
	for p in _projectiles:
		(p.node as Node).queue_free()
	_projectiles.clear()
	if _ring != null:
		_ring.queue_free()
		_ring = null
	world.player.global_position = player_actor.global_position
	player_actor.queue_free()
	player_actor = null
	world.camera.target = world.player
	world.camera.in_combat = false
	world.player.input_enabled = true
	hud.visible_hud(false)
	match r:
		&"won":
			if foe_wild != null and is_instance_valid(foe_wild):
				foe_wild.remove(&"defeated")
			if trainer.size() > 0:
				State.money += int(trainer.get("reward_money", 0))
				State.set_flag(StringName(trainer.get("defeated_flag", "")))
			fight_won.emit(model, foes_c)
		&"lost":
			State.party.heal_all()
			if trainer.get("no_blackout", false):
				State.set_flag(StringName(trainer.get("defeated_flag", "")))
				EventBus.message.emit(trainer.get("win_line", "The battle is over."))
			else:
				State.money = maxi(0, State.money - FightModel.blackout_money_loss(State.badges, State.party.highest_level()))
				var anchor := &"player_spawn" if State.last_center == &"pallet_home" else StringName(String(State.last_center) + "_front")
				if world.has_method(&"teleport_to_anchor"):
					world.teleport_to_anchor(anchor)
				EventBus.message.emit("You blacked out... You hurried back to safety.")
		&"escaped":
			if foe_wild != null and is_instance_valid(foe_wild):
				foe_wild.in_fight = false
				foe_wild.attacked = false
			EventBus.message.emit("Got away safely!")
		&"caught":
			pass
	if foe_actor != null and is_instance_valid(foe_actor) and foe_actor is BattleActor:
		foe_actor.queue_free()
	foe_actor = null
	foe_wild = null
	trainer = {}
	_no_engage_until = Time.get_ticks_msec() / 1000.0 + ENGAGE_COOLDOWN
	var id := fight_id
	model = null
	EventBus.fight_ended.emit(id, r)
	fight_finished.emit(r)


func _show_ring(center: Vector3) -> void:
	_ring = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = FightModel.RING_RADIUS - 0.12
	t.outer_radius = FightModel.RING_RADIUS
	t.rings = 64
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	t.material = m
	_ring.mesh = t
	add_child(_ring)
	_ring.global_position = center + Vector3(0, 0.15, 0)
