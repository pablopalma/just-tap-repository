extends Node
## Plays a star circuit and the forks with steady tapping, capturing them.
## godot --path . res://tools/star_fork_test.tscn

const STEPS := [
	[0.5, "jump", 16, ""], [0.5, "damage", 45.0, ""], [0.5, "rate", 5.0, ""],
	[2.0, "", 0, "70_star_entry"], [7.0, "", 0, "71_star_mid"],
	[40.0, "jump", 37, ""], [40.0, "damage", 260.0, ""], [46.0, "", 0, "72_star6_mid"],
	[70.0, "jump", 41, ""], [70.0, "damage", 260.0, ""], [70.0, "rate", 3.0, ""], [71.2, "", 0, "73_fork_split"], [74.0, "", 0, "74_fork2"],
	[78.0, "jump", 51, ""], [78.0, "damage", 900.0, ""], [81.0, "", 0, "75_fork3"],
	[86.0, "jump", 59, ""], [86.0, "damage", 3000.0, ""],
]
const END := 96.0

var _main: Node
var _t := 0.0
var _i := 0
var _rate := 0.0
var _acc := 0.0
var _log := {}


func _ready() -> void:
	SaveSystem.enabled = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.star_completed.connect(func(n: int) -> void: print("STAR done b%d t=%.1f" % [n, _t]))
	GameState.gate_broken.connect(func(n: int) -> void: _log[n] = _t)
	_main.star.burst.connect(func(_p: Vector2) -> void: print("STAR burst t=%.1f" % _t))


func _process(delta: float) -> void:
	_t += delta
	while _i < STEPS.size() and _t >= STEPS[_i][0]:
		var s: Array = STEPS[_i]
		_i += 1
		match s[1]:
			"jump":
				_main._on_dev("jump", s[2])
			"damage":
				GameState.dev_damage = s[2]
			"rate":
				_rate = s[2]
		if s[3] != "":
			get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % s[3])
			print("SHOT %s stage=%d star=%s branches=%d prog=%.2f" % [s[3], GameState.stage,
				not GameState.star.is_empty(), GameState.branches.size(), GameState.progress()])
	if GameState.running and not GameState.finished:
		_acc += _rate * delta
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap")
	if _t > END:
		var keys := _log.keys()
		keys.sort()
		print("BROKEN ", keys)
		get_tree().quit()