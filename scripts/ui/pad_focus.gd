class_name PadFocus
extends Control
## With a gamepad (Pad.using): the menus' buttons. The latest offered button that is on screen gets
## the focus when nothing has it, so A presses it; the focused button shows the A button beside it,
## drawn in ink. Without a gamepad nothing keeps the focus, so the space bar always taps.

static var _offered: Array[Button] = []


## A menu's main button, to take the focus when the player plays with a gamepad.
static func offer(b: Button) -> void:
	reach(b)
	_offered.append(b)


## A menu's button the gamepad can move to (the game's buttons take no focus otherwise). The ink A
## beside it marks the focus, so Godot's own frame is left out.
static func reach(b: Button) -> void:
	b.focus_mode = FOCUS_ALL
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 100


func _process(_delta: float) -> void:
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


func _draw() -> void:
	if not Pad.using:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if not focus is Button or not focus.is_visible_in_tree():
		return
	var r := focus.get_global_rect()
	var at := get_global_transform().affine_inverse() * Vector2(r.position.x - 26.0, r.get_center().y - 2.0)
	Pad.draw_glyph(self, at, "a", 15.0, Color(Palette.INK, 0.85), pow(1.0 - Music.heard_phase(), 4.0))
