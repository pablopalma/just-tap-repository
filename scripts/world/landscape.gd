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
## A partial grand view for a few seconds (the panoramas during play): 0 distant .. 1 aligned.
var glimpse := 0.0
var _glimpse_tween: Tween
## The demo's dark: the structures shake (0 still .. 1 a hard quake). Eases back on its own.
var tremble := 0.0
## The demo's dark: how broken the built structures are (0 whole .. 1 in pieces, falling). Mending
## brings every fragment back and leaves golden seams for a while (kintsugi).
var broken := 0.0
var mending := 0.0
var _break_tween: Tween


func _ready() -> void:
	layer = -7
	_drawer = Drawer.new()
	add_child(_drawer)


func _process(delta: float) -> void:
	_t += delta
	_drawer.now = _t
	tremble = maxf(0.0, tremble - delta * 0.6)
	_drawer.broken = broken
	_drawer.mending = mending


## Barrier n just broke: draw its piece.
func build_piece(n: int) -> void:
	_drawer.anim[n] = _t + START_DELAY
	var z := Zones.of(n)
	Music.build_piece((n - 1) % 10, _drawer.side(z), DRAW_TIME)


## The grand reveal of the ending (or back to normal on rebirth). ghost: also sketch, in dashed
## faint ink, every piece not built yet — the demo's "still waiting to be drawn".
func set_grand(on: bool, time := 7.0, ghost := false) -> void:
	var tw := create_tween()
	tw.tween_property(self, "grand", 1.0 if on else 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if ghost:
		tw.parallel().tween_property(_drawer, "ghost", 1.0, time * 1.4)


## The structures break a little more (quakes in the demo's dark), up to 	o.
func break_to(to: float, time := 1.2) -> void:
	if _break_tween:
		_break_tween.kill()
	_break_tween = create_tween()
	_break_tween.tween_property(self, "broken", maxf(broken, to), time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## Every fragment flies back to its place; the seams glow gold, then fade.
func mend(time := 4.0) -> void:
	if _break_tween:
		_break_tween.kill()
	mending = 1.0
	_break_tween = create_tween()
	_break_tween.tween_property(self, "broken", 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_break_tween.tween_property(self, "mending", 0.0, 6.0).set_delay(1.0)


func unbreak() -> void:
	if _break_tween:
		_break_tween.kill()
	broken = 0.0
	mending = 0.0


## Ease the landscape toward (or away from) the tower for a panorama.
func glimpse_to(target: float, time: float) -> void:
	if _glimpse_tween:
		_glimpse_tween.kill()
	_glimpse_tween = create_tween()
	_glimpse_tween.tween_property(self, "glimpse", target, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func reset() -> void:
	grand = 0.0
	glimpse = 0.0
	_drawer.ghost = 0.0
	_drawer.anim.clear()
	_drawer.queue_redraw()


func update_view(cam_pos: Vector2, cam_zoom: float, cam_offset: Vector2, vp: Vector2, _tint: Color) -> void:
	var zn := SCALE * (1.0 + (cam_zoom - 1.0) * F) * vp.y / 720.0
	# Aligned: layer point F·w lands on screen exactly where world point w does.
	var za := cam_zoom / F
	var g := maxf(grand, glimpse)
	var z := exp(lerpf(log(zn), log(za), g))
	var center := (cam_pos + cam_offset) * F
	_drawer.grand = g
	_drawer.width_mul = maxf(1.0, zn / z)
	scale = Vector2(z, z)
	offset = vp * 0.5 - center * z
	if tremble > 0.0:
		var a := tremble * tremble * 14.0 * vp.y / 720.0
		offset += Vector2(sin(_t * 41.0) + sin(_t * 23.0), cos(_t * 37.0) + sin(_t * 19.0)) * a * 0.5
		rotation = sin(_t * 17.0) * tremble * tremble * 0.006
	else:
		rotation = 0.0
	_drawer.set_view(center, vp * 0.5 / z)


class Drawer extends Node2D:
	var anim := {}       # n -> time its drawing starts
	var now := 0.0
	var grand := 0.0
	var ghost := 0.0
	var broken := 0.0
	var mending := 0.0
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
		if busy or grand > 0.0 or broken > 0.0 or mending > 0.0:
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
				# Structures still waiting to be built glow much less.
				var waiting := (z - 1) * 10 + 1 > built
				var glow_a := 0.045 * grand * (0.25 if waiting else 1.0)
				for k in 4:
					draw_circle(halo, 520.0 - k * 110.0, Color(col, glow_a))
			for j in ps.size():
				var n := (z - 1) * 10 + j + 1
				if n > built:
					if ghost > 0.0:
						_ghost_piece(ps[j], col)
					continue
				var p := 1.0
				var glow := 0.0
				var rise := Vector2.ZERO
				if anim.has(n):
					var e := now - float(anim[n])
					p = clampf(e / Landscape.DRAW_TIME, 0.0, 1.0)
					p = 1.0 - pow(1.0 - p, 3.0)
					glow = 1.0 - clampf((e - Landscape.DRAW_TIME) / Landscape.SETTLE, 0.0, 1.0)
					if e < 0.0:
						continue
					# It floats up into place as it is drawn, the way things rise in Gris.
					rise = Vector2(0.0, 90.0 * pow(1.0 - p, 2.0))
				# In the dark each piece breaks at its own moment, a little apart from the others.
				var bj := clampf(broken * 1.7 - _h(n * 7 + 3) * 0.7, 0.0, 1.0)
				if bj > 0.0:
					_broken_piece(ps[j], rise, bj, col, n)
					continue
				if mending > 0.0:
					_seams(ps[j], rise, col, n)
				_piece(ps[j], rise, p, glow, col)
				if glow > 0.0:
					_motes(ps[j], rise, p, glow, col, n)
		draw_set_transform(Vector2.ZERO)

	func _piece(piece: Dictionary, f: Vector2, p: float, glow: float, col: Color) -> void:
		var fill: PackedVector2Array = piece.fill
		if fill.size() >= 3 and p > 0.6:
			var a := smoothstep(0.6, 1.0, p) * lerpf(0.09, 0.42, grand)
			_fan(fill, f, Color(col, a))
		var ink := Color(Palette.INK.lerp(col.darkened(0.4), grand * 0.6), 0.42 + 0.4 * glow + 0.3 * grand)
		var w := (1.6 + 0.8 * glow + 0.6 * grand) * width_mul / Landscape.STRUCT_SCALE
		for line in piece.lines:
			if glow > 0.0:
				# a soft light behind the fresh stroke
				_partial(line, f, p, Color(col, 0.22 * glow), w * 6.0)
			var tip := _partial(line, f, p, ink, w)
			if p < 1.0:
				draw_circle(tip, 3.0 / Landscape.STRUCT_SCALE, Color(Palette.INK, 0.8))
				draw_circle(tip, 9.0 / Landscape.STRUCT_SCALE, Color(col, 0.18))

	static func _h(k: int) -> float:
		return fposmod(sin(k * 12.9898) * 43758.5453, 1.0)

	## A piece in fragments: every stroke cut into short shards that drift apart, turn and fall,
	## floating a little as if under water. b: 0 whole .. 1 scattered.
	func _broken_piece(piece: Dictionary, f: Vector2, b: float, col: Color, n: int) -> void:
		var fill: PackedVector2Array = piece.fill
		if fill.size() >= 3 and b < 0.6:
			_fan(fill, f, Color(col, lerpf(0.09, 0.42, grand) * (1.0 - b / 0.6)))
		var ink := Color(Palette.INK.lerp(col.darkened(0.4), grand * 0.6), 0.42 + 0.3 * grand)
		var w := (1.6 + 0.6 * grand) * width_mul / Landscape.STRUCT_SCALE
		var k := n * 131
		for line in piece.lines:
			for i in range(1, line.size()):
				var a: Vector2 = line[i - 1]
				var c: Vector2 = line[i]
				var cuts := maxi(1, int(ceil(a.distance_to(c) / 40.0)))
				for s in cuts:
					k += 1
					var p0 := a.lerp(c, s / float(cuts))
					var p1 := a.lerp(c, (s + 1) / float(cuts))
					var mid := (p0 + p1) * 0.5
					var drift := Vector2.from_angle(_h(k) * TAU) * b * (40.0 + 60.0 * _h(k + 7))
					drift.y += b * b * (60.0 + 200.0 * _h(k + 13))
					drift += Vector2(sin(now * 1.1 + k), cos(now * 0.9 + k * 0.7)) * 5.0 * b
					var ang := (_h(k + 29) - 0.5) * 2.4 * b
					draw_line(mid + (p0 - mid).rotated(ang) + drift + f, mid + (p1 - mid).rotated(ang) + drift + f,
						Color(ink, ink.a * (1.0 - 0.35 * b)), w, true)

	## The mended seams: gold along every stroke, fading out.
	func _seams(piece: Dictionary, f: Vector2, _col: Color, _n: int) -> void:
		var w := 5.0 * width_mul / Landscape.STRUCT_SCALE
		var gold := Color(Palette.GOLD.lightened(0.2), 0.55 * mending)
		for line in piece.lines:
			var pts := PackedVector2Array()
			for q in line:
				pts.append(q + f)
			if pts.size() >= 2:
				draw_polyline(pts, gold, w, true)

	## Sparks of light rising from the pen while it draws, then from the whole piece as it settles.
	func _motes(piece: Dictionary, f: Vector2, p: float, glow: float, col: Color, n: int) -> void:
		if piece.lines.is_empty():
			return
		var line: PackedVector2Array = piece.lines[0]
		var light := col.lightened(0.2)
		for k in 14:
			var seed := float(n * 31 + k * 7)
			var age := fposmod(now * 0.55 + k / 14.0 + seed * 0.13, 1.0)
			# born near the pen while drawing, anywhere along the line once drawn
			var u := clampf(p - 0.04 * fposmod(seed, 3.0), 0.0, 1.0) if p < 1.0 else fposmod(seed * 0.37, 1.0)
			var at := _along(line, u) + f
			# they open out as they rise, and swirl a little
			var drift := Vector2(sin(seed) * 50.0 * age + sin(seed + now * 1.7) * 8.0, -age * 150.0)
			drift /= Landscape.STRUCT_SCALE
			var a := glow * pow(sin(PI * age), 2.0)
			var r := lerpf(3.5, 1.5, age) / Landscape.STRUCT_SCALE
			draw_circle(at + drift, r * 2.5, Color(col, a * 0.2))
			draw_circle(at + drift, r, Color(light, a * 0.55))

	## The point a fraction u of the way through a polyline's vertices.
	func _along(line: PackedVector2Array, u: float) -> Vector2:
		if line.size() == 1:
			return line[0]
		var x := u * (line.size() - 1)
		var i := mini(int(x), line.size() - 2)
		return line[i].lerp(line[i + 1], x - i)

	## A piece not built yet: a faint dashed sketch.
	func _ghost_piece(piece: Dictionary, col: Color) -> void:
		var ink := Color(Palette.INK.lerp(col, 0.3), 0.22 * ghost)
		var w := 1.2 * width_mul / Landscape.STRUCT_SCALE
		var dash := 16.0 * width_mul
		for line in piece.lines:
			var on := true
			var left := dash
			for i in range(1, line.size()):
				var a: Vector2 = line[i - 1]
				var b: Vector2 = line[i]
				var seg := a.distance_to(b)
				var pos := 0.0
				while pos < seg:
					var step := minf(left, seg - pos)
					if on:
						draw_line(a.lerp(b, pos / seg), a.lerp(b, (pos + step) / seg), ink, w, true)
					pos += step
					left -= step
					if left <= 0.0:
						on = not on
						left = dash if on else dash * 0.7

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
