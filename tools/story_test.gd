extends Node
## The story between zones 2 and 3 (scripts/ui/story.gd): jumps to barrier 20, breaks it, and when the
## voice asks, answers "tell me"; the memory draws itself, then the dive into zone 3.
## Record it: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/story_test.tscn

const LENGTH := 36.0

var _main: Node
var _t := 0.0
var _started := false
var _answered := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if not _started and _t > 0.5:
		_started = true
		_main._on_dev("edge", 20)
	if not _answered:
		for c in _main.subtitle.get_parent().get_children():
			if c.has_method("_tell") and _t > 5.5:
				_answered = true
				c._tell()
	if _t > LENGTH:
		get_tree().quit()