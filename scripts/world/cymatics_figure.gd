class_name CymaticsFigure
extends Node2D
## The demo's dark stretch (41–45), where the whale sleeps and wakes: instead of the sacred geometry,
## every note played (a phrase's note, or the tip's own hits in "the now") paints its figure under the
## light, Chladni's lines in wet pigment (shaders/cymatics.gdshader): it blooms as the note sounds and
## dries away before the next, so each note shows as its own figure. It lives in the world, under the
## line and the light, and the dark's inversion (Darkness) turns its pigment to light: deep below the
## player. (tools/cymatics.tscn is the prototype.)

const RADIUS := 170.0
const SETTLE := 1.6          # beats a figure takes to settle
const MODES := [Vector2(1, 2), Vector2(1, 3), Vector2(2, 3), Vector2(1, 4), Vector2(2, 5), Vector2(3, 4),
	Vector2(3, 5), Vector2(2, 7), Vector2(4, 5), Vector2(3, 7), Vector2(5, 6)]
## The colours it glows in, once the dark inverts them (so the pigment itself is their negative).
const COLOURS := [Color("#e2b65a"), Color("#9cbbe0"), Color("#d98f86"), Color("#9ccaa2"), Color("#c3a6e0")]
const SHOW := 1.6            # beats a figure takes to dry away after its note
## The degrees the tip's own hits walk (the now has no phrase to play).
const WALK := [3, 5, 6, 7, 5, 8, 6, 9]

var path: PathData

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
	_mat.set_shader_parameter("lighten", 0.0)
	_mat.set_shader_parameter("aspect", 1.0)
	_mat.set_shader_parameter("radius", 0.48)
	_mat.set_shader_parameter("pigment", _neg(COLOURS[0]))
	_mat.set_shader_parameter("ghost_pigment", _neg(COLOURS[1]))
	_mat.set_shader_parameter("alpha", 0.0)
	_rect.material = _mat
	add_child(_rect)
	GameState.hit.connect(_on_hit)
	GameState.gate_broken.connect(_on_broken)


## The pigment that turns into colour `c` under the dark's inversion.
static func _neg(c: Color) -> Color:
	return Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b)


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
	_mat.set_shader_parameter("pigment", _neg(COLOURS[int(_notes / 4.0) % COLOURS.size()]))
	_since = 0.0
	_shiver = 1.0


func _process(delta: float) -> void:
	var n := GameState.stage
	visible = BuildFlags.is_dark(n) or _leaving >= 0.0
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
	elif _notes > 0:
		# each note's figure blooms in at once and dries away before the next
		var k := _since / (SHOW * beat)
		a = smoothstep(0.0, 0.08, k) * (1.0 - smoothstep(0.35, 1.0, k))
	_mat.set_shader_parameter("alpha", a)
	var c := path.gate_pos(_n)
	_rect.position = c - _rect.size * 0.5 * _rect.scale
