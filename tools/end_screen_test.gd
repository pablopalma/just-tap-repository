extends Node
## The demo's end screen on its own (the rating line, the buttons), to look at it:
## godot --path . --write-movie x.avi --fixed-fps 30 --quit-after 240 res://tools/end_screen_test.tscn [-- es]

var _main: Node
var _t := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es" if "es" in OS.get_cmdline_user_args() else "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 1.5 and _t - delta <= 1.5:
		_main._show_end()
