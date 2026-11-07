extends Node2D
## Prototype (7/11/2026, for later in the game, instead of the sacred geometry): cymatics in paint.
## A plate of wet paper; the notes of light come to it on the beat (as in the phrases) and each one
## you catch sounds its note of the arrangement and sets the plate vibrating in a new mode: the pigment
## runs and gathers into that note's figure, Chladni's lines, as watercolour (shaders/cymatics.gdshader).
## The figures before stay underneath, faint; the colour changes as the phrase goes on.
## Tap: space, click, a gamepad's A. `-- auto` plays it on its own.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/cymatics.tscn -- auto

## The figure for each degree of the arrangement: (n, m) modes, simple low, intricate high.
const MODES := [Vector2(1, 2), Vector2(1, 3), Vector2(2, 3), Vector2(1, 4), Vector2(2, 5), Vector2(3, 4),
	Vector2(3, 5), Vector2(2, 7), Vector2(4, 5), Vector2(3, 7), Vector2(5, 6)]
## The line the notes play (zone 1's arrangement, PhraseLine.ARRANGEMENT), one note a beat.
const LINE := [5, 6, 7, 6, 7, 6, 5, 3, 3, 5, 6, 7, 6, 5, 5, 6, 7, 8, 7, 6, 5, 3, 4, 5, 6, 7, 8, 7, 6, 5, 6, 7, 6, 8, 10]
const COLOURS := [Color("#c95a4f"), Color("#d9a948"), Color("#6c9c72"), Color("#4d84b3"), Color("#8a6aa8")]
const SETTLE := 1.6         # beats a figure takes to settle
const WINDOW := 0.22        # beats either side of the beat that catch it
const FALL := 2.0           # beats a note takes to come down to the plate

var _mat: ShaderMaterial
var _rect: ColorRect
var _i := 0                 # the next note of the line
var _since := 99.0          # seconds since the last note caught
var _shiver := 0.0
var _last_beat := -100
var _auto := false
var _t := 0.0
var _ink: Node2D
var _rings: Array[Dictionary] = []


func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	SaveSystem.enabled = false
	Music.zone = 1
	Music._pending_zone = 1
	Music.start()
	var layer := CanvasLayer.new()
	layer.layer = -1
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/cymatics.gdshader")
	_mat.set_shader_parameter("paper", Palette.PAPER)
	_mat.set_shader_parameter("pigment", COLOURS[0])
	_mat.set_shader_parameter("ghost_pigment", COLOURS[3])
	_rect.material = _mat
	layer.add_child(_rect)
	add_child(layer)
	var top := CanvasLayer.new()
	top.layer = 1
	_ink = Node2D.new()
	_ink.draw.connect(_draw_ink)
	top.add_child(_ink)
	add_child(top)
	_set_mode(Vector2(1, 2), Vector2(1, 2), 1.0)


func _beat_len() -> float:
	return 60.0 / Music.bpm()


func _now() -> float:
	return Music._heard_time() / _beat_len()


func _process(delta: float) -> void:
	_t += delta
	_since += delta
	_shiver = maxf(0.0, _shiver - delta * 2.5)
	var vp := get_viewport_rect().size
	_mat.set_shader_parameter("aspect", vp.x / vp.y)
	_mat.set_shader_parameter("change", clampf(_since / (SETTLE * _beat_len()), 0.0, 1.0))
	_mat.set_shader_parameter("shiver", _shiver)
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < 1.2)
	if _auto and _t > 2.0:
		var k := roundi(_now())
		if k != _last_beat and absf(_now() - k) < 0.03 and randf() > 0.08:
			_tap()
	_ink.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		DevMenu.back_to_game(get_tree())
		return
	var pressed: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A)
	if pressed:
		_tap()


## A tap on the beat: the next note sounds and the plate takes its figure. Off the beat: a soft tap.
func _tap() -> void:
	var now := _now()
	var k := roundi(now)
	if absf(now - k) > WINDOW or k == _last_beat:
		Music.play_tap(0.05, false)
		return
	_last_beat = k
	var deg: int = LINE[_i % LINE.size()]
	_i += 1
	Music._schedule(Music._time, "note", "celesta" if _i % 2 == 0 else "harp", Music.chord_note(deg, Music.tonic() + 12), 0.11)
	if _i % 4 == 1:
		Music._schedule(Music._time, "note", "harp", Music.chord_note(deg - 2, Music.tonic()), 0.05)
	var before: Vector2 = _mat.get_shader_parameter("mode_now")
	var now_mode: Vector2 = MODES[clampi(deg, 0, MODES.size() - 1)]
	if now_mode == before:
		now_mode = Vector2(now_mode.y, now_mode.x + 1.0)   # the same note twice still moves the paint
	_mat.set_shader_parameter("mode_ghost", before)
	_set_mode(before, now_mode, 0.0)
	# the colour walks through the chapters, a phrase (four notes) at a time
	var c: Color = COLOURS[int((_i - 1) / 4.0) % COLOURS.size()]
	var was: Color = _mat.get_shader_parameter("pigment")
	_mat.set_shader_parameter("ghost_pigment", was)
	_mat.set_shader_parameter("pigment", c)
	_shiver = 1.0
	_rings.append({"t": 0.0})


func _set_mode(before: Vector2, now_mode: Vector2, change: float) -> void:
	_mat.set_shader_parameter("mode_before", before)
	_mat.set_shader_parameter("mode_now", now_mode)
	_since = change * SETTLE * _beat_len()


## Over the plate: the notes of light coming down to its centre on the beat, a ring as one lands.
func _draw_ink() -> void:
	var vp := get_viewport_rect().size
	var c := vp * 0.5
	var r := vp.y * 0.42
	var gold := Palette.GOLD.darkened(0.12)
	var now := _now()
	for k in 3:
		var b := floorf(now) + 1.0 + k
		var ahead := b - now
		if ahead > FALL:
			continue
		var p := c + Vector2(0, -r * 1.1 * (ahead / FALL))
		var a := 1.0 - ahead / FALL
		_ink.draw_circle(p, 7.0 * (0.6 + 0.4 * a), Color(gold, 0.25 * a))
		_ink.draw_circle(p, 4.0 * (0.6 + 0.4 * a), Color(gold, a))
	_ink.draw_arc(c, 12.0, 0.0, TAU, 40, Color(gold, 0.5), 1.6, true)
	# a note landing: a soft glow at the centre (no ring out to the edge: the figure has no contour)
	for ring in _rings:
		var k: float = ring.t / 1.2
		for i in 5:
			var j := i / 4.0
			_ink.draw_circle(c, lerpf(60.0, 10.0, j) * (0.6 + 0.6 * k), Color(gold, 0.06 * (1.0 - k) * (0.4 + j)))
