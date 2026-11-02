extends Node
## Plays the end of the demo's dark from barrier 42: the "now" cinematic (the tip breaks the last
## barriers on its own while the voice talks about this moment), then the mandala and the whale.
## Record it: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/now_test.tscn

const LENGTH := 48.0

var _main: Node
var _t := 0.0
var _started := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Narrator.line_started.connect(func(id: String, _text: String, duration: float) -> void:
		print("LINE %s at %.1f s (shown %.1f s)" % [id, _t, duration]))
	GameState.gate_broken.connect(func(n: int) -> void: print("BROKE %d at %.1f s" % [n, _t]))


func _process(delta: float) -> void:
	_t += delta
	if not _started and _t > 0.5:
		_started = true
		_main._on_dev("edge", BuildFlags.now_from() - 1)
	if _t > LENGTH:
		get_tree().quit()