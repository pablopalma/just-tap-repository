extends Node
## A tour of the recorded themes (Songs.TRACKS), to listen to the taps over them: each zone 1-4 for
## STAY seconds (a few taps off the beat, then a run on the beat), the dark, then the story's and the
## letter's themes. Record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/ost_tour.tscn

const STAY := 24.0
const STOPS := [2, 12, 22, 32, 40]   # 40: broken at once, into the dark

var _main: Node
var _t := 0.0
var _i := -1
var _acc := 0.0
var _last_beat := -100
var _since := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.voice_on = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	_since += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	var i := int((_t - 1.0) / STAY) if _t > 1.0 else -1
	if i != _i and i >= 0:
		_i = i
		_since = 0.0
		if i < STOPS.size():
			_main._dev_jump(STOPS[i])
			if STOPS[i] == 40:
				_main._dev_break()
		elif i == STOPS.size():
			Music.play_feature("story")
		elif i == STOPS.size() + 1:
			Music.play_feature("letter")
		else:
			get_tree().quit()
		print("[%5.1f s] parada %d" % [_t, i])
	if i < 0 or i >= STOPS.size() or not GameState.running or GameState.cinematic:
		return
	if _since > STAY * 0.35:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			GameState.tap("tap", k)
	else:
		_acc += delta * 1.2
		if _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap", -1)
