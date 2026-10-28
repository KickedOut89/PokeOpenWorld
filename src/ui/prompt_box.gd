class_name PromptBox
extends CanvasLayer
## A question with numbered options (keys 1-4 or click). Prompts queue up and are
## shown one at a time; each carries its own callback.

var _panel: PanelContainer
var _q: Label
var _opts: VBoxContainer
var _queue: Array = []   # [{question, options, callback}]
var _current: Dictionary = {}
var _cursor: int = 0
var _opened_frame: int = -1


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
	_cursor = 0
	_opened_frame = Engine.get_process_frames()
	_q.text = _current.question
	for c in _opts.get_children():
		c.queue_free()
	for i in _current.options.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, _current.options[i]]
		b.pressed.connect(choose.bind(i))
		_opts.add_child(b)
	_panel.visible = true
	_highlight()


func focus_option(i: int) -> void:
	if not _current.is_empty():
		_cursor = clampi(i, 0, _current.options.size() - 1)
		_highlight()


func _highlight() -> void:
	var i := 0
	for b in _opts.get_children():
		(b as Button).modulate = Color(1, 1, 0.55) if i == _cursor else Color.WHITE
		i += 1


## Up/down (keys, d-pad, stick) moves the cursor; accept picks it; cancel picks the last
## option (always the "no / leave / don't learn" choice).
func _process(_delta: float) -> void:
	if _current.is_empty() or Engine.get_process_frames() == _opened_frame:
		return
	var n: int = _current.options.size()
	if Input.is_action_just_pressed(&"ui_down"):
		focus_option((_cursor + 1) % n)
	elif Input.is_action_just_pressed(&"ui_up"):
		focus_option((_cursor - 1 + n) % n)
	elif Input.is_action_just_pressed(&"ui_accept"):
		choose(_cursor)
	elif Input.is_action_just_pressed(&"ui_cancel"):
		choose(n - 1)


## Number keys 1-9 pick directly (keyboard only, so a controller's A never auto-answers).
func _unhandled_input(event: InputEvent) -> void:
	if _current.is_empty():
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		var k := (event as InputEventKey).physical_keycode
		if k >= KEY_1 and k <= KEY_9:
			choose(k - KEY_1)
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
