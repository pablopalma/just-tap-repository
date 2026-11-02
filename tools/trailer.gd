extends Node
## The demo trailer (docs/guion-trailer-teaser.md), played by the game itself and narrated by its
## voice. Record it with tools/make_trailer.ps1. One continuous score: the music is locked to zone
## 10's key and tempo (84 BPM) and the director adds or removes layers; every cut lands on a bar.
## The director's own taps show a ripple where they land (tools/tap_ripple.gd) so a viewer can tell
## them from what happens on its own. The teaser (tools/teaser.gd) is this same director with
## another plan. Never touches the player's save. Subtitles in English.

const BAR := 4.0 * 60.0 / 84.0   # 2.857 s
const MUSIC_ZONE := 10
const CUT_OUT := 0.16
const CUT_IN := 0.32
## The forks shot: the branches' barriers give way slowly, so the braid stays in view.
const FORK_DAMAGE := 300.0
const QUICK_OUT := 0.06
const QUICK_IN := 0.12

var _main: Node
var _t := 0.0
var _i := 0
var _shots: Array = []          # [time, method, argument], sorted by time
var _tap_rate := 0.0
var _tap_acc := 0.0
var _veil: ColorRect
## The whale starts this far into its crossing (0..1) as soon as it appears; -1: leave it alone.
var _whale_from := -1.0
## How long it runs, in bars.
var length_bars := 24.9
## Damage numbers over the barriers (the teaser keeps them: they say "incremental").
var show_numbers := false
var _hud_on := false
var _ripple: Node2D
var _caption_label: Label
## Added to every bar in _at, _cut and _quick: a longer cut (trailer_v2.gd) plays this plan later.
var offset_bars := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	SaveSystem.voice_on = true
	SaveSystem.had_progress = false
	Narrator.auto = false
	# The voice in front: drier, and everything else ducks well under it (the game ducks only 3 dB).
	Narrator.set_reverb(0.06)
	Narrator.duck_db = -9.0
	Narrator.duck_buses = [Music.MUSIC_BUS, Music.DISTANT_BUS, Music.CELESTIAL_BUS,
		Music.BIRD_BODY_BUS, Music.BIRD_VOICE_BUS]
	Music.set_enabled(true)
	GameState.new_game()
	Music.lock(MUSIC_ZONE, 0)
	Music.start()  # the score starts with the first frame, so bars and cuts line up
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	if not show_numbers:
		_main.fx.font = null
	_main.cinematics_enabled = false  # the director decides every shot
	_ripple = Node2D.new()
	_ripple.set_script(load("res://tools/tap_ripple.gd"))
	_ripple.path = _main.path
	_ripple.camera = _main.camera
	_main.add_child(_ripple)
	_build_veil()
	_plan()


## The whole trailer, in bars (docs/guion-trailer-teaser.md): a story about a grey day.
func _plan() -> void:
	# Act 1 · a grey day. The title, the voice; a spark comes down onto the page and becomes the tip;
	# then one long take: every tap lands, the line climbs.
	_at(0, 0.5, "voice", "tr_01")
	_at(1.6, 0.0, "start", 0)  # the spark: it lands about 0.6 bars later
	_at(1.6, 0.0, "hud", true)
	_at(1.6, 0.0, "layers", 1)
	_at(1.6, 0.0, "damage", 4.0)  # two or three barriers fall in the long take
	_at(1.6, 0.0, "numbers", true)
	_at(2.35, 0.0, "tap", 0)
	_at(2.4, 0.0, "voice", "tr_02")
	_at(2.6, 0.0, "taps", 2.6)
	_at(3.5, 0.0, "layers", 2)
	# Act 2 · you learn. The next barrier will not give: small numbers, the line barely moves.
	_at(4.5, 0.0, "damage", 0.2)
	_at(4.85, 0.0, "voice", "05")  # "It's heavy, isn't it? Grow a little. Then try again."
	# "Grow a little": the tree opens bare and the build grows node by node, every one unlocking the next.
	_at(5.9, 0.0, "taps", 0.0)
	_at(5.9, 0.0, "tree_open", {})
	var picks := ["fuerza", "fuerza", "fuerza", "ganancia", "pulso", "fuerza", "fuerza", "ganancia",
		"ganancia", "pulso", "pulso", "resonancia", "resonancia", "corrosion", "eco", "destello",
		"fuerza", "pulso", "eco", "destello"]
	for i in picks.size():
		_at(6.2 + i * 0.1, 0.0, "pick", picks[i])
	# "Then try again": the same barrier gives way at once, the pulse taps on its own (no ripple).
	_at(8.4, 0.0, "tree_close", true)
	_at(8.4, 0.0, "damage", 1.0)
	_at(8.4, 0.0, "taps", 3.0)
	_at(8.4, 0.0, "layers", 3)
	_at(8.2, 0.0, "voice", "tr_06")  # 2.4 bars long: it has to end before the forks
	# the line forks into three, braided, each branch with its own barrier (full game, after the demo)
	_cut(11.1)
	_at(11.1, 0.0, "hud", false)
	_at(11.1, 0.0, "numbers", false)
	_at(11.1, 0.0, "jump", 51)
	_at(11.1, 0.0, "damage", FORK_DAMAGE)
	_at(11.1, 0.0, "layers", 4)
	_at(11.1, 0.1, "taps", 3.0)
	_at(11.2, 0.0, "voice", "13")  # "You can be more than one thing at once."
	# far back: every barrier broken draws a piece of the city, in colour again; the bird passes
	_cut(12.85)
	_at(12.85, 0.0, "jump", 21)
	_at(12.85, 0.0, "damage", 100000.0)
	_at(12.85, 0.05, "pano", 0)
	_at(12.85, 0.1, "taps", 1.4)
	_at(12.95, 0.0, "voice", "14")
	_at(13.35, 0.0, "bird", 1.8)
	# Act 3 · the dark. Barrier 40 breaks: green for a moment, then white on black.
	_cut(14.85)
	_at(14.85, 0.0, "jump", 40)
	_at(14.85, 0.0, "layers", 2)
	_at(14.85, 0.0, "damage", 1000000.0)
	_at(14.85, 0.0, "taps", 0.0)
	_at(14.85, 0.4, "tap", 0)
	_at(14.85, 0.5, "damage", 1.0)
	_at(15.45, 0.0, "voice", "demo_1")
	_at(16.15, 0.0, "veil_ink", 0)
	_at(16.35, 0.0, "taps", 3.0)
	_at(16.85, 0.0, "layers", 1)
	_at(17.05, 0.0, "voice", "tr_04")
	# you keep tapping: 41–44 give way one by one
	_at(17.45, 0.0, "brk", 0)
	_at(17.75, 0.0, "brk", 0)
	_at(18.05, 0.0, "brk", 0)
	_at(18.35, 0.0, "brk", 0)
	# Act 4 · the last one: the chaos finds its order, the cracks fill with gold
	_at(18.65, 0.0, "taps", 0.0)
	_at(18.65, 0.0, "brk", 0)
	_at(18.65, 0.0, "layers", 3)
	_at(18.65, 0.0, "whale_at", 0.16)
	_at(19.4, 0.0, "voice", "tr_05")
	# something awakens
	_at(20.4, 0.0, "layers", 5)
	_at(21.9, 0.0, "voice", "demo_2")
	# the card
	_at(22.9, 0.0, "card", 0)
	_at(23.3, 0.0, "voice", "00")
	_shots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])

func _at(bar: float, offset: float, method: String, arg) -> void:
	_shots.append([(bar + offset_bars) * BAR + offset, method, arg])


## A cut on the bar: dip to paper just before it, come back just after.
func _cut(bar: float) -> void:
	bar += offset_bars
	_shots.append([bar * BAR - CUT_OUT, "fade", [1.0, CUT_OUT]])
	_shots.append([bar * BAR + 0.02, "fade", [0.0, CUT_IN]])


## A montage cut: a blink.
func _quick(bar: float) -> void:
	bar += offset_bars
	_shots.append([bar * BAR - QUICK_OUT, "fade", [1.0, QUICK_OUT]])
	_shots.append([bar * BAR + 0.02, "fade", [0.0, QUICK_IN]])


func _process(delta: float) -> void:
	_t += delta
	while _i < _shots.size() and _t >= _shots[_i][0]:
		var s: Array = _shots[_i]
		_i += 1
		call("_" + String(s[1]), s[2])
	_main.hud.visible = _hud_on
	if _main.intro != null:
		_main.intro._lang.visible = false
	if _whale_from >= 0.0 and _main.whale.active:
		# Skip the slow start of its crossing: it appears already a little way in.
		_main.whale._t = maxf(_main.whale._t, _whale_from * CelestialWhale.DURATION)
		_whale_from = -1.0
	if _tap_rate > 0.0 and GameState.running and not GameState.finished:
		_tap_acc += _tap_rate * delta
		while _tap_acc >= 1.0:
			_tap_acc -= 1.0
			_tap(0)
	if _t >= length_bars * BAR:
		get_tree().quit()


# --- Actions --------------------------------------------------------------------

func _voice(id: String) -> void:
	Narrator.say_now(id)


func _start(_arg) -> void:
	_main._start()


## One tap of the player's, with its ripple.
func _tap(_arg) -> void:
	if GameState.running and not GameState.finished:
		GameState.tap("tap")
		_ripple.tap()


func _hud(on: bool) -> void:
	_hud_on = on
	if on:
		_main.hud.modulate.a = 1.0


## Two or three words on screen, for viewers with the sound off: [text, seconds].
func _caption(a: Array) -> void:
	_caption_label.text = a[0]
	var tw := create_tween()
	tw.tween_property(_caption_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(maxf(0.1, float(a[1]) - 0.7))
	tw.tween_property(_caption_label, "modulate:a", 0.0, 0.4)


func _buy(id: String) -> void:
	GameState.buy(id)


## A buy from inside the open tree, as a player would: the node pops and its line says what it does.
func _pick(id: String) -> void:
	if not GameState.can_buy(id):
		push_warning("trailer: cannot buy %s" % id)
	_main.tree_panel._buy(id)


## The damage numbers over the barriers.
func _numbers(on: bool) -> void:
	_main.fx.font = UIStyle.italic() if on else null


func _quake(_arg) -> void:
	_main.crumble.quake(1.0)


func _whale(_arg) -> void:
	_main.whale.swim()


func _taps(rate: float) -> void:
	_tap_rate = rate


func _damage(d: float) -> void:
	GameState.dev_damage = d


func _layers(n: int) -> void:
	Music.layers = n


func _jump(n: int) -> void:
	_main._dev_jump(n)


## Breaks the current barrier at once (as one of the player's taps).
func _brk(_arg) -> void:
	_ripple.tap()
	_main._dev_break()


func _whale_at(p: float) -> void:
	_whale_from = p


func _fade(a: Array) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", a[0], a[1]).set_trans(Tween.TRANS_SINE)


## From here on the cuts dip to ink instead of paper (the dark).
func _veil_ink(_arg) -> void:
	_veil.color = Color(Palette.INK.darkened(0.6), _veil.color.a)


## up: the levels to show (several nodes cascade in), with enough light to make them glow.
func _tree_open(up: Dictionary) -> void:
	GameState.up = up.duplicate()
	GameState.seen = {}
	# Bare (the trailer buys it node by node), it gets light for the whole build.
	GameState.light = maxf(GameState.light, 4000.0 if up.is_empty() else 5000.0)
	_main.tree_panel.open_panel()


## keep: the levels stay (the pulse goes on tapping by itself).
func _tree_close(keep: bool) -> void:
	_main.tree_panel.visible = false
	if not keep:
		GameState.up = {}


## The camera pulls far back over the landscape (the game's panorama, longer than a shot).
func _pano(_arg) -> void:
	_main._pano = 10.0
	# Hidden by the cut: start already halfway back, then keep pulling away.
	var cam = _main.camera
	cam.target_pos = Vector2(0.0, _main.tip.position.y + 700.0)
	cam.target_zoom = _main._base_zoom() * 0.3
	cam.snap()


## lead: seconds until it passes closest.
func _bird(lead: float) -> void:
	_main._summon_bird()
	_main.bird._t = 0.3 * GiantBird.DURATION - lead


func _build_veil() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	_veil = ColorRect.new()
	_veil.color = Color(Palette.PAPER, 0.0)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_veil)
	_caption_label = UIStyle.label("", 46, true, Palette.INK)
	_caption_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_caption_label.offset_top = 70
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.add_theme_constant_override("outline_size", 12)
	_caption_label.add_theme_color_override("font_outline_color", Color(Palette.PAPER, 0.9))
	_caption_label.modulate.a = 0.0
	var cl := CanvasLayer.new()
	cl.layer = 24
	add_child(cl)
	cl.add_child(_caption_label)


## Closing card: paper, the title and where to play.
func _card(_arg) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIStyle.theme()
	root.modulate.a = 0.0
	layer.add_child(root)
	var bg := ColorRect.new()
	bg.color = Palette.PAPER
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(box)
	var title := UIStyle.label("just tap", 96)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tag := UIStyle.label("if you had a bad day…", 28, true, Color(Palette.INK, 0.75))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 50)
	box.add_child(gap)
	var where := UIStyle.label("free demo  ·  itch.io", 24, false, Palette.chapter_color(1).darkened(0.1))
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(where)
	create_tween().tween_property(root, "modulate:a", 1.0, 1.4)
