extends Control
## Upgrade tree (§5). Grows upward like the line. Nodes never appear all at once: each one changing
## state comes in on a 220 ms cascade, with its link drawing in from the parent and a celesta note.

const CASCADE := 0.22
const LINK_TIME := 1.3

var _nodes := {}     # id -> TreeNodeView
var _link := {}      # id -> 0..1 drawn progress of the link to its parent
var _area: Control
var _info: Label
var _light: Label
var _title: Label
var _info_id := "fuerza"


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(Palette.PAPER, 0.95)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	_title = UIStyle.label(Loc.t("tree"), 34)
	var title := _title
	title.position = Vector2(28, 18)
	add_child(title)

	_light = UIStyle.label("", 26)
	_light.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	_light.offset_left = -320
	_light.offset_right = -90
	_light.offset_top = 24
	_light.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_light)

	var close := UIStyle.button("×", 34)
	close.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	close.offset_left = -70
	close.offset_right = -20
	close.offset_top = 10
	close.offset_bottom = 60
	close.pressed.connect(close_panel)
	add_child(close)

	_area = Control.new()
	_area.mouse_filter = MOUSE_FILTER_IGNORE
	_area.draw.connect(_draw_links)
	add_child(_area)

	_info = UIStyle.label("", 17, true, Color(Palette.INK, 0.75))
	_info.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
	_info.offset_left = -360
	_info.offset_right = 360
	_info.offset_top = -64
	_info.offset_bottom = -24
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_info)

	for id in Upgrades.ORDER:
		var n := TreeNodeView.new(id)
		n.chosen.connect(_buy)
		n.hovered.connect(_show_info)
		_area.add_child(n)
		_nodes[id] = n
		_link[id] = 0.0

	resized.connect(_layout)
	GameState.upgrade_bought.connect(_on_bought)
	GameState.reborn.connect(_reset)
	GameState.progress_reset.connect(_reset)
	SaveSystem.lang_changed.connect(_on_lang)
	_layout()


func _on_lang() -> void:
	_title.text = Loc.t("tree")
	_show_info(_info_id)


func _on_bought(_id: String, _level: int) -> void:
	if visible:
		_reveal()


func open_panel() -> void:
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
	_layout()
	_sync_states()
	_reveal()
	_show_info("fuerza")


func close_panel() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(hide)


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		_light.text = "◆ " + Fmt.num(GameState.light)
		_light.add_theme_color_override("font_color",
			Palette.chapter_color(Palette.chapter_of(GameState.stage)).darkened(0.15))
		_area.queue_redraw()


## Area keeps a tree-like aspect, centred, leaving room for the title and the info line.
func _layout() -> void:
	var h := maxf(200.0, size.y - 190.0)
	var w := minf(size.x - 40.0, h * 0.95)
	_area.size = Vector2(w, h)
	_area.position = Vector2((size.x - w) * 0.5, 84.0)
	for id in _nodes:
		var n: TreeNodeView = _nodes[id]
		n.position = _node_point(id) - n.center_offset()


func _node_point(id: String) -> Vector2:
	var p: Vector2 = Upgrades.DATA[id].pos
	return Vector2(p.x / 100.0 * _area.size.x, p.y / 100.0 * _area.size.y)


## States already seen show straight away, without animation.
func _sync_states() -> void:
	for id in Upgrades.ORDER:
		var n: TreeNodeView = _nodes[id]
		var seen := int(GameState.seen.get(id, 0))
		n.state = seen
		n.visible = seen > 0
		_link[id] = 1.0 if seen > 0 else 0.0


func _reveal() -> void:
	var i := 0
	for id in Upgrades.ORDER:
		var st := GameState.state_of(id)
		var was := int(GameState.seen.get(id, 0))
		if st <= was:
			continue
		var n: TreeNodeView = _nodes[id]
		var delay := i * CASCADE
		n.state = st
		n.visible = true
		n.appear(delay)
		if was == 0 and Upgrades.DATA[id].req != "":
			_link[id] = 0.0
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_method(func(v: float) -> void: _link[id] = v, 0.0, 1.0, LINK_TIME) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_link[id] = 1.0
		get_tree().create_timer(delay).timeout.connect(Music.play_celesta.bind(i))
		GameState.seen[id] = st
		i += 1


func _draw_links() -> void:
	for id in Upgrades.ORDER:
		var req: String = Upgrades.DATA[id].req
		var n: TreeNodeView = _nodes[id]
		if req == "" or n.state == 0:
			continue
		var p: float = _link[id]
		if p <= 0.0:
			continue
		var a := _node_point(req)
		var b := _node_point(id)
		var dir := (b - a).normalized()
		a += dir * (TreeNodeView.R + 4)
		b -= dir * (TreeNodeView.R + 4)
		var end := a.lerp(b, p)
		if n.state == 1:
			draw_dashed(a, end)
		else:
			_area.draw_line(a, end, Palette.INK, 1.4, true)


func draw_dashed(a: Vector2, b: Vector2) -> void:
	_area.draw_dashed_line(a, b, Color(Palette.INK, 0.45), 1.2, 6.0, true, true)


func _buy(id: String) -> void:
	if GameState.buy(id):
		var n: TreeNodeView = _nodes[id]
		n.pop()
		_show_info(id)


func _show_info(id: String) -> void:
	_info_id = id
	var d: Dictionary = Upgrades.DATA[id]
	var l := GameState.lv(id)
	var st := GameState.state_of(id)
	if st < 2:
		_info.text = Loc.t("needs") % [Loc.upgrade_name(id), Loc.upgrade_name(d.req), d.req_lv]
		return
	var now := Upgrades.effect_text(id, l)
	var text := Loc.t("level_line") % [Loc.upgrade_name(id), Loc.upgrade_desc(id), l, now]
	if not GameState.is_maxed(id):
		text += "  →  %s" % Upgrades.effect_text(id, l + 1)
	_info.text = text


func _reset() -> void:
	for id in _nodes:
		var n: TreeNodeView = _nodes[id]
		n.state = 0
		n.visible = false
		_link[id] = 0.0
