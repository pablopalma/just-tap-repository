class_name Screens
extends RefCounted
## Full-screen texts: the intro, the zone/chapter title and the ending (§11).


## Empty paper → "just tap" → "if you had a bad day…" → a pulsing prompt.
class Intro extends Control:
	var _prompt: Label

	func _init(returning: bool) -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(box)
		var title := _centered(UIStyle.label("just tap", 72))
		var tag := _centered(UIStyle.label("if you had a bad day…", 24, true, Color(Palette.INK, 0.75)))
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 60)
		_prompt = _centered(UIStyle.label("tocá para volver" if returning else "tocá para empezar", 18, true,
			Color(Palette.INK, 0.6)))
		for c in [title, tag, gap, _prompt]:
			box.add_child(c)
			c.modulate.a = 0.0
		_title = title
		_tag = tag

	var _title: Label
	var _tag: Label

	func _ready() -> void:
		var tw := create_tween()
		tw.tween_interval(0.5)
		tw.tween_property(_title, "modulate:a", 1.0, 3.0)
		tw.parallel().tween_property(_tag, "modulate:a", 1.0, 3.0).set_delay(2.0)
		tw.tween_callback(_pulse)

	func _centered(l: Label) -> Label:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l

	func _pulse() -> void:
		var tw := create_tween().set_loops()
		tw.tween_property(_prompt, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_prompt, "modulate:a", 0.25, 1.4).set_trans(Tween.TRANS_SINE)

	func dismiss() -> void:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 3.0)
		tw.tween_callback(queue_free)


## "zona ii completa · raíz" / "el color vuelve · rojo", at 30 % of the height.
class ZoneTitle extends Control:
	var _title: Label
	var _sub: Label
	var _tween: Tween

	func _init() -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		_title = UIStyle.label("", 40)
		_sub = UIStyle.label("", 20, true, Color(Palette.INK, 0.7))
		for l in [_title, _sub]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
			add_child(l)
		modulate.a = 0.0
		resized.connect(_place)

	func _place() -> void:
		_title.position.y = size.y * 0.3 - 30
		_sub.position.y = size.y * 0.3 + 22

	func show_title(title: String, sub: String, color: Color) -> void:
		_place()
		_title.text = title
		_title.add_theme_color_override("font_color", color)
		_sub.text = sub
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 1.0, 1.5)
		_tween.tween_interval(2.5)
		_tween.tween_property(self, "modulate:a", 0.0, 2.0)


## "you made colour" and the rebirth button, low on the screen over a paper gradient.
class EndScreen extends Control:
	signal rebirth_pressed

	func _init() -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		visible = false
		var grad := Gradient.new()
		grad.set_color(0, Color(Palette.PAPER, 0.0))
		grad.set_color(1, Color(Palette.PAPER, 0.95))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill_from = Vector2(0, 0)
		tex.fill_to = Vector2(0, 1)
		var bg := TextureRect.new()
		bg.texture = tex
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
		bg.offset_top = -260
		bg.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(bg)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
		box.offset_left = -240
		box.offset_right = 240
		box.offset_top = -170
		box.offset_bottom = -40
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(box)
		var title := UIStyle.label("you made colour", 44)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(title)
		var b := UIStyle.button("renacer  ·  ×2 para siempre", 22)
		b.pressed.connect(func() -> void: rebirth_pressed.emit())
		box.add_child(b)

	func show_end() -> void:
		visible = true
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 3.0)
