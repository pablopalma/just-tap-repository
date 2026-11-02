extends Node2D
## Trailer v2's close (tools/trailer_v2.gd), drawn over the game. play() fades it in on white:
## close up, the tip draws a line, a note for every half beat, louder and higher as it goes… and when
## it is done the camera pulls back: it has written "just tap". `written` fires when the last stroke
## ends (the voice comes in there). Then the camera falls back into the dot, and the dot turns out to
## be the tap on the raised finger of the girl on the cover: it pulls back over the whole
## illustration, the title on the left. `revealing` fires as the illustration appears (the title
## theme comes in there). Lives in a CanvasLayer under the subtitles.

signal written
signal revealing

const WRITE_FROM := 0.5     # seconds after play()
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

var _playing := false
var _t := 0.0
var _strokes: Array[PackedVector2Array] = []   # the words, in drawing order (word units, y down)
var _lens := PackedFloat32Array()
var _ink_total := 0.0
var _word_rect := Rect2()
var _beat := 0.0
var _note := 0
var _done := false
var _revealed := false
var _art: Texture2D


func _ready() -> void:
	_build_words()
	# Builds/ is not imported (.gdignore): read the picture straight from the file.
	var img := Image.load_from_file(ProjectSettings.globalize_path(ART_PATH))
	if img != null and not img.is_empty():
		_art = ImageTexture.create_from_image(img)
	else:
		push_warning("trailer_words: no key art at %s (python tools/key_art.py)" % ART_PATH)
	visible = false


func play() -> void:
	_playing = true
	_t = 0.0
	_note = 0
	_done = false
	_revealed = false
	_beat = Music.beat_phase()
	visible = true


func _process(delta: float) -> void:
	if not _playing:
		return
	_t += delta
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
	if _playing:
		_draw_words(get_viewport_rect().size)

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
