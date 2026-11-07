class_name CymaticsFigure
extends Node2D
## The demo's dark stretch (41–45), where the whale sleeps and wakes: instead of the sacred geometry,
## every barrier is a plate of wet pigment glowing in the dark (shaders/cymatics.gdshader, glow). Each
## note played on it (a phrase's note, or the tip's own hits in "the now") sets it vibrating in a new
## mode, and the pigment runs and gathers into that note's figure, Chladni's lines; the figure before
## stays underneath, faint. When the barrier falls its figure blooms and fades, and the next plate waits
## at the next barrier. (tools/cymatics.tscn is the prototype.)

const RADIUS := 170.0
const SETTLE := 1.6          # beats a figure takes to settle
const MODES := [Vector2(1, 2), Vector2(1, 3), Vector2(2, 3), Vector2(1, 4), Vector2(2, 5), Vector2(3, 4),
	Vector2(3, 5), Vector2(2, 7), Vector2(4, 5), Vector2(3, 7), Vector2(5, 6)]
const COLOURS := [Color("#e2b65a"), Color("#9cbbe0"), Color("#d98f86"), Color("#9ccaa2"), Color("#c3a6e0")]
## The degrees the tip's own hits walk (the now has no phrase to play).
const WALK := [3, 5, 6, 7, 5, 8, 6, 9]

var path: PathData

var _layer: CanvasLayer   # over the darkness, following the camera like the world
var _rect: ColorRect
var _mat: ShaderMaterial
var _n := -1
var _notes := 0
var _since := 99.0
var _shiver := 0.0
var _show := 0.0
var _leaving := -1.0


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.size = Vector2.ONE * RADIUS * 2.0
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/cymatics.gdshader")
	_mat.set_shader_parameter("glow", true)
	_mat.set_shader_parameter("aspect", 1.0)
	_mat.set_shader_parameter("radius", 0.48)
	_mat.set_shader_parameter("pigment", COLOURS[0])
	_mat.set_shader_parameter("ghost_pigment", COLOURS[1])
	_mat.set_shader_parameter("alpha", 0.0)
	_rect.material = _mat
	_layer = CanvasLayer.new()
	_layer.layer = 7   # over the darkness (6), with the chaos's pale figures: it glows in the dark
	_layer.follow_viewport_enabled = true
	_layer.add_child(_rect)
	add_child(_layer)
	GameState.hit.connect(_on_hit)
	GameState.gate_broken.connect(_on_broken)


func _on_hit(_d: float, _crit: bool, source: String) -> void:
	if source == "now" or source == "cine" or (source == "tap" and not BuildFlags.PHRASES):
		note(-1)


func _on_broken(_n2: int) -> void:
	if visible:
		_leaving = 0.0


func reset() -> void:
	_n = -1
	_leaving = -1.0
	_show = 0.0


## A note played on the plate: degree `deg` of the arrangement (or the next one, for the tip's own hits).
func note(deg: int) -> void:
	if not visible or _leaving >= 0.0:
		return
	_notes += 1
	if deg < 0:
		deg = WALK[_notes % WALK.size()]
	var before: Vector2 = _mat.get_shader_parameter("mode_now")
	var now_mode: Vector2 = MODES[clampi(deg, 0, MODES.size() - 1)]
	if now_mode == before:
		now_mode = Vector2(now_mode.y, now_mode.x + 1.0)
	_mat.set_shader_parameter("mode_ghost", before)
	_mat.set_shader_parameter("mode_before", before)
	_mat.set_shader_parameter("mode_now", now_mode)
	_mat.set_shader_parameter("ghost_pigment", _mat.get_shader_parameter("pigment"))
	_mat.set_shader_parameter("pigment", COLOURS[int(_notes / 4.0) % COLOURS.size()])
	_since = 0.0
	_shiver = 1.0


func _process(delta: float) -> void:
	var n := GameState.stage
	visible = BuildFlags.is_dark(n) or _leaving >= 0.0
	_layer.visible = visible
	if not visible or path == null:
		return
	if n != _n and _leaving < 0.0:
		_n = n
		_notes = 0
		_mat.set_shader_parameter("seed", float(n) * 3.1)
		_mat.set_shader_parameter("mode_before", Vector2(1, 2))
		_mat.set_shader_parameter("mode_now", Vector2(1, 2))
		_mat.set_shader_parameter("mode_ghost", Vector2(2, 3))
		_since = 99.0
		_show = 0.0
	_since += delta
	_shiver = maxf(0.0, _shiver - delta * 2.5)
	var beat := 60.0 / Music.bpm()
	_mat.set_shader_parameter("change", clampf(_since / (SETTLE * beat), 0.0, 1.0))
	_mat.set_shader_parameter("shiver", _shiver)
	var a := 0.0
	if _leaving >= 0.0:
		# the barrier fell: the figure blooms out a little and fades, then the next plate comes
		_leaving += delta
		a = 1.0 - smoothstep(0.0, 1.8, _leaving)
		_rect.scale = Vector2.ONE * (1.0 + 0.25 * smoothstep(0.0, 1.8, _leaving))
		if _leaving >= 1.8:
			_leaving = -1.0
			_rect.scale = Vector2.ONE
	else:
		_show = minf(1.0, _show + delta / 1.2)
		a = _show * (0.35 + 0.65 * minf(1.0, _notes / 2.0))   # a faint plate until the first notes
	_mat.set_shader_parameter("alpha", a)
	var c := path.gate_pos(_n)
	_rect.position = c - _rect.size * 0.5 * _rect.scale
