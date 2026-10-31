extends Node
## Gris-style atmosphere check: a structure piece builds (swell, gliss, float-up, sparks) and the
## giant bird passes (wing air, cry, Doppler rush).
## godot --path . --write-movie Builds/gris_test.avi --fixed-fps 30 res://tools/gris_test.tscn

const LENGTH := 16.0

var _main: Node
var _t := 0.0
var _steps := {}


func _ready() -> void:
	SaveSystem.enabled = false
	Narrator.auto = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	_main.subtitle.visible = false
	_once("jump", 0.3, func(): _main._on_dev("jump", 18))
	_once("break", 1.2, func(): _main._dev_break())
	_once("bird", 2.0, func(): _main.bird.fly())
	_once("break2", 6.5, func(): _main._dev_break())
	if _t >= LENGTH:
		get_tree().quit()


func _once(key: String, at: float, f: Callable) -> void:
	if _t >= at and not _steps.has(key):
		_steps[key] = true
		f.call()
