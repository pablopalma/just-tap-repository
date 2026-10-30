extends Node2D
## Barriers (§6.3). Damage opens a hole in the current one; broken ones leave two stumps and a small
## ring; future ones draw themselves from the centre the first time they come into view.

const HALF := 36.0
const WIDTH := 2.6
const APPEAR := 1.5
const AHEAD := 8
const BEHIND := 6

var path: PathData
var font: Font

var _appear := {}  # n -> time it first came into view
var _t := 0.0


var _wobble := 0.0


func reset() -> void:
	_appear.clear()


## The current barrier trembles where it was hit.
func hit(strength: float) -> void:
	_wobble = minf(1.6, _wobble + strength)


func _process(delta: float) -> void:
	_t += delta
	_wobble *= exp(-7.0 * delta)
	queue_redraw()


func _draw() -> void:
	if path == null:
		return
	var s := GameState.stage
	for n in range(maxi(1, s - BEHIND), mini(PathData.FINAL, s + AHEAD) + 1):
		var p := path.gate_pos(n)
		if n < s or GameState.finished:
			_draw_broken(p, n)
		elif n == s:
			_draw_current(p)
		else:
			_draw_future(p, n)


func _draw_current(p: Vector2) -> void:
	var hole := 3.0 + GameState.progress() * 26.0 + _wobble * 3.0
	# Each half vibrates on its own: inner ends move most, like a struck string.
	var wv := sin(_t * 58.0) * 3.2 * _wobble
	_bar(p + Vector2(-HALF, wv * 0.3), p + Vector2(-hole, -wv), Palette.INK)
	_bar(p + Vector2(hole, -wv), p + Vector2(HALF, wv * 0.3), Palette.INK)
	if font:
		var dim := Color(Palette.INK, 0.65)
		draw_string(font, p + Vector2(HALF + 12, 5), Fmt.num(maxf(0.0, GameState.hp)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, dim)
		var r := GameState.regen(GameState.stage)
		if r > 0.0:
			draw_string(font, p + Vector2(HALF + 12, 22), "+%s/s" % Fmt.num(r),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.INK, 0.4))


func _draw_future(p: Vector2, n: int) -> void:
	if not _appear.has(n):
		_appear[n] = _t
	var k := clampf((_t - float(_appear[n])) / APPEAR, 0.0, 1.0)
	k = 1.0 - pow(1.0 - k, 3.0)
	if k <= 0.0:
		return
	var col := Color(Palette.INK, 0.5)
	_bar(p + Vector2(-HALF * k, 0), p + Vector2(HALF * k, 0), col)


func _draw_broken(p: Vector2, n: int) -> void:
	var col := Palette.line_col(n)
	_bar(p + Vector2(-HALF, 0), p + Vector2(-HALF + 12, 0), col)
	_bar(p + Vector2(HALF - 12, 0), p + Vector2(HALF, 0), col)
	draw_arc(p, 4.0, 0.0, TAU, 18, col, 1.2, true)


## Bar with rounded ends.
func _bar(a: Vector2, b: Vector2, col: Color) -> void:
	if a.distance_to(b) < 0.5:
		return
	draw_line(a, b, col, WIDTH, true)
	draw_circle(a, WIDTH * 0.5, col)
	draw_circle(b, WIDTH * 0.5, col)
