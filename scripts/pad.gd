class_name Pad
extends RefCounted
## Playing with a gamepad (JUST_TAP_GODOT.md §13.6). Buttons go by position, as Godot names them, so
## one mapping serves Xbox, PlayStation and Switch pads: A is the bottom face button, X the left one.
##   tap        A, or either trigger (held: keep tapping)
##   tree_next  RB or d-pad right; tree_prev  LB or d-pad left: the tree node in focus
##   tree_buy   X: buy it
## Menus use Godot's own ui_* actions (A accepts, B cancels, the stick and d-pad move).
## The game shows the gamepad's buttons only while the player is using one (`using`), drawn in the
## game's ink, as the pad's family draws them (`kind`): Xbox letters, PlayStation shapes, Switch letters.

static var using := false
static var kind := "xbox"   # "xbox", "ps" or "switch"


static func setup() -> void:
	_action("tap", [_button(JOY_BUTTON_A), _axis(JOY_AXIS_TRIGGER_RIGHT), _axis(JOY_AXIS_TRIGGER_LEFT)])
	_action("tree_next", [_button(JOY_BUTTON_RIGHT_SHOULDER), _button(JOY_BUTTON_DPAD_RIGHT)])
	_action("tree_prev", [_button(JOY_BUTTON_LEFT_SHOULDER), _button(JOY_BUTTON_DPAD_LEFT)])
	_action("tree_buy", [_button(JOY_BUTTON_X)])
	# the menus: Godot's own actions, with the pad's buttons, d-pad and left stick
	_action("ui_accept", [_button(JOY_BUTTON_A)])
	_action("ui_cancel", [_button(JOY_BUTTON_B)])
	_action("ui_left", [_button(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("ui_right", [_button(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X)])
	_action("ui_up", [_button(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("ui_down", [_button(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y)])


## Every input passes here (Main._input): a gamepad's switches the prompts to it, anything else back.
static func note(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.5):
		if not using:
			using = true
			kind = _kind(Input.get_joy_name(e.device))
	elif e is InputEventMouseButton or e is InputEventScreenTouch or e is InputEventKey 			or (e is InputEventMouseMotion and (e as InputEventMouseMotion).relative.length() > 6.0):
		using = false


static func _kind(joy_name: String) -> String:
	var n := joy_name.to_lower()
	for k in ["playstation", "ps4", "ps5", "dualshock", "dualsense", "sony"]:
		if k in n:
			return "ps"
	for k in ["nintendo", "switch", "joy-con"]:
		if k in n:
			return "switch"
	return "xbox"


## A button's prompt, drawn in ink on `ci` around `center`: a hand-drawn ring and the button's letter
## or shape. button: "a", "b", "x", "y" (by position), "rt" (right trigger) or "rb" (right shoulder).
## press (0..1): the button pushed down, onto the shadow of its rim.
static func draw_glyph(ci: CanvasItem, center: Vector2, button: String, r: float, col: Color, press := 0.0) -> void:
	# the button's side, under it: what it is pushed down onto
	var depth := r * 0.2
	ci.draw_circle(center + Vector2(0, depth), r * 1.02, Color(col, col.a * 0.16))
	ci.draw_arc(center + Vector2(0, depth), r * 1.02, 0.15, PI - 0.15, 24, Color(col, col.a * 0.45), maxf(1.0, r * 0.08), true)
	center += Vector2(0, depth * press)
	ci.draw_circle(center, r, Color(Palette.PAPER, col.a * 0.85))
	# a ring drawn by hand: a little wobble, and its two ends overlapping
	var pts := PackedVector2Array()
	for i in 41:
		var a := -PI * 0.6 + TAU * 1.04 * i / 40.0
		pts.append(center + Vector2.from_angle(a) * r * (1.0 + 0.035 * sin(a * 3.0 + 1.3)))
	ci.draw_polyline(pts, col, maxf(1.2, r * 0.11), true)
	var k := r * 0.42
	if button in ["rt", "rb"]:
		var names := {"xbox": ["RT", "RB"], "ps": ["R2", "R1"], "switch": ["ZR", "R"]}
		var t: String = names[kind][0 if button == "rt" else 1]
		_letters(ci, center, t, r * (0.72 if t.length() > 1 else 1.1), col)
	elif kind == "ps":
		var w := maxf(1.2, r * 0.1)
		match button:
			"a":  # cross
				ci.draw_line(center + Vector2(-k, -k), center + Vector2(k, k), col, w, true)
				ci.draw_line(center + Vector2(-k, k), center + Vector2(k, -k), col, w, true)
			"b":  # circle
				ci.draw_arc(center, k, 0.0, TAU, 28, col, w, true)
			"x":  # square
				ci.draw_rect(Rect2(center - Vector2(k, k) * 0.9, Vector2(k, k) * 1.8), col, false, w)
			"y":  # triangle
				ci.draw_polyline(PackedVector2Array([center + Vector2(0, -k * 1.1), center + Vector2(k, k * 0.75),
					center + Vector2(-k, k * 0.75), center + Vector2(0, -k * 1.1)]), col, w, true)
	else:
		_letters(ci, center, _letter(button), r * 1.15, col)


## The letter on a button: Switch pads swap them (its bottom button is B, its left one Y).
static func _letter(button: String) -> String:
	if kind == "switch":
		return {"a": "B", "b": "A", "x": "Y", "y": "X"}.get(button, button.to_upper())
	return button.to_upper()


static func _letters(ci: CanvasItem, center: Vector2, text: String, size: float, col: Color) -> void:
	var font := UIStyle.font()
	var s := int(size)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var asc := font.get_ascent(s) - font.get_descent(s)
	ci.draw_string(font, center + Vector2(-w * 0.5, asc * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, col)


static func _action(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.4)
	for e: InputEvent in events:
		if not InputMap.action_has_event(action, e):
			InputMap.action_add_event(action, e)


static func _button(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e


static func _axis(axis: JoyAxis, value := 1.0) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
