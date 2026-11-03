extends Node
## Opens each prototype from the dev menu, plays it a moment and comes back with Esc (DevMenu.PROTOS).
## godot --path . res://tools/proto_menu_test.tscn

var _i := 0
var _t := 0.0
var _phase := "game"


func _ready() -> void:
	# the scene gets replaced by the game: the one that drives it lives beside it, under the root
	if not has_meta("driver"):
		set_process(false)
		var d := Node.new()
		d.set_meta("driver", true)
		d.set_script(get_script())
		get_tree().root.add_child.call_deferred(d)
		return
	SaveSystem.enabled = false
	get_tree().root.child_entered_tree.connect(func(n: Node) -> void: print("PROTO scene ", n.name))
	_open_game.call_deferred()


func _open_game() -> void:
	get_tree().change_scene_to_file(DevMenu.GAME_SCENE)


func _process(delta: float) -> void:
	_t += delta
	var cur := get_tree().current_scene
	if cur == null or _t < 2.5:
		return
	if _phase == "game":
		if _i >= DevMenu.PROTOS.size():
			print("PROTO done, back in ", cur.name)
			get_tree().quit()
			return
		print("PROTO open ", DevMenu.PROTOS[_i][0])
		cur._on_dev("proto", _i)
		_phase = "proto"
	elif _phase == "proto":
		for k in 3:
			var tap := InputEventKey.new()
			tap.keycode = KEY_SPACE
			tap.pressed = true
			Input.parse_input_event(tap)
		print("PROTO playing ", cur.name, "  title theme: ", Music.title_on, "  track: ", Music.track)
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		esc.pressed = true
		Input.parse_input_event(esc)
		_phase = "back"
	else:
		print("PROTO back in ", cur.name)
		_i += 1
		_phase = "game"
	_t = 0.0
