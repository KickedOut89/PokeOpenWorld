class_name KantoWorld
extends Node3D
## Root of the Kanto overworld: terrain chunks, the player, camera and lighting.
## Chunks stream in around the player through WorldStreamer.

const SEED := 1996

var streamer: WorldStreamer
var player: Player
var camera: HD2DCamera
var lighting: LightingDirector
var interiors: InteriorManager
var doors: DoorController
var toast: MessageToast
var weather_fx: WeatherFx
var spawner: SpawnNode
var npcs: NPCManager
var barks: BarkSystem
var dialogue: DialogueBox
var ambience: AmbiencePlayer
var fights: FightController
var trainer_sight: TrainerSight
var capture: CaptureController
var prompts: PromptBox
var progression: ProgressionUI
var party_menu: PartyMenu
var quests: QuestRunner
var settings_menu: SettingsMenu
var debug_menu: DebugMenu
var _npc_t: float = 0.0
var _ui_busy_frame: int = -10


func _ready() -> void:
	streamer = WorldStreamer.new()
	streamer.name = "Chunks"
	add_child(streamer)
	streamer.setup_from_db(Data.db, SEED)
	lighting = LightingDirector.new()
	lighting.name = "Lighting"
	add_child(lighting)
	player = load("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	add_child(player)
	player.global_position = find_anchor(&"player_spawn") + Vector3(0, 0.2, 0)
	streamer.target = player
	streamer.update_now()
	camera = HD2DCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.target = player
	camera.make_current()
	camera.snap()
	interiors = InteriorManager.new()
	interiors.name = "Interiors"
	add_child(interiors)
	interiors.setup(player, self, Data.db)
	interiors.entered.connect(func(_id: StringName) -> void: camera.snap())
	interiors.exited.connect(func(_id: StringName) -> void: camera.snap())
	doors = DoorController.new()
	doors.name = "Doors"
	doors.player = player
	doors.interiors = interiors
	add_child(doors)
	weather_fx = WeatherFx.new()
	weather_fx.name = "WeatherFx"
	weather_fx.camera = camera
	weather_fx.lighting = lighting
	weather_fx.area = streamer.current_area
	add_child(weather_fx)
	weather_fx.track_library(streamer.library())
	spawner = SpawnNode.new()
	spawner.name = "Wilds"
	spawner.streamer = streamer
	spawner.camera = camera
	spawner.player = player
	add_child(spawner)
	npcs = NPCManager.new()
	npcs.name = "NPCs"
	add_child(npcs)
	npcs.cap = GraphicsPresets.npc_cap()
	npcs.setup(Data.db.table(&"npcs"), Data.db.table(&"schedules"), NPCManager.index_anchors(streamer.records()),
		func(rec: Dictionary) -> Node3D: return NPC.make(rec))
	update_npcs()
	barks = BarkSystem.new()
	barks.name = "Barks"
	barks.player = player
	add_child(barks)
	dialogue = DialogueBox.new()
	dialogue.name = "Dialogue"
	add_child(dialogue)
	dialogue.choice_made.connect(func(f: StringName) -> void: State.set_flag(f))
	dialogue.closed.connect(func() -> void:
		player.input_enabled = true
		_ui_busy_frame = Engine.get_physics_frames())
	player.interacted.connect(_on_interact)
	ambience = AmbiencePlayer.new()
	ambience.name = "Ambience"
	ambience.area = streamer.current_area
	add_child(ambience)
	interiors.entered.connect(func(_id: StringName) -> void: ambience.indoors = true)
	interiors.exited.connect(func(_id: StringName) -> void: ambience.indoors = false)
	fights = FightController.new()
	fights.name = "Fights"
	fights.world = self
	add_child(fights)
	var ai := CombatAI.new(fights.chart, Data.db, fights.rng)
	fights.ai_brain = func(st: Dictionary) -> Dictionary:
		return ai.decide(st.me, st.my_pos, st.foe, st.foe_pos, st.ready, st.skill)
	trainer_sight = TrainerSight.new()
	trainer_sight.name = "TrainerSight"
	trainer_sight.world = self
	add_child(trainer_sight)
	capture = CaptureController.new()
	capture.name = "Capture"
	capture.world = self
	add_child(capture)
	prompts = PromptBox.new()
	prompts.name = "Prompts"
	add_child(prompts)
	progression = ProgressionUI.new()
	progression.prompts = prompts
	add_child(progression)
	fights.fight_won.connect(func(m: FightModel, foes: Array) -> void: progression.on_fight_won(m, foes, m.kind == &"trainer"))
	quests = QuestRunner.new()
	quests.name = "Quests"
	add_child(quests)
	settings_menu = SettingsMenu.new()
	settings_menu.name = "SettingsMenu"
	add_child(settings_menu)
	debug_menu = DebugMenu.new()
	debug_menu.name = "DebugMenu"
	debug_menu.world = self
	add_child(debug_menu)
	Settings.apply()
	party_menu = PartyMenu.new()
	party_menu.name = "PartyMenu"
	party_menu.can_swap = func() -> bool: return not fights.in_fight()
	party_menu.can_open = func() -> bool: return not (dialogue.is_open() or prompts.is_open())
	add_child(party_menu)
	spawner.wild_spawned.connect(func(w: WildPokemon) -> void: w.engaged.connect(func(x: WildPokemon) -> void: fights.start_wild(x)))
	Saves.in_fight = func() -> bool: return fights != null and fights.in_fight()
	EventBus.area_entered.connect(func(_a: StringName) -> void: autosave())
	interiors.entered.connect(func(_id: StringName) -> void: autosave())
	interiors.exited.connect(func(_id: StringName) -> void: autosave())
	toast = MessageToast.new()
	toast.name = "Toast"
	add_child(toast)


func teleport_to_anchor(id: StringName) -> void:
	player.global_position = find_anchor(id) + Vector3(0, 0.3, 0)
	streamer.update_now()
	camera.snap()
	update_npcs()


func find_anchor(id: StringName) -> Vector3:
	for coord in streamer.records():
		var d: ChunkData = streamer.record(coord)
		for a in d.npc_anchors:
			if StringName(a.id) == id:
				return d.origin() + Vector3(float(a.pos[0]), float(a.pos[1]), float(a.pos[2]))
	return Vector3.ZERO


## Without a Pokémon, Oak stops you at Pallet Town's north edge.
const PALLET_NORTH_Z := 843.0
const PALLET_X := Vector2(128.0, 256.0)


func _check_pallet_exit() -> void:
	if State.has_flag(&"got_starter") or interiors.is_inside():
		return
	var p := player.global_position
	if p.z < PALLET_NORTH_Z and p.z > PALLET_NORTH_Z - 20.0 and p.x > PALLET_X.x and p.x < PALLET_X.y:
		player.global_position.z = PALLET_NORTH_Z + 5.0
		EventBus.message.emit("Professor Oak: Hey! Wait! Don't go out! Wild Pokémon live in tall grass! You need your own Pokémon for protection.")


## True while a dialogue, prompt or menu owns the keyboard/controller.
func ui_busy() -> bool:
	return (dialogue != null and dialogue.is_open()) or (prompts != null and prompts.is_open()) \
		or (party_menu != null and party_menu.is_open()) or (settings_menu != null and settings_menu.is_open())


## Also true for the frame right after a UI closes, so its closing press isn't reused.
func ui_locked() -> bool:
	if ui_busy():
		_ui_busy_frame = Engine.get_physics_frames()
		return true
	return Engine.get_physics_frames() <= _ui_busy_frame + 1


## The save service must not keep calling into a freed world.
func _exit_tree() -> void:
	Saves.in_fight = func() -> bool: return false


func _physics_process(delta: float) -> void:
	if player != null:
		player.ui_blocked = ui_locked()
	_check_pallet_exit()
	_check_player_attack()
	_npc_t -= delta
	if _npc_t <= 0.0:
		_npc_t = NPCManager.UPDATE_INTERVAL
		update_npcs()


func update_npcs() -> void:
	if npcs == null or interiors != null and interiors.is_inside():
		return
	npcs.cap = GraphicsPresets.npc_cap()
	var hour := Clock.model.minutes / 60.0
	npcs.update(player.global_position, hour, _weather_for_chunk, streamer.loaded_coords())


func _weather_for_chunk(c: Vector2i) -> StringName:
	var d := streamer.record(c)
	return Weather.weather_for_area(d.area) if d != null else &"clear"


func _on_interact(target: Node) -> void:
	if dialogue.is_open() or target == null:
		return
	var npc := target as NPC
	if npc == null:
		return
	talk_to(npc.record)


## Opens the NPC's context-picked talk line (and its branch, if any).
## NPCs with a "service" (heal, mart) perform it instead of small talk.
func talk_to(rec: Dictionary) -> void:
	if ui_busy():
		return
	if _story_talk(rec):
		return
	match String(rec.get("service", "")):
		"heal":
			var center := StringName(rec.get("center", "viridian_center"))
			PokemonCenter.heal(State, center)
			EventBus.message.emit("%s: Your Pokémon are fully healed! We hope to see you again!" % rec.get("name", ""))
			EventBus.npc_talked.emit(StringName(rec.get("id", "")))
			return
		"mart":
			if EventBus.has_signal(&"npc_talked"):
				EventBus.npc_talked.emit(StringName(rec.get("id", "")))
			if _quest_handles_talk(StringName(rec.get("id", ""))):
				return
			_open_mart(rec)
			return
	var dlg := Data.db.get_record(&"dialogue", StringName(rec.get("dialogue", "")))
	var line := barks.selector.pick_line(dlg.get("talk", []), barks.context(), RandomNumberGenerator.new())
	if line.is_empty():
		return
	player.input_enabled = false
	dialogue.open(String(rec.get("name", "")), [line], dlg.get("branches", {}))
	EventBus.npc_talked.emit(StringName(rec.get("id", "")))


## Pressing a move key near a wild Pokémon starts the fight (the player "attacks first").
func _check_player_attack() -> void:
	if fights == null or fights.in_fight() or not player.input_enabled or player.ui_blocked:
		return
	if Input.is_action_just_pressed(&"interact"):
		return  # on a controller A is both talk and Move 1: talking wins
	var pressed := false
	for i in 4:
		if Input.is_action_just_pressed(StringName("move_%d" % (i + 1))):
			pressed = true
	if not pressed:
		return
	var best: WildPokemon = null
	var best_d := 10.0
	for w in get_tree().get_nodes_in_group(&"wild"):
		var d := (w as Node3D).global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = w
	if best != null:
		best.attacked = true
		fights.start_wild(best)


## The Mart clerk hands over Oak's Parcel once you have a Pokémon.
func _quest_handles_talk(npc_id: StringName) -> bool:
	if npc_id == &"mart_clerk" and State.has_flag(&"got_starter") and not State.has_flag(&"got_parcel"):
		EventBus.message.emit("Mart Clerk: You're from Pallet Town? Professor Oak ordered this. Would you take it to him?")
		State.set_flag(&"got_parcel")
		return true
	return false


## Story beats that override normal small talk. Returns true when handled.
func _story_talk(rec: Dictionary) -> bool:
	var id := StringName(rec.get("id", ""))
	if id == &"professor_oak" and not State.has_flag(&"got_starter"):
		prompts.ask("Professor Oak: Here, take one of these three Pokémon!", ["Bulbasaur", "Charmander", "Squirtle"],
			func(i: int) -> void: choose_starter(Rival.STARTERS[i]))
		return true
	if id == &"professor_oak" and int(State.items.get(&"oaks_parcel", 0)) > 0:
		if quests.on_talk(id):
			EventBus.message.emit("Professor Oak: Ah, my custom Poké Ball parcel! Thanks! Take this Pokédex — and these five Poké Balls.")
			return true
	quests.on_talk(id)  # advance any talk_to stage, then carry on with normal dialogue
	return false


## Gives the chosen Lv 5 starter; the rival takes the counter-pick and challenges you.
func choose_starter(species: StringName) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var c := Creature.create(species, 5, rng, Data.db)
	State.give_pokemon(c)
	State.pokedex_caught[species] = true
	State.set_flag(StringName("starter_%s" % species))
	State.set_flag(&"got_starter")
	EventBus.message.emit("You received %s!" % c.display_name())
	var rival := Data.db.get_record(&"trainers", &"rival_lab").duplicate(true)
	rival.party = [{"species": String(Rival.counter(species)), "level": 5}]
	var node: Node3D = null
	for n in get_tree().get_nodes_in_group(&"npc"):
		if (n as NPC).record.get("id", "") == "rival_blue":
			node = n
	if node == null:
		node = player
	fights.start_trainer(rival, node)


func _open_mart(rec: Dictionary) -> void:
	var stock := Mart.stock(State)
	var opts: Array = stock.map(func(id: StringName) -> String:
		var it := Data.db.get_record(&"items", id)
		return "%s  ₽%d" % [it.get("name", id), int(it.get("price", 0))])
	opts.append("Leave")
	prompts.ask("%s: Welcome! What would you like? (You have ₽%d)" % [rec.get("name", ""), State.money], opts,
		func(i: int) -> void:
			if i >= stock.size():
				return
			if Mart.buy(State, stock[i], 1, Data.db):
				EventBus.message.emit("Bought a %s." % Data.db.get_record(&"items", stock[i]).get("name", stock[i]))
			else:
				EventBus.message.emit("You don't have enough money."))


## The world's part of a save: where the player is, respawn timers, quest progress.
func snapshot_world() -> Dictionary:
	var p := player.global_position
	var block := {"pos": [p.x, p.y, p.z], "area": String(streamer.current_area)}
	if interiors.is_inside():
		var o := interiors.outdoor_return_point()
		block["interior"] = {"id": String(interiors.current_id), "door": String(interiors.current_door.get("id", "")), "outdoor_pos": [o.x, o.y, o.z]}
	return Saves.snapshot({"player": block, "spawns_respawn_timers": spawner.director.timers_to_dict(), "quests": quest_state()})


func quest_state() -> Dictionary:
	return quests.to_dict()


func restore_quests(d: Dictionary) -> void:
	quests.from_dict(d)


func autosave() -> void:
	if not is_inside_tree() or player == null or (fights != null and fights.in_fight()):
		return
	Saves.save(SaveService.AUTOSAVE_SLOT, snapshot_world())


func save_manually() -> void:
	if Saves.save(SaveService.AUTOSAVE_SLOT, snapshot_world()) == OK:
		EventBus.message.emit("Game saved.")
	else:
		EventBus.message.emit("You can't save right now.")


## Loads a slot and puts the player back where they were (inside a building if saved there).
func continue_from_save(slot: int) -> bool:
	var r := Saves.load_slot(slot)
	if not r.ok:
		return false
	var block := Saves.apply(r.data)
	spawner.director.timers_from_dict(r.data.get("spawns_respawn_timers", {}))
	restore_quests(r.data.get("quests", {}))
	if block.has("interior"):
		var outdoor: Vector3 = block.interior.outdoor_pos
		player.global_position = outdoor
		streamer.update_now()
		var door := _door_record(StringName(block.interior.get("door", "")))
		if not door.is_empty():
			await interiors.enter(door, outdoor)
	elif block.has("pos"):
		player.global_position = block.pos + Vector3(0, 0.2, 0)
		streamer.update_now()
	camera.snap()
	update_npcs()
	if r.used_backup:
		EventBus.message.emit("Your last save was damaged; the previous save was loaded.")
	return true


func _door_record(id: StringName) -> Dictionary:
	for c in streamer.records():
		for d in streamer.record(c).doors:
			if StringName(d.id) == id:
				return d
	return {}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).physical_keycode == KEY_F5:
		save_manually()
