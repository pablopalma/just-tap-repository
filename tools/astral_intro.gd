extends Node2D
## Trailer v2's own scenes (tools/trailer_v2.gd), drawn over the game.
## · play_tunnel(): the opening. An astral journey through a wormhole: a dark tube that bends and
##   twists away, rushing past ever faster, the screen trembling, a rushing hum rising. It ends in a
##   flash of light that gives way to the paper.
## · play_words(): the close. On white, close up, the tip draws a line, a note for every half beat,
##   louder and higher as it goes… and when it is done the camera pulls back: it has written
##   "just tap". `written` fires when the last stroke ends (the voice comes in there).
##   Then the camera falls back into the dot, and the dot turns out to be the tap on the raised
##   finger of the girl on the cover: it pulls back over the whole illustration, the title on the left.
##   `revealing` fires as the illustration appears (the title theme comes in there).
## Lives in a CanvasLayer under the subtitles.

signal written
signal revealing

enum Show { NONE, TUNNEL, WORDS }

const TUNNEL := 4.6         # seconds of the tunnel
const FLASH := 0.5          # the light fills the screen, then gives way to the paper
const WRITE_FROM := 0.5     # the words: seconds after play_words()
const WRITE_TIME := 6.0
const ZOOM_TIME := 3.2      # the pull back, once the words are written
const WHITE := Color(0.985, 0.975, 0.955)
## Then the cover (the store's key art, tools/key_art.py): the dot is the tap on her raised finger.
const DIVE_AT := 10.4       # back into the dot
const DIVE_TIME := 1.3
const REVEAL_AT := 11.7     # the illustration, from her fingertip out to all of it
const REVEAL_TIME := 4.0
const CARD_AT := 15.0       # the title on the left
const ART_PATH := "res://Builds/capsule/art_land.png"
const FINGER := Vector2(0.5452, 0.6731)   # her fingertip in art_land (key_art.py: person, person_s, tip)
const RINGS := 44
const FAR := 9.0
const SIDES := 14           # lines along the tube
const STREAKS := 70
const RATE := 44100

var _show := Show.NONE
var _t := 0.0
var _dist := 0.0            # how far down the wormhole
var _rng := RandomNumberGenerator.new()
var _streaks: Array = []    # {a, r, len, speed}
var _strokes: Array[PackedVector2Array] = []   # the words, in drawing order (word units, y down)
var _lens := PackedFloat32Array()
var _ink_total := 0.0
var _word_rect := Rect2()
var _player: AudioStreamPlayer
var _beat := 0.0
var _note := 0
var _done := false
var _revealed := false
var _art: Texture2D


func _ready() -> void:
	_rng.seed = 5
	for i in STREAKS:
		_streaks.append({"a": _rng.randf() * TAU, "r": _rng.randf(), "len": _rng.randf_range(0.04, 0.16),
			"speed": _rng.randf_range(0.6, 1.4)})
	_build_words()
	# Builds/ is not imported (.gdignore): read the picture straight from the file.
	var img := Image.load_from_file(ProjectSettings.globalize_path(ART_PATH))
	if img != null and not img.is_empty():
		_art = ImageTexture.create_from_image(img)
	else:
		push_warning("astral_intro: no key art at %s (python tools/key_art.py)" % ART_PATH)
	_player = AudioStreamPlayer.new()
	_player.stream = tunnel_sound(TUNNEL + 0.6)
	_player.volume_db = -4.0
	add_child(_player)
	visible = false


func play_tunnel() -> void:
	_show = Show.TUNNEL
	_t = 0.0
	_dist = 0.0
	visible = true
	_player.play()


func play_words() -> void:
	_show = Show.WORDS
	_t = 0.0
	_note = 0
	_done = false
	_revealed = false
	_beat = Music.beat_phase()
	visible = true


func _process(delta: float) -> void:
	if _show == Show.NONE:
		return
	_t += delta
	if _show == Show.TUNNEL:
		var k := clampf(_t / TUNNEL, 0.0, 1.0)
		_dist += delta * lerpf(1.2, 11.0, k * k)
		for s in _streaks:
			s.r += s.speed * delta * (0.4 + 3.5 * k * k)
			if s.r > 1.2:
				s.r = _rng.randf_range(0.0, 0.15)
				s.a = _rng.randf() * TAU
		if _t > TUNNEL + FLASH:
			_show = Show.NONE
			visible = false
	else:
		# While it writes: a note on every half beat, each a little higher and louder.
		var w := (_t - WRITE_FROM) / WRITE_TIME
		var phase := Music.beat_phase()
		if w > 0.0 and w < 1.0 and fmod(phase * 2.0, 1.0) < fmod(_beat * 2.0, 1.0):
			Music.rising_note(_note, lerpf(0.022, 0.06, w))
			_note += 1
		_beat = phase
		if w >= 1.0 and not _done:
			_done = true
			written.emit()
		if _t >= REVEAL_AT and not _revealed:
			_revealed = true
			revealing.emit()
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	if _show == Show.TUNNEL:
		_draw_tunnel(vs)
	elif _show == Show.WORDS:
		_draw_words(vs)


# --- The wormhole -----------------------------------------------------------------------------------

## Where the tube's centre is at depth d (in tube radii): it winds slowly, so the far end wanders.
func _bend(d: float) -> Vector2:
	return Vector2(sin(d * 0.37) * 1.1 + sin(d * 0.16 + 1.0) * 0.8, cos(d * 0.29) * 0.8 + sin(d * 0.11) * 0.5)


func _draw_tunnel(vs: Vector2) -> void:
	var k := clampf(_t / TUNNEL, 0.0, 1.0)
	# The tremble grows with the speed.
	var shake := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * (1.5 + 16.0 * k * k)
	var c := vs * 0.5 + shake
	var focal := vs.y * 0.42
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.028, 0.05))
	var here := _bend(_dist)
	var step := FAR / RINGS
	var first := ceilf(_dist / step) * step
	# Every ring of the tube, far to near: [screen centre, screen radius, depth along the tube, z].
	var rings: Array = []
	for i in range(RINGS - 1, -1, -1):
		var d := first + i * step
		var z := d - _dist
		if z < 0.08:
			continue
		var s := focal / z
		rings.append([c + (_bend(d) - here) * s, s, d, z])
	# the light at the far end
	var end_c: Vector2 = rings[0][0] if not rings.is_empty() else c
	for i in 9:
		var f := 1.0 - i / 9.0
		draw_circle(end_c, vs.y * (0.02 + 0.32 * f) * (0.5 + 0.9 * k), Color(0.95, 0.9, 1.0, 0.04 * (0.4 + k)))
	# The walls: rings that breathe and twist, and lines running along the tube.
	var walls: Array = []   # per ring, its points
	for r in rings:
		var pts := PackedVector2Array()
		var d: float = r[2]
		var twist := d * 0.45 + _t * 0.6
		for j in SIDES * 4 + 1:
			var a := TAU * j / (SIDES * 4) + twist
			var wob := 1.0 + 0.07 * sin(a * 5.0 + d * 2.3 + _t * 2.0)
			pts.append(r[0] + Vector2.from_angle(a) * r[1] * wob)
		walls.append(pts)
		var z: float = r[3]
		var a_ring := clampf((FAR - z) / 3.0, 0.0, 1.0) * clampf(z / 0.6, 0.0, 1.0)
		var near := clampf(1.0 - z / FAR, 0.0, 1.0)
		var col := Color(0.42, 0.36, 0.85).lerp(Color(0.75, 0.95, 1.0), near)
		draw_polyline(pts, Color(col, 0.5 * a_ring), clampf(0.8 + 2.0 * near, 0.8, 3.0), true)
	for j in SIDES:
		var line := PackedVector2Array()
		for w: PackedVector2Array in walls:
			line.append(w[j * 4])
		if line.size() >= 2:
			draw_polyline(line, Color(0.7, 0.75, 1.0, 0.16 + 0.1 * k), 1.2, true)
	# streaks of speed
	var reach := vs.length() * 0.6
	for st in _streaks:
		var r0: float = st.r * reach
		var r1: float = r0 + st.len * reach * (0.3 + 2.0 * k)
		var dir := Vector2.from_angle(st.a)
		draw_line(end_c + dir * r0, end_c + dir * r1, Color(1.0, 0.97, 0.95, 0.06 + 0.3 * k * st.r), 1.5, true)
	# the flash: light fills everything, then the paper shows through
	if _t > TUNNEL - 0.5:
		var f := clampf((_t - (TUNNEL - 0.5)) / 0.5, 0.0, 1.0)
		var paper := clampf((_t - TUNNEL) / FLASH, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(WHITE.lerp(Palette.PAPER, paper), f * f))


# --- The words --------------------------------------------------------------------------------------

func _draw_words(vs: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vs), WHITE)
	if _art != null and _t >= REVEAL_AT:
		_draw_cover(vs)
		return
	var w := clampf((_t - WRITE_FROM) / WRITE_TIME, 0.0, 1.0)
	var we := w * w * (3.0 - 2.0 * w) * 0.15 + w * 0.85   # nearly even, a little ease at both ends
	var drawn := we * _ink_total
	var ball := _point_at(drawn)
	# The view: close on the tip while it writes, then back until the words sit as a title.
	var fit := vs.x * 0.5 / _word_rect.size.x
	var z := clampf((_t - WRITE_FROM - WRITE_TIME) / ZOOM_TIME, 0.0, 1.0)
	var ze := z * z * (3.0 - 2.0 * z)
	# then the dive: back into the dot, which comes to the middle of the screen
	var d := clampf((_t - DIVE_AT) / DIVE_TIME, 0.0, 1.0)
	var de := d * d
	var scale := fit * pow(6.0, 1.0 - ze) * pow(12.0, de)
	var centre := ball.lerp(_word_rect.get_center(), ze * (1.0 - de))
	var screen_c := (vs * Vector2(0.5, 0.36)).lerp(vs * 0.5, de)  # high: the subtitle stays clear below
	draw_set_transform(screen_c - centre * scale, 0.0, Vector2.ONE * scale)
	var ink := Color(Palette.INK, 1.0 - de)
	var width := 3.2 / scale * lerpf(1.6, 1.0, ze)
	var left := drawn
	for i in _strokes.size():
		if left <= 0.0:
			break
		var s := _strokes[i]
		if left >= _lens[i]:
			draw_polyline(s, ink, width, true)
		else:
			draw_polyline(_partial(s, left), ink, width, true)
		left -= _lens[i]
	# the tip, as in the game: a dot with a faint ring; it rests at the end of the last stroke and,
	# in the dive, keeps its size on screen while everything else grows past it
	var tip_a := 1.0 - 0.6 * ze * (1.0 - de)
	var dot := lerpf(7.0 * lerpf(1.0, 1.4, ze), 9.0, de) / scale
	draw_circle(ball, dot, Color(Palette.INK, tip_a))
	draw_arc(ball, 13.0 / scale, 0.0, TAU, 32, Color(Palette.INK, 0.25 * tip_a * (1.0 - de)), 1.2 / scale, true)
	draw_set_transform(Vector2.ZERO)
	# under the title, once it is whole: the tagline
	var base_y := screen_c.y + (_word_rect.end.y - centre.y) * scale
	var tag_a := clampf((z - 0.7) / 0.3, 0.0, 1.0) * (1.0 - clampf(d * 3.0, 0.0, 1.0))
	_centred(UIStyle.italic(), "if you had a bad day…", 30, base_y + 56.0, Color(Palette.INK, 0.75 * tag_a), vs)


func _centred(font: Font, text: String, size: int, y: float, col: Color, vs: Vector2) -> void:
	_centred_at(font, text, size, Vector2(vs.x * 0.5, y), col)


func _centred_at(font: Font, text: String, size: int, at: Vector2, col: Color) -> void:
	if col.a <= 0.0:
		return
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(at.x - tw * 0.5, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## The cover: the camera falls into the dot, and the dot is the tap on the girl's raised finger; it
## pulls back over the whole illustration (her, the line of light, the whale) and the title settles
## on the left, where the store's capsule has it.
func _draw_cover(vs: Vector2) -> void:
	var size := Vector2(_art.get_width(), _art.get_height())
	var fit := maxf(vs.x / size.x, vs.y / size.y)
	var finger := size * FINGER
	var r := clampf((_t - REVEAL_AT) / REVEAL_TIME, 0.0, 1.0)
	var re := r * r * (3.0 - 2.0 * r)
	var scale := fit * pow(9.0, 1.0 - re)
	var natural := vs * 0.5 + (finger - size * 0.5) * fit
	var at := (vs * 0.5).lerp(natural, re)
	var art_a := clampf((_t - REVEAL_AT) / 0.7, 0.0, 1.0)
	draw_texture_rect(_art, Rect2(at - finger * scale, size * scale), false, Color(1, 1, 1, art_a))
	# the dot lands in her tap, and a ring of gold opens from it
	var land := clampf((_t - REVEAL_AT - 0.5) / 1.4, 0.0, 1.0)
	draw_circle(at, lerpf(9.0, 5.0, land), Color(Palette.INK, 1.0 - land))
	if land > 0.0 and land < 1.0:
		var ring := 1.0 - pow(1.0 - land, 3.0)
		draw_arc(at, lerpf(8.0, 90.0, ring), 0.0, TAU, 64, Color(Palette.GOLD, 0.9 * (1.0 - land)), 3.0, true)
	# the title on the left, as on the capsule
	var card := clampf((_t - CARD_AT) / 1.2, 0.0, 1.0)
	if card <= 0.0:
		return
	var logo_c := vs * Vector2(0.25, 0.4)
	var ls := vs.x * 0.28 / _word_rect.size.x
	draw_set_transform(logo_c - _word_rect.get_center() * ls, 0.0, Vector2.ONE * ls)
	for s in _strokes:
		draw_polyline(s, Color(Palette.INK, card), 3.4 / ls, true)
	draw_set_transform(Vector2.ZERO)
	var below := logo_c.y + (_word_rect.end.y - _word_rect.get_center().y) * ls
	_centred_at(UIStyle.italic(), "if you had a bad day…", 32, Vector2(logo_c.x, below + 60.0),
		Color(Palette.INK, 0.8 * card))
	var where := clampf((_t - CARD_AT - 0.8) / 0.8, 0.0, 1.0)
	_centred_at(UIStyle.font(), "free demo  ·  itch.io", 28, Vector2(logo_c.x, below + 118.0),
		Color(Palette.chapter_color(1).darkened(0.15), where))


## Where the tip is after `dist` of ink; between strokes it glides over (no ink) to the next one.
func _point_at(dist: float) -> Vector2:
	var left := dist
	for i in _strokes.size():
		var s := _strokes[i]
		if left <= _lens[i]:
			var p := _partial(s, left)
			return p[p.size() - 1]
		left -= _lens[i]
	var last := _strokes[_strokes.size() - 1]
	return last[last.size() - 1]


func _partial(s: PackedVector2Array, dist: float) -> PackedVector2Array:
	var out := PackedVector2Array([s[0]])
	for j in range(1, s.size()):
		var seg := s[j - 1].distance_to(s[j])
		if dist < seg:
			out.append(s[j - 1].lerp(s[j], dist / maxf(seg, 0.0001)))
			return out
		out.append(s[j])
		dist -= seg
	return out


## "just tap" in one hand-drawn line per stroke: x-height 1, baseline 0 (built y up, stored y down).
func _build_words() -> void:
	var letters := {
		"j": [[[0.3, 1.0], [0.3, 0.2], [0.28, -0.4], [0.14, -0.66], [-0.08, -0.66], [-0.2, -0.52]],
			[[0.26, 1.36], [0.34, 1.36]]],
		"u": [[[0.0, 1.0], [0.0, 0.35], [0.1, 0.08], [0.33, -0.02], [0.56, 0.06], [0.7, 0.3], [0.72, 1.0]],
			[[0.72, 1.0], [0.72, 0.2], [0.78, 0.0], [0.88, 0.02]]],
		"s": [[[0.6, 0.88], [0.44, 1.0], [0.2, 0.99], [0.05, 0.84], [0.1, 0.64], [0.34, 0.53], [0.56, 0.41],
			[0.64, 0.21], [0.52, 0.03], [0.26, -0.02], [0.02, 0.1]]],
		"t": [[[0.24, 1.42], [0.24, 0.24], [0.3, 0.05], [0.47, -0.01], [0.62, 0.08]],
			[[0.0, 1.0], [0.56, 1.0]]],
		"a": [[[0.62, 0.8], [0.46, 0.99], [0.22, 0.97], [0.05, 0.72], [0.03, 0.34], [0.16, 0.05], [0.4, -0.01],
			[0.6, 0.18], [0.66, 0.5]],
			[[0.66, 1.0], [0.66, 0.16], [0.72, 0.0], [0.84, 0.02]]],
		"p": [[[0.0, 1.0], [0.0, -0.72]],
			[[0.0, 0.72], [0.18, 0.96], [0.42, 1.0], [0.64, 0.8], [0.7, 0.46], [0.6, 0.14], [0.38, -0.01],
			[0.16, 0.04], [0.0, 0.22]]],
	}
	var widths := {"j": 0.42, "u": 0.88, "s": 0.66, "t": 0.62, "a": 0.84, "p": 0.72}
	var x := 0.0
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for ch in "just tap":
		if ch == " ":
			x += 0.5
			continue
		for pts: Array in letters[ch]:
			var s := _smooth(pts, x)
			_strokes.append(s)
			for p in s:
				lo = lo.min(p)
				hi = hi.max(p)
		x += widths[ch] + 0.2
	_word_rect = Rect2(lo, hi - lo)
	for s in _strokes:
		var l := 0.0
		for j in range(1, s.size()):
			l += s[j - 1].distance_to(s[j])
		_lens.append(l)
		_ink_total += l


## Catmull-Rom through the points, shifted right by x and flipped so y grows down.
func _smooth(pts: Array, x: float) -> PackedVector2Array:
	var v: Array[Vector2] = []
	for p in pts:
		v.append(Vector2(p[0] + x, -p[1]))
	if v.size() == 2:
		return PackedVector2Array([v[0], v[1]])
	var out := PackedVector2Array()
	for i in v.size() - 1:
		var p0 := v[maxi(i - 1, 0)]
		var p1 := v[i]
		var p2 := v[i + 1]
		var p3 := v[mini(i + 2, v.size() - 1)]
		for k in 10:
			var t := k / 10.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(v[v.size() - 1])
	return out


# --- The sound --------------------------------------------------------------------------------------

## Going very fast through the wormhole: rushing air through a resonant filter that sweeps up
## (fiii…), fluttering faster and faster (ff-ff-ff), over a low hum that rises an octave; at the end
## it all drops away in a long falling whoosh (…fuuu) into the light.
static func tunnel_sound(length: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var low := 0.0
	var band := 0.0
	var low2 := 0.0
	var band2 := 0.0
	var ph1 := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	var flut := 0.0
	var hum_lp := 0.0
	var end := TUNNEL / length   # where the fall begins, 0..1
	for i in n:
		var t := float(i) / n
		var rise := clampf(t / end, 0.0, 1.0)
		var fall := clampf((t - end) / (1.0 - end), 0.0, 1.0)
		var white := rng.randf_range(-1.0, 1.0)
		# the air: a resonant band sweeping up, then falling fast at the end
		var fc := lerpf(350.0, 3800.0, pow(rise, 1.6)) * lerpf(1.0, 0.18, pow(fall, 0.6))
		var f := 2.0 * sin(PI * fc / RATE)
		var hp := white - low - 0.35 * band
		band += f * hp
		low += f * band
		# a second, lower band for body
		var f2 := 2.0 * sin(PI * fc * 0.37 / RATE)
		var hp2 := white - low2 - 0.6 * band2
		band2 += f2 * hp2
		low2 += f2 * band2
		var air := band * 0.55 + band2 * 0.45
		# flutter: the air beats faster and faster
		var rate := lerpf(5.0, 28.0, rise * rise) * lerpf(1.0, 0.4, fall)
		flut += TAU * rate / RATE
		var beat := 0.65 + 0.35 * sin(flut)
		# the hum: two detuned saws and their octave, rising, under a soft low-pass
		var hz := 52.0 * pow(2.0, rise * 1.0) * lerpf(1.0, 0.7, fall)
		ph1 = fmod(ph1 + hz / RATE, 1.0)
		ph2 = fmod(ph2 + hz * 1.012 / RATE, 1.0)
		ph3 = fmod(ph3 + hz * 2.0 / RATE, 1.0)
		var saw := (ph1 * 2.0 - 1.0) + (ph2 * 2.0 - 1.0) + 0.5 * (ph3 * 2.0 - 1.0)
		hum_lp += (saw - hum_lp) * 0.04
		var env := smoothstep(0.0, 0.12, t) * (0.35 + 0.65 * rise) * (1.0 - smoothstep(0.55, 1.0, fall))
		out[i] = (air * beat * 1.4 + hum_lp * 0.22) * env
	var peak := 0.0001
	for s in out:
		peak = maxf(peak, absf(s))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(out[i] / peak * 0.9, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
