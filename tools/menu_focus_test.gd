extends Node
## The title's menu for a returning player: with a gamepad, A's focus on "continue", then the d-pad
## down to "new game"; then with the mouse over "continue". Record it to see which one stands out:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/menu_focus_test.tscn

var _main: Node
var _t := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	GameState.stage = 12
	SaveSystem.had_progress = true
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 7.0 and _t - delta <= 7.0:
		_pad(JOY_BUTTON_DPAD_UP)   # a gamepad comes in: the focus goes to "continue"
	if _t > 9.0 and _t - delta <= 9.0:
		_pad(JOY_BUTTON_DPAD_DOWN)
	if _t > 9.1 and _t - delta <= 9.1:
		print("foco: ", get_viewport().gui_get_focus_owner().text if get_viewport().gui_get_focus_owner() else "ninguno")
	if _t > 11.0 and _t - delta <= 11.0:
		var m := InputEventMouseMotion.new()
		m.relative = Vector2(20, 0)
		Input.parse_input_event(m)   # back to the mouse
		PadFocus._hover = _main.intro._continue
	if _t > 13.0:
		get_tree().quit()


func _pad(b: JoyButton) -> void:
	for down in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		e.pressed = down
		Input.parse_input_event(e)
