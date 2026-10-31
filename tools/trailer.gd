extends Node
## The demo trailer (docs/trailer.md), played by the game itself. Record it with tools/make_trailer.ps1.
## One continuous score: the music is locked to zone 10's key and tempo (84 BPM) and the director
## adds or removes layers; every cut lands on a bar, through a quick dip to paper. Never touches the
## player's save. Subtitles in English; no HUD, no damage numbers.

const LENGTH := 24.0 * 4.0 * 60.0 / 84.0  # 24 bars, 68.6 s
const MUSIC_ZONE := 10
const BAR := 4.0 * 60.0 / 84.0   # 2.857 s
const CUT_OUT := 0.16
const CUT_IN := 0.32

var _main: Node
var _t := 0.0
var _i := 0
var _shots: Array = []          # [time, method, argument], sorted by time
var _tap_rate := 0.0
var _tap_acc := 0.0
var _veil: ColorRect


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
	# 5–8 · the colour comes back
	_cut(5)
	_at(5, 0.0, "tree_close", 0)
	_at(5, 0.0, "jump", 19)
	_at(5, 0.0, "damage", 70.0)
	_at(5, 0.0, "taps", 6.0)
	_at(5, 0.0, "layers", 3)
	_at(5, 2.4, "taps", 0.0)
	_at(6, 0.4, "voice", "06")
	# 8–10 · far back: the city building itself, piece after piece, with sparks rising
	_cut(8)
	_at(8, 0.0, "jump", 21)
	_at(8, 0.0, "damage", 100000.0)
	_at(8, 0.0, "layers", 3)
	_at(8, 0.05, "pano", 0)  # after the jump, which ends any panorama
	_at(8, 0.3, "taps", 1.3)
	_at(9, 2.0, "taps", 0.0)
	# 10–17 · montage, one or two bars each
	_cut(10)
	_at(10, 0.0, "jump", 16)
	_at(10, 0.0, "damage", 22.0)
	_at(10, 0.0, "taps", 5.0)
	_at(10, 0.0, "layers", 4)
	_at(10, 0.5, "voice", "small_lights")
	_cut(11)
	_at(11, 0.0, "jump", 27)
	_at(11, 0.0, "damage", 260.0)
	_at(11, 0.0, "taps", 6.0)
	_at(11, 2.2, "taps", 0.0)  # the star is complete: let it spin up and burst on its own
	_at(12, 0.6, "voice", "whole")
	# the bird passes close: fewer layers so its wings, cry and rush are heard
	_cut(13)
	_at(13, 0.0, "jump", 31)
	_at(13, 0.0, "damage", 120.0)
	_at(13, 0.0, "taps", 2.0)
	_at(13, 0.0, "layers", 2)
	_at(13, 0.05, "bird", 0)  # after the jump, which grounds the bird
	_cut(15)
	_at(15, 0.0, "jump", 41)
	_at(15, 0.0, "damage", 300.0)
	_at(15, 0.0, "taps", 4.0)
	_at(15, 0.0, "layers", 5)
	_at(15, 0.3, "voice", "13")
	_cut(16)
	_at(16, 0.0, "jump", 51)
	_at(16, 0.0, "damage", 1000.0)
	# 17–19 · the dark
	_cut(17)
	_at(17, 0.0, "jump", 39)
	_at(17, 0.0, "taps", 0.0)
	_at(17, 0.0, "layers", 1)
	_at(17, 0.2, "dark", 0)
	_at(17, 1.0, "voice", "demo_1")
	# 19–22 · the city
	_at(18, 2.4, "light", 0)
	_cut(19)
	_at(19, 0.0, "city", 0)
	_at(19, 0.0, "layers", 5)
	_at(19, 1.8, "voice", "made")
	# 22–24 · the card
	_at(22, 0.0, "card", 0)
	_shots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _at(bar: float, offset: float, method: String, arg) -> void:
	_shots.append([bar * BAR + offset, method, arg])


## A cut on the bar: dip to paper just before it, come back just after.
func _cut(bar: float) -> void:
	_shots.append([bar * BAR - CUT_OUT, "fade", 1.0])
	_shots.append([bar * BAR + 0.02, "fade", 0.0])


func _process(delta: float) -> void:
	_t += delta
	while _i < _shots.size() and _t >= _shots[_i][0]:
		var s: Array = _shots[_i]
		_i += 1
		call("_" + String(s[1]), s[2])
	_main.hud.modulate.a = 0.0
	if _main.intro != null:
		_main.intro._lang.visible = false
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


func _fade(to: float) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", to, CUT_OUT if to > 0.5 else CUT_IN).set_trans(Tween.TRANS_SINE)


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


func _bird(_arg) -> void:
	_main._summon_bird()
	# Start it partway: it comes in beating its wings and passes closest early in the shot.
	_main.bird._t = 0.3 * GiantBird.DURATION - 2.4


func _dark(_arg) -> void:
	_main.darkness.to(0.85, 2.0)
	var p: Vector2 = _main.path.gate_pos(GameState.stage)
	_main.fx.crack(p + Vector2(0, 10), 320.0, 3.0)
	_main.fx.crack(_main.path.gate_pos(GameState.stage - 2), 240.0, 4.0)


func _light(_arg) -> void:
	_main.darkness.to(0.0, 0.5)


func _city(_arg) -> void:
	_main.fx.clear()
	_main._on_dev("grand", 0)


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
