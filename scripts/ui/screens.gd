class_name Screens
extends RefCounted
## Full-screen texts: the intro, the zone/chapter title and the ending (§11).


## Empty paper → "just tap" → "if you had a bad day…" → a pulsing prompt. With a saved game the
## prompt becomes two choices: continue (tapping anywhere also continues) or start over, which
## asks for a second tap before erasing anything. A small es/en toggle sits in the corner.
class Intro extends Control:
	signal continue_pressed
	signal new_game_pressed

	const CONFIRM_TIME := 3.0

	var _returning := false
	var _title: Label
	var _tag: Label
	var _prompt: Label
	var _choices: Control
	var _continue: Button
	var _new: Button
	var _lang: Button
	var _confirming := false
	var _confirm_left := 0.0

	func _init(returning: bool) -> void:
		_returning = returning
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(box)
		_title = _centered(UIStyle.label("just tap", 72))
		_tag = _centered(UIStyle.label("if you had a bad day…", 24, true, Color(Palette.INK, 0.75)))
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 60)
		_prompt = _centered(UIStyle.label("", 18, true, Color(Palette.INK, 0.6)))
		_choices = VBoxContainer.new()
		_choices.alignment = BoxContainer.ALIGNMENT_CENTER
		_choices.mouse_filter = MOUSE_FILTER_IGNORE
		_continue = UIStyle.button("", 24)
		_continue.pressed.connect(func() -> void: continue_pressed.emit())
		_new = UIStyle.button("", 17)
		_new.modulate.a = 0.6
		_new.pressed.connect(_on_new)
		_choices.add_child(_continue)
		_choices.add_child(_new)
		for c in [_title, _tag, gap, _prompt if not returning else _choices]:
			box.add_child(c)
			c.modulate.a = 0.0
		# A paper halo keeps the choices readable over the world behind them.
		for l in [_prompt, _continue, _new]:
			l.add_theme_constant_override("outline_size", 10)
			l.add_theme_color_override("font_outline_color", Color(Palette.PAPER, 0.9))
		_lang = UIStyle.button("", 18)
		_lang.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
		_lang.offset_left = 22
		_lang.offset_top = -62
		_lang.offset_right = 80
		_lang.offset_bottom = -18
		_lang.pressed.connect(func() -> void: SaveSystem.set_lang("en" if SaveSystem.lang == "es" else "es"))
		add_child(_lang)
		_refresh()

	func _ready() -> void:
		SaveSystem.lang_changed.connect(_refresh)
		var tw := create_tween()
		tw.tween_interval(0.5)
		tw.tween_property(_title, "modulate:a", 1.0, 3.0)
		tw.parallel().tween_property(_tag, "modulate:a", 1.0, 3.0).set_delay(2.0)
		if _returning:
			tw.tween_property(_choices, "modulate:a", 1.0, 1.2)
		else:
			tw.tween_callback(_pulse)

	func _process(delta: float) -> void:
		if _confirming:
			_confirm_left -= delta
			if _confirm_left <= 0.0:
				_confirming = false
				_refresh()

	func _refresh() -> void:
		_prompt.text = Loc.t("tap_start")
		_continue.text = Loc.t("continue")
		_new.text = Loc.t("confirm_new") if _confirming else Loc.t("new_game")
		_new.add_theme_color_override("font_color",
			Palette.chapter_color(1) if _confirming else Color(Palette.INK, 0.8))
		_lang.text = SaveSystem.lang

	func _on_new() -> void:
		if _confirming:
			new_game_pressed.emit()
			return
		_confirming = true
		_confirm_left = CONFIRM_TIME
		_refresh()

	func _centered(l: Label) -> Label:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l

	func _pulse() -> void:
		var tw := create_tween().set_loops()
		tw.tween_property(_prompt, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_prompt, "modulate:a", 0.25, 1.4).set_trans(Tween.TRANS_SINE)

	func dismiss() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		for b in [_continue, _new, _lang]:
			b.disabled = true
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


## The voice's words, in the chosen language, low on the screen so they never cover a zone title.
class Subtitle extends Control:
	var _label: Label
	var _tween: Tween

	func _init() -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		_label = UIStyle.label("", 26, true, Palette.INK)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.add_theme_constant_override("outline_size", 8)
		_label.add_theme_color_override("font_outline_color", Color(Palette.PAPER, 0.85))
		add_child(_label)
		_label.modulate.a = 0.0
		resized.connect(_place)

	func _place() -> void:
		var w := minf(size.x - 80.0, 820.0)
		_label.size = Vector2(w, 80)
		_label.position = Vector2((size.x - w) * 0.5, size.y * 0.72)

	func show_line(text: String, duration: float) -> void:
		_place()
		_label.text = text
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_label, "modulate:a", 1.0, 1.2)
		_tween.tween_interval(maxf(0.5, duration - 2.7))
		_tween.tween_property(_label, "modulate:a", 0.0, 1.5)


## The creator's letter, near the very end: the game stops being a game for a moment. Paper covers
## the world, the music falls back, and the lines arrive one by one as if being written. The line
## marked "*" in Loc.LETTER lands larger, in gold, after a longer silence. Then "tap to continue".
class Letter extends Control:
	signal finished

	const LINE_GAP := 2.8
	const BEFORE_KEY := 2.2
	const MUSIC_DB := -10.0

	var _lines: Array[Label] = []
	var _prompt: Label
	var _ready_to_leave := false
	var _music_bus := -1

	func _init(taps: int) -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_STOP
		var bg := ColorRect.new()
		bg.color = Palette.PAPER
		bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		bg.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(bg)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(PRESET_CENTER)
		box.offset_left = -380
		box.offset_right = 380
		box.offset_top = -250
		box.offset_bottom = 250
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 10)
		box.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(box)
		for raw in Loc.letter(taps):
			var text: String = raw
			var key := text.begins_with("*")
			var signature := text.begins_with("—")
			var l: Label
			if key:
				l = UIStyle.label(text.substr(1), 40, false, Palette.GOLD.darkened(0.25))
			elif signature:
				l = UIStyle.label(text, 22, true, Color(Palette.INK, 0.75))
			else:
				l = UIStyle.label(text, 23, true, Palette.INK)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if signature else HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.modulate.a = 0.0
			l.set_meta("key", key)
			l.set_meta("signature", signature)
			box.add_child(l)
			_lines.append(l)
		_prompt = UIStyle.label(Loc.t("continue_tap"), 16, true, Color(Palette.INK, 0.5))
		_prompt.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
		_prompt.offset_left = -200
		_prompt.offset_right = 200
		_prompt.offset_top = -70
		_prompt.offset_bottom = -40
		_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_prompt.modulate.a = 0.0
		add_child(_prompt)
		modulate.a = 0.0

	func _ready() -> void:
		_music_bus = AudioServer.get_bus_index(Music.MUSIC_BUS)
		_fade_music(MUSIC_DB, 3.0)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 2.5)
		tw.tween_interval(1.2)
		var voice := _voice_stream()
		if voice:
			_spoken(tw, voice)
		else:
			_written(tw)
		tw.tween_interval(1.5)
		tw.tween_callback(_allow_leave)
		tw.tween_property(_prompt, "modulate:a", 1.0, 1.5)

	## Without a recording: each line at its own pace, a longer silence before the key line.
	func _written(tw: Tween) -> void:
		for l in _lines:
			if l.get_meta("key"):
				tw.tween_interval(BEFORE_KEY)
				tw.tween_callback(Music.choir_swell)
				tw.tween_property(l, "modulate:a", 1.0, 3.0)
				tw.tween_interval(2.5)
			else:
				tw.tween_property(l, "modulate:a", 1.0, 1.6)
				tw.tween_interval(LINE_GAP - 1.6)

	## With audio/voices/vo_letter: the lines follow the recording, each one given a share of its
	## length proportional to its text; the signature comes after the voice ends.
	func _spoken(tw: Tween, voice: AudioStream) -> void:
		tw.tween_callback(_play.bind(voice))
		var total := 0.0
		for l in _lines:
			if not l.get_meta("signature"):
				total += l.text.length()
		var length := voice.get_length()
		for l in _lines:
			if l.get_meta("signature"):
				continue
			var share := length * l.text.length() / maxf(1.0, total)
			var fade := minf(1.2, share)
			if l.get_meta("key"):
				tw.tween_callback(Music.choir_swell)
			tw.tween_property(l, "modulate:a", 1.0, fade)
			tw.tween_interval(maxf(0.0, share - fade))
		for l in _lines:
			if l.get_meta("signature"):
				tw.tween_interval(1.5)
				tw.tween_property(l, "modulate:a", 1.0, 1.6)

	func _voice_stream() -> AudioStream:
		var path := VoiceLines.audio_path("letter")
		if path == "" or not SaveSystem.voice_on:
			return null
		return load(path)

	func _play(voice: AudioStream) -> void:
		var p := AudioStreamPlayer.new()
		p.bus = Narrator.VOICE_BUS
		p.stream = voice
		add_child(p)
		p.play()

	func _allow_leave() -> void:
		_ready_to_leave = true

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.is_pressed():
			_leave()
			accept_event()

	func _unhandled_input(e: InputEvent) -> void:
		if e is InputEventKey and e.is_pressed() and (e as InputEventKey).keycode == KEY_SPACE:
			_leave()
			get_viewport().set_input_as_handled()

	func _leave() -> void:
		if not _ready_to_leave:
			return
		_ready_to_leave = false
		_fade_music(0.0, 3.0)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 2.0)
		tw.tween_callback(finished.emit)
		tw.tween_callback(queue_free)

	func _fade_music(db: float, time: float) -> void:
		if _music_bus == -1:
			return
		var bus := _music_bus
		create_tween().tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
			AudioServer.get_bus_volume_db(bus), db, time)


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
		var b := UIStyle.button(Loc.t("rebirth"), 22)
		b.pressed.connect(func() -> void: rebirth_pressed.emit())
		box.add_child(b)
		SaveSystem.lang_changed.connect(func() -> void: b.text = Loc.t("rebirth"))

	func show_end() -> void:
		visible = true
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 3.0)
