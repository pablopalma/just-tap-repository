extends "res://tools/trailer.gd"
## Trailer v2: trailer.gd's story with a close of its own (tools/trailer_words.gd).
## · Opening: black, and the voice; the page fades in and the spark comes down.
## · The story, as in v1, up to "But you're not alone in this."
## · No voice: in colour again, the tip breaks barrier after barrier, faster and faster, each one a
##   note higher, until the zone gives way.
## · Everything fades to white; close up, the tip draws a line with a note on every half beat,
##   louder and higher… the camera pulls back: it has written "just tap", and the voice says it.
## · The camera falls into the dot: it is the tap on the raised finger of the girl on the cover. It
##   pulls back over the whole illustration, under the title theme; the title settles on the left.
## Record it with tools/make_trailer_v2.ps1; trailer v1 is untouched.

const INTRO_BARS := 0.6   # the black before the story
const FROM_BLACK := 2.6   # seconds the page takes to come out of the black
## The run without voice (just after "But you're not alone in this."): from barrier RUN_FROM, one break
## per rise, closer and closer together.
const RUN_CUT := INTRO_BARS + 23.2
const RUN_FROM := 21  # zone 3, in colour: no star until 27, no zone end on the way
const RUN_GAPS := [0.5, 0.42, 0.35, 0.3, 0.26, 0.22]
## Where the title theme comes in at the end (seconds into title_theme.ogg): its warm, full part.
const THEME_FROM := 84.0
const WHITE_AFTER := 0.8   # bars from the last break to the fade to white

const Words := preload("res://tools/trailer_words.gd")

var _words_view: Node2D


func _ready() -> void:
	super._ready()
	var layer := CanvasLayer.new()
	layer.layer = 5  # over the world, under the subtitles
	add_child(layer)
	_words_view = Node2D.new()
	_words_view.set_script(Words)
	layer.add_child(_words_view)
	_words_view.written.connect(_on_written)
	_words_view.revealing.connect(_on_revealing)
	# It opens in black; the voice starts in it and the page comes out of it.
	_veil.color = Color(0.0, 0.0, 0.0, 1.0)


func _plan() -> void:
	_at(0.0, 0.5, "fade", [0.0, FROM_BLACK])
	_at(0.0, 0.6 + FROM_BLACK, "veil_paper", 0)  # once it is clear: the story's cuts dip to paper
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
	length_bars = white + 0.3 + 20.0 / BAR
	_shots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _process(delta: float) -> void:
	super._process(delta)
	if _main.intro != null:
		_main.intro.visible = false  # no title at the start: the tip writes it at the end


func _veil_paper(_arg) -> void:
	_veil.color = Color(Palette.PAPER, _veil.color.a)


## One break of the run, and its note: the i-th of a climbing line, louder each time.
func _rise(i: int) -> void:
	_brk(0)
	var k := float(i) / (RUN_GAPS.size() - 1)
	Music.rising_note(i * 2 + 1, lerpf(0.03, 0.065, k))
	Music.rising_note(i * 2 + 3, lerpf(0.02, 0.045, k))  # a third above


func _white_out(time: float) -> void:
	_veil.color = Color(Words.WHITE, _veil.color.a)
	create_tween().tween_property(_veil, "color:a", 1.0, time).set_trans(Tween.TRANS_SINE)


func _words(_arg) -> void:
	_tap_rate = 0.0
	_words_view.play()


## The last stroke ends: the voice says it, and the music opens into its major chord.
func _on_written() -> void:
	Narrator.say_now("00")
	Music.layers = 5
	Music.resolve_chord()


## The cover appears: the game's music fades and the title theme comes in, already in its full part.
func _on_revealing() -> void:
	var bus := AudioServer.get_bus_index(Music.MUSIC_BUS)
	create_tween().tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
		AudioServer.get_bus_volume_db(bus), -40.0, 2.5)
	Music.play_theme()
	if Music._title != null:
		Music._title.seek(THEME_FROM)