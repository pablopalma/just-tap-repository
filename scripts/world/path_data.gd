class_name PathData
extends RefCounted
## Deterministic path (design doc §6.1). The world is y-down, so the line climbs toward negative y.

const FINAL := Zones.FINAL
const GAP := 150.0
const START_Y := 520.0
## Zone SPIRAL_ZONE's line is a double spiral: it winds in to a centre and back out along the arm in
## between, never crossing itself, and comes out where the zone would have ended anyway, so the
## rest of the world stays where it was. Its barriers are spread evenly along it.
const SPIRAL_ZONE := 3
const SPIRAL_R := 520.0
const SPIRAL_TURNS := 1.75
const SPIRAL_STEPS := 160      # points per arm
## How much bigger the tip grows at the spiral's centre (×1 + this).
const SPIRAL_GROW := 3.0

var points := PackedVector2Array()
var lengths := PackedFloat32Array()    # cumulative length at each vertex
var gate_vertex := PackedInt32Array()  # vertex of barrier n; index 0 is the origin
var branches: Array[Dictionary] = []   # {"n": int, "pts": PackedVector2Array, "ring": Vector2}
var spiral_c := Vector2.ZERO
var spiral_from := 0.0   # where along the line the spiral starts and ends
var spiral_to := 0.0
var _spiral_v := Vector2i(-1, -1)      # its first and last vertex


static func rnd(i: int, salt: int) -> float:
	var v := sin(i * 127.1 + salt * 311.7) * 43758.5453
	return v - floorf(v)


func _init() -> void:
	points.append(Vector2(0, START_Y))
	points.append(Vector2.ZERO)
	gate_vertex.append(1)
	var g := Vector2.ZERO
	var i := 1
	while i <= FINAL:
		if i == (SPIRAL_ZONE - 1) * 10 + 1:
			g = _spiral(g, i)
			i += 10
			continue
		points.append(Vector2(g.x, g.y - 30.0))
		var nx := g.x
		if rnd(i, 1) < 0.7:
			var dx := 45.0 if rnd(i, 2) < 0.5 else 75.0
			if rnd(i, 3) < 0.5:
				dx = -dx
			nx = clampf(g.x + dx, -95.0, 95.0)
			if not is_equal_approx(nx, g.x):
				points.append(Vector2(nx, g.y - 30.0 - absf(nx - g.x)))
		var gp := Vector2(nx, g.y - GAP)
		points.append(gp)
		gate_vertex.append(points.size() - 1)
		_add_branches(i, gp)
		g = gp
		i += 1

	var acc := 0.0
	lengths.append(0.0)
	for v in range(1, points.size()):
		acc += points[v - 1].distance_to(points[v])
		lengths.append(acc)
	if _spiral_v.x >= 0:
		spiral_from = lengths[_spiral_v.x]
		spiral_to = lengths[_spiral_v.y]


## The ten barriers from `first` as a double spiral from g; returns where it comes out (the place
## the zone's last barrier would have been).
func _spiral(g: Vector2, first: int) -> Vector2:
	var end := Vector2(g.x, g.y - 10.0 * GAP)
	spiral_c = (g + end) * 0.5
	var c := spiral_c
	var arm_in := PackedVector2Array()
	for k in SPIRAL_STEPS + 1:
		var s := float(k) / SPIRAL_STEPS
		var a := PI * 0.5 + TAU * SPIRAL_TURNS * s
		arm_in.append(c + Vector2(cos(a), sin(a)) * SPIRAL_R * (1.0 - s))
	# in from below, round and round to the centre, then out along the arm in between (the first one
	# turned half a turn round the centre), and up to where the zone ends
	var line := PackedVector2Array([g])
	line.append_array(arm_in)
	for k in range(SPIRAL_STEPS - 1, -1, -1):
		line.append(c * 2.0 - arm_in[k])
	line.append(end)
	var total := 0.0
	for k in range(1, line.size()):
		total += line[k - 1].distance_to(line[k])
	_spiral_v.x = points.size() - 1
	var done := 0.0
	var next := 1
	for k in range(1, line.size()):
		var a := line[k - 1]
		var b := line[k]
		var seg := a.distance_to(b)
		while next <= 10 and done + seg >= total * next / 10.0 - 0.01:
			var at := a.lerp(b, clampf((total * next / 10.0 - done) / maxf(seg, 0.001), 0.0, 1.0))
			if not points[points.size() - 1].is_equal_approx(at):
				points.append(at)
			gate_vertex.append(points.size() - 1)
			next += 1
		done += seg
		if not points[points.size() - 1].is_equal_approx(b):
			points.append(b)
	_spiral_v.y = points.size() - 1
	return end


static func in_spiral(n: int) -> bool:
	return (n - 1) / 10 + 1 == SPIRAL_ZONE


## Along the spiral the tip grows towards its centre, and is back to its size as it comes out.
func grow_at(d: float) -> float:
	if _spiral_v.x < 0 or d <= spiral_from or d >= spiral_to:
		return 1.0
	var k := 1.0 - clampf(pos_at(d).distance_to(spiral_c) / SPIRAL_R, 0.0, 1.0)
	return 1.0 + SPIRAL_GROW * k * k


func on_spiral(d: float) -> bool:
	return _spiral_v.x >= 0 and d > spiral_from - 120.0 and d < spiral_to + 120.0


## Which way the line runs at barrier n (unit vector), for barriers drawn across it.
func gate_dir(n: int) -> Vector2:
	var v := gate_vertex[n]
	if v <= 0:
		return Vector2.UP
	var d := points[v] - points[v - 1]
	return d.normalized() if d.length() > 0.001 else Vector2.UP


## Linelight-style decoration: a lateral branch (sometimes with a diagonal kink) ending in a small
## ring, and sometimes a floating piece disconnected from the line.
func _add_branches(i: int, gp: Vector2) -> void:
	if rnd(i, 4) < 0.7:
		var side := -1.0 if rnd(i, 5) < 0.5 else 1.0
		var a := Vector2(gp.x, gp.y + 40.0)
		var pts := PackedVector2Array([a, a + Vector2(side * (40.0 + 90.0 * rnd(i, 6)), 0.0)])
		if rnd(i, 7) < 0.4:
			var d := 20.0 + 15.0 * rnd(i, 9)
			pts.append(pts[1] + Vector2(side * d, -d))
		branches.append({"n": i, "pts": pts, "ring": pts[pts.size() - 1]})
	if rnd(i, 8) < 0.35:
		var side := -1.0 if rnd(i, 10) < 0.5 else 1.0
		var c := Vector2(side * 160.0, gp.y + 75.0)
		var pts := PackedVector2Array([c - Vector2(side * 25.0, 0.0), c + Vector2(side * 25.0, 0.0)])
		branches.append({"n": i, "pts": pts, "ring": pts[1]})


func total_length() -> float:
	return lengths[lengths.size() - 1]


func gate_pos(n: int) -> Vector2:
	return points[gate_vertex[n]]


func gate_len(n: int) -> float:
	return lengths[gate_vertex[n]]


## Point at distance d along the path.
func pos_at(d: float) -> Vector2:
	d = clampf(d, 0.0, total_length())
	var lo := 0
	var hi := lengths.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if lengths[mid] <= d:
			lo = mid
		else:
			hi = mid
	var seg := lengths[hi] - lengths[lo]
	var t := 0.0 if seg <= 0.0 else (d - lengths[lo]) / seg
	return points[lo].lerp(points[hi], t)
