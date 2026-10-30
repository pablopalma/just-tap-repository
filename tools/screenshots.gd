extends Node
## Plays a scripted session in a real window and saves screenshots to user://shots/.
## godot --path . res://tools/screenshots.tscn
## Note: it overwrites user://save.json.

const SHOTS := {30: "01_intro", 260: "02_play", 520: "03_zone_event", 860: "04_tree", 1000: "05_later"}

var _frames := 0
var _main: Node


func _ready() -> void:
	GameState.rebirth()
	GameState.rebirths = 0
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	DirAccess.make_dir_recursive_absolute("user://shots")


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 60:
		_main._start()
	if _frames > 140 and _frames < 700 and _frames % 4 == 0:
		GameState.tap("tap")
		if GameState.stage < 10:
			GameState.tap("tap")
		for id in Upgrades.ORDER:
			GameState.buy(id)
	if _frames == 700:
		_main.tree_panel.open_panel()
	if _frames == 900:
		_main.tree_panel.close_panel()
	if _frames > 900 and _frames % 3 == 0:
		GameState.tap("tap")
		for id in Upgrades.ORDER:
			GameState.buy(id)
	if SHOTS.has(_frames):
		var img := get_viewport().get_texture().get_image()
		var path := "user://shots/%s.png" % SHOTS[_frames]
		img.save_png(path)
		print("SHOT ", ProjectSettings.globalize_path(path), " stage=", GameState.stage)
	if _frames > 1010:
		get_tree().quit()
