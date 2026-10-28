class_name PartyMenu
extends CanvasLayer
## `menu` toggles a panel with the party (HP/status), the bag and money.
## Pressing 1-6 while open moves that Pokémon to the front.

var _panel: PanelContainer
var _label: Label
var can_swap: Callable = func() -> bool: return true
var can_open: Callable = func() -> bool: return true


func _ready() -> void:
	layer = 44
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_panel.offset_left = -560
	_panel.offset_right = -40
	_panel.offset_top = -330
	_panel.offset_bottom = 330
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 22)
	_panel.add_child(_label)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func toggle() -> void:
	_panel.visible = not _panel.visible
	refresh()


func refresh() -> void:
	var lines: Array[String] = ["PARTY  (press 1-6 to lead%s)" % ("" if can_swap.call() else " — not during a battle")]
	for i in State.party.members.size():
		var c := State.party.members[i]
		lines.append("%d. %s  Lv%d  HP %d/%d %s" % [i + 1, c.display_name(), c.level, c.hp, c.max_hp(), String(c.status).to_upper()])
	lines.append("")
	lines.append("BAG")
	for id in State.items:
		lines.append("  %s x%d" % [Data.db.get_record(&"items", id).get("name", id), State.items[id]])
	lines.append("")
	lines.append("Money: ₽%d    Pokédex: %d caught    PC: %d" % [State.money, State.pokedex_caught.size(), State.pc.count()])
	_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu"):
		if not _panel.visible and not can_open.call():
			return
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not _panel.visible:
		return
	for i in 6:
		if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).physical_keycode == KEY_1 + i:
			swap_lead(i)
			get_viewport().set_input_as_handled()


func swap_lead(i: int) -> void:
	if not can_swap.call():
		return
	State.party.swap(0, i)
	refresh()
