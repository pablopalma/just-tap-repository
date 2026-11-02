extends "res://tools/trailer.gd"
## Trailer v2: trailer.gd's story between two new scenes of its own (tools/astral_intro.gd).
## · Opening: an astral journey through a wormhole; a flash, the paper, and the spark comes down.
## · The story, as in v1, up to "But you're not alone in this."
## · No voice: in colour again, the tip breaks barrier after barrier, faster and faster, each one a
##   note higher, until the zone gives way.
## · Everything fades to white; close up, the tip draws a line with a note on every half beat,
##   louder and higher… the camera pulls back: it has written "just tap", and the voice says it.
## Record it with tools/make_trailer_v2.ps1; trailer v1 is untouched.

const INTRO_BARS := 1.6
## The run without voice: from barrier RUN_FROM, one break per rise, closer and closer together.
const RUN_CUT := 24.8
const RUN_FROM := 21  # zone 3, in colour: no star until 27, no zone end on the way
const RUN_GAPS := [0.5, 0.42, 0.35, 0.3, 0.26, 0.22]
const WHITE_AFTER := 0.8   # bars from the last break to the fade to white

const Astral := preload("res://tools/astral_intro.gd")

var _astral: Node2D


func _ready() -> void:
	super._ready()
	var layer := CanvasLayer.new()
	layer.layer = 5  # over the world, under the subtitles
	add_child(layer)
	_astral = Node2D.new()
	_astral.set_script(Astral)
	layer.add_child(_astral)
	_astral.written.connect(_on_written)
	# The score waits under the wormhole's own sound.
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(Music.MUSIC_BUS), -40.0)
	_astral.play_tunnel()


func _plan() -> void:
	_at(INTRO_BARS, 0.0, "music_in", 2.5)  # with the paper
	# v1's story, later, without its card and its last line (they come drawn, at the very end)
	offset_bars = INTRO_BARS
	super._plan()
	offset_bars = 0.0
	_shots = _shots.filter(func(s: Array) -> bool:
		return s[1] != "card" and not (s[1] == "voice" and s[2] == "00"))
	# No voice: back in colour, the tip runs, each barrier a note higher.
	_at(RUN_CUT - 0.3, 0.0, "veil_paper", 0)
	_cut(RUN_CUT)
	_at(RUN_CUT, 0.0, "jump", RUN_FROM)
	_at(RUN_CUT, 0.0, "hud", false)
	_at(RUN_CUT, 0.0, "numbers", false)
	_at(RUN_CUT, 0.0, "damage", 1.0)
	_at(RUN_CUT, 0.0, "taps", 0.0)
	_at(RUN_CUT, 0.0, "layers", 3)
	var bar := RUN_CUT
	for i in RUN_GAPS.size():
		bar += RUN_GAPS[i]
		_at(bar, 0.0, "rise", i)
		if i == 2:
			_at(bar, 0.0, "layers", 4)
		if i == 4:
			_at(bar, 0.0, "layers", 5)
	# Everything goes white; the tip writes.
	var white := bar + WHITE_AFTER
	_at(white, 0.0, "white_out", 0.7)
	_at(white + 0.3, 0.0, "words", 0)
	_at(white + 0.3, 0.0, "layers", 2)
	_at(white + 0.3, 0.05, "fade", [0.0, 0.25])
	_at(white + 1.0, 0.0, "layers", 3)
	_at(white + 1.7, 0.0, "layers", 4)
	length_bars = white + 0.3 + 12.4 / BAR
	_shots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _process(delta: float) -> void:
	super._process(delta)
	if _main.intro != null:
		_main.intro.visible = false  # no title at the start: the tip writes it at the end


func _music_in(time: float) -> void:
	var bus := AudioServer.get_bus_index(Music.MUSIC_BUS)
	create_tween().tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
		AudioServer.get_bus_volume_db(bus), 0.0, time)


func _veil_paper(_arg) -> void:
	_veil.color = Color(Palette.PAPER, _veil.color.a)


## One break of the run, and its note: the i-th of a climbing line, louder each time.
func _rise(i: int) -> void:
	_brk(0)
	var k := float(i) / (RUN_GAPS.size() - 1)
	Music.rising_note(i * 2 + 1, lerpf(0.03, 0.065, k))
	Music.rising_note(i * 2 + 3, lerpf(0.02, 0.045, k))  # a third above


func _white_out(time: float) -> void:
	_veil.color = Color(Astral.WHITE, _veil.color.a)
	create_tween().tween_property(_veil, "color:a", 1.0, time).set_trans(Tween.TRANS_SINE)


func _words(_arg) -> void:
	_tap_rate = 0.0
	_astral.play_words()


## The last stroke ends: the voice says it, and the music opens into its major chord.
func _on_written() -> void:
	Narrator.say_now("00")
	Music.layers = 5
	Music.resolve_chord()
