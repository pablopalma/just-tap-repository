extends Node
## Breaks barrier 25 (halfway through zone 3) and captures the panorama that follows.
## godot --path . res://tools/pano_test.tscn

var _main: Node
var _t := 0.0
var _pano_at := -1.0
var _shots := {}


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _t < 0.6:
		_main._on_dev("jump", 25)
	if _t > 1.5 and GameState.stage == 25:
		_main._dev_break()
	if _main._pano > 0.0 and _pano_at < 0.0:
		_pano_at = _t
		print("PANO start t=%.1f stage=%d" % [_t, GameState.stage])
	if _pano_at > 0.0:
		for at in [1.5, 4.5]:
			var name := "90_pano_%.1f" % at
			if _t - _pano_at >= at and not _shots.has(name):
				_shots[name] = true
				get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)
				print("SHOT %s glimpse=%.2f" % [name, _main.landscape.glimpse])
	if _t > 14.0:
		print("END pano=%.1f glimpse=%.2f" % [_main._pano, _main.landscape.glimpse])
		get_tree().quit()