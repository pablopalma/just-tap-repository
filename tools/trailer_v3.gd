extends "res://tools/trailer.gd"
## Trailer v3: the game as it is now, told by the voice from start to end.
## · Black, the voice; the page comes out of it and the spark comes down. Tap, the line climbs, and
##   the tree's branches sprout from it while the tip keeps tapping.
## · The dive: the camera falls into the dot and comes out in zone 2, running sideways.
## · The story: the memory drawing itself, "…the sun slipping through them, in little pieces".
## · The spiral, the tip growing towards its centre; the camera pulls back over all of it.
## · The starry night: the barriers light as stars.
## · The dark: the whale peeking in, its stars lighting; it wakes.
## · White; the tip writes "just tap"; the cover, under the title theme (tools/trailer_words.gd).
## Record it with tools/make_trailer_v3.ps1; v1 and v2 are untouched.

const Words := preload("res://tools/trailer_words.gd")
const FROM_BLACK := 2.6
## Where the title theme comes in at the end (seconds into title_theme.ogg): its warm, full part.
const THEME_FROM := 84.0
const PICKS := ["fuerza", "fuerza", "fuerza", "ganancia", "pulso", "fuerza", "fuerza", "resonancia",
	"ganancia", "ganancia", "pulso", "pulso", "eco", "resonancia", "destello"]

var _words_view: Node2D
var _story_node: Control
var _dive_to := 0
## "-- --novoice": the same cut without the narrator (and its subtitles), except in the story, for
## montages over the title theme.
var no_voice := "--novoice" in OS.get_cmdline_user_args()


func _voice(id: String) -> void:
	if not no_voice:
		super._voice(id)


func _ready() -> void:
	super._ready()
	_main.turn_zones = true  # this cut shows each zone its own way, the night, the dives
	var layer := CanvasLayer.new()
	layer.layer = 5  # over the world, under the subtitles
	add_child(layer)
	_words_view = Node2D.new()
	_words_view.set_script(Words)
	layer.add_child(_words_view)
	_words_view.written.connect(_on_written)
	_words_view.revealing.connect(_on_revealing)
	_main.droste.turned.connect(_on_dive_turned)
	_veil.color = Color(0.0, 0.0, 0.0, 1.0)  # it opens in black


func _plan() -> void:
	# Open: black, the voice; the page; the spark.
	_at(0.0, 0.5, "fade", [0.0, FROM_BLACK])
	_at(0.0, 0.5, "voice", "tr_01")
	_at(0.0, 0.6 + FROM_BLACK, "veil_paper", 0)
	_at(1.6, 0.0, "start", 0)
	_at(1.6, 0.0, "hud", true)
	_at(1.6, 0.0, "layers", 1)
	_at(1.6, 0.0, "damage", 4.0)
	_at(1.6, 0.0, "numbers", true)
	_at(2.35, 0.0, "tap", 0)
	_at(2.4, 0.0, "voice", "tr_02")
	_at(2.6, 0.0, "taps", 2.6)
	_at(3.4, 0.0, "layers", 2)
	# "Grow a little": the branches sprout from the line, node by node, while the tip keeps tapping.
	_at(4.3, 0.0, "damage", 0.25)
	_at(4.4, 0.0, "voice", "05")
	_at(5.4, 0.0, "tree_open", {})
	_at(5.4, 0.0, "taps", 1.6)
	for i in PICKS.size():
		_at(5.6 + i * 0.11, 0.0, "pick", PICKS[i])
	_at(7.2, 0.0, "voice", "tr_06")
	_at(7.3, 0.0, "damage", 1.0)
	_at(7.3, 0.0, "taps", 3.0)
	_at(7.3, 0.0, "layers", 3)
	# The dive: into the dot, out in zone 2, running sideways.
	_at(9.7, 0.0, "hud", false)
	_at(9.7, 0.0, "numbers", false)
	_at(9.7, 0.0, "dive", 1)
	_at(10.9, 0.0, "taps", 3.0)
	_at(10.9, 0.0, "damage", 4.0)
	# The story: the memory drawing itself.
	_cut(12.6)
	_at(12.6, 0.0, "taps", 0.0)
	_at(12.6, 0.0, "story", 0)
	# The spiral, the tip growing; the camera pulls back over all of it.
	_cut(16.1)
	_at(16.1, 0.0, "story_off", 0)
	_at(16.1, 0.0, "jump", 23)
	_at(16.1, 0.0, "layers", 4)
	_at(16.1, 0.0, "damage", 40.0)
	_at(16.1, 0.1, "taps", 3.0)
	_at(16.3, 0.0, "voice", "15")
	_at(17.7, 0.0, "pano", 0)
	# The starry night: the barriers light as stars.
	_cut(19.2)
	_at(19.2, 0.0, "jump", 31)
	_at(19.2, 0.0, "taps", 0.0)
	_at(19.2, 0.0, "damage", 1.0)
	_at(19.2, 0.0, "layers", 3)
	_at(19.35, 0.0, "voice", "small_lights")
	for i in 6:
		_at(19.6 + i * 0.35, 0.0, "brk", 0)
	# The dark: the whale peeking in, its stars lighting; it wakes.
	_at(21.75, 0.0, "veil_ink", 0)
	_cut(22.0)
	_at(22.0, 0.0, "jump", 43)
	_at(22.0, 0.0, "layers", 2)
	_at(22.2, 0.0, "voice", "now_2")
	_at(23.6, 0.0, "brk", 0)
	_at(24.2, 0.0, "brk", 0)
	_at(24.8, 0.0, "brk", 0)
	_at(24.9, 0.0, "voice", "now_4")
	_at(26.0, 0.0, "layers", 5)
	_at(27.6, 0.0, "voice", "demo_2")
	# White; the tip writes "just tap"; the cover.
	var white := 29.4
	_at(white, 0.0, "white_out", 0.7)
	_at(white + 0.28, 0.0, "whale_off", 0)  # it swims over everything: gone while the page is all white
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


## Falls into the tip; on the far side of the dot, it is the start of zone z + 1.
func _dive(z: int) -> void:
	_dive_to = z * 10 + 1
	_main._begin_droste(z)


func _on_dive_turned() -> void:
	if _dive_to > 0:
		_main._dev_jump(_dive_to)
		_dive_to = 0


## Just the memory's second line, the tree already drawing, the sun coming through.
func _story(_arg) -> void:
	_story_node = load("res://scripts/ui/story.gd").new()
	_story_node.lines = ["story1_2"]
	var parent: Node = _main.subtitle.get_parent()
	parent.add_child(_story_node)
	parent.move_child(_story_node, _main.subtitle.get_index())
	_story_node._tell()
	_story_node._no.visible = false  # no buttons in a trailer
	_story_node._t = 4.6
	_story_node._next = 5.0


func _story_off(_arg) -> void:
	Music.stop_theme()
	if is_instance_valid(_story_node):
		_story_node.queue_free()


## Under the white page: the whale, the dark (its negative) and the cinema bars all go, so the
## words and the cover come out on paper.
func _whale_off(_arg) -> void:
	_main._clear_dark()
	_main.cinema.amount = 0.0


func _white_out(time: float) -> void:
	_veil.color = Color(Words.WHITE, _veil.color.a)
	create_tween().tween_property(_veil, "color:a", 1.0, time).set_trans(Tween.TRANS_SINE)


func _words(_arg) -> void:
	_tap_rate = 0.0
	_words_view.play()


## The last stroke ends: the voice says it, and the music opens into its major chord.
func _on_written() -> void:
	if not no_voice:
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
