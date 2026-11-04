extends Node
## A gameplay clip for social video: tapping on every beat from barrier 15 (the run climbing to ×5,
## the notes of light), the star at 16 playing as an orchestra, then on to break 20 and the red
## coming back. Strong enough that barriers fall every few seconds. Logs when each thing happens,
## to cut the clip. Record it upright for TikTok:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/tiktok_gameplay.tscn [-- en zoom=1.2]
## (zoom=: the camera for a wide trailer, closer than the game's own but less than for a phone)

const LENGTH := 46.0
const FROM := 15
const SKIP_TO := 19        # after the star, jump here and break on into the colour coming back
## On a phone held upright the line is small: the camera closer than the game's own (×ZOOM).
const ZOOM := 1.7

var _main: Node
var _t := 0.0
var _last_beat := -100
var _skipped := false


func _ready() -> void:
	process_priority = 100   # after Main and its camera: this node has the last word on the zoom
	SaveSystem.enabled = false
	SaveSystem.voice_on = false
	SaveSystem.had_progress = false   # a first run: the voice greets, it does not say "welcome back"
	if "en" in OS.get_cmdline_user_args():
		SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_main.camera.process_priority = 200   # Main, then this node's zoom, then the camera moves
	GameState.star_completed.connect(func(n: int) -> void:
		print("[%5.1f s] star %d complete" % [_t, n])
		if not _skipped:
			_skipped = true
			get_tree().create_timer(2.5).timeout.connect(func() -> void: _main._dev_jump(SKIP_TO)))
	GameState.gate_broken.connect(func(n: int) -> void: print("[%5.1f s] barrier %d broken · run %d" % [_t, n, GameState.beat_streak]))


func _zoom() -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("zoom="):
			return float(a.trim_prefix("zoom="))
	return ZOOM


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 1.0 and _t - delta <= 1.0:
		_main._dev_jump(FROM)
		GameState.light = 1e9
		for i in 14:
			_main.inline_tree._choose("fuerza")
	if _t > 1.0:
		_main.camera.target_zoom = _main._base_zoom() * _zoom()
	if _t < 2.5 or not GameState.running or GameState.cinematic:
		return
	var k: int = Music.beat_at_tap()
	if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
		_last_beat = k
		GameState.tap("tap", k)
	if _t > LENGTH:
		get_tree().quit()
