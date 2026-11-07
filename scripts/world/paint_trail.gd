class_name PaintTrail
extends Node2D
## Where the light has passed, the line itself has turned to watercolour (shaders/paint_stroke.gdshader):
## the ink line becomes a stroke of paint as wide as it was (a little wider, as a brush would), in the
## line's own colour for that stretch (grey at first, the chapters' colours as they come back),
## granulated, pooled at its edges, ragged where the water ran. Path draws the ink line ahead only.
## Every note caught drops a small bloom of pigment where the light is.

const STEP := 6.0           # px between the stroke's points
const WIDTH := 2.6         # times the ink line's width (PathView.LINE_W)
const BLOOM_LIFE := 2.2

var path: PathData
var tip: Node2D
## The line's width as the camera sees it (Main keeps it with the path's).
var width_scale := 1.0

var _strokes: Array[Line2D] = []
var _barrier := -1          # the barrier the current stroke leads to
var _done := 0.0            # how far along the line the strokes reach
var _mat: ShaderMaterial
var _blooms: Array[Dictionary] = []   # {p, col, t, r}
var _tex: ImageTexture      # plain white: a Line2D only gives the shader its UV when it has a texture


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/paint_stroke.gdshader")
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_tex = ImageTexture.create_from_image(img)


func reset() -> void:
	for s in _strokes:
		s.queue_free()
	_strokes.clear()
	_barrier = -1
	_done = 0.0
	_blooms.clear()


## A note caught: a small bloom of pigment where the light is.
func bloom() -> void:
	if tip == null:
		return
	var col := _col(GameState.stage)
	_blooms.append({"p": tip.position + Vector2(randf_range(-6, 6), randf_range(-6, 6)), "col": col, "t": 0.0,
		"r": randf_range(16.0, 26.0), "s": randf() * 100.0})


func _col(n: int) -> Color:
	var c := Palette.line_col(n)
	if BuildFlags.is_dark(n):
		c = Palette.GOLD.lightened(0.2)   # in the dark, the line turns to light
	return c


func _process(delta: float) -> void:
	if path == null or tip == null:
		return
	var at: float = tip.lit
	if at < _done - 1.0:
		reset()   # a new game, or a jump back
	# a new stroke for each barrier's stretch, in its colour
	if GameState.stage != _barrier:
		_barrier = GameState.stage
		var s := Line2D.new()
		s.width = WIDTH * 2.2 * width_scale
		s.default_color = _col(_barrier)
		s.joint_mode = Line2D.LINE_JOINT_ROUND
		s.begin_cap_mode = Line2D.LINE_CAP_ROUND
		s.end_cap_mode = Line2D.LINE_CAP_ROUND
		s.antialiased = true
		s.texture = _tex
		s.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		var m := _mat.duplicate() as ShaderMaterial
		m.set_shader_parameter("seed", float(_barrier) * 1.7)
		m.set_shader_parameter("strength", 1.0)
		s.material = m
		add_child(s)
		if _done > 0.0:
			s.add_point(path.pos_at(_done))
		_strokes.append(s)
	for s in _strokes:
		s.width = WIDTH * 2.2 * width_scale
	var cur: Line2D = _strokes[-1]
	while _done + STEP <= at:
		_done += STEP
		cur.add_point(path.pos_at(_done))
	for b in _blooms:
		b.t += delta
	_blooms = _blooms.filter(func(b: Dictionary) -> bool: return b.t < BLOOM_LIFE)
	queue_redraw()


## The blooms: a drop of pigment spreading into wet paper, its edge darker, fading as it dries.
func _draw() -> void:
	for b in _blooms:
		var k: float = b.t / BLOOM_LIFE
		var r: float = b.r * (0.4 + 0.6 * (1.0 - pow(1.0 - k, 3.0)))
		var a := (1.0 - k) * 0.35
		var col: Color = b.col
		var pts := PackedVector2Array()
		for i in 20:
			var ang := TAU * i / 20.0
			var wob := 1.0 + 0.18 * sin(ang * 3.0 + b.s) + 0.1 * sin(ang * 7.0 + b.s * 2.0)
			pts.append(b.p + Vector2.from_angle(ang) * r * wob)
		draw_colored_polygon(pts, Color(col, a * 0.5))
		pts.append(pts[0])
		draw_polyline(pts, Color(col.darkened(0.15), a), 1.6, true)
