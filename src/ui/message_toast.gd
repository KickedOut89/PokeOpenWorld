class_name MessageToast
extends CanvasLayer
## Shows EventBus.message text at the bottom of the screen for a few seconds.

const SHOW_SECONDS := 2.5

var _label: Label
var _t: float = 0.0


func _ready() -> void:
	layer = 40
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_top = -140
	panel.offset_bottom = -60
	panel.offset_left = -420
	panel.offset_right = 420
	add_child(panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 26)
	panel.add_child(_label)
	panel.visible = false
	EventBus.message.connect(show_text)


func show_text(text: String) -> void:
	_label.text = text
	_label.get_parent().visible = true
	_t = SHOW_SECONDS


func current_text() -> String:
	return _label.text if _label.get_parent().visible else ""


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_label.get_parent().visible = false
