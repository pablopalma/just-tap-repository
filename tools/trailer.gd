extends Node
## The demo trailer (docs/trailer.md), played by the game itself. Record it with Movie Maker:
## Godot_console.exe --path . --write-movie Builds/trailer/trailer.avi --fixed-fps 60 --resolution 1920x1080 res://tools/trailer.tscn
## It never touches the player's save. Subtitles in English; no HUD.

const LENGTH := 60.0

## [time in seconds, method, argument]
const SHOTS := [
	[1.0, "voice", "00"],
	[4.0, "start", 0],
	[4.0, "taps", 4.5],
	[6.0, "voice", "01"],
	[14.0, "taps", 0.0],
	[14.0, "tree_open", 0],
	[18.6, "tree_close", 0],
	[19.2, "jump", 19],
	[19.2, "damage", 70.0],
	[19.2, "taps", 6.0],
	[21.6, "taps", 0.0],
	[22.4, "voice", "06"],
	[28.0, "damage", 140.0],
	[28.0, "taps", 3.5],
	[29.0, "bird", 0],
	[36.0, "jump", 42],
	[36.0, "damage", 300.0],
	[37.0, "voice", "15"],
	[42.0, "taps", 0.0],
	[42.0, "dark", 0],
	[43.0, "voice", "demo_1"],
	[47.4, "light", 0],
	[48.0, "city", 0],
	[50.0, "voice", "made"],
	[55.5, "card", 0],
]

var _main: Node
var _t := 0.0
var _i := 0
var _tap_rate := 0.0
var _tap_acc := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	SaveSystem.voice_on = true
	SaveSystem.had_progress = false
	Narrator.auto = false
	Music.set_enabled(true)
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	while _i < SHOTS.size() and _t >= SHOTS[_i][0]:
		var s: Array = SHOTS[_i]
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


func _voice(id: String) -> void:
	Narrator.say_now(id)


func _start(_arg) -> void:
	_main._start()


func _taps(rate: float) -> void:
	_tap_rate = rate


func _damage(d: float) -> void:
	GameState.dev_damage = d


func _jump(n: int) -> void:
	_main._dev_jump(n)


func _tree_open(_arg) -> void:
	# A few levels so several nodes cascade in, and enough light to make them glow.
	GameState.up = {"fuerza": 5, "ganancia": 3, "pulso": 3, "resonancia": 2}
	GameState.seen = {}
	GameState.light = 5000.0
	_main.tree_panel.open_panel()


func _tree_close(_arg) -> void:
	_main.tree_panel.close_panel()
	GameState.up = {}


func _bird(_arg) -> void:
	_main._summon_bird()
	# Start it partway so it passes closest about four seconds from now.
	_main.bird._t = 0.3 * GiantBird.DURATION - 4.0


func _dark(_arg) -> void:
	_main.darkness.to(0.85, 2.5)
	var p: Vector2 = _main.path.gate_pos(GameState.stage)
	_main.fx.crack(p + Vector2(0, 10), 320.0, 4.0)
	_main.fx.crack(_main.path.gate_pos(GameState.stage - 2), 240.0, 5.0)


func _light(_arg) -> void:
	_main.darkness.to(0.0, 1.2)


func _city(_arg) -> void:
	_main.fx.clear()
	_main._on_dev("grand", 0)


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
