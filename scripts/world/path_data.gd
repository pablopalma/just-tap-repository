class_name PathData
extends RefCounted
## Deterministic path (design doc §6.1). The world is y-down, so the line climbs toward negative y.

const FINAL := 100
const GAP := 150.0
const START_Y := 520.0

var points := PackedVector2Array()
var lengths := PackedFloat32Array()    # cumulative length at each vertex
var gate_vertex := PackedInt32Array()  # vertex of barrier n; index 0 is the origin
var branches: Array[Dictionary] = []   # {"n": int, "pts": PackedVector2Array, "ring": Vector2}


static func rnd(i: int, salt: int) -> float:
	var v := sin(i * 127.1 + salt * 311.7) * 43758.5453
	return v - floorf(v)


func _init() -> void:
	points.append(Vector2(0, START_Y))
	points.append(Vector2.ZERO)
	gate_vertex.append(1)
	var g := Vector2.ZERO
	for i in range(1, FINAL + 1):
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

	var acc := 0.0
	lengths.append(0.0)
	for v in range(1, points.size()):
		acc += points[v - 1].distance_to(points[v])
		lengths.append(acc)


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
