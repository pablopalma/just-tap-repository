extends Node
## The beat's lesson as a new player meets it: taps anywhere in time at first, and a few seconds
## into the lesson starts tapping with the music. Logs the voice, the lesson and the runs. Record
## it to see it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/lesson_test.tscn

var _main: Node
var _t := 0.0
var _acc := 0.0
var _lesson_at := -1.0
var _last_beat := -100
var _was_lesson := false
var _best := 0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Narrator.line_started.connect(func(id: String, text: String, _d: float) -> void:
		print("[%5.1f s] voz %s: %s" % [_t, id, text]))
	GameState.gate_broken.connect(func(n: int) -> void: print("[%5.1f s] barrera %d" % [_t, n]))


func _process(delta: float) -> void:
	_t += delta
	if not "lesson" in _main:
		get_tree().quit(1)  # main.gd did not load
		return
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _main.lesson != _was_lesson:
		_was_lesson = _main.lesson
		print("[%5.1f s] lección %s (racha %d)" % [_t, "empieza" if _main.lesson else "termina", GameState.beat_streak])
		if _main.lesson and _lesson_at < 0.0:
			_lesson_at = _t
	if GameState.beat_streak > _best:
		_best = GameState.beat_streak
		print("[%5.1f s] racha %d" % [_t, _best])
	if GameState.running and not GameState.finished and not GameState.cinematic and _t > 6.0:
		if _lesson_at >= 0.0 and _t > _lesson_at + 5.0:
			var k := Music.beat_at_tap()
			if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
				_last_beat = k
				GameState.tap("tap", k)
		else:
			_acc += delta * 3.0
			while _acc >= 1.0:
				_acc -= 1.0
				GameState.tap("tap", Music.beat_at_tap())
	if _t > 60.0:
		get_tree().quit()
