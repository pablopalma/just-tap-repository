extends Node2D
## The barrier's figure (§7.2). Every barrier has its own abstract figure (seeded by its number) from
## five families — rose, Lissajous, hypotrochoid, damped harmonograph, petals — that draws itself
## behind the barrier as you break it: as much of the curve as the barrier is broken. If the barrier
## heals, the figure un-draws. It breathes on the beat, and blooms and fades when the barrier falls.

const POINTS := 900
const RADIUS := 150.0
const BLOOM_TIME := 1.6

var path: PathData

var _n := -1
var _pts := PackedVector2Array()
var _prog := 0.0
var _leaving := {}   # {pts, pos, t} the figure of the barrier that just broke


func _ready() -> void:
	GameState.gate_broken.connect(_on_broken)


func reset() -> void:
	_n = -1
	_prog = 0.0
	_leaving = {}
	queue_redraw()


func _on_broken(n: int) -> void:
	if n == _n and not _pts.is_empty():
		_leaving = {"pts": _pts, "pos": path.gate_pos(n), "t": 0.0}


func _process(delta: float) -> void:
	var n := GameState.stage
	if n != _n:
		_n = n
		_pts = figure(n)
		_prog = 0.0
	var target := 0.0
	if GameState.star.is_empty() and GameState.branches.is_empty() and not GameState.finished:
		target = GameState.progress()
	_prog = lerpf(_prog, target, minf(1.0, delta * 6.0))
	if not _leaving.is_empty():
		_leaving.t += delta
		if _leaving.t >= BLOOM_TIME:
			_leaving = {}
	queue_redraw()


func _draw() -> void:
	if path == null:
		return
	var breath := 1.0 + 0.02 * pow(1.0 - Music.beat_phase(), 4.0)
	var col := Palette.paint_col(Zones.of(GameState.stage), GameState.stage)
	if _prog > 0.002:
		var c := path.gate_pos(_n)
		var count := int(_prog * POINTS)
		draw_circle(c, RADIUS * 0.85, Color(col, 0.04 + 0.14 * _prog * _prog))
		draw_set_transform(c, 0.0, Vector2.ONE * RADIUS * breath)
		if count >= 2:
			draw_polyline(_pts.slice(0, count), Color(Palette.INK, 0.42), 1.0 / RADIUS, true)
		draw_set_transform(Vector2.ZERO)
	if not _leaving.is_empty():
		# blooms ×1.4 in the first third, then fades
		var k: float = _leaving.t / BLOOM_TIME
		var s := lerpf(1.0, 1.4, minf(1.0, k / 0.3))
		var a := 1.0 - k
		draw_set_transform(_leaving.pos, k * 0.4, Vector2.ONE * RADIUS * s)
		draw_polyline(_leaving.pts, Color(col.darkened(0.2), 0.6 * a), 1.4 / (RADIUS * s), true)
		draw_set_transform(Vector2.ZERO)


## The figure of barrier n: POINTS points normalised to radius 1, always the same for the same n.
static func figure(n: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * n + 13
	var family := n % 5
	var pts := PackedVector2Array()
	match family:
		0:  # rose r = cos(k·θ)
			var k := float(rng.randi_range(2, 7)) / float(rng.randi_range(1, 3))
			var turns := 6.0
			for i in POINTS:
				var t := TAU * turns * i / POINTS
				pts.append(Vector2.from_angle(t) * cos(k * t))
		1:  # Lissajous
			var a := rng.randi_range(1, 5)
			var b := rng.randi_range(1, 5)
			if a == b:
				b += 1
			var d := rng.randf() * PI
			for i in POINTS:
				var t := TAU * i / POINTS
				pts.append(Vector2(sin(a * t + d), sin(b * t)))
		2:  # hypotrochoid
			var big := float(rng.randi_range(5, 9))
			var small := float(rng.randi_range(2, 4))
			var dd := rng.randf_range(1.0, 4.0)
			var turns := small
			for i in POINTS:
				var t := TAU * turns * i / POINTS
				pts.append(Vector2((big - small) * cos(t) + dd * cos((big - small) / small * t),
					(big - small) * sin(t) - dd * sin((big - small) / small * t)))
		3:  # damped harmonograph
			var f1 := rng.randf_range(1.9, 3.1)
			var f2 := rng.randf_range(1.9, 3.1)
			var p1 := rng.randf() * TAU
			var p2 := rng.randf() * TAU
			for i in POINTS:
				var t := 40.0 * i / POINTS
				var damp := exp(-0.06 * t)
				pts.append(Vector2(sin(f1 * t + p1), sin(f2 * t + p2)) * damp)
		_:  # petals
			var petals := rng.randi_range(5, 9)
			for i in POINTS:
				var t := TAU * 2.0 * i / POINTS
				var r := 0.35 + 0.65 * absf(sin(petals * t * 0.5))
				pts.append(Vector2.from_angle(t) * r * (0.75 + 0.25 * cos(t * 3.0)))
	var m := 0.0
	for p in pts:
		m = maxf(m, p.length())
	if m > 0.0:
		for i in pts.size():
			pts[i] /= m
	return pts
