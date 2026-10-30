extends Node
## Plays the demo's ending from barrier 40 and captures it along the way.
## godot --path . res://tools/demo_end_test.tscn

const SHOTS := {4.0: "60_demo_green", 13.0: "61_demo_dark", 18.0: "62_demo_bird", 34.0: "63_demo_city",
	52.0: "64_demo_letter", 70.0: "65_demo_end"}

var _main: Node
var _t := 0.0
var _taken := {}
var _started := false


func _ready() -> void:
	GameState.new_game()
	GameState.total_taps = 6120
	SaveSystem.lang = "es"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if not _started and _t > 0.5:
		_started = true
		_main._on_dev("edge", BuildFlags.DEMO_LAST)
		_t = 0.0
	if not _started:
		return
	# Leave the letter as soon as it allows, like a player would.
	for c in _main.hud.get_parent().get_children():
		if c is Screens.Letter and c._ready_to_leave and _t > 60.0:
			c._leave()
	for at in SHOTS:
		if _t >= at and not _taken.has(at):
			_taken[at] = true
			get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % SHOTS[at])
			print("SHOT %s  t=%.0f stage=%d finished=%s grand=%s letter=%s end=%s" % [SHOTS[at], _t,
				GameState.stage, GameState.finished, _main._grand, _main._letter_shown, _main._end_shown])
	if _t > 71.0:
		get_tree().quit()