class_name ModeChoice
extends Control
## How would you like to play? Three ways, named for how they feel (PhraseLine.MODES): breathe (just
## the experience), flow (the phrase as it is), soar (faster, the whole phrase). Asked once, at the
## start of a new game; the choice is kept in the save.

signal chosen(mode: String)

const NAMES := {
	"breathe": {"es": ["respira", "solo la experiencia"], "en": ["breathe", "just the experience"]},
	"flow": {"es": ["fluye", "la frase como es"], "en": ["flow", "the phrase as it is"]},
	"soar": {"es": ["vuela", "más rápido, la frase entera"], "en": ["soar", "faster, the whole phrase"]},
}


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var lang := "en" if SaveSystem.lang == "en" else "es"
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_CENTER)
	box.grow_horizontal = GROW_DIRECTION_BOTH
	box.grow_vertical = GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	add_child(box)
	var title := UIStyle.label("¿cómo quieres tocar?" if lang == "es" else "how would you like to play?", 22, true, Color(Palette.INK, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 70)
	box.add_child(row)
	for i in PhraseLine.ORDER.size():
		var id: String = PhraseLine.ORDER[i]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(col)
		var b := UIStyle.button(NAMES[id][lang][0], 34)
		b.pressed.connect(func() -> void: _pick(id))
		if id == "flow":
			PadFocus.offer(b)
		else:
			PadFocus.reach(b)
		col.add_child(b)
		var sub := UIStyle.label(NAMES[id][lang][1], 15, true, Color(Palette.INK, 0.5))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(sub)
		var dots := UIStyle.label("● ".repeat(i + 1).strip_edges(), 12, false, Color(Palette.GOLD.darkened(0.1), 0.9))
		dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(dots)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.0)


func _pick(id: String) -> void:
	Telemetry.event("mode", {"mode": id})
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void:
		chosen.emit(id)
		queue_free())
