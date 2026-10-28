class_name PromptBox
extends CanvasLayer
## A question with numbered options (keys 1-4 or click). Prompts queue up and are
## shown one at a time; each carries its own callback.

var _panel: PanelContainer
var _q: Label
var _opts: VBoxContainer
var _queue: Array = []   # [{question, options, callback}]
var _current: Dictionary = {}


func _ready() -> void:
	layer = 46
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_left = -360
	_panel.offset_right = 360
	_panel.offset_top = -160
	_panel.offset_bottom = 160
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	_q = Label.new()
	_q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_q.add_theme_font_size_override("font_size", 26)
	v.add_child(_q)
	_opts = VBoxContainer.new()
	v.add_child(_opts)
	_panel.visible = false


func ask(question: String, options: Array, callback: Callable) -> void:
	_queue.append({"question": question, "options": options, "callback": callback})
	if _current.is_empty():
		_next()


func is_open() -> bool:
	return not _current.is_empty()


func question() -> String:
	return _current.get("question", "")


func choose(index: int) -> void:
	if _current.is_empty() or index < 0 or index >= _current.options.size():
		return
	var cb: Callable = _current.callback
	_current = {}
	_panel.visible = false
	cb.call(index)
	_next()


func _next() -> void:
	if _queue.is_empty():
		return
	_current = _queue.pop_front()
	_q.text = _current.question
	for c in _opts.get_children():
		c.queue_free()
	for i in _current.options.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, _current.options[i]]
		b.pressed.connect(choose.bind(i))
		_opts.add_child(b)
	_panel.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if _current.is_empty():
		return
	for i in 4:
		if event.is_action_pressed(StringName("move_%d" % (i + 1))):
			choose(i)
			get_viewport().set_input_as_handled()
