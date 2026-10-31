class_name Chaos
extends CanvasLayer
## The demo's dark stretch (barriers 41–45): the background turns to chaos. Figures like the music's
## and the barriers' multiply, drift and collide in the dark, white on black like the world around them; every collision is a
## soft, low note of the chord (Music.chaos_hit) — the inner chaos, trying to calm itself. They keep
## out of a corridor around the line so the climb stays readable. Every barrier broken calms them a
## little (calm()). When the last one breaks they all glide into place in a slowly turning mandala,
## glow, and fade (resolve()).

signal settled

const MAX := 34
const SETTLE_TIME := 2.6
const HOLD := 6.0
const FADE := 3.5

var active := false
## 0 calm .. 1 full chaos, eased toward _target.
var intensity := 0.0

var _target := 0.0
var _figs: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _drawer: Node2D
var _kick_t := 0.0
var _resolving := false
var _res_t := 0.0
var _arrived := 0
var _settled := false
var _spin := 0.0
var _alpha := 1.0


func _ready() -> void:
	layer = 7  # over the darkness: pale figures moving in the dark
	_drawer = Node2D.new()
	add_child(_drawer)
	_drawer.draw.connect(_draw_all)


## The dark begins (or a save loads inside it). level: how much chaos, 0..1.
func start(level: float, immediate := false) -> void:
	active = true
	_resolving = false
	_settled = false
	_alpha = 1.0
	_target = level
	if immediate:
		intensity = level


func calm(level: float) -> void:
	_target = level


func stop() -> void:
	active = false
	_resolving = false
	_figs.clear()
	_sparks.clear()
	intensity = 0.0
	_drawer.queue_redraw()


## Everything finds its place: a mandala of rings around the centre of the screen.
func resolve() -> void:
	if not active:
		return
	_resolving = true
	_res_t = 0.0
	_arrived = 0
	var vp := _vp()
	var c := vp * 0.5
	# Rings of 6, 10, 14… places, as many as there are figures.
	var places: Array[Vector2] = []
	var ring := 0
	while places.size() < _figs.size():
		var count := 6 + ring * 4
		var radius := vp.y * (0.13 + 0.095 * ring)
		for k in count:
			places.append(Vector2.from_angle(TAU * k / count + ring * 0.3) * radius)
		ring += 1
	# Nearest place first, so nobody crosses the whole screen.
	var order := range(_figs.size())
	order.sort_custom(func(a: int, b: int) -> bool: return _figs[a].p.distance_to(c) < _figs[b].p.distance_to(c))
	for idx in order.size():
		var f: Dictionary = _figs[order[idx]]
		f.from = f.p
		f.place = places[idx]
		f.delay = idx * 0.07
		f.done = false
		f.rot_from = f.rot


func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not active:
		return
	var vp := _vp()
	var unit := vp.y / 720.0
	if _resolving:
		_process_resolve(delta, vp)
	else:
		intensity = move_toward(intensity, _target, delta * 0.12)
		_process_chaos(delta, vp, unit)
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i].t += delta
		if _sparks[i].t > 0.9:
			_sparks.remove_at(i)
	_drawer.queue_redraw()


func _process_chaos(delta: float, vp: Vector2, unit: float) -> void:
	# More figures the more chaos; extra ones fade away instead of vanishing.
	var want := int(round(lerpf(6.0, MAX, intensity)))
	var live := 0
	for f in _figs:
		if not f.leaving:
			live += 1
	if live < want and randf() < delta * 6.0:
		_spawn(vp, unit)
	elif live > want:
		for f in _figs:
			if not f.leaving:
				f.leaving = true
				break
	var speed := lerpf(18.0, 150.0, intensity) * unit
	var c := vp * 0.5
	var corridor := vp.x * 0.11
	# Now and then something lurches.
	_kick_t -= delta
	if _kick_t <= 0.0 and not _figs.is_empty():
		_kick_t = lerpf(1.6, 0.35, intensity)
		var f: Dictionary = _figs[randi() % _figs.size()]
		f.v += Vector2.from_angle(randf() * TAU) * speed * 1.4
	for f in _figs:
		f.t += delta
		f.a = minf(1.0, f.a + delta * 0.8) if not f.leaving else f.a - delta * 0.6
		# a slow swirl around the centre, and a push away from the line's corridor
		var to_c: Vector2 = c - f.p
		f.v += to_c.orthogonal().normalized() * speed * 0.25 * delta * signf(f.r)
		var dx: float = f.p.x - c.x
		if absf(dx) < corridor + f.size:
			f.v.x += signf(dx if dx != 0.0 else 1.0) * speed * 3.0 * delta
		# keep inside the screen
		if f.p.x < f.size: f.v.x = absf(f.v.x)
		if f.p.x > vp.x - f.size: f.v.x = -absf(f.v.x)
		if f.p.y < f.size: f.v.y = absf(f.v.y)
		if f.p.y > vp.y - f.size: f.v.y = -absf(f.v.y)
		if f.v.length() > speed * 1.6:
			f.v = f.v.normalized() * speed * 1.6
		f.p += f.v * delta
		f.rot += f.spin * delta * (0.5 + intensity)
		f.flash = maxf(0.0, f.flash - delta * 2.5)
		f.cool -= delta
	for i in range(_figs.size() - 1, -1, -1):
		if _figs[i].leaving and _figs[i].a <= 0.0:
			_figs.remove_at(i)
	_collide(unit)


## Figures bounce off each other; a hard enough hit is a soft note and a spark.
func _collide(unit: float) -> void:
	for i in _figs.size():
		var a: Dictionary = _figs[i]
		for j in range(i + 1, _figs.size()):
			var b: Dictionary = _figs[j]
			var d: Vector2 = b.p - a.p
			var min_d: float = a.size + b.size
			var dist := d.length()
			if dist >= min_d or dist < 0.001:
				continue
			var nrm := d / dist
			var push := (min_d - dist) * 0.5
			a.p -= nrm * push
			b.p += nrm * push
			var vn: float = (a.v - b.v).dot(nrm)
			if vn <= 0.0:
				continue
			a.v -= nrm * vn * 0.95
			b.v += nrm * vn * 0.95
			if a.cool <= 0.0 and b.cool <= 0.0 and vn > 25.0 * unit:
				a.cool = 0.3
				b.cool = 0.3
				a.flash = 1.0
				b.flash = 1.0
				var strength := clampf(vn / (220.0 * unit), 0.0, 1.0)
				_sparks.append({"p": a.p + nrm * a.size, "t": 0.0, "s": strength, "col": a.col.lerp(b.col, 0.5)})
				Music.chaos_hit(strength)


func _spawn(vp: Vector2, unit: float) -> void:
	var side := randi() % 4
	var p := Vector2(randf() * vp.x, randf() * vp.y)
	match side:
		0: p.x = -20.0
		1: p.x = vp.x + 20.0
		2: p.y = -20.0
		_: p.y = vp.y + 20.0
	var inward := (vp * 0.5 - p).normalized().rotated(randf_range(-0.6, 0.6))
	var white := Color(0.95, 0.95, 0.98)
	_figs.append({
		"p": p, "v": inward * randf_range(40.0, 120.0) * unit,
		"size": randf_range(12.0, 34.0) * unit,
		"sides": [0, 3, 4, 5, 6][randi() % 5],
		"rot": randf() * TAU, "spin": randf_range(-1.6, 1.6),
		"r": 1.0 if randf() < 0.5 else -1.0,
		"col": white.darkened(randf_range(0.0, 0.25)),
		"flash": 0.0, "cool": 0.5, "t": 0.0, "a": 0.0, "leaving": false,
	})


func _process_resolve(delta: float, vp: Vector2) -> void:
	_res_t += delta
	_spin += delta * 0.12
	var c := vp * 0.5
	for f in _figs:
		var k := clampf((_res_t - f.delay) / SETTLE_TIME, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		var place: Vector2 = c + (f.place as Vector2).rotated(_spin)
		f.p = (f.from as Vector2).lerp(place, e)
		f.a = minf(1.0, f.a + delta)
		# turn to face outwards, all alike
		f.rot = lerp_angle(f.rot_from, (f.place as Vector2).angle() + _spin, e)
		f.flash = maxf(0.0, f.flash - delta * 1.5)
		if k >= 1.0 and not f.done:
			f.done = true
			f.flash = 1.0
			if _arrived % 2 == 0 and _arrived < 24:
				Music.settle_note(_arrived / 2)
			_arrived += 1
	if not _settled and _arrived >= _figs.size():
		_settled = true
		settled.emit()
	var last: float = SETTLE_TIME + (_figs.size() * 0.07 if not _figs.is_empty() else 0.0)
	if _res_t > last + HOLD:
		_alpha = maxf(0.0, 1.0 - (_res_t - last - HOLD) / FADE)
		if _alpha <= 0.0:
			stop()


func _draw_all() -> void:
	if not active:
		return
	var vp := _vp()
	var unit := vp.y / 720.0
	var c := vp * 0.5
	var beat := pow(1.0 - Music.beat_phase(), 4.0)
	# The mandala's threads: each figure joined to its neighbour on the ring and to the centre.
	if _resolving and _arrived > 0:
		var glow := clampf(_res_t / (SETTLE_TIME + 2.0), 0.0, 1.0) * _alpha
		for i in _figs.size():
			var f: Dictionary = _figs[i]
			if not f.done:
				continue
			_drawer.draw_line(c, f.p, Color(Palette.GOLD, 0.10 * glow), 1.0 * unit, true)
			var g: Dictionary = _figs[(i + 1) % _figs.size()]
			if g.done:
				_drawer.draw_line(f.p, g.p, Color(Palette.GOLD.lightened(0.3), 0.35 * glow), 1.4 * unit, true)
		_drawer.draw_circle(c, vp.y * 0.05 * (1.0 + 0.1 * beat), Color(Palette.GOLD.lightened(0.4), 0.25 * glow))
	for f in _figs:
		var a: float = f.a * _alpha
		if a <= 0.0:
			continue
		# in the mandala they shrink a little so the rings read as rings
		var settle := 1.0
		if _resolving:
			settle = lerpf(1.0, 0.8, clampf((_res_t - float(f.delay)) / SETTLE_TIME, 0.0, 1.0))
		var r: float = f.size * settle * (1.0 + 0.06 * beat)
		var col: Color = f.col.lerp(Palette.GOLD.lightened(0.3), 0.5 * clampf(_res_t / 3.0, 0.0, 1.0)) if _resolving else f.col
		if f.flash > 0.0:
			_drawer.draw_circle(f.p, r * 1.8, Color(col.lightened(0.5), 0.22 * f.flash * a))
		# Fine white lines with a faint glow, barely filled: drawn light on the dark.
		var halo := Color(col, 0.10 * a)
		var line := Color(col, 0.85 * a)
		if f.sides == 0:
			_drawer.draw_circle(f.p, r, Color(col, 0.07 * a))
			_drawer.draw_arc(f.p, r, 0.0, TAU, 36, halo, 5.0 * unit, true)
			_drawer.draw_arc(f.p, r, 0.0, TAU, 36, line, 1.4 * unit, true)
			continue
		var pts := PackedVector2Array()
		for k in f.sides + 1:
			pts.append(f.p + Vector2.from_angle(f.rot + TAU * k / f.sides) * r)
		var fill := PackedVector2Array(pts)
		fill.resize(f.sides)
		_drawer.draw_colored_polygon(fill, Color(col, 0.07 * a))
		_drawer.draw_polyline(pts, halo, 5.0 * unit, true)
		_drawer.draw_polyline(pts, line, 1.4 * unit, true)
	for s in _sparks:
		var k: float = s.t / 0.9
		_drawer.draw_arc(s.p, lerpf(4.0, 30.0 + 30.0 * s.s, k) * unit, 0.0, TAU, 24,
			Color(s.col as Color, (1.0 - k) * 0.7), 1.2 * unit, true)
