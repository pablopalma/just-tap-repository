extends Node
## Plays a short run and sends its play data to tools/telemetry_sink.py.
## python tools/telemetry_sink.py 8770 Builds/telemetry_test.csv
## godot --headless --path . res://tools/telemetry_test.tscn -- --telemetry-url=http://localhost:8770/

var _main: Node
var _t := 0.0
var _done := false


func _ready() -> void:
	SaveSystem.enabled = false
	Telemetry.testing = true
	Narrator.auto = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if GameState.running and _t < 8.0:
		for i in 4:
			GameState.tap("tap")
	if _t > 3.0 and _t < 3.1:
		_main.tree_panel.open_panel()
		GameState.light = maxf(GameState.light, 200.0)
		GameState.buy("fuerza")
		GameState.buy("fuerza")
	if _t > 4.0 and _t < 4.1:
		_main.tree_panel.close_panel()
	if _t > 9.0 and not _done:
		_done = true
		Telemetry.event("leave", {"test": true})
		Telemetry.flush()
	if _t > 16.0:
		print("TELEMETRY queue=%d inflight=%d stage=%d" % [Telemetry._queue.size(), Telemetry._inflight.size(), GameState.stage])
		get_tree().quit()