extends Node2D
## The first moment of every game: a spark of light, huge at first, comes down and shrinks to the
## size of the tip; when it lands, its glow fades and only the tip is left. Like something divine
## arriving on the page. Main plays it when the game starts.

signal landed

const SHRINK := 1.7    # seconds from huge to the size of the tip
const FADE := 1.1      # seconds for the glow to go once it has landed

var tip: Node2D
var camera: Camera2D

var _t := -1.0
var _landed := false


func play() -> void:
	_t = 0.0
	_landed = false
	visible = true


func is_playing() -> bool:
	return _t >= 0.0


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if not _landed and _t >= SHRINK:
		_landed = true
		landed.emit()
	if _t >= SHRINK + FADE:
		_t = -1.0
		visible = false
	position = tip.position
	queue_redraw()


func _draw() -> void:
	if _t < 0.0:
		return
	var px := 1.0 / maxf(0.05, camera.zoom.x)  # one screen pixel in world units
	var screen_h := get_viewport_rect().size.y * px
	var k := clampf(_t / SHRINK, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	# It comes from above and settles on the tip as it shrinks.
	var at := Vector2(0.0, -screen_h * 0.22 * (1.0 - e) * (1.0 - e))
	var r := lerpf(screen_h * 0.42, 9.0, 1.0 - pow(1.0 - e, 2.2))
	var fade := 1.0 if _t < SHRINK else 1.0 - clampf((_t - SHRINK) / FADE, 0.0, 1.0)
	var glow := Color(Palette.GOLD, 1.0)
	# soft layered light
	for i in 7:
		var f := 1.0 - i / 7.0
		draw_circle(at, r * (0.35 + 1.5 * f), Color(glow, 0.07 * fade * (0.4 + 0.6 * (1.0 - f))))
	draw_circle(at, r * 0.42, Color(Color(1.0, 0.97, 0.88), 0.85 * fade))
	# thin rings closing in with it, so it reads on the paper
	for i in 3:
		var rr := r * (1.15 + 0.55 * i) + (1.0 - e) * screen_h * 0.04 * i
		draw_arc(at, rr, 0.0, TAU, 72, Color(Palette.INK, 0.22 * fade * (1.0 - i / 3.0)), 1.4 * px, true)
	# landing: a ring of light opening from the tip while the glow goes
	if _t >= SHRINK:
		var l := clampf((_t - SHRINK) / FADE, 0.0, 1.0)
		var le := 1.0 - pow(1.0 - l, 3.0)
		draw_arc(Vector2.ZERO, lerpf(10.0, 120.0, le) * px, 0.0, TAU, 72, Color(Palette.GOLD, 0.8 * (1.0 - l)), 3.0 * px, true)
