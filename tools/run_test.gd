extends Node
## A long run on the beat, to see and hear the run's ×N and its milestones (4, 8, 12, 16, 24…:
## Music.play_milestone, the tip's gold rings). Jumps to barrier 13 (zone 2; or the one given) and
## taps every beat.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/run_test.tscn

const LENGTH := 30.0

var _main: Node
var _t := 0.0
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


## The barrier to play at: 13 by default, or the one given (`-- 23` for zone 3's waltz).
func _barrier() -> int:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			return int(a)
	return 13


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 1.0 and _t - delta <= 1.0:
		_main._dev_jump(_barrier())
	if _t > 3.0 and GameState.running and not GameState.cinematic:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			GameState.tap("tap", k)
			if GameState.beat_streak in GameState.BEAT_MILESTONES:
				print("[%5.1f s] racha %d" % [_t, GameState.beat_streak])
	if _t > LENGTH:
		get_tree().quit()
