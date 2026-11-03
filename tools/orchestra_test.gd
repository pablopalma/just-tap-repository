extends Node
## The lights as an orchestra (Music.play_orchestra): jumps to a star (barrier 16 by default, or the
## one given: 27, 37; a fork from 41 in the full game), taps now and then off the beat, then on every
## beat. Logs how the star goes; record it to hear it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/orchestra_test.tscn [-- 27]

const OFF_BEAT := 8.0
const LENGTH := 34.0

var _main: Node
var _t := 0.0
var _acc := 0.0
var _last_beat := -100


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.voice_on = false
	if "en" in OS.get_cmdline_user_args():
		SaveSystem.lang = "en"  # for an English trailer
		SaveSystem.had_progress = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.star_completed.connect(func(n: int) -> void: print("[%5.1f s] estrella %d completa" % [_t, n]))


func _barrier() -> int:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			return int(a)
	return 16


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 1.0 and _t - delta <= 1.0:
		_main._dev_jump(_barrier())
		print("[%5.1f s] barrera %d · luces %d" % [_t, GameState.stage, GameState.star.get("lights", GameState.branches).size()])
	if _t < 3.0 or not GameState.running or GameState.cinematic:
		return
	if _t < OFF_BEAT:
		_acc += delta * 1.5
		if _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap", -1)
	else:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			GameState.tap("tap", k)
	if _t > LENGTH:
		get_tree().quit()
