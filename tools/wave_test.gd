extends Node
## Captures the colour wave: a game in the red chapter, a reveal fired on the camera, frames
## saved at fixed times. godot --path . res://tools/wave_test.tscn

const SHOTS := {0.0: "20_wave_0", 0.35: "21_wave_drained", 1.2: "22_wave_1", 2.0: "23_wave_2", 3.2: "24_wave_3"}

var _main: Node
var _t := -1.0
var _taken := {}


func _ready() -> void:
	GameState.new_game()
	GameState.stage = 26
	GameState.hp = GameState.max_hp(26)
	SaveSystem.had_progress = false
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	if _t < 0.0:
		if Engine.get_process_frames() == 30:
			_main._start()
		if Engine.get_process_frames() == 300:
			_t = 0.0
			_main.colour_wave.reveal(_main.camera.position + Vector2(-120, 80), Palette.chapter_color(2))
		return
	_t += delta
	for at in SHOTS:
		if _t >= at and not _taken.has(at):
			_taken[at] = true
			var path := "user://shots/%s.png" % SHOTS[at]
			get_viewport().get_texture().get_image().save_png(path)
			print("SHOT ", ProjectSettings.globalize_path(path))
	if _t > 3.4:
		get_tree().quit()