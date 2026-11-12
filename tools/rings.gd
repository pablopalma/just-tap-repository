extends Node2D
## Prototype (11/11/2026): the rings of the pulse. You fly into the depth behind your light, the little
## ball going ahead of you along a gentle winding way, and giant rings come towards you, one every
## two beats of the theme (After the Hard Day). Tap as the light goes through one, on its beat: it
## sounds the theme's next note and the ring bursts into colour, a wash of watercolour spilling out
## of it. Miss and it goes by grey; nothing is lost.
## All round, white paper with depth: far off, stains of watercolour in Gris's soft colours open one
## after another like the colour coming back in the game (shaders/stain.gdshader: the pigment floods
## out from a point, its front blooming like cauliflower, its wet edge darker), gathering into
## abstract figures (a spiral, an arc, a flower, a wave, a ring of stains) that you fly into and
## through. A caught ring opens one of those stains from the light, over everything. The more rings
## you have caught in a row, the stronger the colour.
## A white mist (shaders/mist.gdshader): far off everything sinks into it, and wisps of it stream out
## past you as you fly.
## Tap: space, click, a gamepad's A. Esc: back to the game. `-- auto` plays on its own.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/rings.tscn -- auto

const TRACK := "z1"
const PER_BEAT := 6.0        # world units flown each beat
const EVERY := 2             # a ring every this many beats
const WINDOW := 0.24         # how far from its beat a tap still catches the ring (beats)
const RING_R := 3.4          # the rings' radius (world units); the light is a speck by them
const BALL_AHEAD := 4.0      # the light flies this far ahead of the camera
const FAR := 120.0           # nothing is drawn beyond this
const FOCAL := 560.0         # at 720 high
## The figures of watercolour: one every FIGURE_GAP along the way. Once one comes nearer than
## PAINT_FROM its blots start to paint themselves, one after another (BLOT_LAG seconds apart), each
## taking PAINT_TIME: a wet drop that spreads unevenly into the paper, pigment settling in it, its
## edge darkening as it dries, little drops spattered round it.
const FIGURE_GAP := 46.0
const PAINT_FROM := 112.0
const PAINT_TIME := 3.6
const STAINS := 80           # quads for the stains (and the caught rings' own)
const BLOT_LAG := 0.35
const KINDS := ["spiral", "arc", "flower", "wave", "ring", "drift"]
## Gris's soft colours, as watercolour on white.
const WASH := [Color("#d98a80"), Color("#e9b8a8"), Color("#80b6b0"), Color("#8eaed6"), Color("#e2c27a"),
	Color("#a8c79a"), Color("#b7a2d2")]
const INK := Color("#3b3835")

var _auto := false
var _t := 0.0
var _first := 0.0            # the beat of the first ring
var _rings := {}             # ring index -> {"state": 0 coming / 1 caught / 2 missed, "t": seconds since}
var _run := 0
var _caught := 0
var _cam := Vector3.ZERO     # the camera (x, y, z)
var _splash: Array[Dictionary] = []   # watercolour spilling from a caught ring, on the screen
var _figures := {}           # figure index -> its blots
var _kick := 0.0
var _colour := 0.0           # how strong the world's colour is (grows with the run)
var _stain_layer: CanvasLayer
var _quads: Array[ColorRect] = []
var _mist_back: ShaderMaterial
var _mist_front: ShaderMaterial


func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	SaveSystem.enabled = false
	Music.zone = 1
	Music._pending_zone = 1
	Music.start()
	Music.play_feature(TRACK)
	var layer := CanvasLayer.new()
	layer.layer = -10
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/paper.gdshader")
	mat.set_shader_parameter("paper", Color(0.965, 0.955, 0.94))
	paper.material = mat
	layer.add_child(paper)
	add_child(layer)
	_first = -1.0
	# the stains, multiplied over the paper, under the rings and the light
	_stain_layer = CanvasLayer.new()
	_stain_layer.layer = -5
	add_child(_stain_layer)
	var shader: Shader = load("res://shaders/stain.gdshader")
	for i in STAINS:
		var q := ColorRect.new()
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = shader
		q.material = m
		q.visible = false
		_stain_layer.add_child(q)
		_quads.append(q)
	# the mist: a haze over the stains (the rings and the light come out of it), and wisps in front
	_mist_back = _mist(-4, 0.8, 0.6, 0.55, 0.05)
	_mist_front = _mist(1, 0.0, 0.1, 0.75, 0.3)


func _mist(at: int, haze: float, reach: float, wisps: float, from: float) -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.layer = at
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/mist.gdshader")
	m.set_shader_parameter("haze", haze)
	m.set_shader_parameter("haze_reach", reach)
	m.set_shader_parameter("wisps", wisps)
	m.set_shader_parameter("wisp_from", from)
	rect.material = m
	layer.add_child(rect)
	return m


func _beat() -> float:
	return Music._heard_time() / (60.0 / maxf(1.0, Music.bpm()))


## The way the light flies: it winds gently left, right, up and down as it goes.
func _way(z: float) -> Vector2:
	return Vector2(2.4 * sin(z * 0.031) + 1.3 * sin(z * 0.083 + 1.0), 1.3 * sin(z * 0.047 + 2.0) + 0.5 * sin(z * 0.13))


func _ring_beat(i: int) -> float:
	return _first + i * EVERY


func _process(delta: float) -> void:
	_t += delta
	var b := _beat()
	if _first < 0.0 and Music.track != "" and b > 0.5:
		_first = ceilf(b) + 4.0
		_first += fposmod(-_first, float(EVERY))
	var z := b * PER_BEAT
	var w := _way(z)
	_cam = _cam.lerp(Vector3(w.x * 0.8, w.y * 0.8 + 0.9, z), minf(1.0, delta * 3.0))
	_cam.z = z
	_kick = maxf(0.0, _kick - delta * 2.5)
	_colour = lerpf(_colour, clampf(0.35 + _run * 0.08, 0.35, 1.0), minf(1.0, delta * 1.5))
	if _first >= 0.0:
		# rings gone by without a tap: missed
		var i := 0
		while _ring_beat(i) < b - WINDOW:
			if not _rings.has(i):
				_rings[i] = {"state": 2, "t": 0.0}
				_run = 0
			i += 1
	for k in _rings:
		_rings[k].t += delta
	for s in _splash:
		s.t += delta
	_splash = _splash.filter(func(s: Dictionary) -> bool: return s.t < s.life)
	_place_stains()
	var vp := get_viewport_rect().size
	for m in [_mist_back, _mist_front]:
		m.set_shader_parameter("aspect", vp.x / vp.y)
		m.set_shader_parameter("travel", _cam.z * 0.05)
	if _auto and _first >= 0.0:
		var near := _nearest(b)
		if near >= 0 and not _rings.has(near) and absf(_ring_beat(near) - b) < 0.08 and randf() < 0.9:
			_tap()
	queue_redraw()


func _nearest(b: float) -> int:
	if _first < 0.0:
		return -1
	return maxi(0, roundi((b - _first) / EVERY))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		DevMenu.back_to_game(get_tree())
		return
	var pressed: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A)
	if pressed:
		_tap()


func _tap() -> void:
	var b := _beat()
	var i := _nearest(b)
	if i >= 0 and not _rings.has(i) and absf(_ring_beat(i) - b) <= WINDOW:
		_rings[i] = {"state": 1, "t": 0.0}
		_run += 1
		_caught += 1
		_kick = 1.0
		Music.play_accent(_run)
		_spill(i)
	else:
		Music.play_tap(0.05, false)
		_kick = maxf(_kick, 0.3)


## A caught ring spills its colour: drops of watercolour flung out over the screen from its rim,
## blooming and fading as they soak in.
func _spill(i: int) -> void:
	var vp := get_viewport_rect().size
	_splash.append({"at": _ball_screen(), "r": vp.y * randf_range(0.55, 0.75), "col": WASH[i % WASH.size()], "t": 0.0,
		"life": 2.6, "seed": randf() * 100.0})


# --- Drawing ------------------------------------------------------------------------------------

func _px() -> float:
	return get_viewport_rect().size.y / 720.0


## A point of the world on the screen and its scale; z <= 0 when behind the camera.
func _project(p: Vector3) -> Vector3:
	var dz := p.z - _cam.z
	if dz < 0.3:
		return Vector3(0, 0, -1)
	var vp := get_viewport_rect().size
	var s := FOCAL * _px() / dz
	return Vector3(vp.x * 0.5 + (p.x - _cam.x) * s, vp.y * 0.5 + (p.y - _cam.y) * s, s)


func _ball_world() -> Vector3:
	var z := _cam.z + BALL_AHEAD
	var w := _way(z)
	return Vector3(w.x, w.y, z)


func _ball_screen() -> Vector2:
	var q := _project(_ball_world())
	return Vector2(q.x, q.y)


func _draw() -> void:
	var items: Array = []   # [z, kind, data]
	if _first >= 0.0:
		var i0 := maxi(0, int(floorf((_cam.z / PER_BEAT - _first) / EVERY)))
		for i in range(i0, i0 + int(FAR / (PER_BEAT * EVERY)) + 2):
			var z := _ring_beat(i) * PER_BEAT
			if z > _cam.z + 0.3 and z < _cam.z + FAR:
				items.append([z, 1, i])
	items.append([_ball_world().z, 2, null])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for it in items:
		match it[1]:
			1: _draw_ring(it[2])
			2: _draw_ball()


## The blots of figure f, made once: where along the way it stands, its shape, its colours.
func _figure(f: int) -> Array:
	if _figures.has(f):
		return _figures[f]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * f + 13
	var z0 := (f + 0.5) * FIGURE_GAP
	var w := _way(z0)
	var kind: String = KINDS[posmod(f * 5 + rng.randi_range(0, 1), KINDS.size())]
	var c0: int = rng.randi_range(0, WASH.size() - 1)
	# off to one side or the other, so you fly past and through them, not always into the middle
	var side := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3.0, 7.0)
	var out: Array = []
	var n := 9
	for k in n:
		var u := k / float(n - 1)
		var p := Vector2.ZERO
		var dz := 0.0
		var r := 1.6
		match kind:
			"spiral":
				var a := u * TAU * 1.6
				p = Vector2.from_angle(a) * lerpf(1.5, 9.0, u)
				dz = u * 6.0
				r = lerpf(1.2, 2.8, u)
			"arc":
				var a := lerpf(PI * 1.05, PI * 1.95, u)
				p = Vector2.from_angle(a) * 9.0 + Vector2(0, 4.0)
				r = 2.2 + sin(u * PI) * 1.4
			"flower":
				var petal := k % 6
				var a := petal * TAU / 6.0 + rng.randf_range(-0.15, 0.15)
				p = Vector2.from_angle(a) * (4.5 if k < 12 else 0.0) * rng.randf_range(0.85, 1.15)
				r = 2.6 if k < 12 else 3.2
				dz = rng.randf_range(-1.0, 1.0)
			"wave":
				p = Vector2(lerpf(-12.0, 12.0, u), sin(u * TAU * 1.3) * 3.0 - 4.0)
				r = 2.0 + 0.8 * sin(u * 9.0)
				dz = u * 4.0
			"ring":
				var a := u * TAU
				p = Vector2.from_angle(a) * 7.5
				r = 1.8 + 0.6 * sin(u * 13.0)
			_:
				p = Vector2(rng.randf_range(-10.0, 10.0), rng.randf_range(-6.0, 6.0))
				r = rng.randf_range(1.5, 3.4)
				dz = rng.randf_range(-6.0, 6.0)
		var col: Color = WASH[(c0 + (k / 4)) % WASH.size()]
		out.append({"p": Vector3(w.x + side.x + p.x, w.y + side.y + p.y, z0 + dz), "r": r * rng.randf_range(1.1, 1.6),
			"col": col, "seed": rng.randf() * 100.0, "order": k, "turn": rng.randf() * TAU, "start": -1.0,
			"drops": _drops(rng)})
	_figures[f] = out
	return out


## The stains on their quads: every blot of the figures in view, opening over PAINT_TIME from when
## its turn comes, then the caught rings' own over the screen.
func _place_stains() -> void:
	var used := 0
	var vp := get_viewport_rect().size
	var beat := pow(1.0 - fposmod(_beat(), 1.0), 3.0)
	var fz := floorf(_cam.z / FIGURE_GAP)
	for f in range(int(fz), int(fz + FAR / FIGURE_GAP) + 2):
		for b in _figure(f):
			if used >= STAINS:
				break
			var dz: float = b.p.z - _cam.z
			if dz < 0.3 or dz > FAR:
				continue
			if b.start < 0.0:
				if dz > PAINT_FROM:
					continue
				b.start = _t + b.order * BLOT_LAG
			var p: float = clampf((_t - b.start) / PAINT_TIME, 0.0, 1.0)
			if p <= 0.0:
				continue
			var q := _project(b.p)
			if q.z <= 0.0:
				continue
			var half: float = b.r * q.z * 1.6
			var c := Vector2(q.x, q.y)
			if c.x + half < 0 or c.x - half > vp.x or c.y + half < 0 or c.y - half > vp.y or half > vp.x * 3.0:
				continue
			# pale as you fly through it, and faint far off, where they would crowd the middle
			var a := smoothstep(0.5, 9.0, dz) * (1.0 - smoothstep(FAR * 0.45, FAR * 0.9, dz)) * lerpf(0.5, 0.85, _colour)
			_quad(used, c, half, b.col, 1.0 - pow(1.0 - p, 2.5), float(b.seed), a, beat)
			used += 1
	for s in _splash:
		if used >= STAINS:
			break
		var k: float = s.t / s.life
		var open := 1.0 - pow(1.0 - minf(1.0, k * 1.6), 3.0)
		_quad(used, s.at, s.r, s.col, open, float(s.seed), 0.9 * (1.0 - smoothstep(0.5, 1.0, k)), beat)
		used += 1
	for i in range(used, STAINS):
		_quads[i].visible = false


func _quad(i: int, c: Vector2, half: float, col: Color, open: float, seed: float, a: float, beat: float) -> void:
	var q := _quads[i]
	q.visible = true
	q.position = c - Vector2(half, half)
	q.size = Vector2(half, half) * 2.0
	var m := q.material as ShaderMaterial
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("open", open)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("alpha", a)
	m.set_shader_parameter("beat", beat)


## The little drops spattered round a blot: where (in its radii), how big, when they land (0..1 of
## its painting).
func _drops(rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for k in rng.randi_range(2, 5):
		out.append({"at": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.15, 1.7),
			"r": rng.randf_range(0.06, 0.16), "when": rng.randf_range(0.15, 0.8), "seed": rng.randf() * 50.0})
	return out


## A blot of watercolour, painting itself: a wet drop lands and spreads into the paper unevenly,
## reaching further one way than another; pigment settles in it in darker pools; its edge gathers
## pigment and darkens as it dries; drops spatter round it. Pale as you fly through it.
func _draw_blot(b: Dictionary) -> void:
	var dz: float = b.p.z - _cam.z
	if b.start < 0.0:
		if dz > PAINT_FROM:
			return
		b.start = _t + b.order * BLOT_LAG
	var p: float = clampf((_t - b.start) / PAINT_TIME, 0.0, 1.0)
	if p <= 0.0:
		return
	var q := _project(b.p)
	if q.z <= 0.0:
		return
	var r: float = b.r * q.z
	var through := smoothstep(0.5, 9.0, dz)                  # pale as you go through it
	var a := through * lerpf(0.55, 1.0, _colour)
	var col: Color = Color(b.col).lerp(Color(0.92, 0.9, 0.88), 1.0 - _colour * 0.9)
	var c := Vector2(q.x, q.y)
	var vp := get_viewport_rect().size
	if c.x + r * 1.8 < 0 or c.x - r * 1.8 > vp.x or c.y + r * 1.8 < 0 or c.y - r * 1.8 > vp.y:
		return
	var seed: float = b.seed
	# the wet wash spreading: each direction reaches out at its own pace
	var wet := _spread(c, r, p, seed, float(b.turn))
	draw_colored_polygon(wet, Color(col, 0.10 * a * smoothstep(0.0, 0.15, p)))
	# pigment settling in pools, darker, later, smaller, off-centre
	for k in 3:
		var pk := clampf((p - 0.2 - k * 0.15) / 0.5, 0.0, 1.0)
		if pk <= 0.0:
			continue
		var off := Vector2.from_angle(seed * 2.3 + k * 2.1) * r * 0.22
		var pool := _spread(c + off, r * (0.7 - k * 0.15), pk, seed + 11.0 + k * 5.0, float(b.turn) + k)
		draw_colored_polygon(pool, Color(col, (0.10 + 0.03 * k) * a))
	# the edge darkening as it dries
	var dry := smoothstep(0.45, 1.0, p)
	if dry > 0.0:
		var edge := wet.duplicate()
		edge.append(edge[0])
		draw_polyline(edge, Color(col.darkened(0.3), 0.28 * dry * a), clampf(r * 0.025, 1.0, 4.0), true)
	# spatter
	for d in b.drops:
		var pd := clampf((p - float(d.when)) / 0.25, 0.0, 1.0)
		if pd <= 0.0:
			continue
		var dc: Vector2 = c + Vector2(d.at) * r
		var drop := _ragged(dc, r * float(d.r) * lerpf(0.4, 1.0, pd), seed + float(d.seed), 0.0)
		draw_colored_polygon(drop, Color(col.darkened(0.1), 0.3 * a * pd))


## A drop spreading into wet paper, `p` (0..1) of the way: every direction starts a little later or
## sooner and goes a little further or less, and a few reach out in fingers late on.
func _spread(c: Vector2, r: float, p: float, seed: float, turn: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 40
	for i in n:
		var a := TAU * i / n + turn
		var lag := 0.35 * (0.5 + 0.5 * sin(a * 2.0 + seed)) + 0.15 * (0.5 + 0.5 * sin(a * 5.0 + seed * 1.3))
		var reach := 1.0 - pow(1.0 - clampf((p - lag * 0.6) / (1.0 - lag * 0.6), 0.0, 1.0), 2.2)
		var shape := 1.0 + 0.16 * sin(a * 3.0 + seed) + 0.09 * sin(a * 7.0 + seed * 1.7) + 0.05 * sin(a * 13.0 + seed * 0.3)
		var finger := pow(maxf(0.0, sin(a * 4.0 + seed * 0.7)), 6.0) * 0.35 * smoothstep(0.5, 1.0, p)
		pts.append(c + Vector2(cos(a), sin(a) * 0.92) * r * (0.08 + 0.92 * reach) * (shape + finger))
	return pts


## A ragged round shape, like a drop soaking into paper.
func _ragged(c: Vector2, r: float, seed: float, turn: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 30
	for i in n:
		var a := TAU * i / n + turn
		var k := 1.0 + 0.16 * sin(a * 3.0 + seed) + 0.09 * sin(a * 7.0 + seed * 1.7) + 0.05 * sin(a * 13.0 + seed * 0.3)
		pts.append(c + Vector2(cos(a), sin(a) * 0.92) * r * k)
	return pts


## A ring of the pulse: a brush circle of ink, breathing with the beat; caught, it bursts in colour.
func _draw_ring(i: int) -> void:
	var z := _ring_beat(i) * PER_BEAT
	var w := _way(z)
	var q := _project(Vector3(w.x, w.y, z))
	if q.z <= 0.0:
		return
	var dz := z - _cam.z
	var c := Vector2(q.x, q.y)
	var st: Dictionary = _rings.get(i, {"state": 0, "t": 0.0})
	var beat := pow(1.0 - fposmod(_beat(), 1.0), 3.0)
	var r := RING_R * q.z * (1.0 + 0.04 * beat)
	var near := clampf(1.0 - dz / FAR, 0.0, 1.0)
	# out of the mist: far rings faint and pale, sharpening as they near
	var a := smoothstep(0.0, 0.35, near) * smoothstep(0.3, 3.0, dz) * (1.0 - 0.85 * smoothstep(FAR * 0.25, FAR * 0.75, dz))
	var col: Color = Color(INK, 0.55)
	var width := clampf(0.12 * q.z, 1.0, 26.0)
	var wash: Color = WASH[i % WASH.size()]
	if st.state == 1:
		var k: float = clampf(st.t / 0.8, 0.0, 1.0)
		col = wash.lerp(Palette.GOLD, 0.3 * (1.0 - k))
		r *= 1.0 + 0.5 * pow(k, 0.5)
		a *= 1.0 - k
		width *= 1.0 + 1.5 * (1.0 - k)
	elif st.state == 2:
		col = Color(INK, 0.18)
	else:
		# the next ring: it warms as its beat comes
		var due := 1.0 - clampf((_ring_beat(i) - _beat()) / float(EVERY), 0.0, 1.0)
		col = Color(INK, 0.55).lerp(Color(wash.darkened(0.2), 0.8), due * due)
	# a brush stroke: a few rings a little off each other, thicker on one side
	for k in 4:
		var off := Vector2.from_angle(i * 1.7 + k * 2.1) * width * 0.25
		draw_arc(c + off, r * (1.0 + (k - 1.5) * 0.012), 0.0, TAU, 96, Color(col, col.a * a * (0.5 if k > 0 else 0.9)),
			width * (1.0 if k == 0 else 0.5), true)
	if st.state == 1 and st.t < 1.0:
		var k2: float = st.t
		draw_circle(c, r * (0.6 + 0.6 * k2), Color(wash, 0.12 * (1.0 - k2)))


func _draw_ball() -> void:
	var q := _project(_ball_world())
	if q.z <= 0.0:
		return
	var c := Vector2(q.x, q.y)
	var px := _px()
	var gold := Palette.GOLD
	var s := 1.0 + 0.4 * _kick
	for i in 6:
		var k := i / 5.0
		draw_circle(c, lerpf(60.0, 12.0, k) * s * px, Color(gold, 0.04 + 0.05 * k))
	draw_circle(c, 9.0 * s * px, Color(1.0, 0.97, 0.88))
	draw_circle(c, 4.0 * px, gold.darkened(0.15))


func _draw_splash(s: Dictionary) -> void:
	var k: float = s.t / s.life
	var e := 1.0 - pow(1.0 - minf(1.0, k * 2.0), 3.0)
	var c: Vector2 = Vector2(s.from).lerp(s.to, e)
	var r: float = s.r * (0.3 + 0.9 * e)
	var a := (1.0 - k) * 0.9
	for layer in 2:
		var pts := _ragged(c, r * (1.0 - layer * 0.2), float(s.seed) + layer, float(s.seed))
		draw_colored_polygon(pts, Color(s.col, 0.16 * a))
		if layer == 0:
			pts.append(pts[0])
			draw_polyline(pts, Color(Color(s.col).darkened(0.3), 0.25 * a), 2.0 * _px(), true)
