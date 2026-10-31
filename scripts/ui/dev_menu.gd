class_name DevMenu
extends Control
## Developer-only menu (F1). Exists only in debug builds — the editor and debug exports — never in
## a release. Jumps straight to any zone, chapter or moment of the ending, and has a few helpers.
## Main does the actual work through the `action` signal, so this stays a plain panel.

signal action(id: String, arg: int)

var _panel: PanelContainer


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.PAPER, 0.96)
	sb.border_color = Palette.INK
	sb.set_border_width_all(1)
	sb.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
	_panel.offset_left = -330
	_panel.offset_right = -10
	_panel.offset_top = 10
	_panel.offset_bottom = -10
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)

	box.add_child(UIStyle.label("dev  ·  F1", 22))

	_title(box, "Zonas (inicio)")
	var zones := GridContainer.new()
	zones.columns = 5
	box.add_child(zones)
	for z in range(1, Zones.COUNT + 1):
		_button(zones, Zones.ROMAN[z - 1], "jump", (z - 1) * 10 + 1)

	_title(box, "Momentos")
	_button(box, "Antes de completar zona i (b.10)", "edge", 10)
	_button(box, "El color vuelve · rojo (b.20)", "edge", 20)
	_button(box, "El color vuelve · verde (b.40)", "edge", 40)
	_button(box, "El color vuelve · azul (b.60)", "edge", 60)
	_button(box, "El color vuelve · amarillo (b.80)", "edge", 80)

	if BuildFlags.DEMO:
		_title(box, "Oscuridad (demo, b.%d–%d)" % [BuildFlags.DARK_FROM, BuildFlags.DEMO_LAST])
		_button(box, "Entra la oscuridad (romper la b.%d)" % (BuildFlags.DARK_FROM - 1), "edge", BuildFlags.DARK_FROM - 1)
		_button(box, "Jugarla desde el principio (b.%d)" % BuildFlags.DARK_FROM, "jump", BuildFlags.DARK_FROM)
		_button(box, "En el medio del caos (b.43)", "jump", 43)
		_button(box, "La última: mandala y ballena (b.%d)" % BuildFlags.DEMO_LAST, "edge", BuildFlags.DEMO_LAST)
		_button(box, "Temblor", "quake", 0)
		_button(box, "Ballena celeste", "whale", 0)

	_title(box, "Estrellas y ramas")
	_button(box, "Estrella · 4 luces (b.16)", "jump", 16)
	_button(box, "Estrella · 6 luces (b.37)", "jump", 37)
	# In the demo 41–45 are the dark: the first fork shows from 46.
	var fork2 := BuildFlags.DEMO_LAST + 1 if BuildFlags.DEMO else 41
	_button(box, "Bifurcación en 2 (b.%d)" % fork2, "jump", fork2)
	_button(box, "Bifurcación en 3 (b.51)", "jump", 51)
	_button(box, "Unión de las ramas (b.60)", "edge", 60)

	_title(box, "Final")
	if BuildFlags.DEMO:
		_button(box, "Final de la demo (b.%d)" % BuildFlags.DEMO_LAST, "edge", BuildFlags.DEMO_LAST)
	_button(box, "Romper la barrera 100 (final entero)", "edge", 100)
	_button(box, "Ciudad: \"You made all of this\"", "grand", 0)
	_button(box, "Solo la carta", "letter", 0)
	_button(box, "Pantalla de cierre (renacer)", "end", 0)

	_title(box, "Ayudas")
	_button(box, "Romper la barrera actual", "break", 0)
	_button(box, "Daño ×10 (otra vez = ×100…)", "damage", 10)
	_button(box, "Daño normal", "damage", 1)
	_button(box, "+1M de luz", "light", 1000000)
	_button(box, "Ave", "bird", 0)
	_button(box, "Ola de color", "wave", 0)
	_button(box, "Idioma es / en", "lang", 0)


func toggle() -> void:
	visible = not visible
	move_to_front()  # above the letter and the end screen too


func _title(box: Control, text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	box.add_child(gap)
	box.add_child(UIStyle.label(text, 15, true, Color(Palette.INK, 0.6)))


func _button(parent: Control, text: String, id: String, arg: int) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(Palette.INK, 0.06)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate()
	hover.bg_color = Color(Palette.INK, 0.14)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.pressed.connect(func() -> void: action.emit(id, arg))
	parent.add_child(b)
