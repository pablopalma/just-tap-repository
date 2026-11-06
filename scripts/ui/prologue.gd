class_name Prologue
extends Control
## The very first moments of a first run (docs/brief-juego-completo.md §1, "El prólogo", 5/11/2026):
## endless white paper, no line, no HUD. A light falls slowly from the sky and, once it rests, wonders
## where it is, in small handwritten words and no voice. The Father answers with his. It is not said
## whether the light has died: a dream, a faint, an in-between. The Father's last words are the game's
## own greeting, and as they end the paper lifts to show the world and the warm-up begins.
## It plays on its own; a tap moves to the next line; holding skips it all.

signal finished(skipped: bool)

const FALL := 4.0           # seconds the light takes to come down
const SETTLE := 1.2         # after it lands, before it speaks
const LIGHT_LINE := 2.8     # how long one of the light's lines stays
const FATHER_LINE := 4.6    # a Father's line without a recording yet
const GAP := 0.7            # a breath between lines
const LIFT := 2.4           # the paper lifting at the end
const HOLD_SKIP := 1.6      # holding down this long skips it

## Who says what: "light" lines are drawn here; the Father's are VoiceLines ids, said by the Narrator.
const SCRIPT := [
	["light", "where"], ["light", "what"], ["light", "body"],
	["father", "pro_1"],
	["light", "who"],
	["father", "pro_2"],
	["light", "over"],
	["father", "pro_3"],
	["light", "forget"],
	["father", "pro_4"],
	["father", "00"],
]
const LIGHT := {
	"where": {"es": "¿Dónde estoy?", "en": "Where am I?"},
	"what": {"es": "¿Qué me pasó?", "en": "What happened to me?"},
	"body": {"es": "¿Y mi cuerpo?", "en": "Where's my body?"},
	"who": {"es": "¿Quién eres?", "en": "Who are you?"},
	"over": {"es": "¿Se terminó todo?", "en": "Is it… over?"},
	"forget": {"es": "No recuerdo nada.", "en": "I don't remember anything."},
}

## The tip: the light comes to rest where it is on the screen, so the world lines up under it.
var tip: Node2D
var rest := Vector2.ZERO

var _t := 0.0
var _step := -1
var _step_t := 0.0
var _step_len := 0.0
var _lift := -1.0
var _hold := 0.0
var _font: Font
var _paper: ColorRect
var _ink: Control   # the light and its words, over the paper
var _skipped := false


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_font = load(UIStyle.ITALIC)
	_paper = ColorRect.new()
	_paper.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_paper.mouse_filter = MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/paper.gdshader")
	mat.set_shader_parameter("paper", Palette.PAPER.lightened(0.35))
	mat.set_shader_parameter("vignette", Color(Palette.VIGNETTE, 0.12))
	_paper.material = mat
	add_child(_paper)
	_ink = Control.new()
	_ink.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_ink.mouse_filter = MOUSE_FILTER_IGNORE
	_ink.draw.connect(_draw_light)
	add_child(_ink)
	Narrator.hold = true   # nothing else is said while it lasts
	# the theme far away, muffled: almost silence (the warm-up opens it again)
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, -24.0)
		var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
		if lp:
			lp.cutoff_hz = 450.0


## A tap: the next line, now.
func tap() -> void:
	if _step >= 0 and _lift < 0.0:
		_step_t = _step_len


func _process(delta: float) -> void:
	_t += delta
	if tip:
		rest = tip.get_global_transform_with_canvas().origin
	# holding down skips it all
	var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE) \
		or Input.is_action_pressed("tap")
	_hold = _hold + delta if down else 0.0
	if _hold >= HOLD_SKIP and _lift < 0.0:
		_skipped = true
		_begin_lift()
	if _lift >= 0.0:
		_lift += delta
		_paper.modulate.a = 1.0 - smoothstep(0.0, LIFT, _lift)
		if _lift >= LIFT:
			# what the Narrator queued meanwhile (an "I'll wait" while it listened) is dropped
			Narrator._queue.clear()
			Narrator._last_tap = GameState.clock
			Narrator.hold = false
			finished.emit(_skipped)
			queue_free()
	elif _t >= FALL + SETTLE:
		_step_t += delta
		if _step < 0 or _step_t >= _step_len:
			_next()
	_ink.queue_redraw()


func _next() -> void:
	_step += 1
	_step_t = 0.0
	if _step >= SCRIPT.size():
		_begin_lift()
		return
	var line: Array = SCRIPT[_step]
	if line[0] == "father":
		GameState.said[line[1]] = true
		Narrator.say_now(line[1])
		var path := VoiceLines.audio_path(line[1])
		var length := FATHER_LINE
		if path != "":
			length = (load(path) as AudioStream).get_length() + 0.8
		_step_len = length + GAP
	else:
		Music.play_celesta(2 + _step % 4)   # a soft note: the light's own small voice
		_step_len = LIGHT_LINE + GAP


func _begin_lift() -> void:
	if _lift >= 0.0:
		return
	_lift = 0.0


## The falling light, then its words beside it.
func _draw_light() -> void:
	var gold := Palette.GOLD
	var fall := clampf(_t / FALL, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - fall, 3.0)   # slowing as it nears the ground
	var start := Vector2(rest.x, -40.0)
	var at := start.lerp(rest, e)
	var fade := 1.0 - smoothstep(0.0, LIFT, maxf(_lift, 0.0))
	# its trail, falling
	if fall < 1.0:
		for i in 12:
			var k := i / 12.0
			var p := start.lerp(rest, maxf(0.0, e - k * 0.12))
			_ink.draw_circle(p, lerpf(6.0, 1.0, k), Color(gold, 0.25 * (1.0 - k)))
	# the light: a glow that breathes, a bright core
	var breath := 0.5 + 0.5 * sin(_t * 1.4)
	for i in 6:
		var k := i / 5.0
		_ink.draw_circle(at, lerpf(90.0, 16.0, k) * (1.0 + 0.08 * breath), Color(gold.lightened(0.15), (0.06 + 0.1 * k) * fade))
	_ink.draw_circle(at, 13.0, Color(gold, 0.5 * fade))
	_ink.draw_circle(at, 9.0, Color(1.0, 0.97, 0.86, fade))
	# landing: a soft ring
	var since := _t - FALL
	if since > 0.0 and since < 2.0:
		var k := since / 2.0
		_ink.draw_arc(at, lerpf(10.0, 120.0, 1.0 - pow(1.0 - k, 3.0)), 0.0, TAU, 64, Color(gold, 0.6 * (1.0 - k)), 2.0, true)
	# the light's words, small, handwritten, just above it; they fade in and out
	if _step >= 0 and _step < SCRIPT.size() and SCRIPT[_step][0] == "light":
		var key: String = SCRIPT[_step][1]
		var text: String = LIGHT[key].get(SaveSystem.lang, LIGHT[key].en)
		var a := smoothstep(0.0, 0.6, _step_t) * (1.0 - smoothstep(LIGHT_LINE - 0.6, LIGHT_LINE, _step_t)) * fade
		var size := 30
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var p := at + Vector2(-w * 0.5, -46.0 - 6.0 * smoothstep(0.0, LIGHT_LINE, _step_t))
		_ink.draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Palette.INK, 0.8 * a))
	# holding down: a thin ring filling, to show it will skip
	if _hold > 0.25 and _lift < 0.0:
		var k := clampf((_hold - 0.25) / (HOLD_SKIP - 0.25), 0.0, 1.0)
		_ink.draw_arc(at, 30.0, -PI * 0.5, -PI * 0.5 + TAU * k, 48, Color(Palette.INK, 0.4), 2.0, true)
