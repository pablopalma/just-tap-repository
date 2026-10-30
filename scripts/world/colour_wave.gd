class_name ColourWave
extends CanvasLayer
## The colour wave (shaders/colour_wave.gdshader): a full-screen pass above the world and below the
## UI. pass_wave() sends a wet-edged ring of pigment across the world; reveal() first drains the
## world to grey and then lets the new colour flood back from a point.

const MAX_WAVES := 8
const LIFE := 9.0
const DRAIN_TIME := 0.45

var _rect: ColorRect
var _mat: ShaderMaterial
var _waves: Array[Dictionary] = []  # {pos, t, reveal, tint}
var _t := 0.0
var _drain := 0.0
var _drain_tween: Tween


func _ready() -> void:
	layer = 5
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/colour_wave.gdshader")
	_rect.material = _mat
	add_child(_rect)
	_rect.visible = false


## Drop every wave and give the colour back at once.
func clear() -> void:
	_waves.clear()
	if _drain_tween:
		_drain_tween.kill()
	_drain = 0.0
	_rect.visible = false


## A ring of pigment passing through: for zone endings, the bird, finished structures.
func pass_wave(world_pos: Vector2, tint: Color, delay := 0.0) -> void:
	_add(world_pos, tint, false, delay)


## The colour coming back: drain the world to grey, then flood the colour back from world_pos.
func reveal(world_pos: Vector2, tint: Color) -> void:
	_set_drain(1.0, DRAIN_TIME)
	_add(world_pos, tint, true, DRAIN_TIME + 0.15)


func _add(world_pos: Vector2, tint: Color, is_reveal: bool, delay: float) -> void:
	if _waves.size() >= MAX_WAVES:
		_waves.pop_front()
	_waves.append({"pos": world_pos, "t": _t + delay, "reveal": is_reveal, "tint": tint})
	_rect.visible = true


func _set_drain(target: float, time: float) -> void:
	if _drain_tween:
		_drain_tween.kill()
	_drain_tween = create_tween()
	_drain_tween.tween_property(self, "_drain", target, time).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_t += delta
	for i in range(_waves.size() - 1, -1, -1):
		var w: Dictionary = _waves[i]
		if _t - float(w.t) > LIFE:
			# A finished reveal has covered the screen: the colour is simply back.
			if w.reveal:
				_drain = 0.0
			_waves.remove_at(i)
	_rect.visible = not _waves.is_empty() or _drain > 0.001


## Called every frame by Main with the camera's real view.
func update_view(cam_pos: Vector2, cam_zoom: float, cam_offset: Vector2, vp: Vector2) -> void:
	if not _rect.visible:
		return
	var waves := PackedVector4Array()
	var tints := PackedVector4Array()
	for i in MAX_WAVES:
		if i < _waves.size():
			var w: Dictionary = _waves[i]
			var p: Vector2 = w.pos
			var c: Color = w.tint
			waves.append(Vector4(p.x, p.y, w.t, 1.0 if w.reveal else 0.0))
			tints.append(Vector4(c.r, c.g, c.b, 1.0))
		else:
			waves.append(Vector4.ZERO)
			tints.append(Vector4.ONE)
	_mat.set_shader_parameter("waves", waves)
	_mat.set_shader_parameter("tints", tints)
	_mat.set_shader_parameter("wave_count", _waves.size())
	_mat.set_shader_parameter("now", _t)
	_mat.set_shader_parameter("drain", _drain)
	_mat.set_shader_parameter("cam_pos", cam_pos + cam_offset)
	_mat.set_shader_parameter("cam_zoom", cam_zoom)
	_mat.set_shader_parameter("view_size", vp)
	_mat.set_shader_parameter("beat_hz", Zones.BPM[Music.zone - 1] / 60.0)
