extends Node2D
## Short-lived effects in one draw pass: floating numbers, ink rings and drops (§7.5, §12).
## Plain data lists instead of nodes, so nothing is created or freed while playing.

const MAX_FLOATS := 40
const GRAVITY := 260.0

var font: Font

var _floats: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _drops: Array[Dictionary] = []


func clear() -> void:
	_floats.clear()
	_rings.clear()
	_drops.clear()


func float_text(pos: Vector2, text: String, color: Color, size := 15, life := 1.1) -> void:
	if _floats.size() >= MAX_FLOATS:
		_floats.pop_front()
	_floats.append({"pos": pos, "vel": Vector2(randf_range(-12, 12), -48), "text": text,
		"color": color, "size": size, "t": 0.0, "life": life})


## Two concentric ink rings staggered 0.25 s, plus twelve drops of ink and colour.
func aura(pos: Vector2, color: Color) -> void:
	for i in 2:
		_rings.append({"pos": pos, "t": -0.25 * i, "life": 2.2, "r0": 14.0, "r1": 120.0 + 40.0 * i,
			"color": Palette.INK})
	for i in 12:
		var a := randf() * TAU
		var sp := randf_range(60, 170)
		_drops.append({"pos": pos, "vel": Vector2(cos(a), sin(a) - 0.6) * sp, "t": 0.0,
			"life": randf_range(0.9, 1.6), "color": color if i % 2 == 0 else Palette.INK,
			"r": randf_range(1.2, 2.6)})


func ring(pos: Vector2, color: Color, r1 := 90.0, life := 1.6) -> void:
	_rings.append({"pos": pos, "t": 0.0, "life": life, "r0": 10.0, "r1": r1, "color": color})


func _process(delta: float) -> void:
	if _floats.is_empty() and _rings.is_empty() and _drops.is_empty():
		return
	for i in range(_floats.size() - 1, -1, -1):
		var f: Dictionary = _floats[i]
		f.t += delta
		f.pos += f.vel * delta
		f.vel *= exp(-2.0 * delta)
		if f.t >= f.life:
			_floats.remove_at(i)
	for i in range(_rings.size() - 1, -1, -1):
		var r: Dictionary = _rings[i]
		r.t += delta
		if r.t >= r.life:
			_rings.remove_at(i)
	for i in range(_drops.size() - 1, -1, -1):
		var d: Dictionary = _drops[i]
		d.t += delta
		d.vel.y += GRAVITY * delta
		d.pos += d.vel * delta
		if d.t >= d.life:
			_drops.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for r in _rings:
		if r.t < 0.0:
			continue
		var k: float = r.t / r.life
		var e := 1.0 - pow(1.0 - k, 3.0)
		draw_arc(r.pos, lerpf(r.r0, r.r1, e), 0.0, TAU, 64, Color(r.color, 0.45 * (1.0 - k)), 1.1, true)
	for d in _drops:
		var k: float = d.t / d.life
		draw_circle(d.pos, d.r * (1.0 - 0.5 * k), Color(d.color, 0.8 * (1.0 - k)))
	if font == null:
		return
	for f in _floats:
		var k: float = f.t / f.life
		var a := minf(1.0, (1.0 - k) * 2.0)
		draw_string(font, f.pos, f.text, HORIZONTAL_ALIGNMENT_CENTER, -1, f.size, Color(f.color, a))
