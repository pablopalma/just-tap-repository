extends Node
## The demo trailer (docs/trailer.md), played by the game itself. Record it with tools/make_trailer.ps1.
## One continuous score: the music is locked to zone 10's key and tempo (84 BPM) and the director
## adds or removes layers; every cut lands on a bar. It opens calm (cuts through a dip to paper),
## speeds up into a montage of one bar or half a bar per shot (quick cuts), breaks into glimpses of
## the dark, and ends on the whale, barely seen. Never touches the player's save. Subtitles in
## English; no HUD, no damage numbers.

const BAR := 4.0 * 60.0 / 84.0   # 2.857 s
const LENGTH := 20.0 * BAR       # 57.1 s
const MUSIC_ZONE := 10
const CUT_OUT := 0.16
const CUT_IN := 0.32
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


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	SaveSystem.voice_on = true
	SaveSystem.had_progress = false
	Narrator.auto = false
	Music.set_enabled(true)
	GameState.new_game()
	Music.lock(MUSIC_ZONE, 0)
	Music.start()  # the score starts with the first frame, so bars and cuts line up
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_main.fx.font = null
	_main.cinematics_enabled = false  # the director decides every shot
	_build_veil()
	_plan()


## The whole trailer, in bars.
func _plan() -> void:
	# 0–2 · "just tap" on paper
	_at(0.0, 0.6, "voice", "00")
	# 2–4 · first taps, the line climbs, the arch draws itself
	_cut(2)
	_at(2, 0.0, "start", 0)
	_at(2, 0.0, "layers", 1)
	_at(2, 0.0, "taps", 4.5)
	_at(2, 1.0, "voice", "01")
	# 4 · the tree opens
	_cut(4)
	_at(4, 0.0, "taps", 0.0)
	_at(4, 0.0, "tree_open", 0)
	_at(4, 0.0, "layers", 2)
	# 5–7 · the colour comes back
	_cut(5)
	_at(5, 0.0, "tree_close", 0)
	_at(5, 0.0, "jump", 19)
	_at(5, 0.0, "damage", 70.0)
	_at(5, 0.0, "taps", 6.0)
	_at(5, 0.0, "layers", 3)
	_at(5, 2.4, "taps", 0.0)
	_at(5, 0.8, "voice", "06")
	# 7–11 · the montage: everything speeds up, one bar or half a bar per shot
	# far back, the city building itself
	_quick(7)
	_at(7, 0.0, "jump", 21)
	_at(7, 0.0, "damage", 100000.0)
	_at(7, 0.0, "layers", 5)
	_at(7, 0.05, "pano", 0)
	_at(7, 0.1, "taps", 2.5)
	# a star circuit, spinning up
	_quick(8)
	_at(8, 0.0, "jump", 27)
	_at(8, 0.0, "damage", 400.0)
	_at(8, 0.0, "taps", 7.0)
	# the bird, close
	_quick(9)
	_at(9, 0.0, "jump", 31)
	_at(9, 0.0, "damage", 120.0)
	_at(9, 0.0, "taps", 3.0)
	_at(9, 0.05, "bird", 1.1)
	# the line splits in three
	_quick(10)
	_at(10, 0.0, "jump", 51)
	_at(10, 0.0, "damage", 1000.0)
	_at(10, 0.0, "taps", 5.0)
	# the tree again, half a bar
	_quick(10.5)
	_at(10.5, 0.0, "jump", 33)
	_at(10.5, 0.0, "taps", 0.0)
	_at(10.5, 0.0, "tree_open", 0)
	# 11–14 · the dark: white on black, chaos behind, the tower crumbling under each tap
	_at(11, -CUT_OUT - 0.02, "veil_ink", 0)
	_cut(11)
	_at(11, 0.0, "tree_close", 0)
	_at(11, 0.0, "jump", 42)
	_at(11, 0.0, "damage", 1.0)
	_at(11, 0.0, "taps", 5.0)
	_at(11, 0.0, "layers", 1)
	_at(11, 0.5, "voice", "demo_1")
	_at(12.5, 0.0, "taps", 8.0)
	# barriers break on the beat: each one cracks the line and shakes the world (42, 43, 44)
	_at(13, 0.0, "brk", 0)
	_at(13.5, 0.0, "brk", 0)
	_at(14, 0.0, "brk", 0)
	# 14.5–16 · the last one (45): the chaos finds its order, a golden mandala, gold in the seams
	_at(14.5, 0.0, "layers", 3)
	_at(14.5, 0.0, "taps", 0.0)
	_at(14.5, 0.0, "brk", 0)
	_at(14.5, 0.0, "whale_at", 0.16)
	# 16–18 · something awakens: the whale, barely seen
	_at(16, 0.0, "layers", 5)
	_at(17, 0.0, "voice", "demo_2")  # as the whale appears (the game's own line is off: Narrator.auto)
	# 18–20 · the card
	_at(18, 0.0, "card", 0)
	_shots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _at(bar: float, offset: float, method: String, arg) -> void:
	_shots.append([bar * BAR + offset, method, arg])


## A cut on the bar: dip to paper just before it, come back just after.
func _cut(bar: float) -> void:
	_shots.append([bar * BAR - CUT_OUT, "fade", [1.0, CUT_OUT]])
	_shots.append([bar * BAR + 0.02, "fade", [0.0, CUT_IN]])


## A montage cut: a blink.
func _quick(bar: float) -> void:
	_shots.append([bar * BAR - QUICK_OUT, "fade", [1.0, QUICK_OUT]])
	_shots.append([bar * BAR + 0.02, "fade", [0.0, QUICK_IN]])


func _process(delta: float) -> void:
	_t += delta
	while _i < _shots.size() and _t >= _shots[_i][0]:
		var s: Array = _shots[_i]
		_i += 1
		call("_" + String(s[1]), s[2])
	_main.hud.visible = false
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
			GameState.tap("tap")
	if _t >= LENGTH:
		get_tree().quit()


# --- Actions --------------------------------------------------------------------

func _voice(id: String) -> void:
	Narrator.say_now(id)


func _start(_arg) -> void:
	_main._start()


func _taps(rate: float) -> void:
	_tap_rate = rate


func _damage(d: float) -> void:
	GameState.dev_damage = d


func _layers(n: int) -> void:
	Music.layers = n


func _jump(n: int) -> void:
	_main._dev_jump(n)


## Breaks the current barrier at once.
func _brk(_arg) -> void:
	_main._dev_break()


func _whale_at(p: float) -> void:
	_whale_from = p


func _fade(a: Array) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", a[0], a[1]).set_trans(Tween.TRANS_SINE)


## From here on the cuts dip to ink instead of paper (the dark).
func _veil_ink(_arg) -> void:
	_veil.color = Color(Palette.INK.darkened(0.6), _veil.color.a)


func _tree_open(_arg) -> void:
	# A few levels so several nodes cascade in, and enough light to make them glow.
	GameState.up = {"fuerza": 5, "ganancia": 3, "pulso": 3, "resonancia": 2}
	GameState.seen = {}
	GameState.light = 5000.0
	_main.tree_panel.open_panel()


func _tree_close(_arg) -> void:
	_main.tree_panel.visible = false
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
