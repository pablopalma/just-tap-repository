class_name TreeNodeView
extends Control
## One upgrade in the tree. States: hidden, peeking (dotted, no number), open (solid with level);
## the border takes the chapter colour when affordable and the fill when maxed.

signal chosen(id: String)
signal hovered(id: String)

const R := 30.0
const SIZE := Vector2(120, 100)

var id := ""
var state := 0
## 0..1 watercolour blot behind the node while it appears.
var blot_t := 1.0:
	set(v):
		blot_t = v
		queue_redraw()

var _blot: Array[PackedVector2Array]


func _init(upgrade_id: String) -> void:
	id = upgrade_id
	size = SIZE
	pivot_offset = Vector2(SIZE.x * 0.5, R + 4)
	mouse_filter = MOUSE_FILTER_STOP
	_blot = Watercolor.blob(id.hash(), 6)
	mouse_entered.connect(func() -> void: hovered.emit(id))


func center_offset() -> Vector2:
	return pivot_offset


func _gui_input(e: InputEvent) -> void:
	if state == 2 and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(id)
		accept_event()


func pop() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * 1.22, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Scale 0.2 → 1.12 → 1, rotation −50° → +4° → 0°, opacity 0 → 1 in 1.5 s, with a blot spreading behind.
func appear(delay: float) -> void:
	scale = Vector2.ONE * 0.2
	rotation_degrees = -50.0
	modulate.a = 0.0
	blot_t = 0.0
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.9)
	tw.tween_property(self, "blot_t", 1.0, 1.8)
	tw.tween_property(self, "scale", Vector2.ONE * 1.12, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", 4.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "rotation_degrees", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if state == 0:
		return
	var c := pivot_offset
	var col := Palette.chapter_color(Palette.chapter_of(GameState.stage))
	if blot_t < 1.0:
		var k := blot_t
		Watercolor.draw_alpha(self, _blot, c, R * lerpf(0.2, 1.6, k), col, 0.09 * (1.0 - k))

	var d: Dictionary = Upgrades.DATA[id]
	var font := UIStyle.font()
	if state == 1:
		var segs := 28
		for i in segs:
			if i % 2 == 0:
				var a0 := TAU * i / segs
				draw_arc(c, R, a0, a0 + TAU / segs, 4, Color(Palette.INK, 0.45), 1.2, true)
		draw_string(font, Vector2(0, c.y + R + 22), Loc.upgrade_name(id), HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 15,
			Color(Palette.INK, 0.45))
		return

	var maxed := GameState.is_maxed(id)
	var buyable := GameState.can_buy(id)
	draw_circle(c, R, col if maxed else Palette.PAPER)
	var border := col.darkened(0.1) if buyable else Palette.INK
	draw_arc(c, R, 0.0, TAU, 64, border, 2.6 if buyable else 1.4, true)
	var lv_text := str(GameState.lv(id))
	draw_string(font, Vector2(c.x - R, c.y + 8), lv_text, HORIZONTAL_ALIGNMENT_CENTER, R * 2, 22,
		Palette.PAPER if maxed else Palette.INK)
	draw_string(font, Vector2(0, c.y + R + 22), Loc.upgrade_name(id), HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 15, Palette.INK)
	var price := Loc.t("max") if maxed else "◆ " + Fmt.num(GameState.cost(id))
	draw_string(font, Vector2(0, c.y + R + 40), price, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 13,
		col.darkened(0.15) if buyable else Color(Palette.INK, 0.5))
