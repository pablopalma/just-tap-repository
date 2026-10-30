extends Node2D
## The tip of the line (§6.2): climbs to just below the current barrier and jolts forward on each hit.

const STOP_SHORT := 16.0

var path: PathData
var lit := 0.0
var jolt := 0.0

var _squash := 0.0
var _flash := 0.0


func _process(delta: float) -> void:
	if path == null:
		return
	var n := GameState.stage
	var target := path.gate_len(n) - STOP_SHORT
	if GameState.finished:
		target = path.gate_len(n) + 40.0
	var diff := target - lit
	if diff > 0.0:
		# Fast at first, easing in as it arrives.
		lit += maxf(minf(diff, delta * 120.0), diff * minf(1.0, delta * 5.0))
	else:
		lit = target
	jolt *= exp(-9.0 * delta)
	_squash *= exp(-11.0 * delta)
	_flash = maxf(0.0, _flash - delta * 3.0)
	position = path.pos_at(lit + jolt)
	queue_redraw()


## Forward jolt, plus a squash and a ring flashing out from the impact.
func kick(amount: float) -> void:
	jolt = maxf(jolt, amount)
	_squash = minf(1.0, _squash + amount / 12.0)
	_flash = 1.0


func _draw() -> void:
	var c := Palette.line_col(GameState.stage)
	if _flash > 0.0:
		var e := 1.0 - _flash
		draw_arc(Vector2.ZERO, lerpf(10.0, 30.0, e), 0.0, TAU, 40, Color(c, 0.55 * _flash), 1.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + 0.45 * _squash, 1.0 - 0.3 * _squash))
	draw_circle(Vector2.ZERO, 17.0, Color(c, 0.08 + 0.1 * _squash))
	draw_circle(Vector2.ZERO, 9.0, Color(c, 0.16))
	draw_circle(Vector2.ZERO, 4.5, Palette.INK)
	draw_set_transform(Vector2.ZERO)
	if not GameState.finished:
		var f := 1.0 - GameState.progress()
		draw_arc(Vector2.ZERO, 12.0, -PI * 0.5, -PI * 0.5 + TAU * f, 48, Color(Palette.INK, 0.5), 1.3, true)
