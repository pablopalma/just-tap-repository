class_name GiantBird
extends CanvasLayer
## A giant ink-and-watercolour bird that circles the tower now and then: it crosses close and big,
## then turns and passes far and small, behind the line. Wings beat once per musical beat, and it
## sings with notes of the current chord, panned to where it is on screen.

signal passed_close

const DURATION := 24.0

var active := false

var _t := 0.0
var _dir := 1.0
var _drawer: Drawer
var _events: Array[float] = []
var _prev_x := 0.0
var _tint := Color.WHITE


func _ready() -> void:
	layer = -6
	_drawer = Drawer.new()
	add_child(_drawer)
	visible = false


func fly() -> void:
	if active:
		return
	active = true
	visible = true
	Music.set_bird_active(true)
	_t = 0.0
	_dir = -1.0 if randf() < 0.5 else 1.0
	# Moments in the flight (0..1): a call as it enters, call and rush of air when closest,
	# a softer call while far, and a last one as it leaves.
	_events = [0.06, 0.29, 0.3, 0.62, 0.9]


func set_tint(c: Color) -> void:
	_tint = c
	_drawer.tint = c


func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	var p := _t / DURATION
	if p >= 1.0:
		active = false
		visible = false
		Music.set_bird_active(false)
		return
	var vp := get_viewport().get_visible_rect().size
	var unit := vp.y / 720.0
	var th := lerpf(-PI * 0.5 - 0.35, PI * 1.5 + 0.35, p)
	var depth := 0.5 + 0.5 * cos(th)            # 1 near, 0 far
	var x := sin(th) * (vp.x * 0.5 + 360.0 * unit) * _dir
	var y := (-90.0 + sin(th * 2.0) * 70.0 - depth * 60.0) * unit
	var s := lerpf(0.3, 0.85, depth) * unit
	offset = vp * 0.5 + Vector2(x, y)
	scale = Vector2(s, s)
	_drawer.facing = signf(x - _prev_x) if absf(x - _prev_x) > 0.01 else _drawer.facing
	_prev_x = x
	_drawer.fade = clampf(minf(p, 1.0 - p) * 8.0, 0.0, 1.0) * lerpf(0.55, 1.0, depth)

	var pan := clampf(x / (vp.x * 0.5), -1.0, 1.0) * 0.8
	Music.set_bird_pan(pan)
	while not _events.is_empty() and p >= _events[0]:
		var e: float = _events.pop_front()
		if is_equal_approx(e, 0.3):
			Music.bird_whoosh(0.07)
			passed_close.emit()
		else:
			Music.bird_call(lerpf(0.02, 0.06, depth))


class Drawer extends Node2D:
	## A long-necked crane-like bird in profile, facing +x. Ink outlines over layered washes,
	## multiply-blended so it sits in the paper like the rest of the world.
	var tint := Color.WHITE
	var fade := 1.0
	var facing := 1.0

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		material = mat

	func _process(_delta: float) -> void:
		queue_redraw()

	func _ink(a: float) -> Color:
		return Color.WHITE.lerp(Palette.INK, a * fade)

	func _wash(a: float) -> Color:
		return Color.WHITE.lerp(tint, a * fade)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
		var ph := Music.beat_phase() * TAU
		var lift := sin(ph)
		var lift_tip := sin(ph - 0.8)  # the tip lags behind: a slow, heavy beat
		_wing(Vector2(14, -12), lift * 0.8, lift_tip * 0.8, 0.5)
		_legs(ph)
		_tail(ph)
		_body()
		_neck(ph)
		_wing(Vector2(0, -6), lift, lift_tip, 1.0)
		draw_set_transform(Vector2.ZERO)

	func _body() -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var a := TAU * i / 32.0
			var rx := 78.0 if cos(a) > 0.0 else 105.0
			var ry := 21.0 - 7.0 * maxf(0.0, -cos(a))
			pts.append(Vector2(cos(a) * rx, sin(a) * ry))
		_fan(Vector2.ZERO, pts, _wash(0.3))
		_fan(Vector2(-6, 3), _scaled(pts, 0.8), _wash(0.12))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, _ink(0.8), 1.8, true)

	## Long S-shaped neck reaching forward, a small head and a long beak.
	func _neck(ph: float) -> void:
		var bob := sin(ph) * 4.0
		var p0 := Vector2(70, -6)
		var p1 := Vector2(140, 6)
		var p2 := Vector2(165, -44 + bob)
		var center := PackedVector2Array()
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var n := 14
		for i in n + 1:
			var t := i / float(n)
			var q := p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
			center.append(q)
		for i in center.size():
			var a := center[maxi(0, i - 1)]
			var b := center[mini(center.size() - 1, i + 1)]
			var nrm := (b - a).normalized().orthogonal()
			var w := lerpf(13.0, 7.0, i / float(n))
			left.append(center[i] + nrm * w)
			right.append(center[i] - nrm * w)
		var col := _wash(0.28)
		for i in n:
			_quad(left[i], left[i + 1], right[i + 1], right[i], col)
		draw_polyline(left, _ink(0.75), 1.6, true)
		draw_polyline(right, _ink(0.75), 1.6, true)
		var head := p2 + Vector2(6, -4)
		var hp := PackedVector2Array()
		for i in 18:
			hp.append(head + Vector2.from_angle(TAU * i / 18.0) * Vector2(15, 11))
		_fan(head, hp, _wash(0.32))
		var hc := hp.duplicate()
		hc.append(hp[0])
		draw_polyline(hc, _ink(0.85), 1.8, true)
		draw_circle(head + Vector2(5, -3), 2.4, _ink(1.0))
		_tri(head + Vector2(13, -3), head + Vector2(70, 10), head + Vector2(12, 5), _ink(0.7))
		# a red crown, like a crane's, in the chapter colour
		draw_circle(head + Vector2(-2, -9), 4.5, _wash(0.7))

	## Legs held straight back in flight.
	func _legs(ph: float) -> void:
		var sway := sin(ph * 0.5) * 3.0
		for i in 2:
			var hip := Vector2(-50.0 - i * 10.0, 14.0)
			var foot := Vector2(-230.0 - i * 14.0, 26.0 + i * 6.0 + sway)
			draw_line(hip, foot, _ink(0.6), 1.6, true)
			draw_line(foot, foot + Vector2(-14, 5), _ink(0.6), 1.2, true)
			draw_line(foot, foot + Vector2(-12, -3), _ink(0.6), 1.2, true)

	func _tail(ph: float) -> void:
		var root := Vector2(-98, 0)
		for i in 5:
			var a := (i - 2) * 0.12 + sin(ph + i * 0.9) * 0.05
			var dir := Vector2.LEFT.rotated(a)
			var len := 70.0 + 24.0 * (2 - absi(i - 2))
			_feather(root, dir, len, 9.0, 0.25)

	## Side view of a long wing. lift: -1 down .. 1 up. Feathers overlap like leaves and the
	## primaries splay into fingers at the tip.
	func _wing(shoulder: Vector2, lift: float, lift_tip: float, strength: float) -> void:
		var elbow := shoulder + Vector2(-45.0, -130.0 * lift - 16.0)
		var tip := elbow + Vector2(-120.0, -170.0 * lift_tip - 8.0 * absf(lift_tip))
		var back := Vector2(-1.0, 0.25).normalized()
		# coverts: a soft wash where the wing meets the body
		_quad(shoulder, elbow, elbow + back * 50.0, shoulder + back * 70.0, _wash(0.18 * strength))
		var count := 11
		for i in count:
			var u := i / float(count - 1)
			var base := shoulder.lerp(elbow, u * 2.0) if u < 0.5 else elbow.lerp(tip, (u - 0.5) * 2.0)
			var along := (tip - elbow).normalized() if u >= 0.5 else (elbow - shoulder).normalized()
			# inner feathers point back; primaries turn toward the tip direction and fan out
			var dir := back.slerp(along, clampf((u - 0.45) * 1.4, 0.0, 0.75)).normalized()
			dir = dir.rotated((u - 0.5) * 0.25 * signf(lift_tip + 0.001))
			var len := lerpf(70.0, 135.0, u * u)
			_feather(base, dir, len, lerpf(14.0, 9.0, u), strength)
		draw_polyline(PackedVector2Array([shoulder, elbow, tip]), _ink(0.9 * strength), 2.6, true)

	## One leaf-shaped feather: wash fill, ink outline and a quill.
	func _feather(base: Vector2, dir: Vector2, len: float, width: float, strength: float) -> void:
		var perp := dir.orthogonal()
		var a := base
		var b := base + dir * len * 0.45 + perp * width
		var c := base + dir * len
		var d := base + dir * len * 0.45 - perp * width * 0.6
		_quad(a, b, c, d, _wash(0.24 * strength))
		draw_polyline(PackedVector2Array([a, b, c, d, a]), _ink(0.5 * strength), 1.1, true)
		draw_line(a, c, _ink(0.3 * strength), 0.8, true)

	func _scaled(pts: PackedVector2Array, k: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(p * k)
		return out

	func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col, col, col]), PackedVector2Array())

	func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
		_tri(a, b, c, col)
		_tri(a, c, d, col)

	## Fan triangles from a centre: never fails to triangulate, unlike a polygon.
	func _fan(center: Vector2, pts: PackedVector2Array, col: Color) -> void:
		for i in pts.size():
			_tri(center, pts[i], pts[(i + 1) % pts.size()], col)