extends CanvasLayer
## The starry night (zone NIGHT_ZONE in Main): the world turns to its negative (Darkness, as the
## dark does, but gentler) and the sky fills with small white points, twinkling. The zone's barriers
## are stars: the ones ahead are out, faint; breaking one lights it, with a clear note and a glint
## that opens into rays and settles, and it stays lit in the sky. Over the world, under the dive.

const STARS := 260
const GLINT := 1.6

var path: PathData
## The night's barriers: first..last.
var first := 31
var last := 40

var _a := 0.0                 # how much night (0..1)
var _tween: Tween
var _t := 0.0
var _sky: Array[Vector4] = [] # x, y (0..1 of the screen), size, phase
var _lit := {}                # barrier -> time it lit
var _canvas: Node2D


func _ready() -> void:
	layer = 7
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_night)
	add_child(_canvas)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1111
	for i in STARS:
		_sky.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.6, 2.2) * (2.0 if rng.randf() < 0.06 else 1.0),
			rng.randf() * TAU))
	visible = false


func is_on() -> bool:
	return _a > 0.01


func set_on(on: bool, time: float) -> void:
	if _tween:
		_tween.kill()
	visible = true
	if time <= 0.0:
		_a = 1.0 if on else 0.0
		visible = on
		return
	_tween = create_tween()
	_tween.tween_property(self, "_a", 1.0 if on else 0.0, time).set_trans(Tween.TRANS_SINE)
	if not on:
		_tween.tween_callback(func() -> void: visible = false)


## The night's barriers already broken (a save, a jump): lit at once, no glint.
func light_up_to(stage: int) -> void:
	_lit.clear()
	for n in range(first, mini(stage, last + 1)):
		_lit[n] = -100.0


## Barrier n broke: its star lights, with a clear note and a glint.
func light(n: int) -> void:
	if n < first or n > last or _lit.has(n):
		return
	_lit[n] = _t
	Music.star_note(n - first)


func reset() -> void:
	_lit.clear()
	set_on(false, 0.0)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		_canvas.queue_redraw()


func _draw_night() -> void:
	if _a <= 0.0 or path == null:
		return
	var vs := _canvas.get_viewport_rect().size
	var unit := vs.y / 720.0
	var white := Color(0.96, 0.97, 1.0)
	# the sky: small points, each twinkling at its own pace
	for s in _sky:
		var tw := 0.55 + 0.45 * sin(_t * (0.7 + s.z * 0.6) + s.w)
		_canvas.draw_circle(Vector2(s.x * vs.x, s.y * vs.y), s.z * 0.9 * unit, Color(white, 0.55 * tw * _a))
	# the barriers, as stars where they stand in the world
	var ct := _canvas.get_viewport().get_canvas_transform()
	for n in range(first, last + 1):
		var p := ct * path.gate_pos(n)
		if p.x < -200 or p.y < -200 or p.x > vs.x + 200 or p.y > vs.y + 200:
			continue
		if not _lit.has(n):
			_canvas.draw_circle(p, 3.0 * unit, Color(white, 0.5 * _a))
			_spark(p, 10.0 * unit, Color(white, 0.25 * _a), 0.0)
			continue
		var k := clampf((_t - float(_lit[n])) / GLINT, 0.0, 1.0)
		var tw := 0.8 + 0.2 * sin(_t * 1.9 + n)
		# the glint: rays shoot out and draw back in, a ring opens, the core settles
		var ray := lerpf(150.0, 16.0, 1.0 - pow(1.0 - k, 3.0)) * unit if k < 1.0 else 16.0 * unit * tw
		var gold := Palette.GOLD.lightened(0.55)
		_canvas.draw_circle(p, (14.0 + 30.0 * (1.0 - k)) * unit, Color(gold, (0.22 + 0.3 * (1.0 - k)) * _a))
		_spark(p, ray, Color(white, (0.75 + 0.25 * (1.0 - k)) * _a), _t * 0.15 + n)
		_spark(p, ray * 0.55, Color(gold, 0.6 * _a), _t * 0.15 + n + PI / 4.0)
		_canvas.draw_circle(p, 4.2 * unit, Color(white, _a))
		if k < 1.0:
			_canvas.draw_arc(p, lerpf(6.0, 90.0, 1.0 - pow(1.0 - k, 2.0)) * unit, 0.0, TAU, 64,
				Color(gold, (1.0 - k) * 0.8 * _a), 2.0 * unit, true)


## A four-pointed star of light: two thin crossed rays, fading to their tips.
func _spark(p: Vector2, r: float, col: Color, turn: float) -> void:
	if r <= 0.5 or col.a <= 0.002:
		return
	for i in 2:
		var d := Vector2.from_angle(turn + i * PI * 0.5)
		for s in [-1.0, 1.0]:
			_canvas.draw_line(p, p + d * r * s, col, 1.6, true)
			_canvas.draw_line(p + d * r * 0.5 * s, p + d * r * s, Color(col, col.a * 0.4), 1.0, true)
