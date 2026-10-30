class_name Landscape
extends CanvasLayer
## A giant landscape drawn as you climb: every broken barrier draws one piece of its zone's
## structure in the distance, stroke by stroke, with a pen point at the tip, a brighter ink that
## settles and a wash that fills in. Pieces already built (from a save) appear without animation.
## Structures alternate sides and sit at the depth between the ruins and the floating lines.
## At the very end (set_grand) the layer stops being distant: it lines up with the tower so every
## structure stands beside its own zone, and they all fill with colour — a whole city, built.

const F := 0.22
const SCALE := 0.74
const DRAW_TIME := 2.6
const SETTLE := 3.5
const START_DELAY := 0.5
const SIDE_X := 520.0
## Structures on the same side are two zones apart (~660 layer units), so they are drawn smaller than
## that, and every other pair sits further out.
const STRUCT_SCALE := 0.68
const HEIGHT := 900.0 * STRUCT_SCALE  # tallest structure, for culling

var _drawer: Drawer
var _t := 0.0
## 0 = distant parallax layer, 1 = aligned with the tower and in full colour.
var grand := 0.0


func _ready() -> void:
	layer = -7
	_drawer = Drawer.new()
	add_child(_drawer)


func _process(delta: float) -> void:
	_t += delta
	_drawer.now = _t


## Barrier n just broke: draw its piece.
func build_piece(n: int) -> void:
	_drawer.anim[n] = _t + START_DELAY
	var z := Zones.of(n)
	Music.build_piece((n - 1) % 10, _drawer.side(z), DRAW_TIME)


## The grand reveal of the ending (or back to normal on rebirth).
func set_grand(on: bool, time := 7.0) -> void:
	var tw := create_tween()
	tw.tween_property(self, "grand", 1.0 if on else 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func reset() -> void:
	grand = 0.0
	_drawer.anim.clear()
	_drawer.queue_redraw()


func update_view(cam_pos: Vector2, cam_zoom: float, cam_offset: Vector2, vp: Vector2, _tint: Color) -> void:
	var zn := SCALE * (1.0 + (cam_zoom - 1.0) * F) * vp.y / 720.0
	# Aligned: layer point F·w lands on screen exactly where world point w does.
	var za := cam_zoom / F
	var z := exp(lerpf(log(zn), log(za), grand))
	var center := (cam_pos + cam_offset) * F
	_drawer.grand = grand
	_drawer.width_mul = maxf(1.0, zn / z)
	scale = Vector2(z, z)
	offset = vp * 0.5 - center * z
	_drawer.set_view(center, vp * 0.5 / z)


class Drawer extends Node2D:
	var anim := {}       # n -> time its drawing starts
	var now := 0.0
	var grand := 0.0
	## Keeps strokes readable when the layer is zoomed far out.
	var width_mul := 1.0
	var _cache := {}     # z -> Array[Dictionary] pieces
	var _zones := Vector2i(1, 0)

	func side(z: int) -> float:
		return -1.0 if z % 2 == 1 else 1.0

	func foot(z: int) -> Vector2:
		var out := 170.0 * (int((z - 1) / 2.0) % 2)
		return Vector2(side(z) * (Landscape.SIDE_X + out), -((z - 1) * 10) * GameState.GAP * Landscape.F + 140.0)

	func pieces(z: int) -> Array:
		if not _cache.has(z):
			_cache[z] = Structures.build(z)
		return _cache[z]

	func set_view(center: Vector2, half: Vector2) -> void:
		# Zone z spans layer y from foot - HEIGHT to foot.
		var zs := Vector2i(Zones.COUNT + 1, 0)
		for z in range(1, Zones.COUNT + 1):
			var fy := foot(z).y
			if fy + 60.0 >= center.y - half.y and fy - Landscape.HEIGHT <= center.y + half.y:
				zs.x = mini(zs.x, z)
				zs.y = maxi(zs.y, z)
		if zs != _zones:
			_zones = zs
			queue_redraw()

	func _process(_delta: float) -> void:
		# Redraw only while something is being drawn or settling.
		var busy := false
		for n in anim.keys():
			if now - float(anim[n]) < Landscape.DRAW_TIME + Landscape.SETTLE:
				busy = true
			else:
				anim.erase(n)
		if busy or grand > 0.0:
			queue_redraw()

	func _draw() -> void:
		var built := GameState.stage - (0 if GameState.finished else 1)
		for z in range(_zones.x, _zones.y + 1):
			var ps := pieces(z)
			var f := foot(z)
			# In the grand reveal every structure takes a colour of its own: red, green, blue, gold…
			var col := Palette.paint_col(z, 0).lerp(Palette.chapter_color(1 + (z - 1) % 4), grand)
			draw_set_transform(f, 0.0, Vector2.ONE * Landscape.STRUCT_SCALE)
			if grand > 0.0:
				var halo := Vector2(0, -Landscape.HEIGHT * 0.55 / Landscape.STRUCT_SCALE)
				for k in 4:
					draw_circle(halo, 520.0 - k * 110.0, Color(col, 0.045 * grand))
			for j in ps.size():
				var n := (z - 1) * 10 + j + 1
				if n > built:
					break
				var p := 1.0
				var glow := 0.0
				if anim.has(n):
					var e := now - float(anim[n])
					p = clampf(e / Landscape.DRAW_TIME, 0.0, 1.0)
					p = 1.0 - pow(1.0 - p, 3.0)
					glow = 1.0 - clampf((e - Landscape.DRAW_TIME) / Landscape.SETTLE, 0.0, 1.0)
					if e < 0.0:
						continue
				_piece(ps[j], Vector2.ZERO, p, glow, col)
		draw_set_transform(Vector2.ZERO)

	func _piece(piece: Dictionary, f: Vector2, p: float, glow: float, col: Color) -> void:
		var fill: PackedVector2Array = piece.fill
		if fill.size() >= 3 and p > 0.6:
			var a := smoothstep(0.6, 1.0, p) * lerpf(0.09, 0.42, grand)
			_fan(fill, f, Color(col, a))
		var ink := Color(Palette.INK.lerp(col.darkened(0.4), grand * 0.6), 0.42 + 0.4 * glow + 0.3 * grand)
		var w := (1.6 + 0.8 * glow + 0.6 * grand) * width_mul / Landscape.STRUCT_SCALE
		for line in piece.lines:
			var tip := _partial(line, f, p, ink, w)
			if p < 1.0:
				draw_circle(tip, 3.0 / Landscape.STRUCT_SCALE, Color(Palette.INK, 0.8))
				draw_circle(tip, 9.0 / Landscape.STRUCT_SCALE, Color(col, 0.18))

	## Draws the first fraction p of a polyline and returns where the pen is.
	func _partial(line: PackedVector2Array, f: Vector2, p: float, col: Color, w: float) -> Vector2:
		var total := 0.0
		for i in range(1, line.size()):
			total += line[i - 1].distance_to(line[i])
		var target := total * p
		var pts := PackedVector2Array([line[0] + f])
		var acc := 0.0
		for i in range(1, line.size()):
			var seg := line[i - 1].distance_to(line[i])
			if acc + seg >= target:
				var t := 0.0 if seg <= 0.0 else (target - acc) / seg
				pts.append(line[i - 1].lerp(line[i], t) + f)
				break
			pts.append(line[i] + f)
			acc += seg
		if pts.size() >= 2:
			draw_polyline(pts, col, w, true)
		return pts[pts.size() - 1]

	func _fan(poly: PackedVector2Array, f: Vector2, col: Color) -> void:
		var c := Vector2.ZERO
		for q in poly:
			c += q
		c = c / poly.size() + f
		var cols := PackedColorArray([col, col, col])
		for i in poly.size():
			var a := poly[i] + f
			var b := poly[(i + 1) % poly.size()] + f
			draw_primitive(PackedVector2Array([c, a, b]), cols, PackedVector2Array())
