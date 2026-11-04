extends Node
## A slow mouse click on the title's "continue" (down, a few frames, up), as a person clicks, with the
## gamepad in use just before: it has to start the game (a button losing the focus mid-click cancels
## it). godot --path . res://tools/menu_click_test.tscn

var _main: Node
var _f := 0
var _at := Vector2.ZERO


func _ready() -> void:
	SaveSystem.enabled = false
	GameState.new_game()
	SaveSystem.had_progress = true   # a returning player: the title offers "continue"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	_f += 1
	if _f == 420:
		Pad.using = true   # the gamepad was being used: "continue" holds the focus
	if _f == 440:
		var b: Button = _main.intro._continue
		_at = b.get_global_rect().get_center()
		print("CLICK focus before: ", get_viewport().gui_get_focus_owner() == b)
		_mouse(true)
	if _f == 452:
		_mouse(false)
	if _f == 500:
		print("CLICK started: ", _main.intro == null, "  running: ", GameState.running)
		get_tree().quit()


func _mouse(down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	e.position = _at
	e.global_position = _at
	Input.parse_input_event(e)
