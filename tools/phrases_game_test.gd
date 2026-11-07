extends Node
## The phrases in the game (BuildFlags.PHRASES): a new game in the given mode, the warm-up tapped on the
## beat, then every phrase played on its notes (a miss now and then, long notes held). Logs barriers.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/phrases_game_test.tscn [-- en from=40]

const LENGTH := 150.0

var _main: Node
var _t := 0.0
var _last_beat := -100
var _free := 0.0
var _done := {}
var _hold_until := -1.0
var _shown := -1


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.had_progress = false
	SaveSystem.lang = "en" if "en" in OS.get_cmdline_user_args() else "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.gate_broken.connect(func(n: int) -> void: print("[%5.1f s] barrier %d broken" % [_t, n]))


func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0 and _main.intro != null:
		_main._start()
	if _t > 1.5 and _t - delta <= 1.5:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("from="):
				GameState.cinemas["story1"] = true   # the story is its own test (story_test)
				_main._on_dev("edge", int(arg.trim_prefix("from=")))   # jump there and break it
	var w = _main.warmup
	if w and w.phase == 0 and _t - _free > 1.4:
		_free = _t
		_main._press()
	elif w and w.phase == 1 and not BuildFlags.PHRASES:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			_main._press()
	var pl = _main.phrase_line
	if pl and pl._stage != _shown:
		_shown = pl._stage
		if _shown > 0:
			print("[%5.1f s] phrase %d arrangement %s" % [_t, _shown, pl._degs])
	if pl and pl.active:
		var now: float = pl._now()
		for n in pl._notes(pl._start):
			if pl._caught.has(n[0]) or _done.has(Vector2(pl._stage, n[0])):
				continue
			if absf(now - n[0]) < 0.04:
				_done[Vector2(pl._stage, n[0])] = true
				if n[1] != "h" and randf() < 0.1:
					break   # a miss now and then
				Input.action_press("tap")
				_main._press()
				_hold_until = _t + (pl._held_len(n) * pl._beat_len() + 0.1 if n[1] == "h" else 0.08)
				break
	if _hold_until > 0.0 and _t > _hold_until:
		_hold_until = -1.0
		Input.action_release("tap")
	if _t > LENGTH:
		print("[%5.1f s] end · barrier %d" % [_t, GameState.stage])
		get_tree().quit()
