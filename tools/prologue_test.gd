extends Node
## A first run from the title: the prologue plays on its own (no taps), then the warm-up gets its taps.
## Logs each step. Record it: godot --path . --write-movie x.avi --fixed-fps 30 res://tools/prologue_test.tscn [-- en]

const LENGTH := 75.0

var _main: Node
var _t := 0.0
var _was := ""
var _last_beat := -100
var _free := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.had_progress = false
	SaveSystem.lang = "en" if "en" in OS.get_cmdline_user_args() else "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Narrator.line_started.connect(func(id: String, text: String, _d: float) -> void: print("[%5.1f s] voice %s: %s" % [_t, id, text]))


func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0 and _main.intro != null:
		_main._start()
	var now := "prologue" if _main.prologue else ("warm-up %d" % _main.warmup.phase if _main.warmup else "play")
	if now != _was:
		_was = now
		print("[%5.1f s] %s · barrier %d" % [_t, now, GameState.stage])
	if _main.warmup and _main.warmup.phase == 0 and _t - _free > 1.4:
		_free = _t
		_main._press()
	elif _main.warmup and _main.warmup.phase == 1:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			_main._press()
	if _t > LENGTH or (now == "play" and _t > 3.0):
		print("[%5.1f s] end" % _t)
		get_tree().quit()
