extends Node
## Drives the dev menu actions one after another and captures each.
## godot --path . res://tools/dev_menu_test.tscn

const STEPS := [
	[1.0, "menu", 0, ""],
	[1.5, "", 0, "50_dev_menu"],
	[2.0, "jump", 31, ""],
	[4.0, "", 0, "51_dev_zone4"],
	[5.0, "edge", 40, ""],
	[9.0, "", 0, "52_dev_green"],
	[10.0, "grand", 0, ""],
	[22.0, "", 0, "53_dev_grand"],
	[23.0, "letter", 0, ""],
]

var _main: Node
var _t := 0.0
var _i := 0


func _ready() -> void:
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	while _i < STEPS.size() and _t >= STEPS[_i][0]:
		var s: Array = STEPS[_i]
		_i += 1
		if s[1] == "menu":
			_main.dev_menu.toggle()
		elif s[1] != "":
			if _main.dev_menu.visible:
				_main.dev_menu.toggle()
			_main._on_dev(s[1], s[2])
			print("DEV %s %d -> stage=%d finished=%s" % [s[1], s[2], GameState.stage, GameState.finished])
		if s[3] != "":
			var path := "user://shots/%s.png" % s[3]
			get_viewport().get_texture().get_image().save_png(path)
			print("SHOT ", s[3], " stage=", GameState.stage)
	if _t > 26.0:
		print("END stage=%d finished=%s letter=%s" % [GameState.stage, GameState.finished, _main._letter_shown])
		get_tree().quit()