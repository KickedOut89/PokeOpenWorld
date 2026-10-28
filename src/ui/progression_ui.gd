class_name ProgressionUI
extends Node
## Turns post-battle progression events into messages and prompts:
## level-ups, learning a move (forget one / give up), and evolving (continue / stop).

var prompts: PromptBox


func on_fight_won(model: FightModel, foes: Array, trainer: bool) -> void:
	for entry in Progression.award(model, foes, trainer):
		var c: Creature = entry.creature
		for e in entry.events:
			match e.type:
				"level":
					EventBus.message.emit("%s grew to Lv. %d!" % [c.display_name(), e.level])
				"learn":
					_learn(c, e.move)
				"evolve":
					_evolve(c, e.to)


func _learn(c: Creature, move: StringName) -> void:
	var mname := String(Data.db.get_record(&"moves", move).get("name", move))
	if not Progression.needs_prompt(c, move):
		if Progression.learn(c, move, -1):
			EventBus.message.emit("%s learned %s!" % [c.display_name(), mname])
		return
	var opts: Array = c.moves.map(func(m: StringName) -> String: return "Forget %s" % Data.db.get_record(&"moves", m).get("name", m))
	opts.append("Don't learn %s" % mname)
	prompts.ask("%s wants to learn %s, but already knows four moves." % [c.display_name(), mname], opts,
		func(i: int) -> void:
			if i < 4 and Progression.learn(c, move, i):
				EventBus.message.emit("%s learned %s!" % [c.display_name(), mname])
			else:
				EventBus.message.emit("%s did not learn %s." % [c.display_name(), mname]))


func _evolve(c: Creature, to: StringName) -> void:
	var old := c.display_name()
	var to_name := String(Data.db.get_record(&"species", to).get("name", to))
	prompts.ask("What? %s is evolving!" % old, ["Let it evolve", "Stop it"],
		func(i: int) -> void:
			if i == 0:
				c.evolve_to(to)
				State.pokedex_caught[to] = true
				EventBus.message.emit("Congratulations! %s evolved into %s!" % [old, to_name])
			else:
				Progression.cancel_evolution(c)
				EventBus.message.emit("Huh? %s stopped evolving!" % old))
