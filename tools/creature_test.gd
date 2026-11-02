extends Node
## A being waking (scripts/world/creature.gd): starts at barrier --from (1: a new game, the
## firefly; 31: the starry night, the deer) and taps through its barriers.
## godot --path . --write-movie out.avi --fixed-fps 30 res://tools/creature_test.tscn -- --from=31 --dmg=60 --len=40

var _main: Node
var _t := 0.0
var _acc := 0.0
var _from := 1
var _dmg := 6.0
var _len := 40.0
var _started := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			_from = int(a.trim_prefix("--from="))
		elif a.begins_with("--dmg="):
			_dmg = float(a.trim_prefix("--dmg="))
		elif a.begins_with("--len="):
			_len = float(a.trim_prefix("--len="))
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if not _started and _t > 0.5:
		_started = true
		if _from > 1:
			_main._dev_jump(_from)
		else:
			_main._start()
	if _t > 2.0:
		GameState.dev_damage = _dmg
		_acc += delta * 4.0
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap")
	if _t > _len:
		get_tree().quit()