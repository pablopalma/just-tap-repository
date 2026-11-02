extends Control
## HUD (§12): barrier counter and zone, light and damage, music toggle, tree button and a contextual hint.

signal tree_pressed

var _stage: Label
var _zone: Label
var _light: Label
var _dmg: Label
var _hint: Label
var _music: Button
var _voice: Button
var _lang: Button
var _tree: Button
var _dot: Label
var _total_taps := 0
var _cache := {}
## Once a run on the beat (or a hold) has happened, its hint is not needed again this session.
var _beat_learned := false
var hold_learned := false
## Main's lesson on the beat is on: its hint stays up the whole time.
var lesson := false
var _praise_t := 0.0


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

	_voice = _bottom_left_button(Loc.t("voice"), 78, 148)
	_voice.pressed.connect(_toggle_voice)
	_lang = _bottom_left_button("", 154, 204)
	_lang.pressed.connect(_toggle_lang)
	_update_lang()

	_tree = UIStyle.button(Loc.t("tree"), 22)
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
	SaveSystem.lang_changed.connect(_update_lang)


func _on_hit(_damage: float, _crit: bool, source: String) -> void:
	if source == "tap":
		_total_taps += 1


## The lesson's run is done: a word for it, for a moment.
func praise() -> void:
	_praise_t = 2.5


func _process(delta: float) -> void:
	var g := GameState
	_praise_t = maxf(0.0, _praise_t - delta)
	var col := Palette.chapter_color(Palette.chapter_of(g.stage))
	_put_text(_stage, "%s / %d" % [Fmt.pad3(g.stage), g.FINAL])
	_put_text(_zone, Zones.label(Zones.of(g.stage)))
	_put_text(_light, "◆ %s" % Fmt.num(g.light))
	_light.add_theme_color_override("font_color", col.darkened(0.15))
	_put_text(_dmg, Loc.t("per_tap") % Fmt.num(g.power()))
	var buyable := g.any_buyable()
	_dot.visible = buyable
	_dot.add_theme_color_override("font_color", col)

	var hint := ""
	_beat_learned = _beat_learned or g.beat_streak >= 3
	hold_learned = hold_learned or g.hold_taps_at_gate >= 4
	if g.running and not g.finished and not g.cinematic:
		if _total_taps < 3 and g.stage == 1:
			hint = Loc.t("hint_tap")
		elif _praise_t > 0.0:
			hint = Loc.t("hint_beat_ok")
		elif lesson:
			hint = Loc.t("hint_beat")
		elif g.time_at_gate > 12.0 and g.taps_at_gate > 25 and g.progress() < 0.25:
			# beside the line there is nothing to open: the nodes are right there
			hint = Loc.t("hint_tree" if _tree.visible else "hint_tree_inline")
		elif not _beat_learned and g.stage >= 4 and g.stage < 12 and g.taps_at_gate > 15:
			hint = Loc.t("hint_beat")
		elif not hold_learned and g.stage >= 6 and g.stage < 20 and g.taps_at_gate > 40:
			hint = Loc.t("hint_hold")
	_put_text(_hint, hint)


func _put_text(l: Label, text: String) -> void:
	if _cache.get(l) != text:
		_cache[l] = text
		l.text = text


func _bottom_left_button(text: String, left: float, right: float) -> Button:
	var b := UIStyle.button(text, 18)
	b.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	b.offset_left = left
	b.offset_top = -62
	b.offset_right = right
	b.offset_bottom = -18
	add_child(b)
	return b


func _toggle_voice() -> void:
	SaveSystem.voice_on = not SaveSystem.voice_on
	SaveSystem.save_game()
	_voice.modulate.a = 1.0 if SaveSystem.voice_on else 0.35


## Subtitles in English or Spanish; the voice stays English.
func _toggle_lang() -> void:
	SaveSystem.set_lang("en" if SaveSystem.lang == "es" else "es")


func _update_lang() -> void:
	_lang.text = SaveSystem.lang
	_voice.text = Loc.t("voice")
	if _tree:  # built after the voice and language buttons
		_tree.text = Loc.t("tree")
	_voice.modulate.a = 1.0 if SaveSystem.voice_on else 0.35


## The light counter swells when light pours in.
func pulse() -> void:
	_light.pivot_offset = Vector2(_light.size.x, _light.size.y * 0.5)
	var tw := create_tween()
	tw.tween_property(_light, "scale", Vector2.ONE * 1.3, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_light, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _toggle_music() -> void:
	Music.set_enabled(not Music.is_enabled())
	SaveSystem.save_game()
	_update_music_icon()


func _update_music_icon() -> void:
	_music.modulate.a = 1.0 if Music.is_enabled() else 0.35
