extends Node
## Store cover (itch 630x500, Steam 600x900), rendered by the game itself: a small figure with a red
## scarf on the ink line, the line climbing far away into a great golden light (the Father, the whole),
## the whale of light faint in the sky, the title floating in the middle. A vast warm space and one
## spot of colour, so it reads at thumbnail size.
## godot --path . res://tools/cover_art.tscn -- --size=1260x1000 --out=Builds/itch/cover/cover_journey.png
##   frames: renders N frames of a seamless loop (out_0000.png ...) for a GIF instead of one still
##   fps:    frames per second of the loop (the loop lasts frames / fps seconds)
##   title:  0 leaves the title out (to letter it elsewhere)

const SCARF := Color("#c95a4f")

var _args := {"size": "1260x1000", "out": "Builds/itch/cover/cover_journey.png", "frames": "0", "fps": "15",
	"title": "1"}
var _vp: SubViewport
var _paper: ColorRect
var _scene: Node2D
var _whale: CelestialWhale
var _font: Font
var _italic: Font
var _t := 0.0      # the loop's time, seconds
var _loop := 1.0   # its length
var _frame := 0
var _stars: Array[Vector3] = []   # x, y (fractions), phase


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.trim_prefix("--").split("=", true, 1)
			_args[kv[0]] = kv[1]
	SaveSystem.enabled = false
	Narrator.auto = false
	Music.set_enabled(false)
	var wh: PackedStringArray = _args.size.split("x")
	_vp = SubViewport.new()
	_vp.size = Vector2i(int(wh[0]), int(wh[1]))
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.transparent_bg = false
	add_child(_vp)
	_paper = ColorRect.new()
	_paper.size = Vector2(_vp.size)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/paper.gdshader")
	mat.set_shader_parameter("paper", Palette.PAPER.lerp(Palette.GOLD, 0.16))
	mat.set_shader_parameter("vignette", Color(Palette.VIGNETTE, 0.42))
	_paper.material = mat
	_vp.add_child(_paper)
	_scene = Node2D.new()
	_scene.draw.connect(_draw_scene)
	_vp.add_child(_scene)
	_whale = CelestialWhale.new()
	_whale.process_mode = Node.PROCESS_MODE_DISABLED
	_vp.add_child(_whale)
	_whale.active = true
	_whale.visible = true
	_whale._fade = 1.0
	_whale._wake = 1.0
	_whale._drawer.modulate = Color(1, 1, 1, 0.6)
	var top := Node2D.new()   # the title over the whale
	top.draw.connect(_draw_title)
	var layer := CanvasLayer.new()
	layer.layer = 9
	layer.add_child(top)
	_vp.add_child(layer)
	_font = load(UIStyle.REGULAR)
	_italic = load(UIStyle.ITALIC)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		_stars.append(Vector3(rng.randf(), rng.randf_range(0.02, 0.62), rng.randf() * TAU))
	var frames := int(_args.frames)
	_loop = frames / float(_args.fps) if frames > 0 else 1.0
	_pose()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame < 4:
		return
	await RenderingServer.frame_post_draw
	var frames := int(_args.frames)
	var out: String = _args.out
	var path := out if out.contains(":") else ProjectSettings.globalize_path("res://" + out)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := _vp.get_texture().get_image()
	if frames <= 0:
		img.save_png(path)
		print("COVER saved %s" % path)
		get_tree().quit()
		return
	var k := _frame - 4
	img.save_png(path.get_basename() + "_%04d.png" % k)
	if k + 1 >= frames:
		print("COVER saved %d frames" % frames)
		get_tree().quit()
		return
	_t = (k + 1) / float(_args.fps)
	_pose()


## Where everything is at the loop's time _t (every motion is a whole number of cycles per loop).
func _pose() -> void:
	var s := Vector2(_vp.size)
	var ph := TAU * _t / _loop
	# The whale swims in place high in the sky; its body waves at 1.6/s and its fin at 1.2/s, so 2.5 turns of _t close both loops.
	_whale._t = ph * 2.5 + 3.0
	var length := minf(s.x * 0.5, s.y * 0.62)
	var head := Vector2(s.x * 0.93, s.y * (0.22 if s.x > s.y else 0.26) + sin(ph) * s.y * 0.01)
	_whale._build_body(head, length)
	_whale._drawer.queue_redraw()
	_scene.queue_redraw()
	for c in _vp.get_children():
		if c is CanvasLayer:
			c.get_child(0).queue_redraw()


func _horizon() -> float:
	var s := Vector2(_vp.size)
	return 0.71 if s.x > s.y else 0.66


func _light_at() -> Vector2:
	var s := Vector2(_vp.size)
	return Vector2(s.x * 0.5, s.y * 0.1)


## The line: from the foreground at the bottom, winding up and away into the light.
func _line_pt(u: float) -> Vector2:
	var s := Vector2(_vp.size)
	var p0 := Vector2(s.x * 0.12, s.y * 1.06)
	var p1 := Vector2(s.x * 0.9, s.y * 0.92)
	var p2 := Vector2(s.x * 0.2, s.y * 0.76)
	var p3 := Vector2(s.x * 0.5, s.y * _horizon())
	var a := 1.0 - u
	return a * a * a * p0 + 3.0 * a * a * u * p1 + 3.0 * a * u * u * p2 + u * u * u * p3


func _draw_scene() -> void:
	var s := Vector2(_vp.size)
	var unit := s.y / 720.0
	var ph := TAU * _t / _loop
	var l := _light_at()
	# The great light: a soft gold sun far away, and a beam rising from it to the top.
	var breath := 0.5 + 0.5 * sin(ph)
	for i in 40:
		var f := i / 39.0
		_scene.draw_circle(l, s.y * lerpf(0.75, 0.035, pow(f, 0.6)) * (1.0 + 0.04 * breath),
			Color(1.0, 0.97, 0.86, 0.04 + 0.07 * f * f))
	# a column of light falling from it to the horizon, where the line goes
	for k in 8:
		var w := s.y * (0.006 + 0.014 * k)
		_scene.draw_rect(Rect2(l.x - w * 0.5, 0.0, w, s.y * _horizon()), Color(1.0, 0.97, 0.88, 0.035))
	for i in 12:
		var f := i / 11.0
		_scene.draw_circle(l, s.y * lerpf(0.07, 0.012, f), Color(1.0, 0.99, 0.95, 0.12 + 0.1 * f))
	# Faint distant hills of washed paper, like dunes under the light.
	_hill(s.y * 0.62, s.y * 0.05, 0.0, Color(Palette.GOLD.lightened(0.35), 0.18))
	_hill(s.y * 0.74, s.y * 0.06, 1.7, Color(Palette.GOLD.darkened(0.05), 0.12))
	_hill(s.y * 0.88, s.y * 0.05, 3.1, Color(Palette.INK.lerp(Palette.GOLD, 0.6), 0.1))
	# Little gold stars, twinkling.
	for st in _stars:
		var p := Vector2(st.x * s.x, st.y * s.y)
		if p.distance_to(l) < s.y * 0.12:
			continue
		var tw := 0.55 + 0.45 * sin(ph * 2.0 + st.z)
		var r := (3.0 + 2.0 * tw) * unit
		var col := Color(Palette.GOLD.darkened(0.05), 0.55 * tw)
		_scene.draw_line(p - Vector2(r, 0), p + Vector2(r, 0), col, 1.2 * unit, true)
		_scene.draw_line(p - Vector2(0, r), p + Vector2(0, r), col, 1.2 * unit, true)
	# The ink line, thick near us and thinning into the light, with its barriers getting smaller.
	var n := 140
	var prev := _line_pt(0.0)
	for i in range(1, n + 1):
		var u := i / float(n)
		var p := _line_pt(u)
		var near := pow(1.0 - u, 1.6)
		var a := (1.0 - smoothstep(0.6, 1.0, u)) * 0.95
		var col := Palette.INK.lerp(Palette.GOLD.darkened(0.15), smoothstep(0.3, 0.95, u))
		_scene.draw_line(prev, p, Color(col, a), lerpf(1.0, 7.0, near) * unit, true)
		prev = p
	for g in 6:
		var u := 0.2 + g * 0.11
		var p := _line_pt(u)
		var dir := (_line_pt(u + 0.004) - p).normalized()
		var h := lerpf(32.0, 6.0, pow(u, 0.7)) * unit
		var a := (1.0 - smoothstep(0.55, 0.9, u)) * 0.8
		var across := dir.orthogonal()
		_scene.draw_line(p - across * h * 0.5, p + across * h * 0.5, Color(Palette.INK, a), lerpf(3.5, 1.0, u) * unit, true)
	# Notes of light climbing the line towards the light, one per beat.
	for k in 5:
		var u := fposmod(k / 5.0 + _t / _loop, 1.0) * 0.8 + 0.1
		var p := _line_pt(u)
		var a := sin(PI * (u - 0.1) / 0.8)
		var r := lerpf(7.0, 2.0, u) * unit
		_scene.draw_circle(p, r * 2.6, Color(Palette.GOLD, 0.2 * a))
		_scene.draw_circle(p, r, Color(Palette.GOLD.lightened(0.3), 0.95 * a))
	var fu := 0.0
	while _line_pt(fu).y > s.y * 0.95:
		fu += 0.002
	_figure(_line_pt(fu), s.y * (0.13 if s.x > s.y else 0.1), ph)


func _hill(y: float, amp: float, off: float, col: Color) -> void:
	var s := Vector2(_vp.size)
	var pts := PackedVector2Array()
	for i in 41:
		var x := s.x * i / 40.0
		pts.append(Vector2(x, y - amp * (sin(x / s.x * 3.1 + off) * 0.6 + sin(x / s.x * 7.3 + off * 2.0) * 0.4)))
	pts.append(Vector2(s.x, s.y))
	pts.append(Vector2(0, s.y))
	_scene.draw_colored_polygon(pts, col)


## A small figure standing on the line, its back to us, looking at the light; the red scarf in the wind.
func _figure(feet: Vector2, h: float, ph: float) -> void:
	var ink := Palette.INK
	var o := feet
	# shadow on the line
	_scene.draw_colored_polygon(_ellipse(o + Vector2(h * 0.02, 0), h * 0.2, h * 0.035), Color(ink, 0.18))
	# legs
	_scene.draw_line(o + Vector2(-h * 0.05, 0), o + Vector2(-h * 0.04, -h * 0.3), ink, h * 0.05, true)
	_scene.draw_line(o + Vector2(h * 0.05, 0), o + Vector2(h * 0.035, -h * 0.3), ink, h * 0.05, true)
	# a long coat, wider at the hem
	var coat := PackedVector2Array([o + Vector2(-h * 0.15, -h * 0.24), o + Vector2(-h * 0.1, -h * 0.5),
		o + Vector2(-h * 0.11, -h * 0.68), o + Vector2(0, -h * 0.74), o + Vector2(h * 0.11, -h * 0.68),
		o + Vector2(h * 0.1, -h * 0.5), o + Vector2(h * 0.15, -h * 0.24), o + Vector2(0, -h * 0.21)])
	_scene.draw_colored_polygon(coat, ink)
	# head
	_scene.draw_circle(o + Vector2(0, -h * 0.84), h * 0.105, ink)
	# the scarf: around the neck, then a long ribbon trailing left in the wind
	var neck := o + Vector2(0, -h * 0.72)
	_scene.draw_colored_polygon(_ellipse(neck, h * 0.12, h * 0.045), SCARF)
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var seg := 26
	for i in seg + 1:
		var u := i / float(seg)
		var x := -u * h * 1.25
		var y := -u * h * 0.2 + sin(ph * 2.0 - u * 6.5) * h * 0.1 * u
		var w := h * lerpf(0.05, 0.028, u)
		var c := neck + Vector2(x - h * 0.06, y)
		top.append(c + Vector2(0, -w * 0.5))
		bot.append(c + Vector2(0, w * 0.5))
	for i in seg:
		_scene.draw_colored_polygon(PackedVector2Array([top[i], top[i + 1], bot[i + 1], bot[i]]), SCARF)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw_title() -> void:
	if _args.title == "0":
		return
	var s := Vector2(_vp.size)
	var top: CanvasItem = _vp.get_child(_vp.get_child_count() - 1).get_child(0)
	var size := int(s.y * (0.15 if s.x > s.y else 0.1))
	var y := s.y * (0.56 if s.x > s.y else 0.5)
	_text(top, _font, "just tap", y, size, Palette.INK, true)
	_text(top, _italic, "if you had a bad day...", y + size * 0.62, int(size * 0.34), Palette.INK.lerp(Palette.GOLD, 0.25), false)


func _text(ci: CanvasItem, f: Font, txt: String, y: float, size: int, col: Color, glow: bool) -> void:
	var s := Vector2(_vp.size)
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := Vector2((s.x - w) * 0.5, y)
	if glow:
		# a halo of the light behind the letters, so they float in it
		for k in 10:
			var a := TAU * k / 10.0
			ci.draw_string(f, at + Vector2(cos(a), sin(a)) * size * 0.05, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
				Color(1.0, 0.97, 0.88, 0.22))
	ci.draw_string(f, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
