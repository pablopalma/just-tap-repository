class_name CelestialWhale
extends CanvasLayer
## What awakens at the end of the demo's dark: a whale made of light, far bigger than the bird,
## swimming slowly across the sky. Its body undulates from head to fluke, it carries constellations
## inside and leaves a trail of motes; it sings three times (Music.whale_song). Over the darkness,
## so it shines in it; the dark lifts as it passes (Main listens to `passing`).

## What you connect also gives life: through the dark the whale sleeps in the sky, a dotted sketch
## with NODES dark stars, each tied by a thread to one of the dark's barriers. Breaking a barrier
## sends a spark up its thread and lights its star; when the last one lights, the whale fills with
## light right where it sleeps and swims away (sleep, light, wake).

signal passing  # halfway across: the light can come back
signal gone

const DURATION := 22.0
const SPINE := 44
const SONGS := [0.1, 0.42, 0.72]
## Where along its crossing it sleeps, and wakes to swim on from.
const SLEEP_P := 0.33
## Its stars to light, on its body (u along it 0..1, v across -1..1): head to tail.
const NODES := [Vector2(0.1, -0.15), Vector2(0.28, 0.45), Vector2(0.44, -0.35), Vector2(0.6, 0.2), Vector2(0.78, -0.05)]
const SPARK_TIME := 0.9
const WAKE_TIME := 2.2

var active := false
## Asleep in the sky (the dark), waiting for its stars.
var sleeping := false
## Where each node's barrier is on screen (Main sets it every frame while it sleeps).
var anchors := PackedVector2Array()

var _lit: Array[bool] = []
var _sparks: Array[Dictionary] = []   # {i, t}: a light running up a thread
var _pops := {}                       # node -> 0..1 its ring opening
var _wake := 1.0                      # 0: a sketch, 1: all light
var _breath := 0.0

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
	sleeping = false
	_wake = 1.0
	visible = true
	_t = 0.0
	_passed = false
	_songs = SONGS.duplicate()
	_motes.clear()
	Music.prepare_dark()


func stop() -> void:
	active = false
	sleeping = false
	visible = false
	_motes.clear()
	_sparks.clear()
	_pops.clear()
	_lit.clear()


## Asleep in the sky: a sketch with its stars out. `already` of them are lit at once (a save inside
## the dark).
func sleep(already := 0) -> void:
	if sleeping or active:
		return
	sleeping = true
	visible = true
	_wake = 0.0
	_t = SLEEP_P * DURATION
	_lit.clear()
	for i in NODES.size():
		_lit.append(i < already)
	Music.prepare_dark()


## Node i's barrier broke: a spark runs up its thread and lights it.
func light(i: int) -> void:
	if not sleeping or i < 0 or i >= _lit.size() or _lit[i]:
		return
	_sparks.append({"i": i, "t": 0.0})


func all_lit() -> bool:
	return sleeping and not _lit.has(false) and _sparks.is_empty()


## All its stars lit: it fills with light right where it sleeps and swims on.
func wake() -> void:
	if not sleeping:
		swim()
		return
	sleeping = false
	active = true
	_passed = false
	_t = SLEEP_P * DURATION
	_songs = []
	for s in SONGS:
		if s > SLEEP_P:
			_songs.append(s)
	_songs.push_front(SLEEP_P + 0.01)  # it sings as it wakes
	_motes.clear()
	create_tween().tween_property(self, "_wake", 1.0, WAKE_TIME).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_breath += delta
	if sleeping:
		_process_sleep(delta)
		return
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


## Asleep: held where it will wake, breathing a little; the sparks climb, the stars pop.
func _process_sleep(delta: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	var length := vp.y * 1.25
	var p := SLEEP_P
	var head := Vector2(lerpf(-0.1 * vp.x, vp.x + length * 1.05, p),
		vp.y * (0.48 - 0.12 * p) + sin(_t * 0.45) * vp.y * 0.04 + sin(_breath * 0.7) * vp.y * 0.008)
	_build_body(head, length)
	for k in range(_sparks.size() - 1, -1, -1):
		var s: Dictionary = _sparks[k]
		s.t += delta
		if s.t >= SPARK_TIME:
			_lit[s.i] = true
			_pops[s.i] = 0.0
			Music.settle_note(int(s.i) * 2 + 2)
			_sparks.remove_at(k)
	for i in _pops.keys():
		_pops[i] = minf(1.0, _pops[i] + delta / 1.2)
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
	if (not active and not sleeping) or _spine.size() < SPINE:
		return
	var vp := get_viewport().get_visible_rect().size
	var unit := vp.y / 720.0
	if _wake < 1.0:
		_draw_sketch(1.0 - _wake, unit)
	if _wake <= 0.0:
		return
	var a := _fade * _wake
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


## Asleep: a dotted outline that brightens with every star lit, its stars (out, or lit and glowing)
## joined to each other, and a thread from each down to its barrier on the line, a spark climbing it.
func _draw_sketch(g: float, unit: float) -> void:
	var lit := 0
	for b in _lit:
		if b:
			lit += 1
	var pale := Color(0.88, 0.9, 1.0)
	var gold := Palette.GOLD.lightened(0.45)
	var outline := PackedVector2Array()
	for i in SPINE:
		outline.append(_spine[i] + _side(i) * _width[i])
	for i in range(SPINE - 1, -1, -1):
		outline.append(_spine[i] - _side(i) * _width[i])
	outline.append(outline[0])
	var line_a := (0.16 + 0.12 * lit) * g
	for i in range(0, outline.size() - 1, 2):
		_drawer.draw_line(outline[i], outline[i + 1], Color(pale.lerp(gold, lit / 5.0), line_a), 1.4 * unit, true)
	_drawer.draw_circle(_point(0.07, -0.25), 2.5 * unit, Color(pale, line_a))
	var pts: Array[Vector2] = []
	for n in NODES:
		pts.append(_point(n.x, n.y))
	# the stars joined, star chart style; a lit pair in gold
	for i in pts.size() - 1:
		var both := _lit[i] and _lit[i + 1]
		_dotted(pts[i], pts[i + 1], Color(gold if both else pale, (0.45 if both else 0.18) * g), unit)
	for i in pts.size():
		var np := pts[i]
		if i < anchors.size():
			_dotted(anchors[i], np, Color(gold if _lit[i] else pale, (0.3 if _lit[i] else 0.12) * g), unit)
		if _lit[i]:
			var tw := 0.75 + 0.25 * sin(_breath * 2.1 + i * 1.3)
			_drawer.draw_circle(np, 11.0 * unit, Color(gold, 0.3 * tw * g))
			_drawer.draw_circle(np, 3.6 * unit, Color(Color(1.0, 0.97, 0.88), 0.95 * g))
			var pop: float = _pops.get(i, 1.0)
			if pop < 1.0:
				_drawer.draw_arc(np, lerpf(6.0, 46.0, 1.0 - pow(1.0 - pop, 3.0)) * unit, 0.0, TAU, 48,
					Color(gold, (1.0 - pop) * 0.8 * g), 2.0 * unit, true)
		else:
			_drawer.draw_arc(np, 5.0 * unit, 0.0, TAU, 24, Color(pale, 0.45 * g), 1.2 * unit, true)
	for s in _sparks:
		var i: int = s.i
		if i >= anchors.size():
			continue
		var k: float = s.t / SPARK_TIME
		var at := anchors[i].lerp(pts[i], k * k * (3.0 - 2.0 * k))
		_drawer.draw_circle(at, 10.0 * unit, Color(gold, 0.35 * g))
		_drawer.draw_circle(at, 3.2 * unit, Color(Color(1.0, 0.97, 0.88), g))


## A line of dots from a to b, a dot every ~16 px.
func _dotted(a: Vector2, b: Vector2, col: Color, unit: float) -> void:
	var d := a.distance_to(b)
	var n := int(d / (16.0 * unit))
	for k in n:
		var p := a.lerp(b, (k + 0.5) / maxf(1.0, n))
		_drawer.draw_circle(p, 1.3 * unit, col)


## Triangles from the first point: never fails like a polygon can when the shape folds.
func _fan(pts: PackedVector2Array, col: Color) -> void:
	for i in range(1, pts.size() - 1):
		_drawer.draw_primitive(PackedVector2Array([pts[0], pts[i], pts[i + 1]]), PackedColorArray([col, col, col]), PackedVector2Array())


func _quad(q: PackedVector2Array, col: Color) -> void:
	_fan(q, col)
