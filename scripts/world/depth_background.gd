class_name DepthBackground
extends Node
## Parallax depth behind the world. Far layers move and zoom less and are paler (atmospheric
## perspective): mist and a distant sun, ink ruins, and closer Linelight-style floating lines.
## Content is generated per vertical cell from a hash, so it never ends, and a layer only
## redraws when its visible cells or its tint change. Mist is a soft radial falloff, never a hard blot.

const CELL := 700.0
const SPECS := [
	{"f": 0.05, "scale": 0.5, "kind": "mist", "ink": 0.10, "layer": -9},
	{"f": 0.14, "scale": 0.66, "kind": "ruins", "ink": 0.20, "layer": -8},
	{"f": 0.3, "scale": 0.82, "kind": "lines", "ink": 0.30, "layer": -7},
]

var _layers: Array[Dictionary] = []


func _ready() -> void:
	var soft := _soft_texture()
	for s in SPECS:
		var cl := CanvasLayer.new()
		cl.layer = s.layer
		add_child(cl)
		var d := Drawer.new()
		d.spec = s
		d.soft = soft
		cl.add_child(d)
		_layers.append({"canvas": cl, "drawer": d, "spec": s})


## Called every frame by Main with the camera's real position, zoom and shake offset.
func update_view(cam_pos: Vector2, cam_zoom: float, cam_offset: Vector2, vp: Vector2, tint: Color) -> void:
	for e in _layers:
		var cl: CanvasLayer = e.canvas
		var d: Drawer = e.drawer
		var s: Dictionary = e.spec
		var f: float = s.f
		var z: float = s.scale * (1.0 + (cam_zoom - 1.0) * f) * vp.y / 720.0
		var center := (cam_pos + cam_offset) * f
		cl.scale = Vector2(z, z)
		cl.offset = vp * 0.5 - center * z
		d.set_view(center, vp * 0.5 / z)
		d.set_tint(tint)


## White disc whose alpha falls off smoothly to the edge: tinted by modulate when drawn.
static func _soft_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


class Drawer extends Node2D:
	var spec: Dictionary
	var soft: Texture2D
	var _cells := Vector2i(1, 0)
	var _tint := Color.WHITE

	func set_view(center: Vector2, half: Vector2) -> void:
		var c := Vector2i(floori((center.y - half.y) / CELL) - 1, floori((center.y + half.y) / CELL) + 1)
		if c != _cells:
			_cells = c
			queue_redraw()

	func set_tint(c: Color) -> void:
		if not c.is_equal_approx(_tint):
			_tint = c
			queue_redraw()

	func _draw() -> void:
		for k in range(_cells.x, _cells.y + 1):
			match spec.kind:
				"mist": _mist(k)
				"ruins": _ruins(k)
				"lines": _lines(k)

	func _r(k: int, salt: int) -> float:
		return PathData.rnd(k + 7919, salt + int(spec.layer) * 13)

	func _ink(a: float) -> Color:
		return Color(Palette.INK, a * float(spec.ink) / 0.3)

	func _wash(a: float) -> Color:
		return Color(_tint.darkened(0.1), a)

	func _fog(pos: Vector2, r: float, a: float) -> void:
		draw_texture_rect(soft, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false, _wash(a))

	# Far: big pale mist and, now and then, the ring of a distant sun.
	func _mist(k: int) -> void:
		var y0 := k * CELL
		for i in 2:
			var pos := Vector2((_r(k, i * 3) - 0.5) * 2600.0, y0 + _r(k, i * 3 + 1) * CELL)
			var r := 320.0 + 380.0 * _r(k, i * 3 + 2)
			_fog(pos, r, 0.2)
		if _r(k, 20) < 0.18:
			var c := Vector2((_r(k, 21) - 0.5) * 1600.0, y0 + _r(k, 22) * CELL)
			var r := 160.0 + 200.0 * _r(k, 23)
			draw_arc(c, r, 0.0, TAU, 96, _ink(0.08), 2.0, true)
			draw_arc(c, r * 0.93, 0.0, TAU, 96, _ink(0.04), 1.2, true)

	# Middle: ink ruins on both sides — pillars, arches, stairs, a monolith with a ring.
	func _ruins(k: int) -> void:
		var y0 := k * CELL
		var count := 1 + int(_r(k, 1) * 2.0)
		for i in count:
			var side := -1.0 if _r(k, 10 + i) < 0.5 else 1.0
			var x := side * (420.0 + 900.0 * _r(k, 20 + i))
			var base := y0 + CELL * (0.4 + 0.6 * _r(k, 30 + i))
			var h := 260.0 + 520.0 * _r(k, 40 + i)
			var w := 40.0 + 60.0 * _r(k, 50 + i)
			var kind := int(_r(k, 60 + i) * 4.0)
			var ink := _ink(0.55)
			var fill := _wash(0.06)
			match kind:
				0:
					_pillar(Vector2(x, base), w, h, ink, fill)
				1:
					var span := w * 3.0
					_pillar(Vector2(x - span * 0.5, base), w, h, ink, fill)
					_pillar(Vector2(x + span * 0.5, base), w, h, ink, fill)
					draw_arc(Vector2(x, base - h), span * 0.5 + w * 0.5, PI, TAU, 48, ink, 1.6, true)
					draw_arc(Vector2(x, base - h), span * 0.5 - w * 0.5, PI, TAU, 48, ink, 1.0, true)
				2:
					var pts := PackedVector2Array()
					var steps := 6
					for s in steps:
						var px := x + side * -s * w * 0.8
						pts.append(Vector2(px, base - s * h / steps))
						pts.append(Vector2(px - side * w * 0.8, base - s * h / steps))
					draw_polyline(pts, ink, 1.6, true)
				_:
					_pillar(Vector2(x, base), w * 1.4, h * 0.7, ink, fill)
					draw_arc(Vector2(x, base - h * 0.7 - w * 1.2), w * 1.1, 0.0, TAU, 48, ink, 1.6, true)
			# a long horizon-like stroke tying the ruin to the void
			draw_line(Vector2(x - side * 60.0, base), Vector2(x + side * (200.0 + 300.0 * _r(k, 70 + i)), base),
				_ink(0.3), 1.0, true)

	func _pillar(foot: Vector2, w: float, h: float, ink: Color, fill: Color) -> void:
		var rect := Rect2(foot.x - w * 0.5, foot.y - h, w, h)
		draw_rect(rect, fill, true)
		draw_rect(rect, ink, false, 1.6, true)
		draw_line(Vector2(rect.position.x - 8, rect.position.y), Vector2(rect.end.x + 8, rect.position.y), ink, 2.2, true)

	# Near: floating lines with ring ends and dotted diagonals, plus a soft wash.
	func _lines(k: int) -> void:
		var y0 := k * CELL
		var ink := _ink(0.5)
		for i in 3:
			if _r(k, i) > 0.7:
				continue
			var side := -1.0 if _r(k, 10 + i) < 0.5 else 1.0
			var a := Vector2(side * (330.0 + 700.0 * _r(k, 20 + i)), y0 + CELL * _r(k, 30 + i))
			var len := 80.0 + 220.0 * _r(k, 40 + i)
			var b := a + Vector2(side * len, 0.0)
			var pts := PackedVector2Array([a, b])
			if _r(k, 50 + i) < 0.5:
				pts.append(b + Vector2(side, -1.0) * 50.0)
			draw_polyline(pts, ink, 1.4, true)
			draw_arc(pts[pts.size() - 1], 6.0, 0.0, TAU, 20, ink, 1.4, true)
			draw_circle(a, 2.4, ink)
		if _r(k, 80) < 0.5:
			var side := -1.0 if _r(k, 81) < 0.5 else 1.0
			var a := Vector2(side * (500.0 + 500.0 * _r(k, 82)), y0 + CELL * _r(k, 83))
			for d in 9:
				draw_circle(a + Vector2(side, -1.0) * d * 16.0, 1.6, _ink(0.35))
		if _r(k, 90) < 0.6:
			var pos := Vector2((_r(k, 91) - 0.5) * 2000.0, y0 + CELL * _r(k, 92))
			_fog(pos, 220.0 + 220.0 * _r(k, 93), 0.12)
