extends Node2D
## Forks (§19.4). From FORK_FROM the line splits into two branches between every pair of barriers,
## and into three from FORK_THREE: each branch has its own small barrier and its own light, one tap
## hits them all, and the barrier passes once every branch has reached the join. The first split
## (and the third branch) open with a golden burst; the last join closes the fork with another.
## The branches braid: they part, fuse in the middle crossing over, part again at their barriers and
## fuse at the join. They sing as a choir (Music.play_orchestra): a chord while apart, one note
## together where they fuse, and the choir swells as they cross.

signal split_burst(pos: Vector2, count: int)
signal join_burst(pos: Vector2)

## The braid: two lobes between barriers, so the branches fuse at the start, in the middle (crossing
## over) and at the end. Each branch's barrier sits where the second lobe is widest.
const WEAVES := 2
const GATE_T := 0.75
const HALF := 22.0
const OFFSETS := {2: [-58.0, 58.0], 3: [-74.0, 0.0, 74.0]}
const INSTRUMENT_COLORS := 3

var path: PathData
var font: Font

var _stage := -1
var _t: Array[float] = []      # each branch light's position along its branch (0..1)
var _behind := 0.0             # how long one branch has been waiting on a slow one
## Each light glows as it sings its note in the orchestra (Music.orchestra_note), fading.
var _glow: Array[float] = []
## Where the branches fused last (crossing in the middle): a soft flash there, fading.
var _fuse_at := Vector2.ZERO
var _fuse := 0.0
var _was_apart := false


func _ready() -> void:
	GameState.special_changed.connect(_on_special)
	GameState.branch_broke.connect(func(i: int) -> void: Music.play_branch_done(i))
	GameState.gate_broken.connect(_on_gate_broken)
	Music.orchestra_note.connect(func(i: int) -> void:
		if i < _glow.size():
			_glow[i] = 1.0)


func reset() -> void:
	_stage = -1
	queue_redraw()


func is_active() -> bool:
	return not GameState.branches.is_empty()


## Where the lights are, on average: the camera follows this while forked.
func focus() -> Vector2:
	if _t.is_empty():
		return path.gate_pos(GameState.stage)
	var sum := Vector2.ZERO
	for i in _t.size():
		sum += _branch_point(GameState.stage, _t.size(), i, _t[i])
	return sum / _t.size()


func _on_special() -> void:
	var n := GameState.stage
	var count := GameState.fork_count(n)
	if GameState.branches.is_empty():
		_t.clear()
		return
	var first := n == GameState.FORK_FROM or (count == 3 and n == GameState.FORK_THREE)
	_stage = n
	_t.clear()
	_glow.clear()
	for i in count:
		_t.append(0.0)
		_glow.append(0.0)
	_behind = 0.0
	if first:
		split_burst.emit(path.gate_pos(n - 1), count)
		if n == GameState.FORK_FROM:
			Narrator.say("13")


func _on_gate_broken(n: int) -> void:
	if n == GameState.FORK_TO:
		join_burst.emit(path.gate_pos(n))
		Narrator.say("converge")


func _process(delta: float) -> void:
	var branches := GameState.branches
	if branches.is_empty() or _t.size() != branches.size():
		if GameState.stage > GameState.FORK_FROM and GameState.stage <= GameState.FORK_TO + 6:
			queue_redraw()
		return
	for i in _glow.size():
		_glow[i] = maxf(0.0, _glow[i] - delta * 2.5)
	_fuse = maxf(0.0, _fuse - delta * 1.2)
	# how far apart the lights are (0 fused, 1 widest): the choir sings a chord or one note with it
	var avg := 0.0
	for x in _t:
		avg += x
	avg /= maxf(1.0, _t.size())
	var spread := absf(sin(PI * WEAVES * avg))
	Music.fork_spread = spread
	if spread > 0.5:
		_was_apart = true
	elif spread < 0.12 and _was_apart and avg > 0.05 and avg < 0.95:
		_was_apart = false
		_fuse = 1.0
		_fuse_at = _branch_point(GameState.stage, _t.size(), 0, avg)
		Music.choir_swell()
	var done := 0
	var slowest := 1.0
	for i in branches.size():
		var target := 1.0 if branches[i].done else GATE_T - 0.06
		_t[i] = lerpf(_t[i], target, 1.0 - exp(-4.5 * delta))
		if branches[i].done:
			done += 1
		slowest = minf(slowest, GameState.branch_progress(branches[i]))
	# One part of you ahead and another far behind: the voice notices, gently, once.
	if done > 0 and slowest < 0.35:
		_behind += delta
		if _behind > 6.0:
			Narrator.say("own_pace")
	else:
		_behind = 0.0
	queue_redraw()


func _branch_point(n: int, count: int, i: int, t: float) -> Vector2:
	var a := path.gate_pos(n - 1)
	var b := path.gate_pos(n)
	var off: float = OFFSETS[count][i]
	return a.lerp(b, t) + Vector2(off * sin(PI * WEAVES * t), 0.0)


func _branch_line(n: int, count: int, i: int, upto: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 18
	for s in steps + 1:
		pts.append(_branch_point(n, count, i, upto * s / steps))
	return pts


func _draw() -> void:
	var s := GameState.stage
	# forks already passed stay drawn, lit, like the rest of the line
	for n in range(maxi(GameState.FORK_FROM, s - 7), mini(s, GameState.FORK_TO + 1)):
		if n == s and not GameState.branches.is_empty():
			continue
		var count := GameState.fork_count(n)
		var col := Palette.line_col(n)
		for i in count:
			draw_polyline(_branch_line(n, count, i, 1.0), col, 2.0, true)
			draw_circle(_branch_point(n, count, i, GATE_T), 3.0, col)
	var branches := GameState.branches
	if branches.is_empty() or _t.size() != branches.size():
		return
	var count := branches.size()
	var col := Palette.line_col(s)
	if _fuse > 0.0:
		draw_circle(_fuse_at, 10.0 + 40.0 * (1.0 - _fuse), Color(Palette.GOLD, 0.25 * _fuse))
		draw_arc(_fuse_at, 8.0 + 60.0 * (1.0 - _fuse), 0.0, TAU, 40, Color(Palette.GOLD, 0.6 * _fuse), 1.6, true)
	for i in count:
		var b: Dictionary = branches[i]
		draw_polyline(_branch_line(s, count, i, 1.0), Color(Palette.INK, 0.15), 2.0, true)
		draw_polyline(_branch_line(s, count, i, _t[i]), col, 2.2, true)
		# its barrier
		var g := _branch_point(s, count, i, GATE_T)
		if b.done:
			draw_line(g + Vector2(-HALF, 0), g + Vector2(-HALF + 8, 0), col, 2.4, true)
			draw_line(g + Vector2(HALF - 8, 0), g + Vector2(HALF, 0), col, 2.4, true)
		else:
			var hole := 2.0 + GameState.branch_progress(b) * 16.0
			draw_line(g + Vector2(-HALF, 0), g + Vector2(-hole, 0), Palette.INK, 2.4, true)
			draw_line(g + Vector2(hole, 0), g + Vector2(HALF, 0), Palette.INK, 2.4, true)
			if font:
				View.text(self, font, g + Vector2(HALF + 6, 4), Fmt.num(maxf(0.0, b.hp)), HORIZONTAL_ALIGNMENT_LEFT,
					-1, 12, Color(Palette.INK, 0.55))
		# its light, in the colour of its instrument, the beat's notes climbing its branch towards it
		var lp := _branch_point(s, count, i, _t[i])
		if not b.done:
			var length := maxf(1.0, path.gate_len(s) - path.gate_len(s - 1))
			var ti: float = _t[i]
			BeatNotes.draw(self, lp, func(d: float) -> Vector2:
				var tb := ti - d / length
				return _branch_point(s, count, i, tb) if tb >= 0.0 else Vector2.INF, BeatNotes.strength())
		var tint: Color = [Palette.chapter_color(2), Palette.GOLD, Palette.chapter_color(3)][i % INSTRUMENT_COLORS]
		var gl: float = _glow[i] if i < _glow.size() else 0.0
		if gl > 0.0:
			draw_circle(lp, 14.0 + 14.0 * gl, Color(tint, 0.35 * gl))
			draw_arc(lp, 10.0 + 22.0 * (1.0 - gl), 0.0, TAU, 32, Color(tint, 0.7 * gl), 1.6, true)
		draw_circle(lp, 14.0, Color(tint, 0.14))
		draw_circle(lp, 7.0, Color(tint, 0.35))
		draw_circle(lp, 4.0, Palette.INK)
