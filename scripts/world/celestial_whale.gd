class_name CelestialWhale
extends CanvasLayer
## What awakens at the end of the demo's dark: a whale made of light, far bigger than the bird,
## swimming slowly across the sky. Its body undulates from head to fluke, it carries constellations
## inside and leaves a trail of motes; it sings three times (Music.whale_song). Over the darkness,
## so it shines in it; the dark lifts as it passes (Main listens to `passing`).

signal passing  # halfway across: the light can come back
signal gone

const DURATION := 22.0
const SPINE := 44
const SONGS := [0.1, 0.42, 0.72]

var active := false

var _t := 0.0
var _songs: Array = []
var _passed := false
var _drawer: Node2D
var _stars: Array[Vector2] = []    # (u along the body 0..1, v across -1..1)
var _motes: Array[Dictionary] = []
var _spine := PackedVector2Array()
var _width := PackedFloat32Array()
var _fade := 0.0


func _ready() -> void:
	layer = 8
	_drawer = Node2D.new()
	add_child(_drawer)
	_drawer.draw.connect(_draw_whale)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 26:
		_stars.append(Vector2(rng.randf_range(0.08, 0.8), rng.randf_range(-0.7, 0.7)))
	visible = false


func swim() -> void:
	active = true
	visible = true
	_t = 0.0
	_passed = false
	_songs = SONGS.duplicate()
	_motes.clear()
	Music.prepare_dark()


func stop() -> void:
	active = false
	visible = false
	_motes.clear()


func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	var p := _t / DURATION
	if p >= 1.0:
		stop()
		gone.emit()
		return
	_fade = clampf(minf(p, 1.0 - p) * 7.0, 0.0, 1.0)
	while not _songs.is_empty() and p >= float(_songs[0]):
		_songs.pop_front()
		Music.whale_song(SONGS.size() - _songs.size() - 1)
	if not _passed and p >= 0.5:
		_passed = true
		passing.emit()
	var vp := get_viewport().get_visible_rect().size
	var length := vp.y * 1.25
	# Head position: across the sky from left to right, rising a little, in a long slow wave.
	var head := Vector2(lerpf(-0.1 * vp.x, vp.x + length * 1.05, p),
		vp.y * (0.48 - 0.12 * p) + sin(_t * 0.45) * vp.y * 0.04)
	_build_body(head, length)
	# Motes shed from the fluke and the fins, drifting up and fading.
	if randf() < delta * 30.0:
		var at := _spine[SPINE - 1] if randf() < 0.6 else _spine[int(SPINE * 0.3)]
		_motes.append({"p": at + Vector2(randf_range(-20, 20), randf_range(-20, 20)), "t": 0.0,
			"v": Vector2(randf_range(-30, 10), randf_range(-40, -10)), "life": randf_range(1.5, 3.0)})
	for i in range(_motes.size() - 1, -1, -1):
		var m: Dictionary = _motes[i]
		m.t += delta
		m.p += m.v * delta
		if m.t >= m.life:
			_motes.remove_at(i)
	_drawer.queue_redraw()


## The spine trails behind the head; a wave runs from head to tail, growing towards the fluke.
func _build_body(head: Vector2, length: float) -> void:
	_spine.resize(SPINE)
	_width.resize(SPINE)
	for i in SPINE:
		var u := i / float(SPINE - 1)
		var wave := sin(_t * 1.6 - u * 4.2) * length * 0.05 * u * u
		_spine[i] = head + Vector2(-u * length, wave + u * length * 0.04)
		# rounded head, widest at a third, a long tapering tail stock
		var bluff := sqrt(minf(u / 0.26, 1.0))  # a rounded snout
		var w := bluff * (1.0 - smoothstep(0.3, 0.97, u) * 0.9)
		_width[i] = length * 0.17 * maxf(w, 0.035)


func _side(i: int) -> Vector2:
	var a := _spine[maxi(0, i - 1)]
	var b := _spine[mini(SPINE - 1, i + 1)]
	return (a - b).normalized().orthogonal()


func _point(u: float, v: float) -> Vector2:
	var x := u * (SPINE - 1)
	var i := mini(int(x), SPINE - 2)
	var f := x - i
	var c := _spine[i].lerp(_spine[i + 1], f)
	var w := lerpf(_width[i], _width[i + 1], f)
	return c + _side(i) * w * v


func _draw_whale() -> void:
	if not active or _spine.size() < SPINE:
		return
	var vp := get_viewport().get_visible_rect().size
	var unit := vp.y / 720.0
	var a := _fade
	var beat := pow(1.0 - Music.beat_phase(), 3.0)
	var light := Color(1.0, 0.96, 0.86)
	var gold := Palette.GOLD.lightened(0.45)  # luminous on the dark, still golden on the paper
	var edge := Palette.GOLD.lightened(0.1)
	# Outline: upper edge head→tail, lower edge tail→head.
	var outline := PackedVector2Array()
	for i in SPINE:
		outline.append(_spine[i] + _side(i) * _width[i])
	for i in range(SPINE - 1, -1, -1):
		outline.append(_spine[i] - _side(i) * _width[i])
	# Soft body of light, then a glow and a fine line around it.
	for i in SPINE - 1:
		var q := PackedVector2Array([outline[i], outline[i + 1], outline[2 * SPINE - 2 - i], outline[2 * SPINE - 1 - i]])
		_quad(q, Color(gold, 0.32 * a))
	var closed := outline.duplicate()
	closed.append(outline[0])
	_drawer.draw_polyline(closed, Color(light, 0.45 * a), 10.0 * unit, true)
	_drawer.draw_polyline(closed, Color(edge, 0.9 * a), 2.4 * unit, true)
	# Throat grooves along the lower front.
	for k in 6:
		var v := -(0.25 + k * 0.12)
		var groove := PackedVector2Array()
		for s in 9:
			groove.append(_point(0.04 + s * 0.035, v))
		_drawer.draw_polyline(groove, Color(edge, 0.45 * a), 1.2 * unit, true)
	# Pectoral fin: a long curved blade from a third of the body, beating slowly.
	# on the belly side: a long, narrow, curved blade sweeping back and down
	var base_a := _point(0.24, -0.8)
	var base_b := _point(0.31, -0.8)
	var down := -_side(int(SPINE * 0.27))
	var fin_len := _width[int(SPINE * 0.27)] * 1.7
	var sweep := down.rotated(0.85 + 0.2 * sin(_t * 1.2))
	var tip := base_a + sweep * fin_len
	var bend := sweep.orthogonal() * fin_len * 0.12
	var fin := PackedVector2Array([base_a, base_a.lerp(tip, 0.5) - bend, tip, base_b.lerp(tip, 0.55) + bend * 0.4, base_b])
	_fan(fin, Color(gold, 0.22 * a))
	fin.append(base_a)
	_drawer.draw_polyline(fin, Color(light, 0.45 * a), 7.0 * unit, true)
	_drawer.draw_polyline(fin, Color(edge, 0.9 * a), 2.0 * unit, true)	# Flukes: two lobes spreading from the tail.
	var tail := _spine[SPINE - 1]
	var back := (_spine[SPINE - 1] - _spine[SPINE - 2]).normalized()
	var across := back.orthogonal()
	var flap := sin(_t * 1.6 - 4.2) * 0.35
	var span := _width[int(SPINE * 0.32)] * 1.9
	for s in [-1.0, 1.0]:
		var lobe_tip: Vector2 = tail + (across * s + back * (0.5 + flap * s)).normalized() * span
		var lobe := PackedVector2Array([tail, tail.lerp(lobe_tip, 0.5) + back * span * 0.25, lobe_tip,
			tail.lerp(lobe_tip, 0.6) - back * span * 0.12, tail])
		_fan(lobe, Color(gold, 0.24 * a))
		_drawer.draw_polyline(lobe, Color(light, 0.45 * a), 7.0 * unit, true)
		_drawer.draw_polyline(lobe, Color(edge, 0.9 * a), 2.0 * unit, true)
	# Eye.
	var eye := _point(0.07, -0.25)
	_drawer.draw_circle(eye, 4.0 * unit, Color(edge, 0.95 * a))
	_drawer.draw_circle(eye, 9.0 * unit, Color(gold, 0.2 * a))
	# Constellations inside, twinkling on the beat, joined like star charts.
	var prev := Vector2.ZERO
	for i in _stars.size():
		var s := _stars[i]
		var p := _point(s.x, s.y)
		var tw := 0.6 + 0.4 * sin(_t * 2.3 + i * 1.7)
		_drawer.draw_circle(p, (5.0 + 3.0 * beat) * unit, Color(light, 0.35 * tw * a))
		_drawer.draw_circle(p, (1.8 + 1.4 * beat) * unit, Color(edge.lightened(0.2), 0.9 * tw * a))
		if i % 4 != 0:
			_drawer.draw_line(prev, p, Color(edge, 0.3 * a), 1.0 * unit, true)
		prev = p
	for m in _motes:
		var k: float = m.t / m.life
		_drawer.draw_circle(m.p, lerpf(5.0, 2.0, k) * unit, Color(light, (1.0 - k) * 0.6 * a))
		_drawer.draw_circle(m.p, lerpf(2.0, 0.8, k) * unit, Color(gold, (1.0 - k) * 0.9 * a))


## Triangles from the first point: never fails like a polygon can when the shape folds.
func _fan(pts: PackedVector2Array, col: Color) -> void:
	for i in range(1, pts.size() - 1):
		_drawer.draw_primitive(PackedVector2Array([pts[0], pts[i], pts[i + 1]]), PackedColorArray([col, col, col]), PackedVector2Array())


func _quad(q: PackedVector2Array, col: Color) -> void:
	_fan(q, col)
