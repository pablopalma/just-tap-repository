extends Node
## Presses the dev menu's dark-stretch buttons one after another and prints what happened.

var _main: Node
var _t := 0.0
var _steps := [[0.5, "edge", 40], [10.0, "jump", 41], [12.0, "quake", 0], [14.0, "jump", 43], [16.0, "whale", 0],
	[18.0, "edge", 45], [50.0, "", 0]]
var _i := 0


func _ready() -> void:
	SaveSystem.enabled = false
	Narrator.auto = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _i < _steps.size() and _t >= _steps[_i][0]:
		var s: Array = _steps[_i]
		_i += 1
		if s[1] == "":
			get_tree().quit()
			return
		_main._on_dev(s[1], s[2])
		await get_tree().create_timer(1.5).timeout
		print("DEVDARK %s %d -> stage=%d dark=%s invert=%.2f chaos=%s whale=%s finished=%s mode=%d" % [s[1], s[2],
			GameState.stage, _main._dark, _main.darkness.invert, _main.chaos.active, _main.whale.active,
			GameState.finished, _main.mode])