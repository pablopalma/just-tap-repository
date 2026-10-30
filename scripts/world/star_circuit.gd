extends Node2D
## Star circuits (§22.3). At certain barriers the tip becomes n lights that run a star around the
## barrier: each light's circuit is a chord (vertex i to i+k), an arc of the circle (to i+k+1) and a
## ray to the centre, with two small barriers on each part. The whole figure turns faster as it fills;
## what the lights have run is traced in gold and the star paints itself in. When every light reaches
## the centre the figure spins up and bursts, and stays behind, painted, turning slowly.

signal burst(center: Vector2)

const R := 150.0
## Where the six small barriers sit along a circuit (0..1 chord, 1..2 arc, 2..3 ray).
const BARRIER_U := [0.4, 0.85, 1.4, 1.85, 2.4, 2.85]
const ENTRY_TIME := 1.3
const CLIMAX_TIME := 2.8

var path: PathData

var _active := false
var _n := 0
var _k := 0
var _center := Vector2.ZERO
var _rot := 0.0
var _t := 0.0
var _u: Array[float] = []          # where each light is along its circuit
var _climax := -1.0                # seconds into the final spin, or -1
var _done: Array[Dictionary] = []  # finished stars: {center, n, k, rot}


func _ready() -> void:
	GameState.special_changed.connect(_on_special)
	GameState.star_light_broke.connect(_on_light_broke)
	GameState.star_completed.connect(_on_completed)


func reset() -> void:
	_active = false
	_climax = -1.0
	_done.clear()
	queue_redraw()


func is_active() -> bool:
	return _active


func center() -> Vector2:
	return _center


func _on_special() -> void:
	if _active and _climax >= 0.0:
		return  # the finished star is still spinning up; it ends on its own
	if GameState.star.is_empty():
		_active = false
		return
	var n := GameState.stage
	_active = true
	_n = int(GameState.star.n)
	_k = int(GameState.star.k)
	_center = path.gate_pos(n)
	_rot = 0.0
	_t = 0.0
	_climax = -1.0
	_u.clear()
	for i in _n:
		_u.append(-1.0)  # still at the centre: the entry sends them out
	Music.choir_swell()
	Music.build_piece(0, 0.0, ENTRY_TIME)
	Narrator.say("small_lights")


func _on_light_broke(i: int, _seg: int) -> void:
	if _active:
		Music.play_star_step(i, _n)


func _on_completed(_n_barrier: int) -> void:
	if not _active:
		return
	_climax = 0.0
	Narrator.say("whole")


func _process(delta: float) -> void:
	for s in _done:
		s.rot += 0.05 * delta
	if not _active:
		if not _done.is_empty():
			queue_redraw()
		return
	_t += delta
	var prog := GameState.progress() if _climax < 0.0 else 1.0
	var spin := 0.12 + 0.35 * prog
	if _climax >= 0.0:
		_climax += delta
		spin += pow(_climax / CLIMAX_TIME, 2.0) * 9.0
		if _climax >= CLIMAX_TIME:
			_finish()
			return
	_rot += spin * delta

	var lights: Array = GameState.star.get("lights", [])
	for i in _n:
		var target := 3.0
		if _climax < 0.0 and i < lights.size() and lights[i].seg < GameState.STAR_SEGMENTS:
			target = BARRIER_U[lights[i].seg] - 0.07
		if _t < ENTRY_TIME:
			_u[i] = lerpf(-1.0, 0.0, smoothstep(0.0, 1.0, _t / ENTRY_TIME))
		else:
			_u[i] = lerpf(_u[i], target, 1.0 - exp(-6.0 * delta))
	queue_redraw()


func _finish() -> void:
	_done.append({"center": _center, "n": _n, "k": _k, "rot": _rot})
	_active = false
	_climax = -1.0
	burst.emit(_center)
	queue_redraw()


# --- Geometry -----------------------------------------------------------------

func _vertex(c: Vector2, n: int, j: int, rot: float) -> Vector2:
	return c + Vector2.from_angle(rot + TAU * posmod(j, n) / n - PI * 0.5) * R


## Point of light i's circuit at u (-1..0 is the entry from the centre to its vertex).
func _at(c: Vector2, n: int, k: int, i: int, u: float, rot: float) -> Vector2:
	var a := _vertex(c, n, i, rot)
	if u < 0.0:
		return c.lerp(a, u + 1.0)
	var b := _vertex(c, n, i + k, rot)
	if u <= 1.0:
		return a.lerp(b, u)
	if u <= 2.0:
		var a0 := rot + TAU * posmod(i + k, n) / n - PI * 0.5
		return c + Vector2.from_angle(a0 + TAU / n * (u - 1.0)) * R
	var e := _vertex(c, n, i + k + 1, rot)
	return e.lerp(c, minf(u - 2.0, 1.0))


func _trace(c: Vector2, n: int, k: int, i: int, u: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := int(maxf(2.0, u * 16.0))
	for s in steps + 1:
		pts.append(_at(c, n, k, i, u * s / steps, rot))
	return pts


# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	for s in _done:
		_draw_star(s.center, s.n, s.k, s.rot, [], 1.0, 0.45)
	if _active:
		var prog := GameState.progress() if _climax < 0.0 else 1.0
		_draw_star(_center, _n, _k, _rot, _u, prog, 1.0)


func _draw_star(c: Vector2, n: int, k: int, rot: float, us: Array, prog: float, alpha: float) -> void:
	var gold := Palette.GOLD
	var col := Palette.chapter_color(maxi(1, Palette.chapter_of(GameState.stage)))
	var ink := Color(Palette.INK, 0.22 * alpha)
	# the star paints itself in: one triangle per chord, overlapping into the star's shape
	var fill := Color(gold.lerp(col, 0.4), 0.16 * prog * alpha)
	for i in n:
		var tri := PackedVector2Array([c, _vertex(c, n, i, rot), _vertex(c, n, i + k, rot)])
		draw_primitive(tri, PackedColorArray([fill, fill, fill]), PackedVector2Array())
	draw_arc(c, R, 0.0, TAU, 96, ink, 1.2, true)
	for i in n:
		draw_line(_vertex(c, n, i, rot), _vertex(c, n, i + k, rot), ink, 1.0, true)
		draw_line(_vertex(c, n, i, rot), c, Color(ink, ink.a * 0.6), 0.8, true)

	var finished := us.is_empty()
	var lights: Array = GameState.star.get("lights", []) if not finished else []
	for i in n:
		var u: float = 3.0 if finished else us[i]
		# gold: what this light has run
		if u > 0.0:
			draw_polyline(_trace(c, n, k, i, u, rot), Color(gold, 0.85 * alpha), 2.4, true)
		if finished:
			continue
		# the small barriers still ahead of it
		var seg: int = lights[i].seg if i < lights.size() else GameState.STAR_SEGMENTS
		for j in range(seg, GameState.STAR_SEGMENTS):
			var bu: float = BARRIER_U[j]
			var p := _at(c, n, k, i, bu, rot)
			var tangent := (_at(c, n, k, i, bu + 0.02, rot) - _at(c, n, k, i, bu - 0.02, rot)).normalized()
			var half := tangent.orthogonal() * 11.0
			var current := j == seg
			var bar := Palette.INK if current else Color(Palette.INK, 0.4)
			var gap := 0.0
			if current and i < lights.size():
				gap = (1.0 - lights[i].hp / lights[i].max) * 8.0
			if gap > 0.5:
				draw_line(p - half, p - half.normalized() * gap, bar, 2.2, true)
				draw_line(p + half.normalized() * gap, p + half, bar, 2.2, true)
			else:
				draw_line(p - half, p + half, bar, 2.2, true)
		# the light itself
		var lp := _at(c, n, k, i, u, rot)
		draw_circle(lp, 13.0, Color(gold, 0.12))
		draw_circle(lp, 7.0, Color(gold, 0.3))
		draw_circle(lp, 3.6, Palette.INK)
	if _climax >= 0.0 and not finished:
		var k2 := _climax / CLIMAX_TIME
		draw_circle(c, 10.0 + 40.0 * k2, Color(gold, 0.25 * k2))
