extends Node
## Plays with a simulated gamepad (Pad): A starts and taps on the beat, the right trigger is held,
## RB walks the tree and X buys, and at the story's question A answers "tell me". Logs what happened;
## record it to see the prompts:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/pad_test.tscn

const LENGTH := 70.0

var _main: Node
var _t := 0.0
var _press_at := {}   # button -> time to let it go
var _last_beat := -100
var _story_asked := false
var _answered := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	for b in _press_at.keys():
		if _t >= _press_at[b]:
			_press_at.erase(b)
			_button(b, false)
	if _t > 1.0 and _t - delta <= 1.0:
		_tap()   # A on the title: the game starts
		print("[%5.1f s] A en el título · usando joystick: %s (%s)" % [_t, Pad.using, Pad.kind])
	if _t > 3.0 and _t < 20.0 and GameState.running:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_last_beat = k
			_tap()
			if OS.get_cmdline_user_args().has("debug"):
				await get_tree().process_frame
				await get_tree().process_frame
				print("  beat %d → streak %d (barrera %d, cine %s)" % [k, GameState.beat_streak, GameState.stage, GameState.cinematic])
	if _t > 20.0 and _t - delta <= 20.0:
		print("[%5.1f s] racha máx %d, barrera %d, toques %d · usando joystick: %s" % [_t, GameState.best_streak_at_gate, GameState.stage, GameState.total_taps, Pad.using])
		_trigger(1.0)
	if _t > 26.0 and _t - delta <= 26.0:
		_trigger(0.0)
		print("[%5.1f s] gatillo soltado · toques mantenidos en esta barrera %d" % [_t, GameState.hold_taps_at_gate])
		GameState.light = 1e9
	if _t > 28.0 and _t - delta <= 28.0:
		_button(JOY_BUTTON_RIGHT_SHOULDER, true, 0.1)
	if _t > 29.0 and _t - delta <= 29.0:
		var id: String = _main.inline_tree.pad_focus
		var before := GameState.lv(id) if id != "" else -1
		_button(JOY_BUTTON_X, true, 0.1)
		await get_tree().create_timer(0.3).timeout
		print("[%5.1f s] RB → foco '%s' · X → nivel %d → %d" % [_t, id, before, GameState.lv(id) if id != "" else -1])
	if _t > 32.0 and _t - delta <= 32.0:
		_main._on_dev("edge", 20)
	if _main._story and not _story_asked:
		_story_asked = true
		print("[%5.1f s] pregunta de la historia · foco en: %s" % [_t, get_viewport().gui_get_focus_owner()])
	if _story_asked and not _answered and Music.feature == "" and get_viewport().gui_get_focus_owner() != null and _t > 40.0:
		_answered = true
		_tap()
		await get_tree().create_timer(0.5).timeout
		print("[%5.1f s] A en la pregunta → tema '%s'" % [_t, Music.feature])
	if _t > 41.0 and _t - delta <= 41.0:
		print("[%5.1f s] historia: %s · usando %s · foco %s · ofrecidos %d" % [_t, _main._story, Pad.using, get_viewport().gui_get_focus_owner(), PadFocus._offered.size()])
	if _t > LENGTH:
		get_tree().quit()


func _tap() -> void:
	_button(JOY_BUTTON_A, true, 0.08)


func _button(b: int, down: bool, hold := 0.0) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b as JoyButton
	e.pressed = down
	Input.parse_input_event(e)
	if down:
		_press_at[b] = _t + hold


func _trigger(v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_TRIGGER_RIGHT
	e.axis_value = v
	Input.parse_input_event(e)
