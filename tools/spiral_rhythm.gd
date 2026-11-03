extends "res://tools/spiral_down.gd"
## Prototype: the spiral going down as a passage of its own (docs/pendientes.md). No tree, nothing to
## break: the light goes down on its own with the music, reaching each barrier exactly on a beat, and
## you tap as it gets there. On time, the barrier opens in gold and plays the next note of a melody;
## miss, and the light just goes through, that note silent. Nothing is lost: what you catch fills the
## light at the bottom. Barriers come every two beats at first, then on every beat.
## Behind the well, a giant bird of stars: each caught note lights its next star and draws the line
## to it on the beat. At the end it is whole, opens its eye and beats its wings over the light.
## `-- auto` plays it on its own (catching most notes); to record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/spiral_rhythm.tscn -- auto

const COUNT_IN := 4.0        # beats before the first barrier
const SLOW := 12             # barriers every two beats, then every beat
const WINDOW := 0.22         # how far from its beat a tap still catches a barrier (in beats)
## The melody the caught notes play, as degrees of the theme's key: a phrase stepping down, the
## next one a step higher, like a wave going out and coming back.
const MELODY := [4, 3, 2, 1, 4, 3, 2, 1, 5, 4, 3, 2, 5, 4, 3, 2]

var _times: Array[float] = []    # the beat each barrier is reached on (index 1.._total())
var _state := {}                 # barrier -> "hit" or "miss"
var _hits := 0
var _streak := 0
var _started := false
var _rng := RandomNumberGenerator.new()
var _glows := {}                 # barrier -> 0..1, its gold fading

## The bird: strokes of stars in a square from -1 to 1 (wings open, rising), lit in this order:
## the body, then the wings from the shoulders out, the feathers, the tail, and the crest last.
const BIRD := [
	[Vector2(0, -0.42), Vector2(0, -0.22), Vector2(0, 0.0), Vector2(0, 0.2)],                       # body
	[Vector2(0, -0.26), Vector2(-0.28, -0.42), Vector2(-0.55, -0.5), Vector2(-0.8, -0.46), Vector2(-1.0, -0.3)],
	[Vector2(0, -0.26), Vector2(0.28, -0.42), Vector2(0.55, -0.5), Vector2(0.8, -0.46), Vector2(1.0, -0.3)],
	[Vector2(-1.0, -0.3), Vector2(-0.78, -0.2), Vector2(-0.52, -0.12), Vector2(-0.26, -0.08), Vector2(0, 0.0)],
	[Vector2(1.0, -0.3), Vector2(0.78, -0.2), Vector2(0.52, -0.12), Vector2(0.26, -0.08), Vector2(0, 0.0)],
	[Vector2(-0.55, -0.5), Vector2(-0.52, -0.12)],                                                  # feathers
	[Vector2(0.55, -0.5), Vector2(0.52, -0.12)],
	[Vector2(-0.8, -0.46), Vector2(-0.78, -0.2)],
	[Vector2(0.8, -0.46), Vector2(0.78, -0.2)],
	[Vector2(0, 0.2), Vector2(-0.16, 0.46), Vector2(-0.28, 0.72)],                                  # tail
	[Vector2(0, 0.2), Vector2(0, 0.5), Vector2(0, 0.8)],
	[Vector2(0, 0.2), Vector2(0.16, 0.46), Vector2(0.28, 0.72)],
	[Vector2(0, -0.42), Vector2(-0.06, -0.56), Vector2(0, -0.64), Vector2(0.06, -0.56), Vector2(0, -0.42)],   # head
]
const BIRD_EYE := Vector2(0.0, -0.53)
const BIRD_SIZE := 0.46          # of the screen's height, for half its span
const LINE_TIME := 0.3           # seconds a line takes to draw itself to a new star
var _segs: Array[Array] = []     # [from, to] in the bird's square, in the order they light
var _lit: Array[float] = []      # seconds since each segment lit, or -1


func _ready() -> void:
	super()
	_rng.seed = 11
	for stroke in BIRD:
		for i in range(1, stroke.size()):
			_segs.append([stroke[i - 1], stroke[i]])
	_lit.resize(_segs.size())
	_lit.fill(-1.0)


## The music's beat, as the player hears it, as a number that keeps growing.
func _beat_now() -> float:
	return Music._heard_time() / (Music._s16() * 4.0)


func _start_schedule() -> void:
	_started = true
	var b := ceilf(_beat_now()) + COUNT_IN
	_times.resize(_total() + 1)
	_times[0] = b - COUNT_IN
	for i in range(1, _total() + 1):
		_times[i] = b
		b += 2.0 if i < SLOW else 1.0


## Where the light is along the helix for a beat: from barrier to barrier at an even pace, so it
## reaches each one on its beat.
func _theta_at(beat: float) -> float:
	if beat <= _times[0]:
		return 0.0
	for i in range(1, _times.size()):
		if beat <= _times[i]:
			var k := (beat - _times[i - 1]) / (_times[i] - _times[i - 1])
			return lerpf(_barrier_theta(i - 1), _barrier_theta(i), k)
	return _barrier_theta(_total())


func _process(delta: float) -> void:
	_t += delta
	if _ending >= 0.0:
		_process_ending(delta)
		return
	if not _started:
		if _t > 1.0:
			_start_schedule()
		queue_redraw()
		return
	var beat := _beat_now()
	_theta = _theta_at(beat)
	_cam = lerp_angle(_cam, _theta, 1.0 - exp(-10.0 * delta))   # close behind: the light stays at the bottom
	_kick *= exp(-8.0 * delta)
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < 1.6)
	for k in _glows.keys():
		_glows[k] = maxf(0.0, _glows[k] - delta * 0.6)
	for i in _lit.size():
		if _lit[i] >= 0.0:
			_lit[i] += delta
	# the barriers it went through without a tap: missed, quietly
	for i in range(1, _total() + 1):
		if not _state.has(i) and beat > _times[i] + WINDOW:
			_state[i] = "miss"
			_streak = 0
	_barrier = _first_open()
	if _auto:
		var i := _barrier
		if i <= _total() and absf(beat - _times[i]) < 0.03 and not _state.has(i):
			if _rng.randf() < 0.85:
				_tap()
			else:
				_state[i] = "miss"
				_streak = 0
	if beat > _times[_total()] + 1.0:
		_begin_ending()
	queue_redraw()


func _first_open() -> int:
	for i in range(1, _total() + 1):
		if not _state.has(i):
			return i
	return _total() + 1


func _tap() -> void:
	if not _started or _ending >= 0.0:
		return
	var beat := _beat_now()
	var i := _first_open()
	if i > _total() or absf(beat - _times[i]) > WINDOW:
		Music.play_tap(0.2, false)   # between barriers: just a soft note, nothing lost
		return
	_state[i] = "hit"
	_hits += 1
	_streak += 1
	_kick = 1.0
	_glows[i] = 1.0
	_light_next()
	_rings.append({"theta": _barrier_theta(i), "t": 0.0})
	var deg: int = MELODY[(_hits - 1) % MELODY.size()]
	var midi := Music.chord_note(deg, Music.tonic() + 12)
	Music._play("celesta", midi, 0.06)
	Music._play("harp", midi - 12, 0.035)
	Music.shape_note.emit(midi, true)
	if _streak in GameState.BEAT_MILESTONES:
		Music.play_milestone(GameState.BEAT_MILESTONES.find(_streak))


## The next line of the bird draws itself to its star.
func _light_next() -> void:
	var i := _lit.find(-1.0)
	if i >= 0:
		_lit[i] = 0.0


## At the end the bird comes whole: what is still dark lights in a quick run, then it wakes.
func _process_ending(delta: float) -> void:
	super(delta)
	for i in _lit.size():
		if _lit[i] >= 0.0:
			_lit[i] += delta
	var dark := _lit.find(-1.0)
	if dark >= 0 and fmod(_ending, 0.08) < delta:
		_lit[dark] = 0.0


func _light_amount() -> float:
	return float(_hits) / _total()


func _near_end() -> float:
	return clampf(1.0 - (_total() - (_first_open() - 1)) / float(BARRIERS_PER_TURN * 3), 0.0, 1.0)


func _hint_text() -> String:
	return "tap as the light reaches each line   ·   %d / %d notes" % [_hits, _total()]


## The barriers: ahead, ink strokes that grow bold as the light comes near; caught, open and gold;
## missed, faint and left behind.
func _draw_barriers(c: Vector2, ink: Color) -> void:
	var beat := _beat_now() if _started else 0.0
	for b in range(maxi(1, _first_open() - 3), mini(_first_open() + AHEAD * BARRIERS_PER_TURN, _total() + 1)):
		if _barrier_theta(b) < _theta - 0.35:
			continue   # already behind the camera
		var p := _project(_barrier_theta(b), R * (1.0 + INNER) * 0.5)
		if p.is_empty():
			continue
		var s: float = p[1]
		var dir: Vector2 = (p[0] - c).normalized()
		var half := 22.0 * s
		var w := clampf(3.0 * s, 0.8, 5.0)
		var st: String = _state.get(b, "")
		if st == "hit":
			var g: float = _glows.get(b, 0.0)
			var gap := 14.0 * s
			var col := Color(Palette.GOLD, 0.5 + 0.5 * g)
			draw_line(p[0] - dir * half, p[0] - dir * gap, col, w, true)
			draw_line(p[0] + dir * gap, p[0] + dir * half, col, w, true)
			continue
		if st == "miss":
			draw_line(p[0] - dir * half, p[0] + dir * half, Color(ink, 0.15 * clampf(s, 0.0, 1.0)), w * 0.7, true)
			continue
		# coming: bolder in the last beat before the light reaches it
		var near := clampf(1.0 - (_times[b] - beat), 0.0, 1.0) if _started and b < _times.size() else 0.0
		var a := clampf(s * 1.3, 0.0, 1.0) * (0.6 + 0.4 * near)
		draw_line(p[0] - dir * half * (1.0 + 0.3 * near), p[0] + dir * half * (1.0 + 0.3 * near), Color(ink, a), w * (1.0 + 0.8 * near), true)
		if near > 0.0:
			draw_circle(p[0], 10.0 * s * near, Color(Palette.GOLD, 0.25 * near))


## The bird of stars behind the well: its outline barely there as faint points, each caught note
## drawing a gold line on to its next star. At the end it shines whole, opens its eye and its wings
## beat slowly over the light.
func _draw_backdrop(c: Vector2) -> void:
	var h := get_viewport_rect().size.y
	var span := h * BIRD_SIZE
	var wake := clampf(_ending / 3.0, 0.0, 1.0) if _ending >= 0.0 else 0.0
	var flap := sin(_t * 1.6) * 0.06 * wake
	var at := func(v: Vector2) -> Vector2:
		# the wings rise and fall a little more towards their tips
		return c + Vector2(v.x, v.y - flap * absf(v.x) * 2.0) * span
	var gold := Palette.GOLD
	var shine := 0.35 + 0.45 * wake
	# the outline, faint, so it can be guessed before it is drawn
	for seg in _segs:
		for v in seg:
			draw_circle(at.call(v), 1.6, Color(0.93, 0.9, 0.84, 0.10))
	for i in _segs.size():
		var t := _lit[i]
		if t < 0.0:
			continue
		var k := clampf(t / LINE_TIME, 0.0, 1.0)
		var a: Vector2 = at.call(_segs[i][0])
		var b: Vector2 = at.call(_segs[i][1])
		var end := a.lerp(b, k)
		draw_line(a, end, Color(gold, shine), 1.6 + 1.2 * wake, true)
		# the star it reaches flashes as the line arrives, then glows
		if k >= 1.0:
			var flash := clampf(1.0 - (t - LINE_TIME) / 0.6, 0.0, 1.0)
			draw_circle(b, 5.0 + 10.0 * flash, Color(gold, 0.18 + 0.3 * flash))
			draw_circle(b, 2.6, Color(1, 0.96, 0.85, 0.9))
		draw_circle(a, 2.4, Color(1, 0.96, 0.85, 0.8))
	# awake: a soft glow over the whole bird, and its eye opening, blinking once
	if wake > 0.0:
		draw_circle(c + Vector2(0, -0.15) * span, span * 0.9, Color(gold, 0.06 * wake))
		var eye: Vector2 = at.call(BIRD_EYE)
		var open := clampf((_ending - 1.2) / 0.8, 0.0, 1.0)
		var blink := 1.0 - clampf(1.0 - absf(_ending - 2.6) / 0.15, 0.0, 1.0)
		var r := 5.0 * open * blink
		if r > 0.2:
			draw_circle(eye, r * 3.0, Color(gold, 0.25))
			draw_circle(eye, r, Color(1, 0.98, 0.9))
