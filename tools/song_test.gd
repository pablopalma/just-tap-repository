extends Node
## A zone's song (data/songs.gd), to listen to: section A humming by itself, then played by taps on
## the beat; then section B the same way. `-- 3` picks the zone (2 by default); `-- old` plays it the
## old way, to compare. Record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/song_test.tscn [-- 3 old]

const PHASE := 18.0

var _main: Node
var _t := 0.0
var _acc := 0.0
var _last_beat := -100


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	SaveSystem.voice_on = false
	Songs.on = not "old" in OS.get_cmdline_user_args()
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


## Barrier 2 of the zone (the zone's first may start a cinematic).
func _first() -> int:
	var z := 2
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			z = int(a)
	return (z - 1) * 10 + 2


func _process(delta: float) -> void:
	_t += delta
	if not "lesson" in _main or Music.get_script() == null:
		get_tree().quit(1)  # a script did not load
		return
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 1.0 and _t < 1.1:
		_main._dev_jump(_first())
	if _t > 2.0 + PHASE * 2 and GameState.stage < _first() + 4:
		_main._dev_jump(_first() + 4)
		print("[%5.1f s] sección B" % _t)
	var p := int((_t - 2.0) / PHASE)
	if _t < 2.0 or not GameState.running or GameState.cinematic:
		return
	if p % 2 == 1:
		# on every beat: the player plays the melody
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			GameState.tap("tap", k)
	else:
		# now and then, off the beat: the song hums on its own
		_acc += delta * 0.7
		if _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap", -1)
	if _t > 2.0 + PHASE * 4:
		get_tree().quit()
