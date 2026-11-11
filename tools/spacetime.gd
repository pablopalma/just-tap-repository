extends Node2D
## Prototype (10–13/11/2026) of the black hole's chapter (Estrella, 10; first planned for chapter 8 as
## "la malla del espacio-tiempo", docs/brief-juego-completo.md): the view itself is
## scripts/world/SpacetimeView, which the game runs in chapter 10. Here it runs on its own: the hole
## comes nearer with the theme and with every tap on the beat, and when it is all the way, the fall;
## after the white light it starts again. Before the Vastness plays (docs/banda-sonora.md, 11).
## The taps sound the view's own voice, walking the theme's scale (D minor pentatonic).
## Tap: space, click, a gamepad's A. Esc: back to the game.
## `-- auto` plays on its own, `fast` brings the hole in about a minute, `end` starts just before the
## fall, `log` prints the theme's beat.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/spacetime.tscn -- auto

## The taps' notes: D minor pentatonic (D F G A C), as the theme; a run walks the contour up from D4.
const SCALE := [50, 53, 55, 57, 60, 62, 65, 67, 69, 72, 74, 77, 79, 81, 84, 86]
const CONTOUR := [0, 2, 1, 3, 2, 4, 3, 5, 4, 6, 5, 7]
const BASE_I := 5

var _view: SpacetimeView
var _auto := false
var _t := 0.0
var _last_beat := -100
var _run := 0


func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	SaveSystem.enabled = false
	Music.zone = 10
	Music._pending_zone = 10
	Music.start()
	Music.play_feature("spacetime")
	_view = SpacetimeView.new()
	_view.auto_near = true
	_view.standalone = true
	_view.fast = DevMenu.proto_has("fast")
	if DevMenu.proto_has("end"):
		_view.set_near(0.9)
		_view.near_to = 0.97
	add_child(_view)


func _process(delta: float) -> void:
	_t += delta
	if _auto and _t > 1.5 and not _view.falling():
		var k := Music.beat_at_tap()
		if k >= 0 and k != _last_beat and fmod(_t, 9.0) < 7.0 and randf() > 0.25:
			_tap()
	if DevMenu.proto_has("log") and Engine.get_process_frames() % 90 == 0:
		print("TRACK ", Music.track, " bpm ", Music.bpm(), " heard ", snappedf(Music._heard_time(), 0.01))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		DevMenu.back_to_game(get_tree())
		return
	var pressed: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A)
	if pressed and not _view.falling():
		_tap()


func _tap() -> void:
	var k := Music.beat_at_tap()
	if k >= 0 and k != _last_beat:
		_last_beat = k
		_run += 1
		var i: int = BASE_I + CONTOUR[(_run - 1) % CONTOUR.size()] + (2 if (_run - 1) / CONTOUR.size() % 2 == 1 else 0)
		_view.play(SCALE[mini(i, SCALE.size() - 1)], -15.0)
		if _run >= 8 and _run % 4 == 0:
			_view.play(SCALE[mini(i + 5, SCALE.size() - 1)], -22.0)   # a long run: an octave shimmer over it
		_view.tap(true)
	else:
		_run = 0
		_view.play(50, -24.0)   # off the beat: the low D, barely there
		_view.tap(false)
