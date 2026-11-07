extends Node2D
## The barrier's figure (§7.2). Every barrier has its own figure of sacred geometry (seeded by its
## number): seed and flower of life, Metatron's cube, vesica and triquetra, star polygons, the
## merkaba, a Sri Yantra, the golden spiral, the torus, a lotus, nested squares and the tree of life.
## It draws itself, stroke by stroke from the centre out, behind the barrier as you break it: as much
## of the figure as the barrier is broken. If the barrier heals, the figure un-draws. It breathes on
## the beat, and blooms and fades when the barrier falls.

const RADIUS := 150.0
const BLOOM_TIME := 1.6
const FAMILIES := 17
const PHI := 1.6180339887

var path: PathData

var _n := -1
var _fig: Array[PackedVector2Array] = []
var _lens := PackedFloat32Array()
var _total := 0.0
var _prog := 0.0
var _leaving := {}   # {fig, pos, t} the figure of the barrier that just broke


func _ready() -> void:
	GameState.gate_broken.connect(_on_broken)


func reset() -> void:
	_n = -1
	_prog = 0.0
	_leaving = {}
	queue_redraw()


func _on_broken(n: int) -> void:
	if n == _n and not _fig.is_empty():
		_leaving = {"fig": _fig, "pos": path.gate_pos(n), "t": 0.0}


func _process(delta: float) -> void:
	var n := GameState.stage
	if n != _n:
		_n = n
		_fig = figure(n)
		_lens = PackedFloat32Array()
		_total = 0.0
		for s in _fig:
			var l := _length(s)
			_lens.append(l)
			_total += l
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
	if path == null or BuildFlags.is_dark(_n):
		return   # in the demo's dark, the cymatics take its place (CymaticsFigure)
	var breath := 1.0 + 0.02 * pow(1.0 - Music.beat_phase(), 4.0)
	var col := Palette.paint_col(Zones.of(GameState.stage), GameState.stage)
	if _prog > 0.002:
		var c := path.gate_pos(_n)
		draw_circle(c, RADIUS * 0.85, Color(col, 0.04 + 0.14 * _prog * _prog))
		draw_set_transform(c, 0.0, Vector2.ONE * RADIUS * breath)
		_draw_part(_prog * _total, Color(Palette.INK, 0.42), 1.0 / RADIUS)
		draw_set_transform(Vector2.ZERO)
	if not _leaving.is_empty():
		# blooms ×1.4 in the first third, then fades
		var k: float = _leaving.t / BLOOM_TIME
		var s := lerpf(1.0, 1.4, minf(1.0, k / 0.3))
		var a := 1.0 - k
		draw_set_transform(_leaving.pos, k * 0.4, Vector2.ONE * RADIUS * s)
		for stroke: PackedVector2Array in _leaving.fig:
			draw_polyline(stroke, Color(col.darkened(0.2), 0.6 * a), 1.4 / (RADIUS * s), true)
		draw_set_transform(Vector2.ZERO)


## Draws the strokes of the current figure in order until `budget` (a length) runs out.
func _draw_part(budget: float, col: Color, width: float) -> void:
	for i in _fig.size():
		if budget <= 0.0:
			return
		var s := _fig[i]
		if budget >= _lens[i]:
			draw_polyline(s, col, width, true)
		else:
			var part := PackedVector2Array([s[0]])
			for j in range(1, s.size()):
				var seg := s[j - 1].distance_to(s[j])
				if budget < seg:
					part.append(s[j - 1].lerp(s[j], budget / seg))
					break
				part.append(s[j])
				budget -= seg
			if part.size() >= 2:
				draw_polyline(part, col, width, true)
		budget -= _lens[i]


static func _length(s: PackedVector2Array) -> float:
	var l := 0.0
	for j in range(1, s.size()):
		l += s[j - 1].distance_to(s[j])
	return l


## The figure of barrier n: strokes normalised to radius 1, in drawing order, always the same for
## the same n.
static func figure(n: int) -> Array[PackedVector2Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * n + 13
	var f: Array[PackedVector2Array] = []
	var upright := false
	match n % FAMILIES:
		0: _seed_of_life(f, rng)
		1: _star(f, rng)
		2: _germ_of_life(f, rng)
		3: _flower_of_life(f, rng)
		4: _golden(f, rng)
		5: _merkaba(f, rng)
		6: _egg_of_life(f, rng)
		7: _torus(f, rng)
		8: _metatron(f, rng)
		9: _lotus(f, rng)
		10: _vector_equilibrium(f, rng)
		11: _vesica(f, rng)
		12: _fruit_of_life(f, rng)
		13: _nested(f, rng)
		14: _star_tetrahedron(f, rng)
		15:
			_sri_yantra(f, rng)
			upright = true
		_:
			_tree_of_life(f, rng)
			upright = true
	var m := 0.0
	for s in f:
		for p in s:
			m = maxf(m, p.length())
	var turn := 0.0 if upright else rng.randf() * TAU
	for s in f.size():
		var pts := f[s]
		for i in pts.size():
			pts[i] = (pts[i] / m).rotated(turn)
		f[s] = pts
	return f


# --- the figures ----------------------------------------------------------------------------------

## Seven circles: one in the centre, six around it, and the circle that holds them.
static func _seed_of_life(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	f.append(_circle(Vector2.ZERO, 1.0))
	for k in 6:
		f.append(_circle(Vector2.from_angle(k * TAU / 6.0), 1.0, k * TAU / 6.0 + PI))
	f.append(_circle(Vector2.ZERO, 2.0))
	if rng.randf() < 0.5:
		f.append(_circle(Vector2.ZERO, 2.12))


## Nineteen circles on a hexagonal grid, centre first.
static func _flower_of_life(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	for c in _hex_points(2):
		f.append(_circle(c, 1.0, c.angle() + PI))
	f.append(_circle(Vector2.ZERO, 3.0))
	if rng.randf() < 0.6:
		f.append(_circle(Vector2.ZERO, 3.15))


## Thirteen circles of the fruit of life and every line joining their centres.
static func _metatron(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var cs: Array[Vector2] = [Vector2.ZERO]
	for ring in [1.0, 2.0]:
		for k in 6:
			cs.append(Vector2.from_angle(k * TAU / 6.0) * ring)
	for c in cs:
		f.append(_circle(c, 0.5, c.angle() + PI))
	var only_cube := rng.randf() < 0.4  # sometimes just the cube's hexagons and star
	for i in cs.size():
		for j in range(i + 1, cs.size()):
			if only_cube and (i == 0 or j == 0):
				continue
			f.append(PackedVector2Array([cs[i], cs[j]]))


## Two, three or four circles crossing through each other's centres, and the circle around them.
static func _vesica(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var k := rng.randi_range(2, 4)
	var d := 0.5 if k == 2 else 0.58
	for i in k:
		var c := Vector2.from_angle(i * TAU / k - PI / 2.0) * d
		f.append(_circle(c, 1.0 if k == 2 else d * 1.73))
	if k == 2:
		f.append(PackedVector2Array([Vector2(0, -0.87), Vector2(0, 0.87)]))
		f.append(PackedVector2Array([Vector2(-1.5, 0), Vector2(1.5, 0)]))
	f.append(_circle(Vector2.ZERO, 1.5 if k == 2 else d + d * 1.73))


## A star polygon {p/q} in its circle, with the polygon its points close around.
static func _star(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var stars := [[5, 2], [7, 2], [7, 3], [8, 3], [9, 2], [9, 4], [10, 3], [11, 4], [12, 5]]
	var pick: Array = stars[rng.randi_range(0, stars.size() - 1)]
	var p: int = pick[0]
	var q: int = pick[1]
	f.append(_circle(Vector2.ZERO, 0.08))
	f.append(_circle(Vector2.ZERO, 1.0))
	var s := PackedVector2Array()
	for i in p + 1:
		s.append(Vector2.from_angle(TAU * q * i / p - PI / 2.0))
	f.append(s)
	var inner := cos(PI * q / p) / cos(PI * (q - 1) / p)
	f.append(_ngon(p, inner, PI / p - PI / 2.0))
	f.append(_circle(Vector2.ZERO, 1.12))


## Two triangles through each other (the merkaba seen from above), the hexagon inside, and again
## smaller.
static func _merkaba(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var levels := rng.randi_range(2, 3)
	var r := 1.0
	f.append(_circle(Vector2.ZERO, 1.0))
	for l in levels:
		f.append(_ngon(3, r, -PI / 2.0))
		f.append(_ngon(3, r, PI / 2.0))
		r /= sqrt(3.0)  # the inner hexagon's circumradius
		f.append(_ngon(6, r, 0.0))
		f.append(_circle(Vector2.ZERO, r * 0.866))
		r *= 0.866


## Six petals where the circles of the seed of life cross, in their circle.
static func _germ_of_life(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var k := 6 if rng.randf() < 0.7 else 12
	f.append(_circle(Vector2.ZERO, 0.06))
	# each petal lies between two circles centred on the rim, 60° either side of it
	var w := PI / 3.0
	for i in k:
		var a := i * TAU / k + PI / 6.0
		var tip := Vector2.from_angle(a)
		var c1 := Vector2.from_angle(a - w)
		var c2 := Vector2.from_angle(a + w)
		var s := PackedVector2Array()
		# out along one circle to the tip, back along the other
		_arc_into(s, c2, 1.0, a + w + PI, a + w + PI + (PI - 2.0 * w))
		_arc_into(s, c1, 1.0, (tip - c1).angle(), (tip - c1).angle() + (PI - 2.0 * w))
		f.append(s)
	f.append(_circle(Vector2.ZERO, 1.0))


## Seven circles touching: one in the middle and six around it.
static func _egg_of_life(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	f.append(_circle(Vector2.ZERO, 1.0))
	for k in 6:
		f.append(_circle(Vector2.from_angle(k * TAU / 6.0) * 2.0, 1.0, k * TAU / 6.0 + PI))
	if rng.randf() < 0.5:
		f.append(_circle(Vector2.ZERO, 3.0))


## The thirteen circles of the fruit of life, on their own.
static func _fruit_of_life(f: Array[PackedVector2Array], _rng: RandomNumberGenerator) -> void:
	f.append(_circle(Vector2.ZERO, 0.5))
	for ring in [1.0, 2.0]:
		for k in 6:
			var a := k * TAU / 6.0
			f.append(_circle(Vector2.from_angle(a) * ring, 0.5, a + PI))


## The cuboctahedron seen along an axis: a hexagon, its star, its spokes and the small hexagon.
static func _vector_equilibrium(f: Array[PackedVector2Array], _rng: RandomNumberGenerator) -> void:
	var v: Array[Vector2] = []
	for k in 6:
		v.append(Vector2.from_angle(k * TAU / 6.0))
	for k in 3:
		f.append(PackedVector2Array([v[k], v[k + 3]]))
	f.append(_ngon(3, 1.0 / sqrt(3.0), PI / 6.0))
	f.append(_ngon(3, 1.0 / sqrt(3.0), -PI / 6.0))
	f.append(_ngon(6, 1.0 / sqrt(3.0), PI / 6.0))
	f.append(_ngon(3, 1.0, 0.0))
	f.append(_ngon(3, 1.0, PI / 3.0))
	f.append(_ngon(6, 1.0, 0.0))


## Two big triangles through each other, each cut into a grid of small ones (the 64-star
## tetrahedron, flattened).
static func _star_tetrahedron(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var n := rng.randi_range(3, 4)
	for start in [-PI / 2.0, PI / 2.0]:
		var t: Array[Vector2] = []
		for k in 3:
			t.append(Vector2.from_angle(start + k * TAU / 3.0))
		f.append(PackedVector2Array([t[0], t[1], t[2], t[0]]))
		for k in 3:
			var a := t[k]
			var b := t[(k + 1) % 3]
			var c := t[(k + 2) % 3]
			for i in range(1, n):
				var u := float(i) / n
				f.append(PackedVector2Array([a.lerp(b, u), a.lerp(c, u)]))
	f.append(_ngon(6, 1.0 / sqrt(3.0), 0.0))


## Circles of the same size turning around the centre: the torus seen from above.
static func _torus(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var k := rng.randi_range(9, 18)
	for i in k:
		var a := i * TAU / k
		f.append(_circle(Vector2.from_angle(a) * 0.5, 0.5, a + PI))
	f.append(_circle(Vector2.ZERO, 1.0))


## Two rings of petals around a centre, held in circles.
static func _lotus(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var k: int = [6, 8, 12][rng.randi_range(0, 2)]
	f.append(_circle(Vector2.ZERO, 0.08))
	f.append(_circle(Vector2.ZERO, 0.3))
	for i in k:
		f.append(_petal(i * TAU / k, 0.3, 0.62, PI / k))
	f.append(_circle(Vector2.ZERO, 0.62))
	for i in k * 2:
		f.append(_petal((i + 0.5) * TAU / (k * 2), 0.62, 0.92, PI / (k * 2)))
	f.append(_circle(Vector2.ZERO, 0.92))
	f.append(_circle(Vector2.ZERO, 1.0))


## Squares (or other polygons) each turned to rest its corners on the sides of the last.
static func _nested(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var m: int = [4, 5, 6, 8][rng.randi_range(0, 3)]
	var count := rng.randi_range(6, 9)
	var r := 1.0
	var a := 0.0
	f.append(_circle(Vector2.ZERO, 1.0))
	for i in count:
		f.append(_ngon(m, r, a))
		r *= cos(PI / m)
		a += PI / m
	f.append(_circle(Vector2.ZERO, r))


## The golden rectangle cut into squares, and the spiral that runs through them.
static func _golden(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	var x := -PHI / 2.0
	var y := -0.5
	var w := PHI
	var h := 1.0
	f.append(_rect(x, y, w, h))
	var spiral := PackedVector2Array()
	var steps := rng.randi_range(7, 9)
	for i in steps:
		match i % 4:
			0:
				f.append(_rect(x, y, h, h))
				_arc_into(spiral, Vector2(x + h, y + h), h, PI, 1.5 * PI)
				x += h
				w -= h
			1:
				f.append(_rect(x, y, w, w))
				_arc_into(spiral, Vector2(x, y + w), w, -0.5 * PI, 0.0)
				y += w
				h -= w
			2:
				f.append(_rect(x + w - h, y, h, h))
				_arc_into(spiral, Vector2(x + w - h, y), h, 0.0, 0.5 * PI)
				w -= h
			_:
				f.append(_rect(x, y + h - w, w, w))
				_arc_into(spiral, Vector2(x + w, y + h - w), w, 0.5 * PI, PI)
				h -= w
	f.append(spiral)
	f.append(_circle(Vector2.ZERO, PHI * 0.62))


## Nine triangles crossing in a circle, four pointing up and five down, a point in the middle,
## petals and the square with its gates.
static func _sri_yantra(f: Array[PackedVector2Array], rng: RandomNumberGenerator) -> void:
	f.append(_circle(Vector2(0, 0.06), 0.03))
	var ups := [[-0.82, 0.48], [-0.6, 0.3], [-0.36, 0.14], [-0.14, 0.22]]
	var downs := [[0.86, -0.56], [0.66, -0.4], [0.48, -0.2], [0.3, -0.06], [0.18, -0.3]]
	for t in downs + ups:
		var apex: float = t[0]
		var base: float = t[1]
		var hw := sqrt(maxf(0.0, 1.0 - base * base)) * (0.92 - absf(apex - base) * 0.12)
		f.append(PackedVector2Array([Vector2(0, apex), Vector2(hw, base), Vector2(-hw, base), Vector2(0, apex)]))
	f.append(_circle(Vector2.ZERO, 1.0))
	var k := 8 if rng.randf() < 0.5 else 16
	for i in k:
		f.append(_petal(i * TAU / k, 1.0, 1.25, PI / k))
	f.append(_circle(Vector2.ZERO, 1.25))
	f.append(_circle(Vector2.ZERO, 1.32))
	# the square with a gate in the middle of each side
	var s := 1.5
	var g := 0.28
	for side in 4:
		var rot := side * PI / 2.0
		var gate := PackedVector2Array([Vector2(-s, -s), Vector2(-g, -s), Vector2(-g, -s - 0.18),
			Vector2(g, -s - 0.18), Vector2(g, -s), Vector2(s, -s)])
		for i in gate.size():
			gate[i] = gate[i].rotated(rot)
		f.append(gate)


## The ten spheres of the tree of life and its twenty-two paths.
static func _tree_of_life(f: Array[PackedVector2Array], _rng: RandomNumberGenerator) -> void:
	var cs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0.58), Vector2(-1, 0.58), Vector2(1, 1.73),
		Vector2(-1, 1.73), Vector2(0, 2.31), Vector2(1, 2.89), Vector2(-1, 2.89), Vector2(0, 3.46),
		Vector2(0, 4.62)]
	var paths := [[0, 1], [0, 2], [0, 5], [1, 2], [1, 3], [1, 5], [2, 4], [2, 5], [3, 4], [3, 5],
		[3, 6], [4, 5], [4, 7], [5, 6], [5, 7], [5, 8], [6, 7], [6, 8], [6, 9], [7, 8], [7, 9], [8, 9]]
	var r := 0.26
	for i in cs.size():
		cs[i] -= Vector2(0, 2.31)
	for c in cs:
		f.append(_circle(c, r))
	for p in paths:
		var a: Vector2 = cs[p[0]]
		var b: Vector2 = cs[p[1]]
		var d := (b - a).normalized() * r
		f.append(PackedVector2Array([a + d, b - d]))


# --- strokes --------------------------------------------------------------------------------------

## A circle drawn from angle `start`, so neighbours can begin where they touch the centre.
static func _circle(c: Vector2, r: float, start := -PI / 2.0) -> PackedVector2Array:
	var segs := clampi(int(r * 90.0), 24, 96)
	var s := PackedVector2Array()
	for i in segs + 1:
		s.append(c + Vector2.from_angle(start + TAU * i / segs) * r)
	return s


## The centres of a hexagonal grid of unit spacing, `rings` rings out, nearest first.
static func _hex_points(rings: int) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for q in range(-rings, rings + 1):
		for r in range(-rings, rings + 1):
			if absi(q + r) <= rings:
				pts.append(Vector2.from_angle(0.0) * q + Vector2.from_angle(PI / 3.0) * r)
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.length() < b.length() - 0.001 or (absf(a.length() - b.length()) <= 0.001 and a.angle() < b.angle()))
	return pts


static func _ngon(m: int, r: float, start: float) -> PackedVector2Array:
	var s := PackedVector2Array()
	for i in m + 1:
		s.append(Vector2.from_angle(start + TAU * i / m) * r)
	return s


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h), Vector2(x, y)])


static func _arc_into(s: PackedVector2Array, c: Vector2, r: float, from: float, to: float) -> void:
	var segs := 24
	for i in segs + 1:
		s.append(c + Vector2.from_angle(lerpf(from, to, float(i) / segs)) * r)


## A petal pointing at angle `a`, from radius r1 to r2, `half` radians wide at its widest.
static func _petal(a: float, r1: float, r2: float, half: float) -> PackedVector2Array:
	var s := PackedVector2Array()
	var segs := 16
	for i in segs + 1:
		var t := float(i) / segs
		s.append(Vector2.from_angle(a + half * sin(PI * t)) * lerpf(r1, r2, t))
	for i in range(segs - 1, -1, -1):
		var t := float(i) / segs
		s.append(Vector2.from_angle(a - half * sin(PI * t)) * lerpf(r1, r2, t))
	return s
