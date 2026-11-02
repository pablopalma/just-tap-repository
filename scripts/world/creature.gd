extends CanvasLayer
## What you connect gives life (JUST_TAP_GODOT.md §1): a being asleep on the screen, a dotted sketch
## with dark stars, each tied by a thread to one of its barriers on the line. Breaking a barrier sends
## a spark up its thread and lights its star, with a note; when the last one lights it wakes, its own
## way. The whale (CelestialWhale) is the first of them. These live far back, behind the world (the
## line and its figures pass in front), and asleep they are only a few loose stars and faint threads
## between them: what they are shows only when the last star lights and they draw themselves in light.
## In screen space, so they stay upright whichever way a zone runs.
##   kind "firefly": awake, it blinks and drifts away, far off, trailing light.
##   kind "deer": a constellation; awake, it shines and leaps away across the sky.

signal woke

const SPARK_TIME := 0.9
const WAKE_TIME := 1.6

var kind := "firefly"
var path: PathData
var tip: Node2D
## Its barriers, in order: barrier i lights star i.
var barriers: Array[int] = []
## Where it sleeps (fraction of the screen) and how big (fraction of the screen's height).
var home := Vector2(0.78, 0.3)
var size := 0.18
## Under the world's negative (the night): drawn in the opposite colours, so they come out right.
var inverted := false

var _strokes: Array = []         # Array of PackedVector2Array, in its own units (about -1..1)
var _stars: Array[Vector2] = []  # its stars, in the same units
var _lit: Array[bool] = []
var _sparks: Array[Dictionary] = []
var _pops := {}
var _state := 0                  # 0 hidden, 1 asleep, 2 waking/awake, 3 gone
var _show := 0.0                 # the sketch fading in / out
var _wake := 0.0                 # 0 sketch .. 1 alive
var _t := 0.0
var _awake_t := 0.0
var _pos := Vector2.ZERO         # where it is on screen now
var _trail: Array[Vector2] = []
var _canvas: Node2D


func _ready() -> void:
	layer = -6  # far back: over the far landscape, behind the line and everything on it
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_it)
	add_child(_canvas)
	_build()
	visible = false


func is_asleep() -> bool:
	return _state == 1


## Asleep on the screen; `already` of its barriers are behind (a save, a jump): lit at once.
func sleep(stage: int) -> void:
	if _state == 1:
		return
	_state = 1
	visible = true
	_wake = 0.0
	_lit.clear()
	_pops.clear()
	_sparks.clear()
	for b in barriers:
		_lit.append(b < stage)
	create_tween().tween_property(self, "_show", 1.0, 2.0)


func reset() -> void:
	_state = 0
	_show = 0.0
	_wake = 0.0
	_sparks.clear()
	_trail.clear()
	visible = false


## Barrier n broke: if it is one of its barriers, a spark runs up the thread.
func light(n: int) -> void:
	var i := barriers.find(n)
	if _state != 1 or i < 0 or _lit[i]:
		return
	_sparks.append({"i": i, "t": 0.0})


func _process(delta: float) -> void:
	_t += delta
	if _state == 0 or _state == 3:
		return
	var vs := _canvas.get_viewport_rect().size
	if _state == 1:
		_pos = vs * home + Vector2(sin(_t * 0.6), cos(_t * 0.45)) * vs.y * 0.006
		for k in range(_sparks.size() - 1, -1, -1):
			var s: Dictionary = _sparks[k]
			s.t += delta
			if s.t >= SPARK_TIME:
				_lit[s.i] = true
				_pops[s.i] = 0.0
				Music.star_note(int(s.i) + (0 if kind == "firefly" else 3))
				_sparks.remove_at(k)
		if not _lit.has(false) and _sparks.is_empty():
			_begin_wake()
	else:
		_awake_t += delta
		_behave(delta, vs)
	for i in _pops.keys():
		_pops[i] = minf(1.0, _pops[i] + delta / 1.2)
	_canvas.queue_redraw()


func _begin_wake() -> void:
	_state = 2
	_awake_t = 0.0
	create_tween().tween_property(self, "_wake", 1.0, WAKE_TIME).set_trans(Tween.TRANS_SINE)
	Music.choir_swell()
	for i in 4:
		Music.rising_note(i * 2 + 4, 0.05)
	woke.emit()


## Awake, each its own way.
func _behave(delta: float, vs: Vector2) -> void:
	if kind == "firefly":
		# it blinks awake where it was, then drifts off, far away, wandering up and out of sight
		var go := clampf((_awake_t - 2.0) / 16.0, 0.0, 1.0)
		var target := vs * home + Vector2(-go * vs.x * 0.35 + sin(_awake_t * 1.3) * vs.y * 0.05,
			-go * vs.y * 0.38 + cos(_awake_t * 1.7) * vs.y * 0.04)
		_pos = _pos.lerp(target, 1.0 - exp(-3.0 * delta))
		_trail.push_front(_pos)
		if _trail.size() > 30:
			_trail.pop_back()
		if go >= 1.0:
			_state = 3
			visible = false
	else:
		# shines a moment, then leaps away in long bounds across the sky, up and to the right
		var leap := clampf((_awake_t - 1.8) / 3.6, 0.0, 1.0)
		var hop := absf(sin(leap * PI * 2.0)) * vs.y * 0.08
		_pos = vs * home + Vector2(leap * vs.x * 0.55, -leap * vs.y * 0.3 - hop)
		if leap >= 1.0:
			_state = 3
			visible = false


# --- Drawing --------------------------------------------------------------------------------------

func _draw_it() -> void:
	if _state == 0 or _state == 3:
		return
	var vs := _canvas.get_viewport_rect().size
	var unit := vs.y / 720.0
	var s := vs.y * size
	var pale := Color(0.95, 0.95, 1.0) if kind == "deer" else Color(Palette.INK, 1.0)
	var gold := Palette.GOLD.lightened(0.4)
	var light := Color(1.0, 0.97, 0.88)
	var g := _show * (1.0 - _wake)
	var flip := -1.0 if kind == "deer" and _state == 2 else 1.0
	# Asleep: no outline yet, only loose stars and faint threads. The threads run down to its
	# barriers on the line; between lit stars a fine line of light appears, so a shape slowly
	# begins to show, without saying what it is.
	if g > 0.0:
		var ct := _canvas.get_viewport().get_canvas_transform()
		for i in _stars.size() - 1:
			if _lit[i] and _lit[i + 1]:
				_canvas.draw_line(_p(_stars[i], s), _p(_stars[i + 1], s), _c(Color(gold, 0.4 * g)), 1.2 * unit, true)
		for i in _stars.size():
			var np := _p(_stars[i], s)
			if i < barriers.size() and path:
				var anchor := ct * path.gate_pos(barriers[i])
				_dotted(anchor, np, _c(Color(gold if _lit[i] else pale, (0.22 if _lit[i] else 0.08) * g)), unit)
			if _lit[i]:
				_canvas.draw_circle(np, 9.0 * unit, _c(Color(gold, 0.3 * g)))
				_canvas.draw_circle(np, 3.0 * unit, _c(Color(light, g)))
				var pop: float = _pops.get(i, 1.0)
				if pop < 1.0:
					_canvas.draw_arc(np, lerpf(5.0, 40.0, 1.0 - pow(1.0 - pop, 3.0)) * unit, 0.0, TAU, 40,
						_c(Color(gold, (1.0 - pop) * 0.8 * g)), 2.0 * unit, true)
			else:
				_canvas.draw_circle(np, 1.8 * unit, _c(Color(pale, 0.4 * g)))
		for sp in _sparks:
			var i: int = sp.i
			if i >= barriers.size() or path == null:
				continue
			var k: float = sp.t / SPARK_TIME
			var at := (ct * path.gate_pos(barriers[i])).lerp(_p(_stars[i], s), k * k * (3.0 - 2.0 * k))
			_canvas.draw_circle(at, 9.0 * unit, _c(Color(gold, 0.35 * g)))
			_canvas.draw_circle(at, 3.0 * unit, _c(Color(light, g)))
	if _wake <= 0.0:
		return
	# Awake: it draws itself in light, line by line, and only now you see what it is.
	var a := _wake
	if kind == "firefly":
		for k in _trail.size():
			var f := 1.0 - float(k) / _trail.size()
			_canvas.draw_circle(_trail[k], (2.0 + 5.0 * f) * unit, _c(Color(gold, 0.25 * f * a)))
		var blink := 0.65 + 0.35 * sin(_t * 6.0)
		_canvas.draw_circle(_pos, s * 0.45 * blink, _c(Color(gold, 0.18 * a)))
		_canvas.draw_circle(_pos, s * 0.18, _c(Color(gold, 0.55 * a * blink)))
	var ink := Color(1.0, 0.96, 0.85) if kind == "deer" else gold.darkened(0.2)
	for st: PackedVector2Array in _strokes:
		var line := PackedVector2Array()
		var n := maxi(2, int(ceil(st.size() * a)))
		for k in mini(n, st.size()):
			line.append(_p(Vector2(st[k].x * flip, st[k].y), s))
		if line.size() >= 2:
			_canvas.draw_polyline(line, _c(Color(ink, 0.9 * a)), 1.8 * unit, true)
	for q in _stars:
		var p := _p(Vector2(q.x * flip, q.y), s)
		_canvas.draw_circle(p, 7.0 * unit, _c(Color(gold, 0.3 * a)))
		_canvas.draw_circle(p, 2.8 * unit, _c(Color(light, a)))


## The colour to draw so it shows as `col` (under the world's negative, its opposite).
func _c(col: Color) -> Color:
	return Color(1.0 - col.r, 1.0 - col.g, 1.0 - col.b, col.a) if inverted else col


func _p(q: Vector2, s: float) -> Vector2:
	return _pos + q * s


func _dotted(a: Vector2, b: Vector2, col: Color, unit: float) -> void:
	var n := int(a.distance_to(b) / (14.0 * unit))
	for k in n:
		_canvas.draw_circle(a.lerp(b, (k + 0.5) / maxf(1.0, n)), 1.2 * unit, col)


# --- The beings -----------------------------------------------------------------------------------

func _build() -> void:
	_strokes.clear()
	_stars.clear()
	if kind == "firefly":
		# a small body seen from above: head, thorax, a glowing tail, two pairs of wings, antennae
		_strokes.append(_oval(Vector2(0, -0.55), 0.14, 0.12))
		_strokes.append(_oval(Vector2(0, -0.25), 0.18, 0.2))
		_strokes.append(_oval(Vector2(0, 0.3), 0.22, 0.38))
		for sd in [-1.0, 1.0]:
			_strokes.append(_oval(Vector2(sd * 0.42, -0.2), 0.36, 0.16, sd * 0.5))
			_strokes.append(_oval(Vector2(sd * 0.36, 0.08), 0.28, 0.12, sd * 0.9))
			_strokes.append(PackedVector2Array([Vector2(sd * 0.05, -0.66), Vector2(sd * 0.18, -0.9), Vector2(sd * 0.3, -0.98)]))
		_stars.assign([Vector2(0, -0.55), Vector2(-0.6, -0.25), Vector2(0.6, -0.25), Vector2(0, 0.45)])
	else:
		# a deer standing, facing left: a constellation, straight lines between its stars
		var head := Vector2(-0.82, -0.42)
		var neck := Vector2(-0.6, -0.08)
		var withers := Vector2(-0.42, 0.0)
		var rump := Vector2(0.42, 0.0)
		_strokes.append(PackedVector2Array([head + Vector2(-0.12, 0.06), head, Vector2(-0.68, -0.52), neck, withers, rump]))
		_strokes.append(PackedVector2Array([neck, Vector2(-0.4, 0.14), Vector2(0.35, 0.14), rump]))
		_strokes.append(PackedVector2Array([Vector2(-0.4, 0.14), Vector2(-0.46, 0.6)]))
		_strokes.append(PackedVector2Array([Vector2(-0.28, 0.14), Vector2(-0.22, 0.6)]))
		_strokes.append(PackedVector2Array([Vector2(0.3, 0.14), Vector2(0.24, 0.6)]))
		_strokes.append(PackedVector2Array([rump, Vector2(0.46, 0.3), Vector2(0.48, 0.6)]))
		_strokes.append(PackedVector2Array([rump, Vector2(0.52, -0.1)]))
		_strokes.append(PackedVector2Array([Vector2(-0.7, -0.5), Vector2(-0.62, -0.85), Vector2(-0.5, -1.0)]))
		_strokes.append(PackedVector2Array([Vector2(-0.62, -0.85), Vector2(-0.78, -0.95)]))
		_strokes.append(PackedVector2Array([Vector2(-0.74, -0.5), Vector2(-0.9, -0.78), Vector2(-1.0, -0.86)]))
		_stars.assign([head, Vector2(-0.5, -1.0), withers, rump, Vector2(-0.46, 0.6)])


func _oval(c: Vector2, rx: float, ry: float, turn := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 25:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(turn))
	return pts
