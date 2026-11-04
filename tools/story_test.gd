extends Node
## The story at the end of zone 4 (scripts/ui/story.gd, Main.STORY_AFTER_ZONE): jumps to its last barrier,
## breaks it, and when the voice asks, answers "tell me"; the memory draws itself, then the zone's end
## goes on (in the demo, the dark comes in).
## Record it: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/story_test.tscn

const LENGTH := 44.0

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
		_main._on_dev("edge", _main.STORY_AFTER_ZONE * 10)
	if not _answered:
		for c in _main.subtitle.get_parent().get_children():
			if c.has_method("_tell") and _t > 5.5:
				_answered = true
				c._tell()
				print("STORY offered after barrier ", GameState.stage - 1, ", told")
	if _t > LENGTH:
		print("STORY after it: barrier ", GameState.stage, " dark ", BuildFlags.is_dark(GameState.stage), " story still on ", _main._story)
		get_tree().quit()