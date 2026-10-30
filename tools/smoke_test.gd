extends Node
## Headless smoke test: loads the main scene, starts the game and plays greedily for a while.
## godot --headless --path . res://tools/smoke_test.tscn
## Note: it overwrites user://save.json.

const FRAMES := 2400

var _frames := 0
var _main: Node
var _broken := 0
var _zones := 0
var _notes := {}  # instrument -> notes played


func _ready() -> void:
	GameState.rebirth()  # start from zero regardless of any save
	GameState.rebirths = 0
	GameState.gate_broken.connect(func(_n: int) -> void: _broken += 1)
	GameState.zone_completed.connect(func(_z: int) -> void: _zones += 1)
	Music.note_played.connect(func(_m: int, inst: String) -> void: _notes[inst] = _notes.get(inst, 0) + 1)
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 5:
		_main._start()
		_main.tree_panel.open_panel()
	if _frames > 5:
		for i in 6:
			GameState.tap("tap")
		for id in Upgrades.ORDER:
			while GameState.buy(id):
				pass
	if _frames == 600:
		_main.tree_panel.close_panel()
	if _frames >= FRAMES or GameState.finished:
		print("SMOKE frames=%d stage=%d broken=%d zones=%d light=%s up=%s music_zone=%d layers=%d playing=%s" % [
			_frames, GameState.stage, _broken, _zones, Fmt.num(GameState.light), str(GameState.up),
			Music.zone, Music.layers, Music.playing])
		print("SMOKE notes=%s" % str(_notes))
		get_tree().quit()
