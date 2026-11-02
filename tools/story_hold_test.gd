extends Node
## Zone 2 and the story's question: the tree's texts with the view turned sideways, and the voice
## keeping quiet while the story waits for an answer. Logs every line the voice starts and whether
## the question was open. Record it to look at the frames:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/story_hold_test.tscn

var _main: Node
var _t := 0.0
var _acc := 0.0
var _asked_at := -1.0
var _answered := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Narrator.line_started.connect(func(id: String, _x: String, _d: float) -> void:
		print("[%5.1f s] voz %s%s" % [_t, id, "   <- con la pregunta abierta" if _main._story and _asked_at >= 0.0 and id != "story_ask" and not _answered else ""]))


## The barrier it jumps to (`-- 34` for the night); 17 by default, near the story.
func _from() -> int:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			return int(a)
	return 17


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _t > 2.0 and _t < 2.1:
		_main._dev_jump(_from())
		GameState.light = 1e9
	if _t > 4.0 and _t < 4.1:
		for i in 25:
			_main.inline_tree._choose("fuerza")
		for id in ["ganancia", "pulso", "corrosion"]:
			_main.inline_tree._choose(id)
	if _main._story and _asked_at < 0.0:
		_asked_at = _t
		print("[%5.1f s] pregunta de la historia" % _t)
	if _asked_at >= 0.0 and not _answered and _t > _asked_at + 10.0:
		_answered = true
		print("[%5.1f s] responde: seguir" % _t)
		for c in _main.subtitle.get_parent().get_children():
			if c.has_method("_tell"):
				c._end(false)
	if _t > 8.0 and GameState.running and not _main._story and _asked_at < 0.0:
		_acc += delta * 8.0
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap")
	if _answered and _t > _asked_at + 22.0 or _t > 90.0:
		get_tree().quit()
