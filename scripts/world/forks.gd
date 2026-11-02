extends Node2D
## Forks (§19.4). From FORK_FROM the line splits into two branches between every pair of barriers,
## and into three from FORK_THREE: each branch has its own small barrier and its own light, one tap
## hits them all, and the barrier passes once every branch has reached the join. The first split
## (and the third branch) open with a golden burst; the last join closes the fork with another.

signal split_burst(pos: Vector2, count: int)
signal join_burst(pos: Vector2)

const GATE_T := 0.62
const HALF := 22.0
const OFFSETS := {2: [-58.0, 58.0], 3: [-74.0, 0.0, 74.0]}
const INSTRUMENT_COLORS := 3

var path: PathData
var font: Font

var _stage := -1
var _t: Array[float] = []      # each branch light's position along its branch (0..1)
var _behind := 0.0             # how long one branch has been waiting on a slow one


func _ready() -> void:
	GameState.special_changed.connect(_on_special)
	GameState.branch_broke.connect(func(i: int) -> void: Music.play_branch_done(i))
	GameState.gate_broken.connect(_on_gate_broken)


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
	for i in count:
		_t.append(0.0)
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
	return a.lerp(b, t) + Vector2(off * sin(PI * t), 0.0)


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
		# its light, in the colour of its instrument
		var lp := _branch_point(s, count, i, _t[i])
		var tint: Color = [Palette.chapter_color(2), Palette.GOLD, Palette.chapter_color(3)][i % INSTRUMENT_COLORS]
		draw_circle(lp, 14.0, Color(tint, 0.14))
		draw_circle(lp, 7.0, Color(tint, 0.35))
		draw_circle(lp, 4.0, Palette.INK)
