extends Node
## The story at the end of zone 4 (scripts/ui/story.gd, Main.STORY_AFTER_ZONE): jumps to its last barrier,
## breaks it, and when the voice asks, answers "tell me"; the memory draws itself, then the zone's end
## goes on (in the demo, the dark comes in).
## Record it: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/story_test.tscn

const LENGTH := 95.0

var _main: Node
var _t := 0.0
var _started := false
var _answered := false
var _seen_continue := -1.0


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
	var story: Node = null
	for c in _main.subtitle.get_parent().get_children():
		if c.has_method("_offer_continue"):
			story = c
	if story and story._continue != null:
		if _seen_continue < 0.0:
			_seen_continue = _t
			print("STORY continue shown at ", snappedf(_t, 0.1))
		elif _t - _seen_continue > 3.0 and not story._ending:
			story._continue.pressed.emit()
			print("STORY continue pressed at ", snappedf(_t, 0.1))
	if _t > LENGTH:
		print("STORY after it: barrier ", GameState.stage, " dark ", BuildFlags.is_dark(GameState.stage), " story still on ", _main._story)
		get_tree().quit()