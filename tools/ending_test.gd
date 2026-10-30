extends Node
## Plays the ending up to the grand reveal and captures it.
## godot --path . res://tools/ending_test.tscn

const SHOTS := {9.0: "40_ending_top", 12.0: "41_grand_start", 16.0: "42_grand_mid", 22.0: "43_grand_full"}

var _main: Node
var _t := 0.0
var _taken := {}


func _ready() -> void:
	GameState.new_game()
	GameState.stage = 100
	GameState.hp = 0.5
	GameState.total_taps = 18304
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 2.0 and not GameState.finished:
		GameState.hp = 0.0
		GameState.tap("tap")
	if _t > 11.0 and not _main._grand:
		_main._begin_grand()
	for at in SHOTS:
		if _t >= at and not _taken.has(at):
			_taken[at] = true
			var path := "user://shots/%s.png" % SHOTS[at]
			get_viewport().get_texture().get_image().save_png(path)
			print("SHOT ", ProjectSettings.globalize_path(path))
	if _t > 22.5:
		get_tree().quit()