extends Node2D
## Prototype (docs/pendientes.md, "La espiral hacia abajo"): a spiral sinking into the depth, seen
## from above. The light goes down it turn by turn: what lies deeper is drawn smaller, nearer the
## centre and fainter, like looking down a well, with a light at the bottom that grows as you go.
## No 3D: every point of the helix has a depth and is projected (a tunnel in 2D).
## Tap (space, click, a gamepad's A) to push the light down to the next barrier; on the beat it
## counts double. Near the bottom a radiant light comes out of it; when the last barrier breaks the
## light goes down on its own, faster and faster, a gold glow fills everything and the next scene
## begins (here, the well again). `-- auto` taps on its own, on the beat; `-- end` starts a few
## barriers from the bottom. To record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/spiral_down.tscn -- auto end

const R := 1.0              # the helix's radius, in world units
const PITCH := 0.32         # depth gained per radian
const TURNS := 14           # how deep the well goes
const STEPS := 64           # points per turn
const BARRIERS_PER_TURN := 3
const BARRIER_HP := 6.0
const EYE := 3.2            # the camera's height above the light
const RING_PX := 250.0      # the light's circle on screen
const INNER := 0.84         # the inner rail: the path is a ribbon, like a spiral staircase
const RUNG := 0.22          # radians between the steps across it
const MOTES := 90
## The ending: the descent on its own (radians per second, growing), the glow filling the screen,
## how long it holds, and how long the next scene takes to come in.
const DIVE_SPEED := 1.2
const DIVE_GROW := 1.6
const GLOW_TIME := 4.5
const GLOW_HOLD := 1.6
const NEXT_TIME := 2.2
const GLOW_COL := Color(1.0, 0.86, 0.48)
const AHEAD := 9            # turns drawn below the light
const BEHIND := 0.6         # turns drawn above it, fading out

var _theta := 0.0           # where the light is, along the helix (radians)
var _target := 0.0
var _barrier := 1           # the next barrier's index
var _hp := BARRIER_HP
var _cam := 0.0             # the camera's turn, following the light softly
var _run := 0
var _last_beat := -100
var _kick := 0.0
var _rings: Array[Dictionary] = []   # {theta, t}: barriers breaking
var _auto := false
var _t := 0.0
var _font: Font
## Dust in the well: {a, depth} in world space; as the light goes down they rise past the camera.
var _motes: Array[Dictionary] = []
var _ending := -1.0         # seconds since the last barrier broke, or -1
var _dive := 0.0


func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	_font = UIStyle.font()
	SaveSystem.enabled = false
	# the starry night's theme, for the mood
	Music.zone = 4
	Music._pending_zone = 4
	Music.start()
	if DevMenu.proto_has("end"):
		_barrier = _total() - 3
		_theta = _barrier_theta(_barrier - 1) + 0.2
		_target = _theta
	_cam = _theta
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in MOTES:
		_motes.append({"a": rng.randf() * TAU, "r": rng.randf_range(0.2, 1.6), "d": rng.randf_range(-1.0, TURNS * TAU * PITCH)})


func _total() -> int:
	return TURNS * BARRIERS_PER_TURN


## How close the bottom is: 0 far, 1 at the last barrier (the radiant light comes out over the last
## three turns).
func _near_end() -> float:
	return clampf(1.0 - (_total() - (_barrier - 1)) / float(BARRIERS_PER_TURN * 3), 0.0, 1.0)


func _barrier_theta(i: int) -> float:
	return TAU * i / BARRIERS_PER_TURN


func _process(delta: float) -> void:
	_t += delta
	if _ending >= 0.0:
		_process_ending(delta)
		return
	if _auto and _t > 1.5:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_tap()
	# the light runs up to just before the next barrier
	var stop := _barrier_theta(_barrier) - 0.08
	_target = minf(_target, stop)
	_theta = lerpf(_theta, _target, 1.0 - exp(-6.0 * delta))
	# the camera turns with it, a little behind: the light stays near the bottom of the screen
	_cam = lerp_angle(_cam, _theta, 1.0 - exp(-3.0 * delta))
	_kick *= exp(-8.0 * delta)
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < 1.6)
	queue_redraw()


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
	var k: int = Music.beat_at_tap()
	var on := k >= 0 and k != _last_beat
	if on:
		_run = _run + 1 if k - _last_beat <= 2 else 1
		_last_beat = k
		Music.play_accent(_run)
	else:
		_run = 0
		Music.play_tap(1.0 - _hp / BARRIER_HP, false)
	_kick = 1.0
	_hp -= 2.0 if on else 1.0
	# each tap eases the light a little closer to the barrier
	var stop := _barrier_theta(_barrier)
	_target = lerpf(_theta, stop, 0.35)
	if _hp <= 0.0:
		_rings.append({"theta": stop, "t": 0.0})
		Music.choir_swell()
		_barrier += 1
		_hp = BARRIER_HP
		_target = stop + 0.15
		if _barrier > _total():
			_begin_ending()


## The last barrier broke: no more taps, the light goes down on its own into the light.
func _begin_ending() -> void:
	_ending = 0.0
	_dive = DIVE_SPEED
	Music.play_milestone(5)
	Music.choir_swell()


func _process_ending(delta: float) -> void:
	_ending += delta
	_dive += DIVE_GROW * delta
	_theta += _dive * delta
	_cam = lerp_angle(_cam, _theta, 1.0 - exp(-3.0 * delta))
	if _ending - delta < GLOW_TIME * 0.7 and _ending >= GLOW_TIME * 0.7:
		Music.resolve_chord()
	for r in _rings:
		r.t += delta
	if _ending > GLOW_TIME + GLOW_HOLD + NEXT_TIME:
		get_tree().reload_current_scene()   # the next scene; in the prototype, the well again
	queue_redraw()


## 0..1: the gold glow over everything, then the next scene's paper coming in.
func _glow() -> float:
	return clampf(_ending / GLOW_TIME, 0.0, 1.0) if _ending >= 0.0 else 0.0


func _next() -> float:
	return clampf((_ending - GLOW_TIME - GLOW_HOLD) / NEXT_TIME, 0.0, 1.0) if _ending >= 0.0 else 0.0


## A point of the helix on screen, and how near it is (its scale; 1 at the light).
func _project(theta: float, radius := R) -> Array:
	var depth := (theta - _theta) * PITCH          # below the light: positive
	return _project_at(theta - _cam + PI * 0.5, radius, depth)   # the light sits at the bottom


## Any point of the well: its angle on screen, its radius and its depth below the light.
func _project_at(a: float, radius: float, depth: float) -> Array:
	var rel := EYE + depth
	if rel < 0.35:
		return []
	var s := EYE / rel
	return [_centre() + Vector2.from_angle(a) * radius * RING_PX * s, s]


func _centre() -> Vector2:
	return get_viewport_rect().size * 0.5 + Vector2(0, -10)


func _draw() -> void:
	var size := get_viewport_rect().size
	var c := _centre()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.075, 0.07, 0.085))
	_draw_backdrop(c)
	var ink := Color(0.93, 0.9, 0.84)
	var gold := Palette.GOLD
	var progress := _light_amount()
	# the light at the bottom of the well, growing as you go down
	for i in 6:
		var r := (18.0 + 70.0 * progress) * (1.0 + i * 0.7)
		draw_circle(c, r, Color(gold, (0.05 + 0.08 * progress) / (1 + i)))
	# near the bottom, a radiant light comes out of it: rays turning slowly, a brighter heart
	var near := maxf(_near_end(), 1.0 if _ending >= 0.0 else 0.0)
	if near > 0.0:
		var e := near * near
		var rays := 18
		for i in rays:
			var a := TAU * i / rays + _t * 0.15
			var length := (120.0 + 520.0 * e) * (0.75 + 0.25 * sin(_t * 1.3 + i * 1.7))
			var w := (10.0 + 30.0 * e) * (0.6 + 0.4 * sin(i * 2.3))
			var dir := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([c + dir.orthogonal() * w * 0.5, c + dir * length, c - dir.orthogonal() * w * 0.5]),
				Color(GLOW_COL, 0.10 * e))
		for i in 5:
			draw_circle(c, (24.0 + 90.0 * e) * (1.0 + i * 0.6), Color(GLOW_COL, 0.18 * e / (1 + i)))
		draw_circle(c, 10.0 + 30.0 * e, Color(1, 0.97, 0.88, 0.8 * e))
	# the helix: deeper is smaller, nearer the centre, fainter; above the light it fades out
	var from := _theta - BEHIND * TAU
	var to := minf(_theta + AHEAD * TAU, TURNS * TAU)
	var n := int((to - from) / TAU * STEPS)
	# dust rising past as you go down
	var depth_now := _theta * PITCH
	for m in _motes:
		var p := _project_at(float(m.a) - _cam, float(m.r), float(m.d) - depth_now)
		if p.is_empty():
			continue
		var ms: float = p[1]
		draw_circle(p[0], clampf(1.6 * ms, 0.4, 4.0), Color(ink, clampf(0.35 * ms, 0.0, 0.5)))
	for rail in [R, R * INNER]:
		var prev: Array = []
		for i in n + 1:
			var th := from + (to - from) * i / n
			var p := _project(th, rail)
			if p.is_empty():
				prev = []
				continue
			if not prev.is_empty():
				var s: float = p[1]
				var lit := th <= _theta
				var fade := clampf(s * 1.2, 0.0, 1.0) if not lit else clampf(1.0 - (_theta - th) / (BEHIND * TAU), 0.0, 1.0)
				var k := 1.0 if rail == R else 0.55
				var col := Color(ink, (0.85 if lit else 0.5) * fade * k)
				draw_line(prev[0], p[0], col, clampf(2.4 * s * k, 0.5, 6.0), true)
			prev = p
	# the steps across the path, faint: a spiral staircase going down
	var first := ceilf(from / RUNG) * RUNG
	var th2 := first
	while th2 < to:
		var o := _project(th2, R)
		var i2 := _project(th2, R * INNER)
		if not o.is_empty() and not i2.is_empty():
			var s2: float = o[1]
			var lit2 := th2 <= _theta
			var f2 := clampf(s2 * 1.1, 0.0, 1.0) if not lit2 else clampf(1.0 - (_theta - th2) / (BEHIND * TAU), 0.0, 1.0)
			draw_line(o[0], i2[0], Color(ink, 0.18 * f2), clampf(1.2 * s2, 0.4, 3.0), true)
		th2 += RUNG

	_draw_barriers(c, ink)
	# barriers breaking: a gold ring where they were
	for r in _rings:
		if float(r.theta) < _theta - 0.35:
			continue   # already behind the camera
		var p := _project(r.theta)
		if p.is_empty():
			continue
		var k: float = r.t / 1.6
		draw_arc(p[0], (12.0 + 80.0 * k) * float(p[1]), 0.0, TAU, 48, Color(gold, 0.8 * (1.0 - k)), 2.2, true)
	# the light
	var lp := _project(_theta, R * (1.0 + INNER) * 0.5)
	if not lp.is_empty():
		var pos: Vector2 = lp[0]
		draw_circle(pos, 26.0 + 8.0 * _kick, Color(gold, 0.12))
		draw_circle(pos, 12.0 + 4.0 * _kick, Color(gold, 0.35))
		draw_circle(pos, 6.0, ink)
		if _run >= 2:
			var worth := GameState.beat_worth(_run)
			var txt := "×%s" % (str(int(worth)) if is_equal_approx(worth, roundf(worth)) else "%.1f" % worth)
			draw_string(_font, pos + Vector2(-90, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(gold, 0.9))
	if _ending < 0.0:
		draw_string(_font, Vector2(24, size.y - 24), _hint_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(ink, 0.45))
	# the end: a gold glow grows from the centre until it fills everything, then the next scene's
	# paper comes in over it
	var g := _glow()
	if g > 0.0:
		var k := g * g * (3.0 - 2.0 * g)
		var far := size.length()
		for i in 8:
			var r := lerpf(40.0, far, k) * (0.4 + i * 0.12)
			draw_circle(c, r, Color(GLOW_COL, 0.16 * k))
		draw_rect(Rect2(Vector2.ZERO, size), Color(GLOW_COL, smoothstep(0.55, 1.0, g)))
	var nx := _next()
	if nx > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.PAPER, nx))


## How bright the light at the bottom is (0..1): how far down you are.
func _light_amount() -> float:
	return float(_barrier - 1) / _total()


func _hint_text() -> String:
	return "space / click / A · on the beat counts double   %d / %d" % [_barrier - 1, _total()]


## The barriers ahead: a short stroke across the path, the next one opening as it is tapped.
func _draw_barriers(c: Vector2, ink: Color) -> void:
	for b in range(_barrier, mini(_barrier + AHEAD * BARRIERS_PER_TURN, TURNS * BARRIERS_PER_TURN + 1)):
		var th := _barrier_theta(b)
		var p := _project(th, R * (1.0 + INNER) * 0.5)
		if p.is_empty():
			continue
		var s: float = p[1]
		var dir: Vector2 = (p[0] - c).normalized()
		var half := 22.0 * s
		var gap := 0.0
		if b == _barrier:
			gap = (1.0 - _hp / BARRIER_HP) * 14.0 * s
		var a := clampf(s * 1.3, 0.0, 1.0) * (1.0 if b == _barrier else 0.6)
		var w := clampf(3.0 * s, 0.8, 5.0)
		if gap > 0.5:
			draw_line(p[0] - dir * half, p[0] - dir * gap, Color(ink, a), w, true)
			draw_line(p[0] + dir * gap, p[0] + dir * half, Color(ink, a), w, true)
		else:
			draw_line(p[0] - dir * half, p[0] + dir * half, Color(ink, a), w, true)


## Behind the well (nothing here; the rhythm passage draws its creature).
func _draw_backdrop(_c: Vector2) -> void:
	pass
