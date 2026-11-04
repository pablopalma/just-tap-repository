extends Node
## A new player's warm-up (scripts/world/warmup.gd): three calm taps a second or so apart, then taps
## on the beat (one off it, to hear the difference) until it opens and the climb starts; then a few
## game taps. Logs each step. Record it to see and hear it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/warmup_test.tscn [-- en]

const LENGTH := 32.0

var _main: Node
var _t := 0.0
var _free_at := [4.0, 5.4, 6.8]
var _last_beat := -100
var _beat_taps := 0
var _phase := -2


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.had_progress = false
	if "en" in OS.get_cmdline_user_args():
		SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0 and _main.intro != null:
		_main._start()
	var w = _main.warmup
	var ph: int = w.phase if w else -1
	if ph != _phase:
		_phase = ph
		print("[%5.1f s] warm-up phase %d · game taps %d · barrier %d" % [_t, ph, GameState.total_taps, GameState.stage])
	if not _free_at.is_empty() and _t >= _free_at[0]:
		_free_at.pop_front()
		_main._press()
	elif _t > 8.5 and _t < LENGTH - 2.0:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			_beat_taps += 1
			if _beat_taps != 2:   # one beat skipped and tapped late instead, off the beat
				_main._press()
			else:
				get_tree().create_timer(0.3).timeout.connect(_main._press)
	if _t > LENGTH:
		print("[%5.1f s] end · game taps %d · barrier %d · lesson done %s" % [_t, GameState.total_taps, GameState.stage, _main._lesson_done])
		get_tree().quit()
