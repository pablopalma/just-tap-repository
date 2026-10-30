class_name UIStyle
extends RefCounted
## Shared theme: serif type with generous letter spacing, ink on paper, flat buttons.

static var _font: Font
static var _italic: Font


static func font() -> Font:
	if _font == null:
		_font = _make(false)
	return _font


static func italic() -> Font:
	if _italic == null:
		_italic = _make(true)
	return _italic


static func _make(is_italic: bool) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Cormorant Garamond", "Cormorant", "Garamond", "Georgia", "Times New Roman", "serif"])
	f.font_weight = 300 if not is_italic else 400
	f.font_italic = is_italic
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	var v := FontVariation.new()
	v.base_font = f
	v.spacing_glyph = 1
	return v


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 18
	t.set_color("font_color", "Label", Palette.INK)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(s, "Button", empty)
	t.set_color("font_color", "Button", Color(Palette.INK, 0.8))
	t.set_color("font_hover_color", "Button", Palette.INK)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_focus_color", "Button", Color(Palette.INK, 0.8))
	t.set_color("font_hover_pressed_color", "Button", Palette.INK)
	t.set_font_size("font_size", "Button", 20)
	return t


static func label(text: String, size: int, is_italic := false, color := Palette.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if is_italic:
		l.add_theme_font_override("font", italic())
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	return b
