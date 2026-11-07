class_name PhraseLine
extends Node2D
## Every barrier is a musical phrase (7/11/2026, tools/phrases.tscn grown into the game; replaces the
## upgrade tree). The notes of light climb the line to the tip in the phrase's rhythm, on the zone's
## own theme (its tempo, its bars); you tap each as it reaches the light and it plays its note of an
## arrangement written over the theme (_compose). A missed note passes, silent, and the phrase comes
## round again; with
## its notes caught the barrier breaks. Long notes are held: the bar of light burns and the note keeps
## sounding, and ends half a beat before the next so there is time to let go. What grows is the song:
## the zone's theme opens barrier by barrier, from far and muffled to whole.
## One way to play for now (7/11/2026: the three modes did not convince): the timing below.

signal phrase_done(n: int, misses: int)
## A note of the phrase caught: its degree of the arrangement (the dark's cymatics take its figure).
signal note_played(deg: int)
## The warm-up's lesson phrase is played (Warmup): the game itself begins.
signal lesson_done

## How to play them: beats either side of a note that still catch it, px a note travels per beat,
## beats of notes shown coming, half beats played, long notes held, a phrase whole in one pass.
const PLAY := {"window": 0.24, "speed": 82.0, "ahead": 4.0, "halves": true, "hold": true, "whole": false}
const RELEASE := 0.5        # a long note is held for its beats less this
const LEAD := 1.5           # at least this many beats before a phrase's first note
## The phrases of each zone, simple to rich: [beats, kind], kind "n" a note, "r" a rest, "h" a long note.
## Barrier n of a zone plays phrase (n - 1) % size of its zone's list.
const SETS := {
	1: [
		[[1, "n"], [1, "n"], [1, "n"], [1, "n"]],
		[[1, "n"], [1, "n"], [1, "n"], [1, "n"]],
		[[1, "n"], [1, "n"], [1, "n"], [1, "r"]],
		[[1, "n"], [1, "r"], [1, "n"], [1, "n"]],
		[[1, "n"], [1, "n"], [1, "n"], [1, "n"], [1, "n"], [1, "n"], [1, "n"], [1, "r"]],
		[[1, "n"], [1, "n"], [2, "h"]],
		[[1, "n"], [1, "r"], [1, "n"], [1, "r"]],
		[[2, "h"], [1, "n"], [1, "n"]],
		[[1, "n"], [1, "n"], [2, "h"], [1, "n"], [1, "n"], [1, "n"], [1, "r"]],
		[[1, "n"], [1, "n"], [1, "n"], [1, "n"], [2, "h"], [1, "n"], [1, "r"]],
	],
	2: [
		[[1, "n"], [0.5, "n"], [0.5, "n"], [1, "n"], [1, "r"]],
		[[0.5, "n"], [0.5, "n"], [1, "n"], [1, "n"], [1, "r"]],
		[[1, "n"], [1, "n"], [2, "h"]],
		[[1, "n"], [0.5, "n"], [0.5, "n"], [2, "h"]],
		[[0.5, "n"], [0.5, "n"], [0.5, "n"], [0.5, "n"], [1, "n"], [1, "r"]],
		[[2, "h"], [0.5, "n"], [0.5, "n"], [1, "n"]],
		[[1, "n"], [1, "r"], [0.5, "n"], [0.5, "n"], [1, "n"]],
		[[1, "n"], [0.5, "n"], [0.5, "n"], [1, "n"], [1, "n"], [2, "h"], [1, "n"], [1, "r"]],
		[[0.5, "n"], [0.5, "n"], [1, "n"], [2, "h"], [1, "n"], [1, "n"], [1, "n"], [1, "r"]],
		[[1, "n"], [1, "n"], [0.5, "n"], [0.5, "n"], [1, "n"], [2, "h"], [1, "n"], [1, "r"]],
	],
}
## The arrangement written for each phrase of SETS, note by note (rests left out), in degrees of the
## theme's pentatonic counted up from its tonic an octave up: 5 per octave, 0 the tonic, 2 the third,
## 3 the fifth, 5 the tonic again. A line that rises and falls through the zone, phrases asking and
## answering, the tenth coming home high. Each bar's notes follow that bar's key (Songs.TRACKS keys),
## so the line sits on the theme's harmony.
const ARRANGEMENT := {
	1: [
		[5, 6, 7, 6],
		[7, 6, 5, 3],
		[3, 5, 6],
		[7, 6, 5],
		[5, 6, 7, 8, 7, 6, 5],
		[3, 4, 5],
		[6, 7],
		[8, 7, 6],
		[5, 6, 7, 6, 5, 3],
		[5, 6, 7, 6, 8, 10],
	],
	2: [
		[5, 6, 7, 5],
		[7, 6, 5, 6],
		[7, 8, 5],
		[3, 4, 5, 3],
		[5, 6, 7, 6, 8],
		[8, 7, 6, 5],
		[3, 5, 6, 5],
		[5, 6, 7, 8, 6, 5, 3],
		[6, 7, 8, 7, 6, 5, 6],
		[5, 6, 7, 8, 7, 8, 10],
	],
}
## The warm-up's lesson (Main sets `lesson` while the warm-up asks for it): the real mechanic, slow,
## a note every two beats coming down the line to the light; four caught and it is learned (or three
## passes, so nobody is stuck). Its own little line of the arrangement.
const LESSON := [[2, "n"], [2, "n"], [2, "n"], [2, "n"]]
const LESSON_LINE := [5, 6, 7, 5]
const LESSON_PASSES := 3

## The arrangement's range, in degrees of the theme's pentatonic counted up from its tonic an octave
## up (5 per octave: 0 the tonic, 2 the third, 3 the fifth): where its line moves.
const LOW := 2
const HIGH := 9

var path: PathData
var tip: Node2D
## The warm-up's lesson phrase instead of the barrier's (it breaks nothing).
var lesson := false
## Main says when it may play: the game running, nothing else (a cinematic, the warm-up) in the way.
var active := false
## Main says when the theme is its to open (not under the prologue or the warm-up, not in the dark).
var owns_air := false

var _stage := -1
var _phrase: Array = []
var _start := 0.0           # beat the current pass starts on
var _origin := -1.0         # Music's beat grid when the phrase was set (a new theme moves it)
var _caught := {}
var _hits := 0
var _need := 0
var _misses := 0
var _holding := -1.0
var _hold_ring := 0.0
var _degs: Array = []       # the arrangement: a degree for each note of the phrase, in order
var _last_deg := 3          # where the line ended: the next phrase starts near it
var _hold_midi := 0
var _rings: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _t := 0.0
var _was_lesson := false
var _passes := 0


func _m() -> Dictionary:
	return PLAY


func _beat_len() -> float:
	return 60.0 / Music.bpm()


## Now, as heard, in beats of the current theme.
func _now() -> float:
	return Music._heard_time() / _beat_len()


func _metre() -> int:
	return int(Songs.TRACKS[Music.track].metre) if Music.track != "" else 4


## Beats from the grid's first beat to its first downbeat.
func _bar_offset() -> float:
	if Music.track == "":
		return 0.0
	var t: Dictionary = Songs.TRACKS[Music.track]
	return roundf((float(t.bar0) - float(t.beat0)) / _beat_len())


func _set_phrase() -> void:
	_stage = GameState.stage
	_was_lesson = lesson
	_passes = 0
	var zone := clampi(Zones.of(_stage), 1, SETS.size())
	var set: Array = SETS[zone]
	_phrase = LESSON if lesson else set[(_stage - 1) % set.size()]
	_misses = 0
	_hits = 0   # each barrier starts its own count
	_holding = -1.0
	_origin = Music._zone_origin
	_begin_pass(_next_bar(_now() + LEAD))
	_need = _notes(0.0).size()
	_degs = LESSON_LINE.duplicate() if lesson else _compose(_notes(0.0))


## The first downbeat at or after beat b.
func _next_bar(b: float) -> float:
	var m := float(_metre())
	var off := _bar_offset()
	return off + ceilf((b - off) / m) * m


func _length() -> float:
	var n := 0.0
	for p in _phrase:
		n += float(p[0])
	return ceilf(n / _metre()) * _metre()


func _begin_pass(at: float) -> void:
	_start = at
	_caught = {}
	if _m().whole:
		_hits = 0


## The notes of the pass starting on beat `from`: [beat, kind, beats].
func _notes(from: float) -> Array:
	var out: Array = []
	var b := from
	var m := _m()
	for p in _phrase:
		var kind: String = p[1]
		if kind == "h" and not m.hold:
			kind = "n"
		if kind != "r" and (absf(b - from - roundf(b - from)) < 0.01 or m.halves):
			out.append([b, kind, float(p[0])])
		b += float(p[0])
	return out


func _held_len(n: Array) -> float:
	return maxf(0.5, float(n[2]) - RELEASE)


func _process(delta: float) -> void:
	_t += delta
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < 1.0)
	for sp in _sparks:
		sp.t += delta
		sp.p += sp.v * delta
	_sparks = _sparks.filter(func(sp: Dictionary) -> bool: return sp.t < sp.life)
	_open_song(delta)
	if not active:
		_holding = -1.0
		queue_redraw()
		return
	if _stage != GameState.stage or absf(_origin - Music._zone_origin) > 0.001 or _was_lesson != lesson:
		_set_phrase()
	var now := _now()
	if now >= _start + _length():
		_begin_pass(_start + _length())
		_passes += 1
		if lesson and _passes >= LESSON_PASSES:
			_finish_lesson()
	var m := _m()
	for n in _notes(_start):
		if now > n[0] + m.window and not _caught.has(n[0]):
			_caught[n[0]] = false
			_misses += 1
	if _holding >= 0.0:
		var n := _note_at(_holding)
		if n.is_empty() or not _down():
			_holding = -1.0   # let go too soon: it sounded, but it was not held
		elif now >= n[0] + _held_len(n):
			_holding = -1.0
			_count(n)
		else:
			_sustain(delta)
			if randf() < delta * 40.0:
				_sparks.append({"p": tip.position + Vector2(randf_range(-5, 5), 0), "v": Vector2(randf_range(-30, 30), randf_range(-120, -50)),
					"t": 0.0, "life": randf_range(0.3, 0.6)})
	queue_redraw()


func _down() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE) \
		or Input.is_action_pressed("tap")


func _note_at(beat: float) -> Array:
	for n in _notes(_start):
		if absf(n[0] - beat) < 0.01:
			return n
	return []


## A tap (Main): the note it lands on, or a soft tap with nothing lost.
func tap() -> void:
	if not active:
		return
	var now := _now()
	GameState.total_taps += 1
	GameState.taps_at_gate += 1
	var notes := _notes(_start)
	for i in notes.size():
		var n: Array = notes[i]
		if _caught.has(n[0]):
			continue
		if absf(now - n[0]) <= _m().window:
			_caught[n[0]] = true
			_play_note(i, n)
			_rings.append({"t": 0.0})
			if n[1] == "h":
				_holding = n[0]
			else:
				_count(n)
			return
	Music.play_tap(0.05, false)


func _count(_n: Array) -> void:
	_hits += 1
	GameState.beat_streak += 1
	if lesson:
		if _hits >= _need:
			_finish_lesson()
		return
	var max_hp := GameState.max_hp(GameState.stage)
	GameState.hp = max_hp * (1.0 - float(_hits) / maxf(1.0, _need))   # the barrier cracks as it fills
	if _hits >= _need:
		_holding = -1.0
		print("PHRASE %d done: %d notes, %d missed" % [_stage, _need, _misses])
		phrase_done.emit(_stage, _misses)
		_stage = -1   # a new phrase once the next barrier is there


func _finish_lesson() -> void:
	_holding = -1.0
	lesson = false
	_stage = -1
	lesson_done.emit()


## Where none is written (later zones): one line through the whole phrase, the same every time it comes
## round, like a part written for the song. It starts near where the last phrase ended and arches up,
## its long notes and its first beats of a bar on the steady tones (the tonic, the third, the fifth),
## the quick notes stepping between them, never the same note three times running. Phrases answer each
## other: an odd barrier asks (ending open, on the fifth), an even one answers (home, on the tonic);
## the tenth of a zone ends high, on the tonic an octave up.
func _compose(notes: Array) -> Array:
	var n := notes.size()
	if n == 0:
		return []
	# the written arrangement, where there is one for this phrase
	var zone := Zones.of(_stage)
	if ARRANGEMENT.has(zone):
		var set: Array = ARRANGEMENT[zone]
		var line: Array = set[(_stage - 1) % set.size()]
		if line.size() == n:
			_last_deg = int(line[-1])
			return line.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = _stage * 7919
	# it starts where the last phrase came home, an octave down if that was high: the middle of the
	# range, so the line has room to rise and fall again
	var start := _last_deg - 5 if _last_deg > 6 else _last_deg
	start = clampi(start, LOW, HIGH - 3)
	var peak := clampi(start + 2 + rng.randi_range(0, 2), LOW, HIGH)
	var top := 0.55 + rng.randf_range(-0.1, 0.1)
	# where it comes home: the tonic (an answer) or the fifth (a question), in the octave nearest
	var homes: Array = [0, 5, 10] if _stage % 2 == 0 else [3, 8]
	if _stage % 10 == 0:
		homes = [5, 10]
	var out: Array = []
	var prev := start
	for i in n:
		var t := i / maxf(1.0, n - 1.0)
		var aim := lerpf(start, peak, t / top) if t <= top else lerpf(peak, start, (t - top) / (1.0 - top))
		var step := clampi(roundi(aim) - prev, -2, 2)   # it moves by steps, as a voice would
		var deg := prev + step if i > 0 else start
		var note: Array = notes[i]
		var on_bar := absf(fposmod(float(note[0]) - _bar_offset(), _metre())) < 0.01
		if note[1] == "h" or on_bar:
			deg = _steady(deg)
		deg = clampi(deg, LOW, HIGH)
		if out.size() >= 2 and deg == out[-1] and deg == out[-2]:
			deg = deg + 1 if deg < HIGH and t < top else deg - 1   # never the same note three times running
		out.append(deg)
		prev = deg
	var home: int = homes[0]
	for h in homes:
		if absi(h - (out[-2] if n > 1 else start)) < absi(home - (out[-2] if n > 1 else start)):
			home = h
	out[n - 1] = home
	_last_deg = home
	return out


## The nearest steady tone (tonic, third, fifth of the pentatonic: degrees 0, 2, 3 in each octave).
func _steady(deg: int) -> int:
	for d in [0, 1, -1, 2, -2]:
		if posmod(deg + d, 5) in [0, 2, 3]:
			return deg + d
	return deg


## The note `i` of the phrase sounds: its degree of the arrangement, in the theme's own colour (its
## instruments for a bar's first beat and the rest, as its taps), with a soft third below on the long
## notes and on the bars' first beats.
func _play_note(i: int, n: Array) -> void:
	var deg: int = _degs[i] if i < _degs.size() else 5
	var inst := "celesta"
	var shift := 0
	var gain := 1.0
	var on_bar := absf(fposmod(float(n[0]) - _bar_offset(), _metre())) < 0.01
	if Music.track != "" and Songs.TRACKS[Music.track].has("taps"):
		var v: Array = Songs.TRACKS[Music.track].taps.down if on_bar else Songs.TRACKS[Music.track].taps.beat
		inst = v[0]
		shift = int(v[1])
		gain = float(v[2])
	var midi := Music.chord_note(deg, Music.tonic() + 12) + shift
	while midi > Music.BRIGHT_CEILING:
		midi -= 12
	Music._schedule(Music._time, "note", inst, midi, 0.1 * gain)
	if n[1] == "h" or on_bar:
		Music._schedule(Music._time, "note", "harp", Music.chord_note(deg - 2, Music.tonic()), 0.045)
	_hold_midi = midi
	_hold_ring = 0.0
	note_played.emit(deg)


## A long note held keeps sounding: the same note shimmering on every eighth until you let go.
func _sustain(delta: float) -> void:
	_hold_ring += delta
	var every := _beat_len() * 0.5
	if _hold_ring >= every:
		_hold_ring -= every
		var odd := int(_t / every) % 2 == 1
		Music._schedule(Music._time, "note", "glass" if odd else "celesta", _hold_midi + (12 if odd else 0), 0.05)


## The zone's theme opens as its barriers fall: far and muffled at the first, whole at the tenth.
func _open_song(delta: float) -> void:
	if not owns_air:
		return
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus == -1:
		return
	var k := clampf(float((GameState.stage - 1) % 10) / 9.0, 0.0, 1.0)
	var db := lerpf(-11.0, 0.0, k)
	var cut := exp(lerpf(log(900.0), log(20000.0), k))
	var a := 1.0 - exp(-1.2 * delta)
	AudioServer.set_bus_volume_db(bus, lerpf(AudioServer.get_bus_volume_db(bus), db, a))
	var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	if lp:
		lp.cutoff_hz = exp(lerpf(log(maxf(lp.cutoff_hz, 1.0)), log(cut), a))


## A point `d` px back along the line from the tip (and straight on below the line's start).
func _back(d: float) -> Vector2:
	var at: float = tip.lit
	if at - d >= 0.0:
		return path.pos_at(at - d)
	var start := path.pos_at(0.0)
	return start + (start - path.pos_at(8.0)).normalized() * (d - at)


func _draw() -> void:
	if not active or tip == null:
		return
	var ink := Palette.INK
	var gold := Palette.GOLD.darkened(0.12)
	var m := _m()
	var now := _now()
	var light: Vector2 = tip.position
	# where the notes land
	_soft_ring(light, 19.0, gold, 0.5, 7.0)
	for pass_from in [_start, _start + _length()]:
		for n in _notes(pass_from):
			var ahead: float = n[0] - now
			if ahead > m.ahead or ahead < -0.5:
				continue
			var caught: Variant = _caught.get(n[0], null) if pass_from == _start else null
			var held: bool = n[1] == "h" and _holding >= 0.0 and absf(_holding - n[0]) < 0.01
			if caught == true and not held:
				continue
			var p := _back(ahead * m.speed)
			var a := clampf(1.0 - ahead / m.ahead, 0.0, 1.0) * (0.3 if caught == false else 1.0)
			if n[1] == "h":
				var from_d: float = 0.0 if held else ahead * m.speed
				var to_d: float = (ahead + _held_len(n)) * m.speed
				var pts := PackedVector2Array()
				var steps := 12
				for i in steps + 1:
					pts.append(_back(lerpf(from_d, to_d, i / float(steps))))
				var flick := 0.85 + 0.15 * sin(_t * 40.0)
				draw_polyline(pts, Color(gold, (0.9 * flick if held else 0.55) * a), 17.0 if held else 11.0, true)
				draw_polyline(pts, Color(1.0, 0.97, 0.88, (1.0 if held else 0.8) * a), 6.0 if held else 4.0, true)
				if held:
					continue
			var r := lerpf(5.0, 9.5, 1.0 - clampf(ahead / m.ahead, 0.0, 1.0))
			var col := ink.lerp(gold, smoothstep(2.0, 0.3, ahead))
			_soft_dot(p, r, col, a)
	if _holding >= 0.0:
		var pulse := 0.5 + 0.5 * sin(_t * 18.0)
		for i in 5:
			var k := i / 4.0
			draw_circle(light, lerpf(70.0, 18.0, k) * (1.0 + 0.1 * pulse), Color(Palette.GOLD.lightened(0.4), 0.05 + 0.1 * k))
		_soft_ring(light, 24.0 + 4.0 * pulse, gold, 0.8, 8.0)
	for sp in _sparks:
		var k: float = sp.t / sp.life
		draw_circle(sp.p, lerpf(2.6, 0.8, k), Color(1.0, 0.95, 0.75, 1.0 - k))
	for r in _rings:
		var k: float = r.t / 1.0
		_soft_ring(light, lerpf(12.0, 36.0, 1.0 - pow(1.0 - k, 3.0)), gold, 0.7 * (1.0 - k), 8.0)
	# how many notes the phrase needs: dots across the line, beside the barrier
	var gate := path.gate_pos(GameState.stage)
	var g_len := path.gate_len(GameState.stage)
	var side := (path.pos_at(g_len) - path.pos_at(g_len - 8.0)).normalized().orthogonal()
	for j in _need:
		draw_circle(gate + side * (40.0 + j * 12.0), 3.6, Color(gold) if j < _hits else Color(ink, 0.25))


## A ring with no hard edge: thin arcs stacked across its width, strongest in the middle, fading out
## on both sides, like light bleeding into the paper.
func _soft_ring(c: Vector2, r: float, col: Color, a: float, width: float) -> void:
	var steps := 7
	for i in steps:
		var u := (i / float(steps - 1)) * 2.0 - 1.0   # -1 inside .. 1 outside
		var k := exp(-u * u * 2.6)
		draw_arc(c, r + u * width * 0.5, 0.0, TAU, 48, Color(col, a * k * 0.45), width / steps * 1.6, true)


## A note as a soft drop of light: its glow fading out, its core with no hard edge.
func _soft_dot(p: Vector2, r: float, col: Color, a: float) -> void:
	var steps := 6
	for i in steps:
		var k := i / float(steps - 1)   # 0 outermost .. 1 the core
		draw_circle(p, lerpf(r * 2.4, r * 0.55, k), Color(col, a * lerpf(0.06, 0.55, k * k)))
