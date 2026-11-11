class_name SpiralWell
extends Node2D
## The black hole's chapter, barriers 97–100 (11/11/2026, docs/brief-juego-completo.md §6): the light
## has gone into orbit. The view turns to look straight down a well, a spiral staircase sinking turn by
## turn (as tools/spiral_down.gd) towards the black hole at its bottom, seen face on: its shadow and,
## round it, the burning disk turning. The light goes down it with the music, a turn every two bars;
## the phrase's notes come up the spiral to meet it, each landing as its beat sounds. Behind the well,
## a giant bird of stars (as tools/spiral_rhythm.gd): every note caught lights its next star and
## draws the line to it.
## SpacetimeView owns it and fades it in (`shown`); when the fall begins the well goes, and the bird,
## whole, opens its eye and flies down into the hole ahead of the light, carrying it (`carry` 0..1)
## through the inside to the white.

## The helix: its radius (world units), depth per radian, how many turns are drawn below the light
## and above it, and points per turn.
const R := 1.0
const PITCH := 0.32
const AHEAD := 6.0
const BEHIND := 0.5
const STEPS := 64
const INNER := 0.84         # the inner rail: the path is a ribbon, like a staircase
const RUNG := 0.22
const EYE := 3.2            # the camera's height above the light
const RING_PX := 250.0      # the light's circle on screen, at 720 high
const PER_BEAT := TAU / 8.0  # a turn every two bars
## The bird: strokes of stars in a square from -1 to 1 (wings open, rising), lit in order: the body,
## the wings from the shoulders out, the feathers, the tail, and the crest last.
const BIRD := [
	[Vector2(0, -0.42), Vector2(0, -0.22), Vector2(0, 0.0), Vector2(0, 0.2)],
	[Vector2(0, -0.26), Vector2(-0.28, -0.42), Vector2(-0.55, -0.5), Vector2(-0.8, -0.46), Vector2(-1.0, -0.3)],
	[Vector2(0, -0.26), Vector2(0.28, -0.42), Vector2(0.55, -0.5), Vector2(0.8, -0.46), Vector2(1.0, -0.3)],
	[Vector2(-1.0, -0.3), Vector2(-0.78, -0.2), Vector2(-0.52, -0.12), Vector2(-0.26, -0.08), Vector2(0, 0.0)],
	[Vector2(1.0, -0.3), Vector2(0.78, -0.2), Vector2(0.52, -0.12), Vector2(0.26, -0.08), Vector2(0, 0.0)],
	[Vector2(-0.55, -0.5), Vector2(-0.52, -0.12)],
	[Vector2(0.55, -0.5), Vector2(0.52, -0.12)],
	[Vector2(-0.8, -0.46), Vector2(-0.78, -0.2)],
	[Vector2(0.8, -0.46), Vector2(0.78, -0.2)],
	[Vector2(0, 0.2), Vector2(-0.16, 0.46), Vector2(-0.28, 0.72)],
	[Vector2(0, 0.2), Vector2(0, 0.5), Vector2(0, 0.8)],
	[Vector2(0, 0.2), Vector2(0.16, 0.46), Vector2(0.28, 0.72)],
	[Vector2(0, -0.42), Vector2(-0.06, -0.56), Vector2(0, -0.64), Vector2(0.06, -0.56), Vector2(0, -0.42)],
]
const BIRD_EYE := Vector2(0.0, -0.53)
const BIRD_SIZE := 0.42     # of the screen's height, for half its span
const LINE_TIME := 0.3      # seconds a line takes to draw itself to a new star
const STARS := 160

## How much of the well shows (0..1); the bird has its own.
var shown := 0.0
var bird_shown := 0.0
## How far down the chapter's spiral is (0 at its first barrier, 1 at the last): the hole grows.
var depth := 0.0
## The fall: 0 the well, 1 the bird gone down ahead into the hole; then `carry` through the inside.
var fall := 0.0
var carry := 0.0
## The notes to draw: SpacetimeView's `notes`.
var notes: Callable

var _t := 0.0
var _cam := 0.0
var _kick := 0.0
var _segs: Array[Array] = []
var _lit: Array[float] = []
var _stars: Array[Vector3] = []
var _hits := 0
var _rings: Array[float] = []   # notes caught: their gold ring at the light, seconds


func _ready() -> void:
	for stroke in BIRD:
		for i in range(1, stroke.size()):
			_segs.append([stroke[i - 1], stroke[i]])
	_lit.resize(_segs.size())
	_lit.fill(-1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 97
	for i in STARS:
		_stars.append(Vector3(rng.randf() * TAU, sqrt(rng.randf()) * 1.25, rng.randf_range(0.3, 1.0)))


## A note caught: the light kicks, and every other one the bird lights its next star (the orbit's
## four phrases have about twice as many notes as the bird has lines: it is whole at the end).
func hit() -> void:
	_kick = 1.0
	_rings.append(0.0)
	_hits += 1
	if _hits % 2 == 1:
		return
	for i in _lit.size():
		if _lit[i] < 0.0:
			_lit[i] = 0.0
			return


## How much of the bird is lit (0..1).
func bird_done() -> float:
	var n := 0
	for l in _lit:
		if l >= 0.0:
			n += 1
	return float(n) / maxf(1.0, _lit.size())


func _process(delta: float) -> void:
	_t += delta
	_kick *= exp(-7.0 * delta)
	for i in _lit.size():
		if _lit[i] >= 0.0:
			_lit[i] += delta
	for i in _rings.size():
		_rings[i] += delta
	_rings = _rings.filter(func(r: float) -> bool: return r < 1.0)
	_cam = lerp_angle(_cam, _theta(), 1.0 - exp(-3.0 * delta))
	visible = shown > 0.001 or bird_shown > 0.001
	if visible:
		queue_redraw()


## The beat now, as heard, as a number that keeps growing.
func _beat() -> float:
	return Music._heard_time() / (60.0 / maxf(1.0, Music.bpm()))


## Where the light is along the helix.
func _theta() -> float:
	return _beat() * PER_BEAT


func _px() -> float:
	return get_viewport_rect().size.y / 720.0


func _centre() -> Vector2:
	return get_viewport_rect().size * 0.5


## A point of the helix on screen and its scale (1 at the light); empty when behind the camera.
func _project(theta: float, radius := R) -> Array:
	var d := (theta - _theta()) * PITCH
	var rel := EYE + d
	if rel < 0.35:
		return []
	var s := EYE / rel
	var a := theta - _cam + PI * 0.5   # the light sits at the bottom of the screen
	return [_centre() + Vector2.from_angle(a) * radius * RING_PX * _px() * s, s]


func _draw() -> void:
	var vp := get_viewport_rect().size
	var c := _centre()
	var a := shown
	var px := _px()
	if a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.012, 0.014, 0.024, a))
		# stars, turning slowly round the well
		for st in _stars:
			var p := c + Vector2.from_angle(st.x + _t * 0.02) * st.y * vp.y * 0.75
			draw_circle(p, 1.1 * px * st.z, Color(0.85, 0.88, 0.95, 0.5 * st.z * a))
		_draw_hole(c, a)
	if bird_shown > 0.0:
		_draw_bird(vp, c)
	if a > 0.0:
		_draw_helix(c, a)
		_draw_notes(a)
		_draw_light(a)


## The black hole at the bottom, face on: the shadow, the thin bright ring round it and the disk,
## streaks of gas turning, brighter on the side coming towards us. It grows as you go down.
func _draw_hole(c: Vector2, a: float) -> void:
	var px := _px()
	var r := lerpf(26.0, 70.0, depth) * px
	var hot := Color(1.0, 0.86, 0.55)
	var warm := Color(0.95, 0.55, 0.2)
	for i in 7:
		var rr := r * (1.25 + i * 0.32)
		draw_circle(c, rr, Color(warm, 0.06 * a / (1.0 + i * 0.6)))
	var spin := _t * 0.6
	for k in 26:
		var rr := r * (1.15 + 0.07 * k)
		var a0 := spin * (1.6 - k * 0.04) + k * 1.9
		var len := 0.9 + 0.8 * sin(k * 2.3)
		var bright := 0.5 + 0.5 * sin(a0)   # the side turning towards us is brighter
		draw_arc(c, rr, a0, a0 + len, 24, Color(hot.lerp(warm, k / 26.0), (0.2 + 0.35 * bright) * a * (1.0 - k / 30.0)),
			(2.2 - k * 0.05) * px, true)
	draw_circle(c, r * 1.04, Color(1.0, 0.92, 0.7, 0.9 * a))
	draw_circle(c, r, Color(0.0, 0.0, 0.0, a))


func _draw_helix(c: Vector2, a: float) -> void:
	var ink := Color(0.93, 0.9, 0.84)
	var th0 := _theta()
	var from := th0 - BEHIND * TAU
	var to := th0 + AHEAD * TAU
	var n := int((to - from) / TAU * STEPS)
	for rail in [R, R * INNER]:
		var prev: Array = []
		for i in n + 1:
			var th := from + (to - from) * i / n
			var p := _project(th, rail)
			if p.is_empty():
				prev = []
				continue
			if not prev.is_empty():
				var s: float = p[1]
				var lit := th <= th0
				var fade := clampf(s * 1.2, 0.0, 1.0) if not lit else clampf(1.0 - (th0 - th) / (BEHIND * TAU), 0.0, 1.0)
				var k := 1.0 if rail == R else 0.55
				draw_line(prev[0], p[0], Color(ink, (0.75 if lit else 0.42) * fade * k * a), clampf(2.4 * s * k, 0.5, 6.0), true)
			prev = p
	var th2 := ceilf(from / RUNG) * RUNG
	while th2 < to:
		var o := _project(th2, R)
		var i2 := _project(th2, R * INNER)
		if not o.is_empty() and not i2.is_empty():
			var s2: float = o[1]
			var f2 := clampf(s2 * 1.1, 0.0, 1.0) if th2 > th0 else clampf(1.0 - (th0 - th2) / (BEHIND * TAU), 0.0, 1.0)
			draw_line(o[0], i2[0], Color(ink, 0.16 * f2 * a), clampf(1.2 * s2, 0.4, 3.0), true)
		th2 += RUNG


## The phrase's notes coming up the spiral: drops of light on the path, long ones a stretch of it.
func _draw_notes(a: float) -> void:
	if not notes.is_valid():
		return
	var mid := R * (1.0 + INNER) * 0.5
	var th0 := _theta()
	var gold := Palette.GOLD
	for n in notes.call():
		var ahead: float = n.ahead
		var dim := 0.3 if n.state == 1 else 1.0
		var col := Color(0.78, 0.88, 1.0).lerp(gold, smoothstep(2.0, 0.2, ahead))
		if n.len > 0.0:
			var held: bool = n.state == 2
			var pts := PackedVector2Array()
			var f := 0.0 if held else ahead
			for k in 17:
				var p := _project(th0 + lerpf(f, ahead + n.len, k / 16.0) * PER_BEAT, mid)
				if not p.is_empty():
					pts.append(p[0])
			if pts.size() > 1:
				draw_polyline(pts, Color(col, (0.5 if held else 0.3) * a * dim), 10.0 * _px(), true)
				draw_polyline(pts, Color(1.0, 0.97, 0.88, (0.95 if held else 0.6) * a * dim), 3.0 * _px(), true)
			if held:
				continue
		var p := _project(th0 + ahead * PER_BEAT, mid)
		if p.is_empty():
			continue
		var s: float = p[1]
		var r := clampf(7.0 * s, 1.5, 12.0) * _px()
		draw_circle(p[0], r * 2.4, Color(col, 0.14 * a * dim))
		draw_circle(p[0], r, Color(col, 0.95 * a * dim))


func _draw_light(a: float) -> void:
	var lp := _project(_theta(), R * (1.0 + INNER) * 0.5)
	if lp.is_empty():
		return
	var pos: Vector2 = lp[0]
	var px := _px()
	var gold := Palette.GOLD
	draw_circle(pos, (26.0 + 8.0 * _kick) * px, Color(gold, 0.14 * a))
	draw_circle(pos, (12.0 + 4.0 * _kick) * px, Color(gold, 0.4 * a))
	draw_circle(pos, 6.0 * px, Color(1.0, 0.97, 0.88, a))
	for r in _rings:
		draw_arc(pos, lerpf(12.0, 40.0, 1.0 - pow(1.0 - r, 3.0)) * px, 0.0, TAU, 40, Color(gold, 0.8 * (1.0 - r) * a), 2.0 * px, true)


## The bird of stars behind the well; in the fall it opens its eye, beats its wings and goes down
## into the hole ahead of the light, and through the inside it carries it to the white.
func _draw_bird(vp: Vector2, c: Vector2) -> void:
	var b := bird_shown
	var size := vp.y * BIRD_SIZE
	var at := c + Vector2(0, -vp.y * 0.04)
	var flap := 0.0
	var eye := 0.0
	if fall > 0.0 or carry > 0.0:
		# down into the hole, smaller and smaller, then back out of the dark ahead, carrying the light
		var e := smoothstep(0.2, 1.0, fall)
		size *= lerpf(1.0, 0.25, e)
		at = at.lerp(c, e)
		if carry > 0.0:
			var k := smoothstep(0.0, 0.5, carry)
			size = lerpf(vp.y * BIRD_SIZE * 0.25, vp.y * 0.3, k)
			at = c + Vector2(0, lerpf(0.0, -vp.y * 0.06, k))
		flap = sin(_t * 3.2) * (0.35 if fall > 0.0 else 0.0)
		eye = smoothstep(0.0, 0.3, fall)
	var star := Color(0.92, 0.95, 1.0)
	var gold := Palette.GOLD
	var whole := fall > 0.0 or carry > 0.0
	for i in _segs.size():
		var p0 := _bird_point(_segs[i][0], at, size, flap)
		var p1 := _bird_point(_segs[i][1], at, size, flap)
		var lit := whole or _lit[i] >= 0.0
		if not lit:
			draw_circle(p1, 1.4 * _px(), Color(star, 0.12 * b))
			continue
		var grow := 1.0 if whole else clampf(_lit[i] / LINE_TIME, 0.0, 1.0)
		var fresh := 0.0 if whole else clampf(1.0 - _lit[i] / 1.2, 0.0, 1.0)
		var tip := p0.lerp(p1, grow)
		draw_line(p0, tip, Color(gold.lerp(star, 0.4), (0.45 + 0.4 * fresh) * b), (1.6 + 1.6 * fresh) * _px(), true)
		draw_circle(p0, 2.2 * _px(), Color(star, 0.85 * b))
		if grow >= 1.0:
			draw_circle(p1, (2.2 + 3.0 * fresh) * _px(), Color(star, 0.9 * b))
	if eye > 0.0:
		var ep := _bird_point(BIRD_EYE, at, size, flap)
		draw_circle(ep, 7.0 * eye * _px(), Color(gold, 0.35 * b))
		draw_circle(ep, 3.0 * eye * _px(), Color(1.0, 0.97, 0.88, b))
	if carry > 0.0:
		# the light, carried under its breast
		var lp := _bird_point(Vector2(0, 0.32), at, size, flap)
		draw_circle(lp, 22.0 * _px(), Color(gold, 0.2 * b))
		draw_circle(lp, 6.0 * _px(), Color(1.0, 0.97, 0.88, b))


func _bird_point(q: Vector2, at: Vector2, size: float, flap: float) -> Vector2:
	# the wings beat: their tips rise and fall more than the shoulders
	var y := q.y - flap * absf(q.x) * absf(q.x)
	return at + Vector2(q.x, y) * size
