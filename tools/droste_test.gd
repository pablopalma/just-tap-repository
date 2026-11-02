extends Node
## The Droste dive between zones (BuildFlags.DROSTE): jumps to barrier 10, breaks it, falls into the
## tip and comes out in zone 2, which runs to the right; then taps through a few of its barriers.
## Record it: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/droste_test.tscn
## [-- --edge=20 --len=40 --dmg=300] (from barrier 20 it dives into the spiral and runs it)

var length := 20.0
var damage := 40.0

var _main: Node
var _t := 0.0
var _acc := 0.0
var _started := false


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if not _started and _t > 0.5:
		_started = true
		# the zone end to dive from: 10 by default, or godot ... -- --edge=20
		var edge := 10
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--edge="):
				edge = int(a.trim_prefix("--edge="))
			elif a.begins_with("--len="):
				length = float(a.trim_prefix("--len="))
			elif a.begins_with("--dmg="):
				damage = float(a.trim_prefix("--dmg="))
		_main._on_dev("edge", edge)
	# a few seconds into zone 2, tap through its barriers like a player
	if _t > 7.5:
		GameState.dev_damage = damage
		_acc += delta * 4.0
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap")
	if _t > length:
		print("DROSTE stage=%d angle=%.2f" % [GameState.stage, _main.camera.angle])
		get_tree().quit()