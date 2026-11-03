extends Node2D
## The tip of the line (§6.2): climbs to just below the current barrier and jolts forward on each hit.

const STOP_SHORT := 16.0
const NOTES := 3
const NOTE_GAP := 64.0

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
## Main's lesson on the beat: the ring is drawn bold and the tip glows on every beat.
var lesson := false
var _bold := 0.0
## Holding the button: an arc filling round the tip until holding starts to tap (0..1).
var hold_k := 0.0
## While a run lasts, what a tap on the beat is worth shows beside the tip ("×2.4").
var font: Font
var _since_accent := 99.0
## A run reached one of GameState.BEAT_MILESTONES: a burst of gold rings, bigger the further it got.
var _mile := 0.0
var _mile_level := 0
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
	_bold = lerpf(_bold, 1.0 if lesson else 0.0, minf(1.0, delta * 3.0))
	_since_accent += delta
	_mile = maxf(0.0, _mile - delta * 0.9)
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


func milestone(level: int) -> void:
	_mile = 1.0
	_mile_level = level


func accent(run: int) -> void:
	_gold = 1.0
	_run = run
	_since_accent = 0.0


## The beat as notes of light climbing the line: one per beat, NOTE_GAP apart, each reaching the
## tip as its beat sounds, so a player sees the next few coming and taps as one arrives.
func _draw_notes(ph: float, ring: float) -> void:
	var gap := lerpf(NOTE_GAP, NOTE_GAP * 1.25, _bold)
	for k in NOTES:
		var d := (k + 1.0 - ph) * gap
		var at := lit + jolt - d
		if at < 0.0:
			continue
		var p := path.pos_at(at) - position
		var near := 1.0 - d / (gap * NOTES)
		var a := ring * lerpf(0.35, 0.85, _bold) * smoothstep(0.0, 0.35, near)
		var r := lerpf(3.0, 5.5, near) * lerpf(1.0, 1.3, _bold)
		var col := Palette.INK.lerp(Palette.GOLD.darkened(0.2), smoothstep(0.55, 0.9, near) * maxf(_bold, 0.5))
		draw_circle(p, r * 2.2, Color(col, a * 0.18))
		draw_circle(p, r, Color(col, a))
	# the moment of the beat: the note lands in the tip and opens a small ring
	var land := 1.0 - minf(1.0, ph / 0.25)
	if land > 0.0:
		draw_arc(Vector2.ZERO, lerpf(12.0, 26.0, 1.0 - land), 0.0, TAU, 40,
			Color(Palette.GOLD.darkened(0.2), 0.5 * land * ring), 1.5, true)


func _draw() -> void:
	# While a star or a fork runs, the tip is its lights; it comes back as one when they rejoin.
	if not GameState.star.is_empty() or not GameState.branches.is_empty():
		return
	var c := Palette.line_col(GameState.stage)
	for i in range(1, _trail.size()):
		var k := 1.0 - float(i) / TRAIL_LEN
		draw_circle(_trail[i] - position, 3.5 * k, Color(c, 0.35 * k))
	var ph := Music.heard_phase()
	var ring := maxf(_ring, _bold)
	if ring > 0.01:
		_draw_notes(ph, ring)
	if _bold > 0.01:
		# the beat itself: the tip glows as the ring arrives
		var on := pow(1.0 - minf(1.0, fposmod(ph + 0.06, 1.0) / 0.3), 2.0)
		draw_circle(Vector2.ZERO, 24.0, Color(Palette.GOLD, 0.3 * on * _bold))
	if hold_k > 0.0:
		var hc := Color(Palette.INK, 0.5 if hold_k < 1.0 else 0.3)
		draw_arc(Vector2.ZERO, 28.0, -PI * 0.5, -PI * 0.5 + TAU * hold_k, 48, hc, 2.0, true)
	if _mile > 0.0:
		var e := 1.0 - _mile
		var far := 70.0 + 14.0 * mini(_mile_level, 6)
		for k in 3:
			var ek := clampf(e * 1.4 - k * 0.18, 0.0, 1.0)
			if ek <= 0.0 or ek >= 1.0:
				continue
			draw_arc(Vector2.ZERO, lerpf(18.0, far, ek), 0.0, TAU, 64, Color(Palette.GOLD, 0.7 * (1.0 - ek)), 2.6 - k * 0.6, true)
		for i in 10:
			var a := TAU * i / 10.0 + _mile_level
			var d := lerpf(16.0, far * 0.8, e)
			draw_circle(Vector2.from_angle(a) * d, 2.2 * _mile, Color(Palette.GOLD, 0.8 * _mile))
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
	# What the run is worth, beside the tip, while it lasts (it fades two beats or so after the last
	# accent, and at once when the run breaks).
	var shown := 1.0 - smoothstep(1.6, 2.4, _since_accent)
	if font != null and GameState.beat_streak > 0 and shown > 0.0:
		var worth := GameState.beat_worth(GameState.beat_streak)
		var s := "×%s" % (str(int(worth)) if is_equal_approx(worth, roundf(worth)) else "%.1f" % worth)
		# on the left, a little below: the barrier's own number sits on its right. It grows with the
		# run, jumps a little on every accent and a lot on a milestone.
		var pop := 1.0 + 0.3 * (1.0 - smoothstep(0.0, 0.25, _since_accent)) + 0.5 * _mile * _mile
		var size := int((28 + 2 * mini(GameState.beat_streak, 10)) * pop)
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at := View.screen(Vector2(-38.0 - w, 14.0 + size * 0.35))
		View.text(self, font, at + View.screen(Vector2(1.5, 1.5)), s, HORIZONTAL_ALIGNMENT_LEFT, -1,
			size, Color(Palette.PAPER, 0.8 * shown))
		View.text(self, font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1,
			size, Color(Palette.GOLD.darkened(0.35), shown))
