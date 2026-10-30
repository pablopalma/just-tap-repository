extends Node
## Shows the creator's letter (sped up) in both languages and captures it.
## godot --path . res://tools/letter_test.tscn

var _main: Node
var _t := 0.0
var _step := 0


func _ready() -> void:
	GameState.new_game()
	GameState.total_taps = 18304
	SaveSystem.lang = "es"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Engine.time_scale = 4.0


func _process(delta: float) -> void:
	_t += delta / Engine.time_scale
	if _step == 0 and _t > 0.5:
		_step = 1
		_main._start()
		_main._show_letter()
	elif _step == 1 and _t > 11.0:
		_step = 2
		_shot("30_letter_es")
		SaveSystem.lang = "en"
		var l := Screens.Letter.new(GameState.total_taps)
		_main.hud.get_parent().add_child(l)
	elif _step == 2 and _t > 21.5:
		_shot("31_letter_en")
		Engine.time_scale = 1.0
		get_tree().quit()


func _shot(name: String) -> void:
	var path := "user://shots/%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", ProjectSettings.globalize_path(path))