extends Control
## A story (JUST_TAP_GODOT.md §1): the voice stops the game and offers to tell a memory, Pablo's own.
## "tell me" fades the world to paper and draws the memory in ink while the voice tells it, over
## the title theme: a sidewalk, a child lying on it, a tree, and the sun slipping through its leaves
## in little pieces. "keep going" (there all along) goes on at once, never a penalty.
## `finished(told)` when it is over; Main then dives into the next zone.

signal finished(told: bool)

const LINES := ["story1_1", "story1_2", "story1_3"]
const FIRST_LINE := 2.2     # seconds after "tell me"
const SUN_LINE := "story1_2"  # the sun comes through as this line starts
## The lines it tells (a director, the trailer, can tell just one).
var lines: Array = LINES.duplicate()
const PAPER := Color(0.97, 0.955, 0.93)

var _scene: Control
var _yes: Button
var _no: Button
var _t := 0.0
var _telling := false
var _ending := false
var _line_i := 0
var _next := 0.0
var _sun_t := -1.0
var _flecks: Array[Vector3] = []   # x, y (0..1 of the screen), phase
var _leaves: Array[Vector3] = []   # x, y, radius (in screen heights)


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_scene = Control.new()
	_scene.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_scene.mouse_filter = MOUSE_FILTER_IGNORE
	_scene.draw.connect(_draw_scene)
	add_child(_scene)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_CENTER)
	box.offset_top = 90
	box.offset_left = -200
	box.offset_right = 200
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 60)
	add_child(box)
	_yes = UIStyle.button(Loc.t("story_yes"), 26)
	_no = UIStyle.button(Loc.t("story_no"), 20)
	_no.modulate.a = 0.75
	for b in [_yes, _no]:
		b.add_theme_constant_override("outline_size", 10)
		b.add_theme_color_override("font_outline_color", Color(Palette.PAPER, 0.9))
		box.add_child(b)
	_yes.pressed.connect(_tell)
	_no.pressed.connect(func() -> void: _end(_telling))
	box.modulate.a = 0.0
	create_tween().tween_property(box, "modulate:a", 1.0, 1.2).set_delay(1.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	for i in 34:
		_flecks.append(Vector3(rng.randf_range(0.22, 0.86), rng.randf_range(0.6, 0.8), rng.randf() * TAU))
	for i in 16:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, 0.14)
		_leaves.append(Vector3(0.64 + cos(a) * d * 1.3, 0.28 + sin(a) * d * 0.7, rng.randf_range(0.045, 0.085)))


func _ready() -> void:
	Narrator.say_now("story_ask")


## "tell me": the world goes to paper, the theme plays, and the memory draws itself line by line.
func _tell() -> void:
	_telling = true
	_t = 0.0
	_next = FIRST_LINE
	_yes.get_parent().remove_child(_yes)
	_yes.queue_free()
	# "keep going" stays, small, out of the way
	var box := _no.get_parent()
	box.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	box.offset_left = -220
	box.offset_top = -70
	box.offset_right = -30
	box.offset_bottom = -24
	Music.play_theme()


func _process(delta: float) -> void:
	if not _telling or _ending:
		return
	_t += delta
	if _line_i < lines.size() and _t >= _next:
		Narrator.say_now(lines[_line_i])
		if lines[_line_i] == SUN_LINE:
			_sun_t = _t
		_next = _t + _length(lines[_line_i])
		_line_i += 1
	elif _line_i >= lines.size() and _t >= _next:
		_end(true)
	_scene.queue_redraw()


## How long a line takes: its recording and a breath, or the subtitle's own time without one.
func _length(id: String) -> float:
	var p := VoiceLines.audio_path(id)
	if p != "" and SaveSystem.voice_on:
		return (load(p) as AudioStream).get_length() + 1.4
	return Narrator.MIN_SHOW + 0.8


func _end(told: bool) -> void:
	if _ending:
		return
	_ending = true
	if told:
		Music.stop_theme()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.6 if told else 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		finished.emit(told)
		queue_free())


# --- The memory, drawn ----------------------------------------------------------------------------

func _draw_scene() -> void:
	if not _telling:
		return
	var vs := _scene.size
	var h := vs.y
	var ink := Palette.INK
	_scene.draw_rect(Rect2(Vector2.ZERO, vs), Color(PAPER, 0.95 * _k(0.0, 1.4)))
	var ground := 0.64 * h  # above the subtitles (Screens.Subtitle sits at 72 %)
	var lift := ground - 0.74 * h  # the layout below was drawn for a ground at 74 %
	# the sidewalk and its curb
	var kg := _k(0.6, 1.8)
	_line(Vector2(0.08 * vs.x, ground), Vector2(lerpf(0.08, 0.92, kg) * vs.x, ground), Color(ink, 0.8), 2.2)
	_line(Vector2(0.08 * vs.x, ground + 0.035 * h), Vector2(lerpf(0.08, 0.92, kg) * vs.x, ground + 0.035 * h), Color(ink, 0.35), 1.4)
	for i in 6:
		var x := lerpf(0.14, 0.86, i / 5.0) * vs.x
		if x < lerpf(0.08, 0.92, kg) * vs.x:
			_line(Vector2(x, ground), Vector2(x - 0.012 * h, ground + 0.035 * h), Color(ink, 0.25), 1.0)
	# the child, lying back, knees up, hands under the head
	var kc := _k(1.8, 1.6)
	if kc > 0.0:
		var c := Color(ink, 0.85 * kc)
		var head := Vector2(0.3 * vs.x, ground - 0.028 * h)
		_scene.draw_arc(head, 0.022 * h, 0.0, TAU * kc, 32, c, 2.0, true)
		var hip := Vector2(0.39 * vs.x, ground - 0.012 * h)
		_line(head + Vector2(0.022 * h, 0.006 * h), head.lerp(hip, 1.0) if kc > 0.4 else head, c, 2.4)
		if kc > 0.6:
			var knee := Vector2(0.43 * vs.x, ground - 0.075 * h)
			_line(hip, knee, c, 2.2)
			_line(knee, Vector2(0.47 * vs.x, ground - 0.004 * h), c, 2.0)
			_line(head + Vector2(-0.01 * h, -0.018 * h), head + Vector2(0.03 * h, -0.03 * h), Color(c, c.a * 0.7), 1.6)
	# the tree: trunk, a few branches, and its leaves, swaying a little
	var kt := _k(3.4, 2.0)
	if kt > 0.0:
		var c := Color(ink, 0.85)
		var base := Vector2(0.66 * vs.x, ground)
		var top := Vector2(0.645 * vs.x, ground - lerpf(0.0, 0.42 * h, kt))
		_line(base, top, c, 5.0)
		if kt > 0.7:
			for b in [[-0.06, -0.08], [0.05, -0.1], [-0.02, -0.13]]:
				_line(top + Vector2(0, 0.06 * h), top + Vector2(b[0] * vs.x, b[1] * h), Color(ink, 0.7), 2.2)
	var kl := _k(4.6, 3.2)
	for i in _leaves.size():
		var l := _leaves[i]
		var each := clampf(kl * _leaves.size() - i, 0.0, 1.0)
		if each <= 0.0:
			continue
		var sway := Vector2(sin(_t * 0.8 + i * 1.3), cos(_t * 0.6 + i)) * 0.004 * h
		var p := Vector2(l.x * vs.x, l.y * h + lift) + sway
		_scene.draw_circle(p, l.z * h, Color(ink, 0.05 * each))
		_scene.draw_arc(p, l.z * h, -PI * 0.5, -PI * 0.5 + TAU * each, 40, Color(ink, 0.55), 1.5, true)
	# the sun, slipping through the leaves in little pieces
	if _sun_t >= 0.0:
		var ks := clampf((_t - _sun_t) / 2.5, 0.0, 1.0)
		var sun := Vector2(0.95 * vs.x, 0.05 * h)
		for i in 6:
			var through := Vector2(lerpf(0.52, 0.76, i / 5.0) * vs.x, 0.33 * h + lift)
			var flick := 0.6 + 0.4 * sin(_t * 1.3 + i * 2.1)
			_scene.draw_line(sun, through + (through - sun) * 1.4, Color(Palette.GOLD, 0.07 * ks * flick), 10.0, true)
		for f in _flecks:
			var flick := 0.5 + 0.5 * sin(_t * (1.6 + f.z) + f.z * 3.0)
			var p := Vector2(f.x * vs.x, f.y * h + lift)
			_scene.draw_circle(p, 0.012 * h * (0.6 + 0.4 * flick), Color(Palette.GOLD, 0.35 * ks * flick))
			_scene.draw_circle(p, 0.004 * h, Color(Color(1.0, 0.97, 0.86), 0.8 * ks * flick))


func _k(from: float, time: float) -> float:
	var k := clampf((_t - from) / time, 0.0, 1.0)
	return 1.0 - pow(1.0 - k, 3.0)


func _line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	if col.a > 0.002 and a.distance_to(b) > 0.5:
		_scene.draw_line(a, b, col, w, true)
