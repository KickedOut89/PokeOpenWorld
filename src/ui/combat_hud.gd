class_name CombatHUD
extends CanvasLayer
## HP bars, move slots with cooldowns, stamina, switch cooldown, escape timer.

var _root: Control
var _mine: Label
var _mine_hp: ProgressBar
var _foe: Label
var _foe_hp: ProgressBar
var _moves: Array[Label] = []
var _stamina: ProgressBar
var _info: Label
var _float: Label
var _float_t: float = 0.0


func _ready() -> void:
	layer = 30
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var foe_box := _panel(Vector2(40, 30), Vector2(460, 90))
	_foe = _label(foe_box, 24)
	_foe_hp = _bar(foe_box, Color("e04040"))
	var me_box := _panel(Vector2(40, 820), Vector2(560, 220))
	_mine = _label(me_box, 24)
	_mine_hp = _bar(me_box, Color("40c060"))
	_stamina = _bar(me_box, Color("e0c040"))
	for i in 4:
		_moves.append(_label(me_box, 20))
	_info = _label(_panel(Vector2(1380, 30), Vector2(500, 70)), 20)
	_float = Label.new()
	_float.add_theme_font_size_override("font_size", 40)
	_float.position = Vector2(860, 380)
	_root.add_child(_float)


func _panel(pos: Vector2, size: Vector2) -> VBoxContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = size
	_root.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	return v


func _label(parent: Control, font: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font)
	parent.add_child(l)
	return l


func _bar(parent: Control, col: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(400, 18)
	b.show_percentage = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	b.add_theme_stylebox_override("fill", sb)
	parent.add_child(b)
	return b


func visible_hud(on: bool) -> void:
	if _root != null:
		_root.visible = on


func refresh(fc: FightController) -> void:
	var m := fc.model
	if m == null:
		return
	var me := m.active()
	_mine.text = "%s  Lv%d  %s" % [me.creature.display_name(), me.creature.level, String(me.status).to_upper()]
	_mine_hp.max_value = me.creature.max_hp()
	_mine_hp.value = me.creature.hp
	_stamina.value = me.stamina
	var foe := m.current_foe()
	if foe != null:
		_foe.text = "%s  Lv%d  %s" % [foe.creature.display_name(), foe.creature.level, String(foe.status).to_upper()]
		_foe_hp.max_value = foe.creature.max_hp()
		_foe_hp.value = foe.creature.hp
	for i in 4:
		if i < me.creature.moves.size():
			var mv := me.creature.moves[i]
			var cd := fc.cooldown_left(&"player", mv)
			var name := String(Data.db.get_record(&"moves", mv).get("name", mv))
			_moves[i].text = "[%d] %s%s" % [i + 1, name, "  (%.1fs)" % cd if cd > 0.0 else ""]
		else:
			_moves[i].text = "[%d] -" % (i + 1)
	var bits: Array[String] = []
	if m.switch_cooldown > 0.0:
		bits.append("Switch in %.1fs" % m.switch_cooldown)
	if m.escape_timer > 0.0:
		bits.append("Escaping... %.1fs" % (FightModel.ESCAPE_SECONDS - m.escape_timer))
	if m.kind == &"trainer":
		bits.append("Trainer battle — no escape")
	_info.text = "   ".join(bits)
	if _float_t > 0.0:
		_float_t -= get_process_delta_time()
		_float.visible = _float_t > 0.0


func show_damage(dmg: int, type_mult: float, side: StringName) -> void:
	var note := ""
	if type_mult > 1.0:
		note = "  Super effective!"
	elif type_mult < 1.0 and type_mult > 0.0:
		note = "  Not very effective..."
	_float.text = "%s%d%s" % ["-" if side == &"player" else "Ouch! -", dmg, note]
	_float.visible = true
	_float_t = 1.0


func flash_event(e: Dictionary) -> void:
	if e.get("type", "") == "stun":
		_float.text = "Paralyzed! It can't move!"
		_float.visible = true
		_float_t = 0.8
