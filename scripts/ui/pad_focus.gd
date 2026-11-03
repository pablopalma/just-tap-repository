class_name PadFocus
extends Control
## With a gamepad (Pad.using): the menus' buttons. The latest offered button that is on screen gets
## the focus when nothing has it, so A presses it; the focused button shows the A button beside it,
## drawn in ink. Without a gamepad nothing keeps the focus, so the space bar always taps.
## Either way the button you are on (in focus, or under the mouse) stands out: it comes forward, a
## little bigger and fully inked, with a line drawn under it.

const LIFT := 1.08

static var _offered: Array[Button] = []
static var _hover: Button


## A menu's main button, to take the focus when the player plays with a gamepad.
static func offer(b: Button) -> void:
	reach(b)
	_offered.append(b)


## A menu's button the gamepad can move to (the game's buttons take no focus otherwise). The ink A
## beside it marks the focus, so Godot's own frame is left out.
static func reach(b: Button) -> void:
	b.focus_mode = FOCUS_ALL
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_to_group(&"pad_reach")
	b.mouse_entered.connect(func() -> void: _hover = b)
	b.mouse_exited.connect(func() -> void:
		if _hover == b:
			_hover = null)


## The button you are on: the gamepad's focus, or the one under the mouse.
func _hot() -> Button:
	if Pad.using:
		var focus := get_viewport().gui_get_focus_owner()
		return focus as Button if focus is Button and focus.is_visible_in_tree() else null
	if is_instance_valid(_hover) and _hover.is_visible_in_tree():
		return _hover
	return null


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 100


func _process(delta: float) -> void:
	_lift(delta)
	var vp := get_viewport()
	var focus := vp.gui_get_focus_owner()
	if not Pad.using:
		if focus != null:
			focus.release_focus()
		queue_redraw()
		return
	if focus == null:
		for i in range(_offered.size() - 1, -1, -1):
			var b := _offered[i]
			if not is_instance_valid(b):
				_offered.remove_at(i)
			elif b.is_visible_in_tree() and not b.disabled:
				b.grab_focus()
				break
	queue_redraw()


## Every reachable button eases towards its rest (its own alpha, its size) or, the one you are on,
## towards full ink and LIFT.
func _lift(delta: float) -> void:
	var hot := _hot()
	var k := minf(1.0, delta * 12.0)
	for b in _reachable():
		if not b.has_meta("rest_a"):
			b.set_meta("rest_a", b.modulate.a)
		var on := b == hot
		b.pivot_offset = b.size * 0.5
		b.scale = b.scale.lerp(Vector2.ONE * (LIFT if on else 1.0), k)
		b.modulate.a = lerpf(b.modulate.a, 1.0 if on else float(b.get_meta("rest_a")), k)


func _reachable() -> Array[Button]:
	var out: Array[Button] = []
	for n in get_tree().get_nodes_in_group(&"pad_reach"):
		if n is Button and n.is_visible_in_tree():
			out.append(n)
	return out


func _draw() -> void:
	var hot := _hot()
	if hot == null:
		return
	var a := _shown(hot)
	if a <= 0.01:
		return
	var inv := get_global_transform().affine_inverse()
	var r := hot.get_global_rect()
	# a line drawn by hand under the text, a little wavy
	var font := hot.get_theme_font("font")
	var w := font.get_string_size(hot.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hot.get_theme_font_size("font_size")).x * hot.scale.x
	var y := r.get_center().y + r.size.y * 0.32
	var pts := PackedVector2Array()
	for i in 13:
		var x := r.get_center().x - w * 0.5 + w * i / 12.0
		pts.append(inv * Vector2(x, y + sin(i * 1.7) * 0.8))
	draw_polyline(pts, Color(Palette.INK, 0.7 * a), 1.4, true)
	if Pad.using:
		var at := inv * Vector2(r.get_center().x - w * 0.5 - 26.0, r.get_center().y - 2.0)
		Pad.draw_glyph(self, at, "a", 15.0, Color(Palette.INK, 0.85 * a), pow(1.0 - Music.heard_phase(), 4.0))


## How visible a button is, its menu's fades included (each parent's modulate), so the marks come in
## and go with it. The button's own lift is left out.
func _shown(b: Control) -> float:
	var a := 1.0
	var n: Node = b.get_parent()
	while n is CanvasItem:
		a *= (n as CanvasItem).modulate.a * (n as CanvasItem).self_modulate.a
		n = n.get_parent()
	return a
