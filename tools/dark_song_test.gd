extends Node
## The dark's song (Songs.DARK), to listen to: barrier 41 (the deep) and 42 (a crack of light), each
## first humming by itself and then played by taps on the beat; then 43, where the "now" cinematic
## breaks the last barriers on its own and the song comes out in major, to the whale. Record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/dark_song_test.tscn

const STAY := 22.0
const LENGTH := STAY * 2 + 40.0

var _main: Node
var _t := 0.0
var _broken := 0
var _acc := 0.0
var _last_beat := -100


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.gate_broken.connect(func(n: int) -> void: print("[%5.1f s] barrera %d" % [_t, n]))


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.3 and _t - delta <= 0.3:
		_main._on_dev("jump", 40)
	# 40 at once, then 41 and 42 after STAY each
	var due := 1 + int((_t - 1.0) / STAY) if _t > 1.0 else 0
	if _broken < mini(due, 3):
		_broken += 1
		_main._dev_break()
	if GameState.running and not GameState.finished and not GameState.cinematic and _broken in [1, 2]:
		var into := fmod(_t - 1.0, STAY)
		if into > STAY * 0.5:
			var k: int = Music.beat_at_tap()
			if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
				_last_beat = k
				GameState.tap("tap", k)
		else:
			_acc += delta * 1.5
			if _acc >= 1.0:
				_acc -= 1.0
				GameState.tap("tap", -1)
	if _t >= LENGTH:
		get_tree().quit()
