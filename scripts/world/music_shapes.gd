extends Node2D
## Musical shapes (§7.4): what sounds is seen. Every tap note and every accompaniment note gives
## birth to a shape beside the tower — a triangle, square, pentagon or hexagon chosen by the note,
## a circle for the bright high ones — that grows, turns and fades in 3.2–4.4 s.

const MAX_SHAPES := 48
const MIN_GAP := 0.09   # seconds between two shapes, so fast tapping stays readable

## Where the camera looks, set by Main every frame; shapes are born around it.
var focus := Vector2.ZERO

var _shapes: Array[Dictionary] = []
var _since := 0.0
var _side := 1.0


func _ready() -> void:
	Music.shape_note.connect(_on_note)


func clear() -> void:
	_shapes.clear()
	queue_redraw()


func _on_note(midi: int, bright: bool) -> void:
	if _since < MIN_GAP:
		return
	_since = 0.0
	if _shapes.size() >= MAX_SHAPES:
		_shapes.pop_front()
	_side = -_side
	var pos := focus + Vector2(_side * randf_range(150.0, 430.0), randf_range(-240.0, 200.0))
	_shapes.append({
		"pos": pos,
		"sides": 0 if bright else 3 + posmod(midi, 4),
		"r": randf_range(10.0, 20.0) * (0.8 if bright else 1.0),
		"rot": randf() * TAU,
		"spin": randf_range(-0.7, 0.7),
		"t": 0.0,
		"life": randf_range(3.2, 4.4),
		"col": Palette.paint_col(Zones.of(GameState.stage), midi),
	})


func _process(delta: float) -> void:
	_since += delta
	if _shapes.is_empty():
		return
	for i in range(_shapes.size() - 1, -1, -1):
		var s: Dictionary = _shapes[i]
		s.t += delta
		s.rot += s.spin * delta
		if s.t >= s.life:
			_shapes.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for s in _shapes:
		var k: float = s.t / s.life
		var grow := lerpf(1.0, 1.8, 1.0 - pow(1.0 - k, 2.0))
		var a := minf(1.0, k * 8.0) * (1.0 - k)
		var r: float = s.r * grow
		var col: Color = s.col
		if s.sides == 0:
			draw_circle(s.pos, r, Color(col, 0.10 * a))
			draw_arc(s.pos, r, 0.0, TAU, 40, Color(Palette.INK, 0.45 * a), 1.1, true)
			continue
		var pts := PackedVector2Array()
		for j in s.sides + 1:
			pts.append(s.pos + Vector2.from_angle(s.rot + TAU * j / s.sides) * r)
		var fill := PackedVector2Array(pts)
		fill.resize(s.sides)
		draw_colored_polygon(fill, Color(col, 0.10 * a))
		draw_polyline(pts, Color(Palette.INK, 0.45 * a), 1.1, true)
