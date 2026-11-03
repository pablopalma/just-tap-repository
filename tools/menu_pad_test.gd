extends Node
## The title for a new player with a gamepad: the d-pad reaches the language and the data buttons,
## A presses them, B lets go and A then starts the game. Logs the focus and the language.
## godot --headless --path . --fixed-fps 30 res://tools/menu_pad_test.tscn

var _main: Node
var _t := 0.0
var _steps := [
	[2.0, JOY_BUTTON_DPAD_LEFT], [3.0, JOY_BUTTON_A], [4.0, JOY_BUTTON_DPAD_RIGHT],
	[5.0, JOY_BUTTON_B], [6.0, JOY_BUTTON_A],
]


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	SaveSystem.had_progress = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	for st in _steps:
		if _t > st[0] and _t - delta <= st[0]:
			for down in [true, false]:
				var e := InputEventJoypadButton.new()
				e.button_index = st[1]
				e.pressed = down
				Input.parse_input_event(e)
	for at in [2.5, 3.5, 4.5, 5.5, 7.0]:
		if _t > at and _t - delta <= at:
			var f := get_viewport().gui_get_focus_owner()
			print("[%.1f s] foco: %s · idioma: %s · jugando: %s" % [_t, (f as Button).text if f else "—", SaveSystem.lang, _main.intro == null])
	if _t > 8.0:
		get_tree().quit()
