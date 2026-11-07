class_name Warmup
extends Node2D
## A new player's first moments (4/11/2026, a player's suggestion on Reddit): before the line climbs,
## a calm warm-up at the tip. First a few taps one at a time, each a soft note in a quiet room (the
## theme muffled and low); then the beat comes in shown just as in the game, the notes of light
## climbing the line to the tip (BeatNotes, drawn bold by the tip), and you tap as each one lands, until
## a few are on the beat. The voice welcomes you (Main's own
## greeting), gives the tip ("beat_1") and says you got it ("beat_2"). It never fails: after enough
## taps it goes on anyway. Main sends it the taps and starts the game when it is finished.

signal finished(on_beat: int, taps: int)

const FREE_TAPS := 3      # one at a time, no rhythm yet
const BEAT_TAPS := 4      # on the beat, to be done
const MAX_TAPS := 14      # in the beat part: then it goes on anyway
const RING := 46.0        # the light's ring, screen px
const OUT_TIME := 1.8     # the ring opening in gold before the game starts
## The theme while it lasts: muffled and low at first, opening as the beat comes in.
const QUIET_CUT := 600.0
const BEAT_CUT := 2200.0
const QUIET_DB := -9.0

var tip: Node2D
var cam: Camera2D
## 0 one tap at a time, 1 with the beat, 2 done.
var phase := 0

var _free := 0
var _hits := 0
var _taps := 0
var _last_beat := -100
var _t := 0.0
var _out := -1.0
var _blooms: Array[Dictionary] = []   # {t, gold}
var _air: Tween


func _ready() -> void:
	z_index = 5
	_set_air(QUIET_CUT, QUIET_DB, 1.5)


func tap() -> void:
	if phase == 0:
		_free += 1
		Music.play_celesta(_free * 2)   # a soft note climbing, no beat asked for yet
		_blooms.append({"t": 0.0, "gold": false})
		if _free >= FREE_TAPS:
			phase = 1
			_t = 0.0
			_say("beat_1")
			_set_air(BEAT_CUT, -4.0, 2.0)
	elif phase == 1 and BuildFlags.PHRASES:
		pass   # the lesson phrase takes the taps (Main sends them to PhraseLine)
	elif phase == 1:
		_taps += 1
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat:
			_last_beat = k
			_hits += 1
			Music.play_accent(_hits)
			_blooms.append({"t": 0.0, "gold": true})
		else:
			Music.play_tap(0.1, false)
			_blooms.append({"t": 0.0, "gold": false})
		if _hits >= BEAT_TAPS or _taps >= MAX_TAPS:
			phase = 2
			_out = 0.0
			if _hits >= BEAT_TAPS:
				_say("beat_2")
			Music.play_milestone(1)
			_set_air(20000.0, 0.0, 2.5)


## With phrases: the lesson phrase was played (PhraseLine.lesson_done). caught: whether it was learned.
func lesson_done(caught: bool) -> void:
	if phase != 1:
		return
	_hits = BEAT_TAPS if caught else 0
	phase = 2
	_out = 0.0
	if caught:
		_say("beat_2")
	Music.play_milestone(1)
	_set_air(20000.0, 0.0, 2.5)


func _process(delta: float) -> void:
	_t += delta
	for b in _blooms:
		b.t += delta
	_blooms = _blooms.filter(func(b: Dictionary) -> bool: return b.t < 1.4)
	if _out >= 0.0:
		_out += delta
		if _out >= OUT_TIME:
			_out = -1.0
			finished.emit(_hits, _taps)
	if tip:
		global_position = tip.global_position
	queue_redraw()


## Right now, not after the narrator's usual gap: the tip belongs to this moment. Marked as said, so
## the game's own lesson does not repeat it.
func _say(id: String) -> void:
	GameState.said[id] = true
	Narrator.say_now(id)


## The theme's bus: how muffled (low-pass cutoff) and how loud, eased over `time`.
func _set_air(cut: float, db: float, time: float) -> void:
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus == -1:
		return
	var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	if _air:
		_air.kill()
	_air = create_tween().set_parallel()
	if lp:
		_air.tween_property(lp, "cutoff_hz", cut, time).set_trans(Tween.TRANS_SINE)
	_air.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
		AudioServer.get_bus_volume_db(bus), db, time)


func _exit_tree() -> void:
	# whatever happens, the theme comes back as it was
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, 0.0)
		var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
		if lp:
			lp.cutoff_hz = 20000.0


func _draw() -> void:
	var px := 1.0 / (cam.zoom.x if cam else 1.0)   # one screen pixel, in the world
	var gold := Palette.GOLD
	var r := RING * px
	var show := minf(1.0, _t / 1.2) if phase == 0 else 1.0
	if phase == 0:
		# the light breathes slowly, waiting: no beat asked for yet
		var b := 0.5 + 0.5 * sin(_t * 1.6)
		draw_circle(Vector2.ZERO, r * (1.6 + 0.3 * b), Color(gold, 0.06 * show))
		draw_arc(Vector2.ZERO, r * (1.0 + 0.1 * b), 0.0, TAU, 64, Color(Palette.INK, 0.35 * show), 1.5 * px, true)
	# the taps on the beat so far, as small lights around the ring
	for i in _hits:
		var a := -PI * 0.5 + TAU * i / BEAT_TAPS
		var p := Vector2.from_angle(a) * r * 1.9
		draw_circle(p, 9.0 * px, Color(gold, 0.25))
		draw_circle(p, 4.0 * px, Color(1.0, 0.97, 0.88))
	# each tap blooms: gold on the beat, soft ink otherwise
	for b in _blooms:
		var k: float = b.t / 1.4
		var col: Color = gold if b.gold else Palette.INK
		draw_arc(Vector2.ZERO, r * lerpf(1.0, 3.0, 1.0 - pow(1.0 - k, 3.0)), 0.0, TAU, 64,
			Color(col, (0.7 if b.gold else 0.35) * (1.0 - k)), 2.5 * px, true)
	# done: the ring opens in gold
	if _out >= 0.0:
		var k := _out / OUT_TIME
		for i in 3:
			var kk := clampf(k * 1.3 - i * 0.15, 0.0, 1.0)
			draw_arc(Vector2.ZERO, r * lerpf(1.0, 9.0, kk), 0.0, TAU, 96, Color(gold, 0.8 * (1.0 - kk)), 3.0 * px, true)
