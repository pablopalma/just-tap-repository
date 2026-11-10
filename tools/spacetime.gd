extends Node2D
## Prototype (10/11/2026, chapter 8 "Cielo", docs/brief-juego-completo.md: "la malla del espacio-tiempo"):
## the paper is a mesh seen in perspective, and the light has weight. Where it is, the mesh sinks
## into a well around it, as in the drawings of relativity; the line it follows sinks with it. Only a
## visual: the light still goes along its line. A tap on the beat makes the light heavier for a moment
## (the well deepens) and sends a ripple out across the mesh, a gravitational wave, as it surges ahead.
## Off the beat: a soft tap, a small dip. The well lags behind the light a little, like cloth settling.
## The sky (11/11/2026): deep space and a black hole on the horizon, colossal, the light a speck before
## it (shaders/black_hole.gdshader); the mesh, pale on the dark, runs off towards it.
## Tap: space, click, a gamepad's A. Esc: back to the game. `-- auto` plays it on its own.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/spacetime.tscn -- auto

const BLUE := Color("#4d84b3")
## The mesh on the dark: pale blue, warming where it sinks (towards the light).
const LINE := Color("#7f9fc4")
const LINE_SUNK := Color("#f1dcae")
## The mesh: a grid on the floor, in world units, drawn from the camera to the far edge.
const SPAN_X := 26.0
const NEAR := 2.0
const FAR := 52.0
const STEP := 1.0          # between the grid's lines
const SUB := 4             # each segment in this many pieces, so the lines can bend
## The camera, above the floor and a little behind the light.
const CAM_H := 3.6
const CAM_BACK := 16.0
const FOCAL := 620.0
const HORIZON := 0.44       # where the camera's eye line meets the screen, from the top
## The well under the light: how deep and how wide (a Gaussian), and the extra weight of a tap.
const DEPTH := 2.8
const WIDTH := 2.6
const TAP_WEIGHT := 1.6
const RIPPLE_SPEED := 9.0  # world units a second
const RIPPLE_LIFE := 3.2
## The hole's pull on the far mesh: the floor sinks away towards it, the line going down into it.
const PULL := 7.0
const NEAR_TAP := 0.015
const NEAR_DRIFT := 0.003
const SPEED := 2.4         # how far the light goes a second, on its own
const SURGE := 3.2         # and the extra a tap on the beat gives it

var _auto := false
var _t := 0.0
var _dist := 0.0            # how far along its line the light is
var _surge := 0.0
var _weight := 0.0          # a tap's extra weight, easing out
var _well := Vector2.ZERO   # where the well's centre is (it follows the light, lagging)
var _ripples: Array[Dictionary] = []   # {at: Vector2, t, k}
var _last_beat := -100
var _run := 0
## How near the hole has come (0..1): a little with every tap on the beat, slowly on its own. It grows
## in the sky and its pull bends the far mesh more.
var _near := 0.0
var _mat: ShaderMaterial
var _sky: ColorRect
var _sky_mat: ShaderMaterial
var _grid: MeshInstance2D
var _top: Node2D


func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	SaveSystem.enabled = false
	Music.zone = 8
	Music._pending_zone = 8
	Music.start()
	_well = _line(0.0)
	_build_sky()
	_build_mesh()
	get_viewport().msaa_2d = Viewport.MSAA_4X   # the mesh's lines are one pixel wide


## The light's line on the floor: it winds left and right as it goes ahead.
func _line(d: float) -> Vector2:
	return Vector2(3.2 * sin(d * 0.21) + 1.4 * sin(d * 0.53 + 1.0), d)


func _process(delta: float) -> void:
	_t += delta
	_surge = maxf(0.0, _surge - delta * 2.5)
	_weight = maxf(0.0, _weight - delta * 1.1)
	_dist += delta * (SPEED + SURGE * _surge)
	_near = minf(1.0, _near + delta * NEAR_DRIFT)
	_well = _well.lerp(_line(_dist), minf(1.0, delta * 4.0))
	for r in _ripples:
		r.t += delta
	_ripples = _ripples.filter(func(r: Dictionary) -> bool: return r.t < RIPPLE_LIFE)
	if _auto and _t > 1.5:
		var k := Music.beat_at_tap()
		if k >= 0 and k != _last_beat and fmod(_t, 9.0) < 7.0 and randf() > 0.25:
			_tap()
	_update_mesh()
	_top.queue_redraw()
	queue_redraw()


func _exit_tree() -> void:
	get_viewport().msaa_2d = Viewport.MSAA_DISABLED


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
	var k := Music.beat_at_tap()
	if k >= 0 and k != _last_beat:
		_last_beat = k
		_run += 1
		Music.play_accent(_run)
		_near = minf(1.0, _near + NEAR_TAP)
		_weight = 1.0
		_surge = 1.0
		_ripples.append({"at": _line(_dist), "t": 0.0, "k": 1.0})
	else:
		_run = 0
		Music.play_tap(0.1, false)
		_weight = maxf(_weight, 0.35)
		_ripples.append({"at": _line(_dist), "t": 0.0, "k": 0.35})


## How far the floor sinks at p: the light's well, deeper with a tap's weight, and the ripples
## running out from where taps landed (a ring of rise and fall, fading as it spreads).
func _height(p: Vector2) -> float:
	var d2 := p.distance_squared_to(_well)
	var depth := DEPTH * (1.0 + TAP_WEIGHT * _weight * _weight)
	var h := -depth * exp(-d2 / (WIDTH * WIDTH * (1.0 + 0.3 * _weight)))
	for r in _ripples.slice(-8):
		var front: float = r.t * RIPPLE_SPEED
		var d: float = p.distance_to(r.at)
		var x := d - front
		var fade: float = (1.0 - r.t / RIPPLE_LIFE) * r.k / (1.0 + front * 0.15)
		h += 0.55 * fade * sin(x * 1.6) * exp(-x * x * 0.35)
	return h + _pull(p)


## The hole's pull: far off, the floor sinks away towards it, more as it comes nearer. Same as the
## mesh's shader.
func _pull(p: Vector2) -> float:
	var cam := Vector2(_well.x * 0.6, _dist - CAM_BACK)
	var far := clampf((p.y - cam.y) / FAR, 0.0, 1.0)
	var dx := p.x - cam.x
	var sp := 5.0 + 12.0 * far
	return -_pull_k() * pow(far, 2.2) * exp(-dx * dx / (2.0 * sp * sp))


func _pull_k() -> float:
	return PULL * (0.6 + 0.8 * _near)


## World (x on the floor across, z ahead, h up) to the screen. The camera follows the light.
func _project(x: float, z: float, h: float) -> Vector3:
	var vp := get_viewport_rect().size
	var cam_z := _dist - CAM_BACK
	var cam_x := _well.x * 0.6
	var dz := z - cam_z
	if dz < 0.5:
		return Vector3(0, 0, -1)
	var s := FOCAL * (vp.y / 720.0) / dz
	return Vector3(vp.x * 0.5 + (x - cam_x) * s, vp.y * HORIZON + (CAM_H - h) * s, dz)


## The sky: a full-screen rect behind everything, the black hole drawn by its shader.
func _build_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	_sky = ColorRect.new()
	_sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = load("res://shaders/black_hole.gdshader")
	_sky.material = _sky_mat
	layer.add_child(_sky)
	add_child(layer)


## The mesh is drawn on the GPU (shaders/spacetime.gdshader): a grid of short line pieces around
## the camera, moved along by `origin` in whole steps so it seems to stay put on the floor.
func _build_mesh() -> void:
	var pts := PackedVector2Array()
	var piece := STEP / SUB
	var xs := int(SPAN_X / STEP) + 1
	var zs := int(FAR / STEP) + 2
	for zi in zs + 1:
		for xi in range(-xs * SUB, xs * SUB):
			pts.append(Vector2(xi * piece, zi * STEP))
			pts.append(Vector2((xi + 1) * piece, zi * STEP))
	for xi in range(-xs, xs + 1):
		for zi in zs * SUB:
			pts.append(Vector2(xi * STEP, zi * piece))
			pts.append(Vector2(xi * STEP, (zi + 1) * piece))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	# never culled: the shader moves every vertex far from where the mesh says it is
	mesh.custom_aabb = AABB(Vector3(-1e5, -1e5, -1), Vector3(2e5, 2e5, 2))
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/spacetime.gdshader")
	_mat.set_shader_parameter("ink", LINE)
	_mat.set_shader_parameter("blue", LINE_SUNK)
	_mat.set_shader_parameter("cam_h", CAM_H)
	_mat.set_shader_parameter("focal", FOCAL)
	_mat.set_shader_parameter("horizon", HORIZON)
	_mat.set_shader_parameter("far_span", FAR)
	_grid = MeshInstance2D.new()
	_grid.mesh = mesh
	_grid.material = _mat
	add_child(_grid)
	_top = Node2D.new()
	_top.draw.connect(func() -> void:
		_draw_path()
		_draw_light())
	add_child(_top)


func _update_mesh() -> void:
	var cam := Vector2(_well.x * 0.6, _dist - CAM_BACK)
	var vp := get_viewport_rect().size
	_sky_mat.set_shader_parameter("aspect", vp.x / vp.y)
	_sky_mat.set_shader_parameter("spin", _t * 0.25)
	# the hole hardly moves: it is that far; the camera's sway shifts it only a touch
	var radius := 0.2 + 0.14 * _near
	_sky_mat.set_shader_parameter("radius", radius)
	_sky_mat.set_shader_parameter("center", Vector2(0.5 - cam.x * 0.004, HORIZON - 0.55 * radius))
	_mat.set_shader_parameter("pull", _pull_k())
	_mat.set_shader_parameter("origin", Vector2(snappedf(cam.x, STEP), floorf((cam.y + NEAR) / STEP) * STEP))
	_mat.set_shader_parameter("cam", cam)
	_mat.set_shader_parameter("screen", get_viewport_rect().size)
	_mat.set_shader_parameter("well", _well)
	_mat.set_shader_parameter("depth", DEPTH * (1.0 + TAP_WEIGHT * _weight * _weight))
	_mat.set_shader_parameter("width2", WIDTH * WIDTH * (1.0 + 0.3 * _weight))
	var rs: Array[Vector4] = []
	for r in _ripples.slice(-8):
		var front: float = r.t * RIPPLE_SPEED
		rs.append(Vector4(r.at.x, r.at.y, front, (1.0 - r.t / RIPPLE_LIFE) * r.k / (1.0 + front * 0.15)))
	_mat.set_shader_parameter("ripple_count", rs.size())
	while rs.size() < 8:
		rs.append(Vector4.ZERO)
	_mat.set_shader_parameter("ripples", rs)


## The light's line: lit behind it, faint ahead; it sinks with the mesh where the light is.
func _draw_path() -> void:
	var pts_lit := PackedVector2Array()
	var pts_ahead := PackedVector2Array()
	var d := _dist - CAM_BACK + NEAR
	while d < _dist + FAR - CAM_BACK:
		var p := _line(d)
		var q := _project(p.x, p.y, _height(p) + 0.02)
		if q.z > 0.0:
			if d <= _dist:
				pts_lit.append(Vector2(q.x, q.y))
			else:
				if pts_ahead.is_empty() and not pts_lit.is_empty():
					pts_ahead.append(pts_lit[pts_lit.size() - 1])
				pts_ahead.append(Vector2(q.x, q.y))
		d += 0.25
	if pts_ahead.size() > 1:
		_top.draw_polyline(pts_ahead, Color(LINE, 0.55), 1.5, true)
	if pts_lit.size() > 1:
		_top.draw_polyline(pts_lit, Color(Palette.GOLD.darkened(0.15), 0.9), 3.0, true)


## The light, sitting at the bottom of its well.
func _draw_light() -> void:
	var p := _line(_dist)
	var q := _project(p.x, p.y, _height(p) + 0.15)
	if q.z <= 0.0:
		return
	var c := Vector2(q.x, q.y)
	var s := 1.0 + 0.35 * _weight
	var ph := Music.heard_phase()
	var beat := pow(1.0 - minf(1.0, fposmod(ph + 0.06, 1.0) / 0.3), 2.0)
	for i in 5:
		var k := i / 4.0
		_top.draw_circle(c, lerpf(46.0, 12.0, k) * s, Color(Palette.GOLD, (0.05 + 0.04 * beat) * (0.5 + k)))
	_top.draw_circle(c, 7.0 * s, Color(1.0, 0.97, 0.88))
	_top.draw_circle(c, 3.5 * s, Palette.GOLD.darkened(0.2))
