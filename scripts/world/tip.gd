extends Node2D
## The tip of the line (§6.2): climbs to just below the current barrier and jolts forward on each hit.

const STOP_SHORT := 16.0

var path: PathData
var lit := 0.0
var jolt := 0.0

var _squash := 0.0
var _flash := 0.0
## A tap on the beat: a gold ring, wider the longer the run.
var _gold := 0.0
var _run := 0
## The beat ring: a faint circle closing in on the tip with each beat of the music, so a player can
## tap with it (JUST_TAP_GODOT.md §1, "tocar con la música"). It shows once the player has tapped,
## and grows clearer while a run on the beat lasts.
var _ring := 0.0
## In a cinematic the tip leaves a trail of its last positions (world space), fading.
var trail := false
var _trail: Array[Vector2] = []
const TRAIL_LEN := 22


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
	_gold = maxf(0.0, _gold - delta * 2.2)
	var g := GameState
	var ring_to := 0.0
	if g.running and not g.finished and not g.cinematic and g.total_taps > 0:
		ring_to = 0.35 + 0.65 * minf(1.0, g.beat_streak / 4.0)
	_ring = lerpf(_ring, ring_to, minf(1.0, delta * 2.0))
	position = path.pos_at(lit + jolt)
	if trail:
		_trail.push_front(position)
		if _trail.size() > TRAIL_LEN:
			_trail.pop_back()
	elif not _trail.is_empty():
		_trail.pop_back()
	queue_redraw()


## Forward jolt, plus a squash and a ring flashing out from the impact.
func kick(amount: float) -> void:
	jolt = maxf(jolt, amount)
	_squash = minf(1.0, _squash + amount / 12.0)
	_flash = 1.0


func accent(run: int) -> void:
	_gold = 1.0
	_run = run


func _draw() -> void:
	# While a star or a fork runs, the tip is its lights; it comes back as one when they rejoin.
	if not GameState.star.is_empty() or not GameState.branches.is_empty():
		return
	var c := Palette.line_col(GameState.stage)
	for i in range(1, _trail.size()):
		var k := 1.0 - float(i) / TRAIL_LEN
		draw_circle(_trail[i] - position, 3.5 * k, Color(c, 0.35 * k))
	if _ring > 0.01:
		var ph := Music.heard_phase()
		var r := lerpf(40.0, 17.0, ph)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(Palette.INK, 0.16 * _ring * smoothstep(0.0, 0.5, ph)), 1.0, true)
	if _gold > 0.0:
		var e := 1.0 - _gold
		var far := 30.0 + 4.0 * minf(_run, 8)
		draw_arc(Vector2.ZERO, lerpf(14.0, far, e), 0.0, TAU, 48, Color(Palette.GOLD, 0.8 * _gold), 2.2, true)
		draw_circle(Vector2.ZERO, 20.0, Color(Palette.GOLD, 0.12 * _gold))
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
