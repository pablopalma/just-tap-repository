extends Node
## Checks the intro choices and the English UI: needs a save with progress.
## godot --path . res://tools/intro_test.tscn

var _frames := 0
var _main: Node


func _ready() -> void:
	GameState.new_game()
	GameState.stage = 23
	GameState.light = 500.0
	GameState.up = {"fuerza": 6, "ganancia": 3}
	SaveSystem.had_progress = true
	SaveSystem.lang = "en"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 330:
		_shot("10_intro_en")
		_main.intro._on_new()
	if _frames == 340:
		_shot("11_confirm_en")
		_main.intro._on_new()
	if _frames == 360:
		print("INTRO stage=%d light=%s up=%s said=%s" % [GameState.stage, GameState.light, GameState.up, GameState.said])
	if _frames == 520:
		_main.tree_panel.open_panel()
	if _frames == 640:
		_shot("12_hud_tree_en")
		get_tree().quit()


func _shot(name: String) -> void:
	var path := "user://shots/%s.png" % name
	DirAccess.make_dir_recursive_absolute("user://shots")
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", ProjectSettings.globalize_path(path))