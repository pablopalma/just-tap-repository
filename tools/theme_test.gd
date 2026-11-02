extends Node
## The title theme as a player hears it: the menu, untouched until TAP_AT, then the first tap.
## Record it: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/theme_test.tscn

const LENGTH := 26.0
const TAP_AT := 14.0  # then a tap: the theme gives way to the game's music

var _t := 0.0
var _notes := 0
var _main: Node


func _ready() -> void:
	SaveSystem.enabled = false
	GameState.new_game()
	Music.note_played.connect(func(_m: int, _i: String) -> void: _notes += 1)
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t >= TAP_AT and _main.intro != null:
		_main._start()
	if _t > LENGTH:
		print("THEME notes=%d title_on=%s playing=%s zone=%d" % [_notes, Music.title_on, Music.playing, Music.zone])
		get_tree().quit()