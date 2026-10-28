class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen talk box. Advances on `interact`; branches show numbered choices
## (move_1..move_4 or click) which may set a story flag and jump to another node.

signal closed
signal choice_made(set_flag: StringName)

var speaker: String = ""
var _panel: PanelContainer
var _name: Label
var _text: Label
var _choices: VBoxContainer
var _queue: Array = []
var _branches: Dictionary = {}
var _current_choices: Array = []
var _open: bool = false


func _ready() -> void:
	layer = 45
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -230
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_bottom = -30
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 22)
	v.add_child(_name)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 28)
	v.add_child(_text)
	_choices = VBoxContainer.new()
	v.add_child(_choices)
	_panel.visible = false


func is_open() -> bool:
	return _open


func current_text() -> String:
	return _text.text if _open else ""


## lines: Array of {text, branch?}; branches: {node_id: {text, choices:[{text, next?, set_flag?}]}}
func open(who: String, lines: Array, branches: Dictionary = {}) -> void:
	speaker = who
	_queue = lines.duplicate()
	_branches = branches
	_open = true
	_panel.visible = true
	_name.text = who
	_advance()


func _clear_choices() -> void:
	_current_choices = []
	for c in _choices.get_children():
		c.queue_free()


func _advance() -> void:
	_clear_choices()
	if _queue.is_empty():
		_close()
		return
	var line: Dictionary = _queue.pop_front()
	_text.text = line.get("text", "")
	var b: String = line.get("branch", "")
	if b != "" and _branches.has(b):
		_show_branch(_branches[b])


func _show_branch(node: Dictionary) -> void:
	_clear_choices()
	if node.has("text"):
		_text.text = node.text
	_current_choices = node.get("choices", [])
	var i := 1
	for ch in node.get("choices", []):
		var btn := Button.new()
		btn.text = "%d. %s" % [i, ch.text]
		btn.pressed.connect(choose.bind(i - 1))
		_choices.add_child(btn)
		i += 1


func choose(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return
	var ch: Dictionary = _current_choices[index]
	if ch.has("set_flag"):
		choice_made.emit(StringName(ch.set_flag))
	if ch.has("next") and _branches.has(ch.next):
		_show_branch(_branches[ch.next])
	else:
		if ch.has("reply"):
			_queue.push_front({"text": ch.reply})
		_advance()


func has_choices() -> bool:
	return not _current_choices.is_empty()
func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if has_choices():
		for i in 4:
			if event.is_action_pressed(StringName("move_%d" % (i + 1))):
				choose(i)
				get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		_advance()


func _close() -> void:
	_open = false
	_panel.visible = false
	closed.emit()
