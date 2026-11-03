extends Node
## The demo's letter at its own pace, with its theme (Songs.TRACKS.letter) and the voice, to listen
## to them together. Record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/letter_track_test.tscn

const LENGTH := 80.0

var _main: Node
var _t := 0.0
var _shown := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	GameState.total_taps = 18304
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if not _shown and _t > 0.5:
		_shown = true
		_main._start()
		_main._demo_end = true
		_main._show_letter()
	if _t > 2.0 and fmod(_t, 5.0) < delta:
		print("[%5.1f s] tema '%s'" % [_t, Music.track])
	if _t > LENGTH:
		get_tree().quit()
