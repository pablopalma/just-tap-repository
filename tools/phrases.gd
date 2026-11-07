extends Node2D
## Prototype (4/11/2026, replacing the upgrade tree): every barrier is a musical phrase. The notes of
## light climb the line in the phrase's own rhythm (beats, half beats, rests, long notes to hold) and
## you tap each one as it reaches the light; it plays the next note of a melody in the theme's key.
## A note missed just passes, silent: the phrase comes round again until it is complete, and the
## barrier breaks. What you gain is the song: the theme starts muffled and far away, and every phrase
## opens it more, until it plays whole. Progress is learning to play, not upgrades.
## Three ways to play (like Guitar Hero's difficulties, named for how they feel), chosen first:
##   Breathe: just the experience. Wide timing, only the notes on the beat, long notes need no holding;
##            every note caught counts, across passes.
##   Flow:    the phrase as written; every note caught counts, across passes, and long notes are held.
##   Soar:    faster notes, tighter timing, and the phrase must be played whole in one pass.
## Holding a long note lights it up: the light flares and sparks run up the held bar.
## Tap: space, click, a gamepad's A (hold them for the long notes). Choose a mode with a tap on it or
## the keys 1–3. `-- auto mode=flow` plays it on its own in that mode.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/phrases.tscn -- auto mode=breathe

const GAP := 300.0          # px between barriers
## The modes: name, timing window (beats either side), px a note travels per beat, beats of notes
## shown coming, half beats played, long notes held, the whole phrase in one pass.
const MODES := {
	"breathe": {"es": "respira", "en": "breathe", "sub_es": "solo la experiencia", "sub_en": "just the experience",
		"window": 0.38, "speed": 105.0, "ahead": 4.5, "halves": false, "hold": false, "whole": false},
	"flow": {"es": "fluye", "en": "flow", "sub_es": "la frase como es", "sub_en": "the phrase as it is",
		"window": 0.24, "speed": 125.0, "ahead": 4.0, "halves": true, "hold": true, "whole": false},
	"soar": {"es": "vuela", "en": "soar", "sub_es": "más rápido, la frase entera", "sub_en": "faster, the whole phrase",
		"window": 0.15, "speed": 175.0, "ahead": 3.0, "halves": true, "hold": true, "whole": true},
}
const ORDER := ["breathe", "flow", "soar"]
## A long note is held for its beats less this, so it ends a moment before the next note comes and
## there is time to let go and tap again: the spacing between notes stays the music's.
const RELEASE := 0.5
const START_BEAT := 4.0     # the first phrase begins after a bar to listen
## The phrases: [beats, kind] with kind "n" a note, "r" a rest, "h" a note held for its beats.
const PHRASES := [
	[[1, "n"], [1, "n"], [1, "n"], [1, "n"]],
	[[1, "n"], [1, "n"], [1, "n"], [1, "r"]],
	[[1, "n"], [1, "n"], [2, "h"]],
	[[1, "n"], [1, "r"], [1, "n"], [1, "n"]],
	[[0.5, "n"], [0.5, "n"], [1, "n"], [1, "n"], [1, "r"]],
	[[1, "n"], [0.5, "n"], [0.5, "n"], [1, "n"], [1, "n"]],
	[[2, "h"], [1, "n"], [1, "n"]],
	[[0.5, "n"], [0.5, "n"], [0.5, "n"], [0.5, "n"], [1, "n"], [1, "r"], [2, "h"], [1, "n"], [1, "r"]],
]
## The melody the caught notes play, degrees of the theme's key, phrase by phrase.
const MELODY := [0, 2, 4, 2, 4, 5, 4, 2, 1, 2, 4, 7, 5, 4, 2, 0]
## The theme, muffled at first and opening phrase by phrase.
const CUT_FROM := 500.0
const DB_FROM := -14.0

var _phrase := 0            # the barrier being played
var _hits := 0              # notes caught in it
var _need := 0              # notes it takes
var _loop_from := 0.0       # beat the current pass of the phrase started on
var _caught := {}           # beat -> true: notes of this pass caught (or missed: false)
var _holding := -1.0        # beat of the long note being held, or -1
var _hold_ok := false
var _light_y := 0.0         # the light, along the line (px, up is negative)
var _target_y := 0.0
var _rings: Array[Dictionary] = []
var _cracks := 0.0
var _auto := false
var _ending := -1.0
var _mel := 0
var _down := false
var _font: Font
var _cam: Camera2D
var _t := 0.0
var _mode := ""             # "" while choosing
var _m: Dictionary
var _sparks: Array[Dictionary] = []   # rising from a held note
var _hold_deg := 0                   # the note a held one keeps sounding
var _hold_ring := 0.0                # when it sounds again

func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	SaveSystem.enabled = false
	_font = UIStyle.font()
	Music.zone = 1
	Music._pending_zone = 1
	Music.start()
	var bg := CanvasLayer.new()
	bg.layer = -1
	var paper := ColorRect.new()
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/paper.gdshader")
	paper.material = mat
	bg.add_child(paper)
	add_child(bg)
	_cam = Camera2D.new()
	_cam.zoom = Vector2.ONE * 1.9   # close on the light: the notes are what you read
	add_child(_cam)
	_light_y = 0.0
	_target_y = 0.0
	_air(0.0, 0.1)
	for a in Array(OS.get_cmdline_user_args()) + DevMenu.proto_args:
		if str(a).begins_with("mode="):
			_choose(str(a).trim_prefix("mode="))


func _choose(mode: String) -> void:
	if not MODES.has(mode) or _mode != "":
		return
	_mode = mode
	_m = MODES[mode]
	Music.play_celesta(2 + ORDER.find(mode) * 2)
	# the first phrase on the next bar but one, so there is a bar to listen
	_begin_phrase(ceilf((_now() + 2.0) / 4.0) * 4.0)


func _window() -> float:
	return float(_m.window)


func _beat_len() -> float:
	return 60.0 / Music.bpm()


## Now, as heard, in beats.
func _now() -> float:
	return Music._heard_time() / _beat_len()


func _phrase_len(i: int) -> float:
	var n := 0.0
	for p in PHRASES[i]:
		n += float(p[0])
	return ceilf(n / 4.0) * 4.0   # a phrase takes whole bars


## The notes of the current phrase's pass starting at `from`: [beat, kind, length].
func _notes(from: float) -> Array:
	var out: Array = []
	var b := from
	for p in PHRASES[_phrase]:
		var on_beat := absf(b - roundf(b)) < 0.01
		var kind: String = p[1]
		# breathe: only the notes on the beat, and long notes are plain notes
		if kind == "h" and not _m.hold:
			kind = "n"
		if kind != "r" and (on_beat or _m.halves):
			out.append([b, kind, float(p[0])])
		b += float(p[0])
	return out


func _begin_phrase(at: float) -> void:
	_loop_from = at
	_caught = {}
	_hits = 0
	_need = _notes(0.0).size()


func _process(delta: float) -> void:
	_t += delta
	var now := _now()
	for sp in _sparks:
		sp.t += delta
		sp.p += sp.v * delta
	_sparks = _sparks.filter(func(sp: Dictionary) -> bool: return sp.t < sp.life)
	if _mode == "":
		_cam.position = Vector2(0, _light_y + 60.0)
		queue_redraw()
		if _auto and _t > 1.0:
			_choose("flow")
		return
	if _holding >= 0.0 and randf() < delta * 40.0:
		_sparks.append({"p": Vector2(randf_range(-6, 6), _light_y - 4.0), "v": Vector2(randf_range(-40, 40), randf_range(-160, -60)),
			"t": 0.0, "life": randf_range(0.3, 0.7)})
	if _ending >= 0.0:
		_ending += delta
		_light_y -= delta * 220.0 * minf(1.0, _ending)
		if _ending > 5.0:
			get_tree().reload_current_scene()
	else:
		# the phrase comes round again until it is complete
		if now >= _loop_from + _phrase_len(_phrase):
			_loop_from += _phrase_len(_phrase)
			_caught = {}
			if _m.whole:
				_hits = 0   # soar: the phrase must be played whole in one pass
		# missed notes: they pass, silent
		for n in _notes(_loop_from):
			if now > n[0] + _window() and not _caught.has(n[0]):
				_caught[n[0]] = false
		# a long note held to its end
		if _holding >= 0.0:
			var n := _note_at(_holding)
			if not n.is_empty():
				if not _down:
					_holding = -1.0   # let go too soon: it was played, but not held
				elif now >= n[0] + _held_len(n):
					_holding = -1.0   # held to its end: it counts, and the hand is free for the next
					_hit(n, true)
				else:
					_sustain(delta)
		if _auto:
			_auto_play(now)
	_light_y = lerpf(_light_y, _target_y, 1.0 - exp(-4.0 * delta)) if _ending < 0.0 else _light_y
	_cam.position = Vector2(0, _light_y + 60.0)   # the light a little above centre, its notes coming from below
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < 1.2)
	_cracks = maxf(0.0, _cracks - delta * 2.0)
	queue_redraw()


func _note_at(beat: float) -> Array:
	for n in _notes(_loop_from):
		if absf(n[0] - beat) < 0.01:
			return n
	return []


func _unhandled_input(e: InputEvent) -> void:
	var press: bool = (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventKey and not e.echo and e.keycode == KEY_SPACE) \
		or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A)
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		DevMenu.back_to_game(get_tree())
		return
	if _mode == "" and e is InputEventKey and e.pressed:
		var k := (e as InputEventKey).keycode - KEY_1
		if k >= 0 and k < ORDER.size():
			_choose(ORDER[k])
		return
	if not press:
		return
	if _mode == "":
		if e.is_pressed() and e is InputEventMouseButton:
			var x: float = (e as InputEventMouseButton).position.x / get_viewport_rect().size.x
			_choose(ORDER[clampi(int(x * 3.0), 0, 2)])
		elif e.is_pressed():
			_choose("flow")
		return
	if e.is_pressed():
		_down = true
		_tap()
	else:
		_down = false


func _tap() -> void:
	if _ending >= 0.0:
		return
	var now := _now()
	for n in _notes(_loop_from):
		if _caught.has(n[0]):
			continue
		if absf(now - n[0]) <= _window():
			if n[1] == "h":
				_caught[n[0]] = true   # it sounds now; held to the end it counts
				_holding = n[0]
				_play_note(n[2])
			else:
				_hit(n, false)
			return
	Music.play_tap(0.05, false)   # off the notes: a soft tap, nothing lost


func _hit(n: Array, held: bool) -> void:
	_caught[n[0]] = true
	_hits += 1
	if not held:
		_play_note(1.0)
	_rings.append({"y": _light_y, "t": 0.0, "gold": true})
	_cracks = 1.0
	if _hits >= _need:
		_break()


## How long a long note is held: its beats less a breath before the next note.
func _held_len(n: Array) -> float:
	return maxf(0.5, float(n[2]) - RELEASE)


## The next note of the melody, on the theme's key.
func _play_note(beats: float) -> void:
	var deg: int = MELODY[_mel % MELODY.size()] + 2 * int(_phrase / 4.0)
	_mel += 1
	var inst := "celesta" if _phrase % 2 == 0 else "harp"
	Music._schedule_deg(Music._time, inst, deg, 12, 0.06 if beats < 2.0 else 0.08)
	_hold_deg = deg
	_hold_ring = 0.0


## While a long note is held it keeps sounding, as in Guitar Hero: the same note shimmering on, glass
## and celesta in turns every eighth, an octave up now and then; it stops the moment you let go.
func _sustain(delta: float) -> void:
	_hold_ring += delta
	var every := _beat_len() * 0.5
	if _hold_ring >= every:
		_hold_ring -= every
		var odd := int(_t / every) % 2 == 1
		Music._schedule_deg(Music._time, "glass" if odd else "celesta", _hold_deg, 24 if odd else 12, 0.035)


## The phrase is whole: the barrier opens, the light climbs to the next, the song opens a little more.
func _break() -> void:
	print("PHRASES phrase %d done at %.1f s" % [_phrase, _t])
	_rings.append({"y": _light_y - 40.0, "t": 0.0, "gold": true, "big": true})
	Music.choir_swell()
	_phrase += 1
	_target_y = -GAP * _phrase
	if _phrase >= PHRASES.size():
		_ending = 0.0
		Music.resolve_chord()
		_air(1.0, 3.0)
		return
	_air(float(_phrase) / PHRASES.size(), 2.5)
	# the next phrase starts on the next bar after the climb
	var now := _now()
	_begin_phrase(ceilf((now + 1.5) / 4.0) * 4.0)


## The theme's bus: k 0 muffled and far, 1 whole.
func _air(k: float, time: float) -> void:
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus == -1:
		return
	var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	var tw := create_tween().set_parallel()
	if lp:
		tw.tween_property(lp, "cutoff_hz", exp(lerpf(log(CUT_FROM), log(20000.0), k)), time)
	tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
		AudioServer.get_bus_volume_db(bus), lerpf(DB_FROM, 0.0, k), time)


func _exit_tree() -> void:
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, 0.0)
		var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
		if lp:
			lp.cutoff_hz = 20000.0


## For recording: catches most notes, misses one now and then, holds the long ones.
func _auto_play(now: float) -> void:
	for n in _notes(_loop_from):
		if _caught.has(n[0]):
			continue
		if absf(now - n[0]) < 0.04:
			if randf() < 0.12 and n[1] != "h":
				_caught[n[0]] = false
				return
			_down = true
			_tap()
			if n[1] != "h":
				get_tree().create_timer(0.1).timeout.connect(func() -> void: _down = false)
			return
	if _holding < 0.0 and _down:
		_down = false   # a held note done: let go


func _draw() -> void:
	if _mode == "":
		_draw_choice()
		return
	var ink := Palette.INK
	var gold := Palette.GOLD.darkened(0.12)
	var vp := get_viewport_rect().size
	var top := _cam.position.y - vp.y
	var bottom := _cam.position.y + vp.y
	# the line
	draw_line(Vector2(0, bottom), Vector2(0, -GAP * (PHRASES.size() + 1)), Color(ink, 0.8), 3.0, true)
	# the barriers, ahead; the current one cracking as its notes are caught
	for i in range(_phrase, PHRASES.size()):
		var y := -GAP * i - 40.0
		var w := 46.0
		var k := float(_hits) / maxf(1.0, _need) if i == _phrase else 0.0
		draw_line(Vector2(-w, y), Vector2(w, y), Color(ink, 0.9), 5.0, true)
		if i == _phrase:
			for c in int(k * 6.0):
				var x := lerpf(-w * 0.8, w * 0.8, (c + 0.5) / 6.0)
				draw_line(Vector2(x, y - 6), Vector2(x + 4, y + 6), Color(gold, 0.9), 2.0, true)
			# how many notes the phrase needs, as dots beside it
			for j in _need:
				var dot := Vector2(w + 16.0 + j * 12.0, y)
				draw_circle(dot, 3.5, Color(gold if j < _hits else Color(ink, 0.25)))
	# the notes, climbing to the light in the phrase's rhythm (this pass and the next)
	var now := _now()
	var light := Vector2(0, _light_y)
	var ahead_max: float = _m.ahead
	var speed: float = _m.speed
	if _ending < 0.0:
		for pass_from in [_loop_from, _loop_from + _phrase_len(_phrase)]:
			for n in _notes(pass_from):
				var ahead: float = n[0] - now
				if ahead > ahead_max or ahead < -0.6:
					continue
				var caught: Variant = _caught.get(n[0], null) if pass_from == _loop_from else null
				if caught == true and n[1] != "h":
					continue
				var p := light + Vector2(0, ahead * speed)
				var a := clampf(1.0 - ahead / ahead_max, 0.0, 1.0) * (0.35 if caught == false else 1.0)
				if n[1] == "h":
					# a long note: a bar of light as long as it lasts, to hold through
					var tail := light + Vector2(0, (ahead + _held_len(n)) * speed)
					var held := _holding >= 0.0 and absf(_holding - n[0]) < 0.01
					var from := light if held else p
					# held: the bar burns bright and wide, flickering as it pours into the light
					var flick := 0.85 + 0.15 * sin(_t * 40.0)
					draw_line(from, tail, Color(gold, (0.9 * flick if held else 0.55) * a), 16.0 if held else 9.0, true)
					draw_line(from, tail, Color(1.0, 0.97, 0.88, (1.0 if held else 0.8) * a), 6.0 if held else 3.0, true)
				var r := lerpf(4.0, 8.0, 1.0 - clampf(ahead / ahead_max, 0.0, 1.0))
				var col := ink.lerp(gold, smoothstep(2.0, 0.3, ahead))
				draw_circle(p, r * 2.2, Color(col, 0.25 * a))
				draw_circle(p, r, Color(col, a))
	# where they land
	draw_arc(light, 16.0, 0.0, TAU, 40, Color(gold, 0.5), 1.8, true)
	# holding a long note: the light flares, a wide ring pulses and sparks fly up
	if _holding >= 0.0:
		var pulse := 0.5 + 0.5 * sin(_t * 18.0)
		for i in 6:
			var k := i / 5.0
			draw_circle(light, lerpf(90.0, 20.0, k) * (1.0 + 0.1 * pulse), Color(Palette.GOLD.lightened(0.4), 0.05 + 0.1 * k))
		draw_arc(light, 28.0 + 5.0 * pulse, 0.0, TAU, 48, Color(gold, 0.9), 2.5, true)
	for sp in _sparks:
		var k: float = sp.t / sp.life
		draw_circle(sp.p, lerpf(3.0, 1.0, k), Color(1.0, 0.95, 0.75, 1.0 - k))
	# the light
	for i in 5:
		var k := i / 4.0
		draw_circle(light, lerpf(44.0, 10.0, k), Color(Palette.GOLD.lightened(0.3), 0.08 + 0.18 * k))
	draw_circle(light, 8.0, Color(1.0, 0.98, 0.9))
	for r in _rings:
		var k: float = r.t / 1.2
		var big := r.has("big")
		draw_arc(Vector2(0, r.y), lerpf(12.0, 120.0 if big else 40.0, 1.0 - pow(1.0 - k, 3.0)), 0.0, TAU, 48,
			Color(gold, 0.8 * (1.0 - k)), 2.5 if big else 1.8, true)


## Choosing how to play: three words side by side, the one under the mouse brighter.
func _draw_choice() -> void:
	var vp := get_viewport_rect().size / _cam.zoom
	var c := _cam.position
	var lang := "en" if SaveSystem.lang == "en" else "es"
	var title := "¿cómo quieres tocar?" if lang == "es" else "how would you like to play?"
	var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(_font, c + Vector2(-tw * 0.5, -vp.y * 0.22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Palette.INK, 0.6))
	var mouse := get_viewport().get_mouse_position().x / get_viewport_rect().size.x
	for i in ORDER.size():
		var m: Dictionary = MODES[ORDER[i]]
		var x := c.x + (i - 1) * vp.x * 0.3
		var hot := int(mouse * 3.0) == i
		var name: String = m[lang]
		var sub: String = m["sub_" + lang]
		var w := _font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var sw := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var a := 1.0 if hot else 0.55
		draw_string(_font, Vector2(x - w * 0.5, c.y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(Palette.INK, a))
		draw_string(_font, Vector2(x - sw * 0.5, c.y + 20.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(Palette.INK, 0.5 * a))
		# a small light under each, brighter for the harder ones
		for k in i + 1:
			draw_circle(Vector2(x + (k - i * 0.5) * 12.0, c.y + 40.0), 3.0, Color(Palette.GOLD.darkened(0.1), a))
