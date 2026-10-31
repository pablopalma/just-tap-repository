class_name Darkness
extends CanvasLayer
## Ink darkness creeping in from the screen edges (shaders/darkness.gdshader). Above the world and
## the colour wave, below the UI. Used when the demo ends. invert turns the world below into its
## negative — white on black — for the demo's dark stretch.

var amount := 0.0:
	set(v):
		amount = v
		_mat.set_shader_parameter("amount", v)
		_rect.visible = v > 0.001 or invert > 0.001

var invert := 0.0:
	set(v):
		invert = v
		_mat.set_shader_parameter("invert", v)
		_rect.visible = v > 0.001 or amount > 0.001

var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween
var _invert_tween: Tween


func _init() -> void:
	layer = 6
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/darkness.gdshader")
	_rect.material = _mat
	_rect.visible = false
	add_child(_rect)


func to(target: float, time: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "amount", target, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func invert_to(target: float, time: float) -> void:
	if _invert_tween:
		_invert_tween.kill()
	_invert_tween = create_tween()
	_invert_tween.tween_property(self, "invert", target, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
