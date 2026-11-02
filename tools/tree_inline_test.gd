extends Node
## Check for the tree's branches growing out of the line (BuildFlags.TREE_INLINE): plays the first barriers
## tapping fast on the barrier while now and then a tap lands on a node of the tree and buys it,
## without pausing. Taps go through the real input path (Input.parse_input_event), and a ring marks
## where each one lands. Record it at 1280×720, and at 540×960 (portrait override.cfg) for phones:
## godot --path . --write-movie out.avi --fixed-fps 30 res://tools/tree_inline_test.tscn

const LENGTH := 28.0
const TAP_EVERY := 0.15
const TREE_EVERY := 1.7
## Which node to go for first when several can be bought.
const WANT := ["fuerza", "pulso", "ganancia", "fuerza", "resonancia", "eco", "corrosion", "destello"]

var _main: Node
var _t := 0.0
var _started := false
var _next_tap := 1.2
var _next_tree := 2.0
var _marks: Node2D
var _rings: Array[Dictionary] = []
var _wrong_done := false
var _want_i := 0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	_main.cinematics_enabled = false  # keep playing: the story cinematics hide the tree
	add_child(_main)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_marks = Node2D.new()
	_marks.draw.connect(_draw_marks)
	layer.add_child(_marks)
	GameState.upgrade_bought.connect(func(id: String, l: int) -> void: print("BUY %s %d at %.1f s" % [id, l, _t]))
	GameState.gate_broken.connect(func(n: int) -> void: print("BROKE %d at %.1f s" % [n, _t]))


func _process(delta: float) -> void:
	_t += delta
	if not _started and _t > 0.5:
		_started = true
		_main._on_dev("jump", 1)
		_main._set_tree_inline(true)
		GameState.add_light(25)
	if _started and _t >= _next_tap:
		_next_tap += TAP_EVERY * randf_range(0.8, 1.25)
		var vs := _main.get_viewport().get_visible_rect().size
		var gate: Vector2 = _main.path.gate_pos(GameState.stage) + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		var at: Vector2 = _main.get_viewport().get_canvas_transform() * gate
		_click(at.clamp(Vector2.ZERO, vs), false)
	if _started and _t >= _next_tree:
		_next_tree += TREE_EVERY
		_tap_tree()
	# Keep enough light coming to show the tree growing in a short clip.
	if _started and _t > 2.0:
		GameState.add_light(delta * (6.0 + _t * 3.0))
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i].t += delta
		if _rings[i].t > 0.6:
			_rings.remove_at(i)
	_marks.queue_redraw()
	if _t > LENGTH:
		get_tree().quit()


func _tap_tree() -> void:
	var tree = _main.inline_tree
	var id := ""
	for i in WANT.size():
		var w: String = WANT[(_want_i + i) % WANT.size()]
		if GameState.can_buy(w):
			id = w
			_want_i += i + 1
			break
	if id == "" and not _wrong_done and GameState.state_of("ganancia") >= 1:
		id = "ganancia"  # once: a node that can't be bought yet nudges and says what it needs
		_wrong_done = true
	if id == "":
		return
	var at: Vector2 = tree.get_global_transform_with_canvas() * tree._point(id)
	_click(at, true)


func _click(at: Vector2, tree: bool) -> void:
	_rings.append({"p": at, "t": 0.0, "tree": tree})
	# Events come in window coordinates; the window may be smaller than the viewport.
	at = _main.get_viewport().get_final_transform() * at
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		Input.parse_input_event(e)


func _draw_marks() -> void:
	for r in _rings:
		var k: float = r.t / 0.6
		var col := Color(0.85, 0.3, 0.2) if r.tree else Color(0.1, 0.1, 0.1)
		_marks.draw_circle(r.p, 7.0, Color(col, 0.35 * (1.0 - k)))
		_marks.draw_arc(r.p, lerpf(8.0, 30.0 if r.tree else 20.0, k), 0.0, TAU, 32, Color(col, 0.7 * (1.0 - k)), 2.0, true)
