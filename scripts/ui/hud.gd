extends Control
## HUD (§12): barrier counter and zone, light and damage, music toggle, tree button and a contextual hint.

signal tree_pressed

var _stage: Label
var _zone: Label
var _light: Label
var _dmg: Label
var _hint: Label
var _music: Button
var _tree: Button
var _dot: Label
var _total_taps := 0
var _cache := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	var tl := VBoxContainer.new()
	tl.position = Vector2(28, 18)
	tl.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(tl)
	_stage = UIStyle.label("", 44)
	_zone = UIStyle.label("", 17, true, Color(Palette.INK, 0.7))
	tl.add_child(_stage)
	tl.add_child(_zone)

	var tr := VBoxContainer.new()
	tr.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	tr.offset_left = -260
	tr.offset_right = -28
	tr.offset_top = 22
	tr.offset_bottom = 120
	tr.alignment = BoxContainer.ALIGNMENT_BEGIN
	tr.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(tr)
	_light = UIStyle.label("", 30)
	_light.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dmg = UIStyle.label("", 15, true, Color(Palette.INK, 0.6))
	_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(_light)
	tr.add_child(_dmg)

	_music = UIStyle.button("♪", 26)
	_music.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	_music.offset_left = 22
	_music.offset_top = -64
	_music.offset_right = 72
	_music.offset_bottom = -18
	_music.pressed.connect(_toggle_music)
	add_child(_music)

	_tree = UIStyle.button("árbol", 22)
	_tree.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_tree.offset_left = -120
	_tree.offset_top = -64
	_tree.offset_right = -26
	_tree.offset_bottom = -18
	_tree.pressed.connect(func() -> void: tree_pressed.emit())
	add_child(_tree)
	_dot = UIStyle.label("●", 14)
	_dot.position = Vector2(-8, 4)
	_dot.visible = false
	_tree.add_child(_dot)

	_hint = UIStyle.label("", 18, true, Color(Palette.INK, 0.55))
	_hint.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
	_hint.offset_left = -200
	_hint.offset_right = 200
	_hint.offset_top = -70
	_hint.offset_bottom = -40
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	GameState.hit.connect(_on_hit)
	_update_music_icon()


func _on_hit(_damage: float, _crit: bool, source: String) -> void:
	if source == "tap":
		_total_taps += 1


func _process(_delta: float) -> void:
	var g := GameState
	var col := Palette.chapter_color(Palette.chapter_of(g.stage))
	_put_text(_stage, "%s / %d" % [Fmt.pad3(g.stage), g.FINAL])
	_put_text(_zone, Zones.label(Zones.of(g.stage)))
	_put_text(_light, "◆ %s" % Fmt.num(g.light))
	_light.add_theme_color_override("font_color", col.darkened(0.15))
	_put_text(_dmg, "%s por tap" % Fmt.num(g.power()))
	var buyable := g.any_buyable()
	_dot.visible = buyable
	_dot.add_theme_color_override("font_color", col)

	var hint := ""
	if g.running and not g.finished:
		if _total_taps < 3 and g.stage == 1:
			hint = "tap"
		elif g.time_at_gate > 12.0 and g.taps_at_gate > 25 and g.progress() < 0.25:
			hint = "mejorá el árbol"
	_put_text(_hint, hint)


func _put_text(l: Label, text: String) -> void:
	if _cache.get(l) != text:
		_cache[l] = text
		l.text = text


func _toggle_music() -> void:
	Music.set_enabled(not Music.is_enabled())
	SaveSystem.save_game()
	_update_music_icon()


func _update_music_icon() -> void:
	_music.modulate.a = 1.0 if Music.is_enabled() else 0.35
