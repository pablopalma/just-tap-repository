extends Node
## The first minute of a new player, to look at it: the title, a tap to start, then tapping like
## someone who does not know the game yet (about 3 taps a second, not on the beat). Logs what the
## voice says, every barrier broken and every cinematic, with the time.
## godot --path . --write-movie x.avi --fixed-fps 30 --quit-after 1800 res://tools/first_minute_test.tscn

var _main: Node
var _t := 0.0
var _acc := 0.0
var _started := false
var _cine := false
var _lesson := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	SaveSystem.had_progress = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Narrator.line_started.connect(func(id: String, text: String, _d: float) -> void:
		print("[%5.1f s] voz %s: %s" % [_t, id, text]))
	GameState.gate_broken.connect(func(n: int) -> void: print("[%5.1f s] barrera %d rota" % [_t, n]))


func _process(delta: float) -> void:
	_t += delta
	# someone reads the title for a few seconds, then taps
	if not _started and _t > 4.0:
		_started = true
		print("[%5.1f s] toca para empezar" % _t)
		_main._press()
	if GameState.cinematic != _cine:
		_cine = GameState.cinematic
		print("[%5.1f s] cinemática %s (barrera %d)" % [_t, "empieza" if _cine else "termina", GameState.stage])
	if _main.lesson != _lesson:
		_lesson = _main.lesson
		print("[%5.1f s] lección %s · cola de la voz: %s" % [_t, "empieza" if _lesson else "termina", Narrator._queue])
	if _started and GameState.running and not GameState.cinematic:
		_acc += delta * 3.0
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap", -1)
	if OS.get_cmdline_user_args().has("debug") and fmod(_t, 3.0) < delta:
		print("    [%5.1f s] voz: cooldown %.1f · sonando %s · cola %s · hold %s" % [_t, Narrator._cooldown,
			Narrator._player.playing, Narrator._queue, Narrator.hold])
	if _t > 60.0:
		get_tree().quit()
