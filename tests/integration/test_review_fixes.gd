extends GutTest
## Regression tests for the final-review findings (real input where input is the bug).

var world: KantoWorld
var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 13
	State.from_dict({})
	State.party = Party.new()
	State.pc = PCStorage.new()
	world = load("res://scenes/regions/kanto/kanto_world.tscn").instantiate()
	add_child_autofree(world)
	world.spawner.enabled = false
	world.interiors.fade_seconds = 0.0
	for id in Weather.models:
		var m: WeatherModel = Weather.models[id]
		m.current = &"clear"
		m.target = &"clear"
		m.blend = 1.0
	await wait_physics_frames(2)


func after_each() -> void:
	for a in [&"interact", &"move_1", &"move_2", &"ui_cancel", &"ui_accept"]:
		Input.action_release(a)
	State.from_dict({})
	State.party = Party.new()


## Sends a real press/release pair through the input pipeline, like a key or button would.
func _tap(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await wait_frames(5)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(5)


func _npc_in_front() -> NPC:
	var n := NPC.make(Data.db.get_record(&"npcs", &"granny_ruth"))
	world.npcs.add_child(n)
	n.global_position = world.player.global_position + Vector3(0, 0, 1.2)
	n.goal = n.global_position
	world.player.facing = Vector2(0, 1)
	return n


func test_interact_twice_closes_dialogue_and_restores_movement() -> void:
	_npc_in_front()
	await wait_physics_frames(2)
	await _tap(&"interact")
	assert_true(world.dialogue.is_open(), "first press talks")
	await _tap(&"interact")
	assert_false(world.dialogue.is_open(), "second press closes and does not reopen")
	assert_true(world.player.input_enabled)


func test_starter_prompt_cannot_stack() -> void:
	var oak := Data.db.get_record(&"npcs", &"professor_oak")
	world.talk_to(oak)
	world.talk_to(oak)
	world.prompts.choose(0)
	world.prompts.choose(0)
	assert_eq(State.party.members.size(), 1)


func test_prompt_cancel_picks_last_option() -> void:
	var picked := [-1]
	world.prompts.ask("Q", ["a", "b", "c", "d", "e", "Leave"], func(i: int) -> void: picked[0] = i)
	await wait_frames(2)
	await _tap(&"ui_cancel")
	assert_eq(picked[0], 5)


func test_prompt_keyboard_focus_reaches_fifth_option() -> void:
	var picked := [-1]
	world.prompts.ask("Q", ["a", "b", "c", "d", "e"], func(i: int) -> void: picked[0] = i)
	await wait_frames(2)
	world.prompts.focus_option(4)
	await _tap(&"ui_accept")
	assert_eq(picked[0], 4)


func test_prompt_answer_does_not_start_a_fight() -> void:
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	var w := WildPokemon.make(Creature.create(&"pidgey", 3, rng, Data.db), world.player.global_position + Vector3(0, 0, -5), &"t")
	world.spawner.add_child(w)
	world.prompts.ask("Q", ["yes", "no"], func(_i: int) -> void: pass)
	await _tap(&"move_1")
	assert_false(world.fights.in_fight(), "answering a prompt with 1 must not attack")


func test_party_swap_blocked_in_fight() -> void:
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	State.party.members.append(Creature.create(&"pidgey", 8, rng, Data.db))
	var w := WildPokemon.make(Creature.create(&"pidgey", 3, rng, Data.db), world.player.global_position + Vector3(0, 0, -4), &"t")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	world.party_menu.toggle()
	world.party_menu.swap_lead(1)
	assert_eq(State.party.members[0].species, &"squirtle")


func test_losing_frees_the_wild() -> void:
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	var w := WildPokemon.make(Creature.create(&"pidgey", 3, rng, Data.db), world.player.global_position + Vector3(0, 0, -4), &"t")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	State.party.members[0].hp = 0
	await wait_physics_frames(3)
	assert_false(world.fights.in_fight())
	assert_true(not is_instance_valid(w) or not w.in_fight, "no frozen statue left behind")


func test_fight_pauses_while_ball_shakes() -> void:
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	State.items[&"poke_ball"] = 1
	var w := WildPokemon.make(Creature.create(&"pidgey", 3, rng, Data.db), world.player.global_position + Vector3(0, 0, -5), &"t")
	world.spawner.add_child(w)
	await wait_physics_frames(1)
	world.fights.start_wild(w)
	var foe := world.fights.model.current_foe()
	foe.apply_status(&"psn", rng)
	foe.creature.hp = 1
	world.capture.forced_attempt = {"caught": true, "shakes": 3, "critical": false}
	assert_true(world.capture.throw_at(w))
	for i in 400:
		if not world.capture.busy():
			break
		await wait_physics_frames(1)
	await wait_physics_frames(2)
	assert_eq(State.party.members.size(), 2, "poison did not knock it out mid-shake")


func test_trainer_fight_keeps_pokemon_in_ring() -> void:
	State.party.members.append(Creature.create(&"squirtle", 8, rng, Data.db))
	var npc := Node3D.new()
	world.add_child(npc)
	npc.global_position = world.player.global_position + Vector3(0, 0, -5)
	world.fights.start_trainer({"id": "t", "party": [{"species": "caterpie", "level": 3}], "skill": 0.3, "defeated_flag": "t_beaten"}, npc)
	world.fights.player_actor.global_position = world.fights.model.center + Vector3(20, 0.5, 0)
	world.fights.forced = {"move": Vector3(1, 0, 0)}
	await wait_physics_frames(3)
	var c := world.fights.model.center
	var p := world.fights.player_actor.global_position
	assert_lte(Vector2(p.x - c.x, p.z - c.z).length(), FightModel.RING_RADIUS + 0.2)


