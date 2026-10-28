class_name InputSetup
extends RefCounted
## Registers the game's input actions (keyboard/mouse + gamepad) if missing.

const KEYS := {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"dodge": [KEY_SPACE], "move_1": [KEY_1], "move_2": [KEY_2], "move_3": [KEY_3], "move_4": [KEY_4],
	"switch": [KEY_TAB], "throw": [KEY_F], "interact": [KEY_E, KEY_ENTER], "menu": [KEY_ESCAPE],
	"run": [KEY_SHIFT],
}
const MOUSE := {"aim": MOUSE_BUTTON_RIGHT, "throw": MOUSE_BUTTON_LEFT}
const PAD_BUTTONS := {
	"dodge": JOY_BUTTON_B, "move_1": JOY_BUTTON_A, "move_2": JOY_BUTTON_X, "move_3": JOY_BUTTON_Y,
	"move_4": JOY_BUTTON_RIGHT_SHOULDER, "switch": JOY_BUTTON_LEFT_SHOULDER, "interact": JOY_BUTTON_A,
	"menu": JOY_BUTTON_START, "run": JOY_BUTTON_LEFT_STICK,
}
const PAD_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
	"aim": [JOY_AXIS_TRIGGER_LEFT, 1.0], "throw": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
}


static func register() -> void:
	var actions := {}
	for a in KEYS: actions[a] = true
	for a in MOUSE: actions[a] = true
	for a in PAD_AXES: actions[a] = true
	for a in actions:
		if InputMap.has_action(a):
			continue
		InputMap.add_action(a, 0.25)
		for k in KEYS.get(a, []):
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
		if MOUSE.has(a):
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE[a]
			InputMap.action_add_event(a, m)
		if PAD_BUTTONS.has(a):
			var b := InputEventJoypadButton.new()
			b.button_index = PAD_BUTTONS[a]
			InputMap.action_add_event(a, b)
		if PAD_AXES.has(a):
			var j := InputEventJoypadMotion.new()
			j.axis = PAD_AXES[a][0]
			j.axis_value = PAD_AXES[a][1]
			InputMap.action_add_event(a, j)
