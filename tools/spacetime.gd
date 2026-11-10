extends Node2D
## Prototype (10/11/2026, chapter 10 "Estrella", first planned for chapter 8, docs/brief-juego-completo.md: "la malla del espacio-tiempo"):
## the paper is a mesh seen in perspective, and the light has weight. Where it is, the mesh sinks
## into a well around it, as in the drawings of relativity; the line it follows sinks with it. Only a
## visual: the light still goes along its line. A tap on the beat makes the light heavier for a moment
## (the well deepens) and sends a ripple out across the mesh, a gravitational wave, as it surges ahead.
## Off the beat: a soft tap, a small dip. The well lags behind the light a little, like cloth settling.
## The sky (11/11/2026): deep space and a black hole on the horizon, colossal, the light a speck before
## it (shaders/black_hole.gdshader); the mesh, pale on the dark, runs off towards it.
## The taps sound their own voice (12/11/2026): a soft tone with a slow beat in it, in a big reverb,
## on the theme's scale (D minor pentatonic; the theme sits on D). The hole draws near smoothly; when
## it has come all the way, the cinematic: the hole fills the sky, the mesh drains into it, the light
## falls in, and inside, the light of all the stars it swallowed streams past, until a white light
## ahead takes everything. Then it starts again. `end`: from just before the fall.
## The lens (12/11/2026): as in a real black hole, its gravity bends the light of what is behind it.
## The stars and the galaxy's band stretch into arcs round it and gather in an Einstein ring; the far
## mesh and the line wrap round it. Faint at first, it grows as you come near, and through the fall
## the sky folds in round the shadow. The fall is slow, and the theme muffles and fades as you go in.
## Unfolding (12/11/2026): space is dragged round the spinning hole, a swirl that grows as you near,
## and the lens's second image shows: a flipped copy of the far mesh inside the ring. Falling in, the
## shadow is no longer empty: the matter inside shows through it, and the fall runs on into it.
## The notes (12/11/2026): lights coming down the line from the hole towards the light, one a beat,
## each reaching it as its beat sounds (tap then); pale blue far off, gold as they arrive. They ride
## the mesh and bend through the lens like everything else.
## Close in (13/11/2026): as the hole nears, the camera comes down onto its disk, which becomes the
## floor, a sea of burning gas; the hole grows up over it to one side and its bent light arcs
## overhead, blinding. The mesh and the notes darken to show on it.
## The shake (13/11/2026): a rumble that starts close in and grows through the fall, with jolts now
## and then, harder as you go in, each a surge of speed inside and a deep thud; it calms in the white.
## Tap: space, click, a gamepad's A. Esc: back to the game. `-- auto` plays it on its own.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/spacetime.tscn -- auto  (`log`: the theme and its beat)

const BLUE := Color("#4d84b3")
## The mesh on the dark: pale blue, warming where it sinks (towards the light).
const LINE := Color("#7f9fc4")
const LINE_SUNK := Color("#f1dcae")
## The mesh: a grid on the floor, in world units, drawn from the camera to the far edge.
const SPAN_X := 26.0
const NEAR := 2.0
const FAR := 52.0
const STEP := 1.0          # between the grid's lines
const SUB := 4             # each segment in this many pieces, so the lines can bend
## The camera, above the floor and a little behind the light.
const CAM_H := 3.6
const CAM_BACK := 16.0
const FOCAL := 620.0
const HORIZON := 0.44       # where the camera's eye line meets the screen, from the top
## The well under the light: how deep and how wide (a Gaussian), and the extra weight of a tap.
const DEPTH := 2.8
const WIDTH := 2.6
const TAP_WEIGHT := 1.6
const RIPPLE_SPEED := 9.0  # world units a second
const RIPPLE_LIFE := 3.2
## The hole's pull on the far mesh: the floor sinks away towards it, the line going down into it.
const PULL := 7.0
const NEAR_TAP := 0.003     # over the theme's four minutes, it comes all the way
const NEAR_DRIFT := 0.0012
const SPEED := 2.4         # how far the light goes a second, on its own
const SURGE := 3.2         # and the extra a tap on the beat gives it
const NEAR_EASE := 0.8      # how fast the hole follows where the taps say it is (no jumps)
## The taps' notes: D minor pentatonic (D F G A C), as the theme; a run walks the contour up from D4.
const SCALE := [50, 53, 55, 57, 60, 62, 65, 67, 69, 72, 74, 77, 79, 81, 84, 86]
const CONTOUR := [0, 2, 1, 3, 2, 4, 3, 5, 4, 6, 5, 7]
const BASE_I := 5
## The notes on the line: how many, and how far apart (world units, a beat each).
const NOTES := 5
const NOTE_GAP := 2.6
const VOICE_BUS := "SpaceVerb"
const VOICE_MIDI := 62.0
## The cinematic: the fall (the hole fills the sky, the mesh drains into it), then the way through.
const FALL := 20.0
const THROUGH := 16.0
const AFTER := 3.0

var _auto := false
## `fast`: the hole comes in about a minute, to see the whole approach.
var _fast := false
var _t := 0.0
var _dist := 0.0            # how far along its line the light is
var _surge := 0.0
var _weight := 0.0          # a tap's extra weight, easing out
var _well := Vector2.ZERO   # where the well's centre is (it follows the light, lagging)
var _ripples: Array[Dictionary] = []   # {at: Vector2, t, k}
var _last_beat := -100
var _run := 0
## How near the hole has come (0..1): a little with every tap on the beat, slowly on its own. It grows
## in the sky and its pull bends the far mesh more.
var _near := 0.0
var _near_to := 0.0
var _fall := -1.0           # seconds into the fall, -1 before it
var _through := -1.0        # seconds inside, -1 before
var _voice: AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _player_i := 0
var _spin := 0.0
var _sky_layer: CanvasLayer
var _jolt := 0.0            # the last jolt, easing out
var _next_jolt := 0.0       # seconds to the next one
var _travel := 0.0          # how far through the inside (it surges with each jolt)
var _hole_uv := Vector2(0.5, 0.3)   # the hole on the screen (UV) and its shadow's radius
var _hole_r := 0.2
var _mat: ShaderMaterial
var _sky: ColorRect
var _sky_mat: ShaderMaterial
var _grid: MeshInstance2D
var _grid2: MeshInstance2D       # the lens's second image of the mesh
var _mat2: ShaderMaterial
var _top: Node2D


func _ready() -> void:
	_auto = DevMenu.proto_has("auto")
	_fast = DevMenu.proto_has("fast")
	SaveSystem.enabled = false
	Music.zone = 8
	Music._pending_zone = 8
	Music.start()
	Music.play_feature("spacetime")   # Before the Vastness (docs/banda-sonora.md, 11): the beat follows it
	_well = _line(0.0)
	_build_sky()
	_build_mesh()
	_build_voice()
	if DevMenu.proto_has("end"):
		_near = 0.9
		_near_to = 0.97
	get_viewport().msaa_2d = Viewport.MSAA_4X   # the mesh's lines are one pixel wide


## The light's line on the floor: it winds left and right as it goes ahead.
func _line(d: float) -> Vector2:
	return Vector2(3.2 * sin(d * 0.21) + 1.4 * sin(d * 0.53 + 1.0), d)


func _process(delta: float) -> void:
	_t += delta
	_surge = maxf(0.0, _surge - delta * 2.5)
	_weight = maxf(0.0, _weight - delta * 1.1)
	_dist += delta * (SPEED + SURGE * _surge)
	_near_to = minf(1.0, _near_to + delta * NEAR_DRIFT * (14.0 if _fast else 1.0))
	_near += (_near_to - _near) * minf(1.0, delta * NEAR_EASE)
	if _fall < 0.0 and _near > 0.985:
		_begin_fall()
	if _fall >= 0.0:
		_fall += delta
		_surge = 1.0 + 2.0 * _fall_k()   # the light speeds on, drawn in
		if _fall >= FALL and _through < 0.0:
			_through = 0.0
			_chord([62, 69, 74, 77, 81], -14.0)
	if _through >= 0.0:
		_through += delta
		if _through >= THROUGH + AFTER:
			get_tree().reload_current_scene()
			return
	_well = _well.lerp(_line(_dist), minf(1.0, delta * 4.0))
	for r in _ripples:
		r.t += delta
	_ripples = _ripples.filter(func(r: Dictionary) -> bool: return r.t < RIPPLE_LIFE)
	if _auto and _t > 1.5 and _fall < 0.0:
		var k := Music.beat_at_tap()
		if k >= 0 and k != _last_beat and fmod(_t, 9.0) < 7.0 and randf() > 0.25:
			_tap()
	if DevMenu.proto_has("log") and Engine.get_process_frames() % 90 == 0:
		print("TRACK ", Music.track, " bpm ", Music.bpm(), " heard ", snappedf(Music._heard_time(), 0.01), " near ", snappedf(_near, 0.01))
	_shake(delta)
	_update_mesh()
	_top.queue_redraw()
	queue_redraw()


func _exit_tree() -> void:
	get_viewport().msaa_2d = Viewport.MSAA_DISABLED
	get_viewport().canvas_transform = Transform2D.IDENTITY
	var bus := AudioServer.get_bus_index(VOICE_BUS)
	if bus != -1:
		AudioServer.remove_bus(bus)
	Music.muffle = 20000.0
	var track_bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if track_bus != -1:
		AudioServer.set_bus_volume_db(track_bus, 0.0)


## How strongly the hole bends light: a little from far, more as it comes, most as you fall.
## How far down onto the disk the camera has come (0 the far view, 1 on it).
func _immerse() -> float:
	return smoothstep(0.2, 0.95, _near)


func _cam_h() -> float:
	return lerpf(CAM_H, 1.5, _immerse())


func _horizon() -> float:
	return lerpf(HORIZON, 0.56, _immerse())


func _lens_k() -> float:
	return 0.15 + 0.85 * smoothstep(0.1, 1.0, _near) + 1.2 * smoothstep(0.0, 0.8, _fall_k())


## The Einstein ring's radius, in shadow radii, for the sky; and how much the mesh bends.
func _sky_te() -> float:
	return 1.0 + 0.9 * _lens_k()


func _mesh_te() -> float:
	return 1.6 * _lens_k() * (1.0 - 0.85 * _immerse())   # on the disk the mesh stays down on it, the arch clear


## Where the hole is on the screen and its shadow's radius, in pixels.
func _hole_px() -> Vector3:
	var vp := get_viewport_rect().size
	return Vector3(_hole_uv.x * vp.x, _hole_uv.y * vp.y, _hole_r * vp.y)


## A point on the screen as seen through the lens (the mesh's shader does the same).
func _lens(q: Vector2, far: float) -> Vector2:
	var h := _hole_px()
	var te := _mesh_te()
	if te <= 0.0:
		return q
	var d := (q - Vector2(h.x, h.y)) / h.z
	var b := d.length() + 0.0001
	var th := (b + sqrt(b * b + 4.0 * te * te)) * 0.5
	var behind := smoothstep(0.2, 0.7, far)
	var at := lerpf(b, th, behind)
	var u := (d / b).rotated(_mesh_twist() * behind / (at * at + 0.3))
	return Vector2(h.x, h.y) + u * at * h.z


## Space dragged round the hole: radians at the ring, growing as it nears and as you fall.
func _twist() -> float:
	var k := _lens_k()
	return 0.8 * k * k


## On the disk the mesh lies flat on it: the swirl stays in the sky.
func _mesh_twist() -> float:
	return _twist() * (1.0 - 0.95 * _immerse())


## A parameter for both copies of the mesh.
func _mp(param: String, value: Variant) -> void:
	_mat.set_shader_parameter(param, value)
	_mat2.set_shader_parameter(param, value)


## The camera shakes: a rumble growing from close in through the fall, and jolts, harder and more
## often as you go in. The whole view moves (the sky on its layer, the rest on the canvas).
func _shake(delta: float) -> void:
	var fk := _fall_k()
	var going := fk + (minf(1.0, _through / 6.0) if _through >= 0.0 else 0.0)   # 0..2
	var calm := 1.0 - (smoothstep(THROUGH - 5.0, THROUGH, _through) if _through >= 0.0 else 0.0)
	_jolt = maxf(0.0, _jolt - delta * 2.2)
	if _fall >= 0.0 and calm > 0.2:
		_next_jolt -= delta
		if _next_jolt <= 0.0:
			_next_jolt = lerpf(2.2, 0.7, minf(1.0, going * 0.6)) * randf_range(0.7, 1.3)
			_jolt = minf(1.0, 0.35 + 0.4 * going)
			if _jolt > 0.5:
				_note(38, lerpf(-16.0, -6.0, _jolt))   # a deep thud
	var rumble := (1.5 * _immerse() + 9.0 * smoothstep(0.0, 1.0, fk) + 6.0 * smoothstep(1.0, 2.0, going)) * calm
	var kick := 26.0 * _jolt * _jolt * calm
	var t := _t
	var off := Vector2(sin(t * 37.0) + 0.6 * sin(t * 61.0 + 1.3), cos(t * 41.0) + 0.6 * sin(t * 53.0 + 2.1)) * 0.6 * rumble 		+ Vector2(sin(t * 23.0), cos(t * 19.0)) * kick
	var rot := (sin(t * 29.0) * rumble * 0.0006) + sin(t * 17.0) * kick * 0.0012
	if not is_finite(off.x):
		off = Vector2.ZERO
	var vp := get_viewport_rect().size
	# a touch of zoom, so the shaken view never shows its edges
	var zoom := 1.0 + (rumble * 1.6 + kick * 1.2 + 4.0) / vp.y + absf(rot) * 1.2
	var xf := Transform2D(rot, Vector2.ONE * zoom, 0.0, Vector2.ZERO).translated(off)
	# turn round the screen's centre, not its corner
	xf = Transform2D(0.0, vp * 0.5) * xf * Transform2D(0.0, -vp * 0.5)
	get_viewport().canvas_transform = xf
	if _sky_layer:
		_sky_layer.transform = xf
	# each jolt is a surge of speed inside
	if _fall >= 0.0:
		_travel += delta * (0.8 + 2.2 * _jolt)


func _fall_k() -> float:
	return clampf(_fall / FALL, 0.0, 1.0) if _fall >= 0.0 else 0.0


func _begin_fall() -> void:
	_fall = 0.0
	_note(38, -6.0)                 # a deep D under the theme
	_note(50, -12.0)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		DevMenu.back_to_game(get_tree())
		return
	var pressed: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A)
	if pressed and _fall < 0.0:
		_tap()


func _tap() -> void:
	var k := Music.beat_at_tap()
	if k >= 0 and k != _last_beat:
		_last_beat = k
		_run += 1
		var i: int = BASE_I + CONTOUR[(_run - 1) % CONTOUR.size()] + (2 if (_run - 1) / CONTOUR.size() % 2 == 1 else 0)
		_note(SCALE[mini(i, SCALE.size() - 1)], -15.0)
		if _run >= 8 and _run % 4 == 0:
			_note(SCALE[mini(i + 5, SCALE.size() - 1)], -22.0)   # a long run: an octave shimmer over it
		_near_to = minf(1.0, _near_to + NEAR_TAP)
		_weight = 1.0
		_surge = 1.0
		_ripples.append({"at": _line(_dist), "t": 0.0, "k": 1.0})
	else:
		_run = 0
		_note(50, -24.0)   # off the beat: the low D, barely there
		_weight = maxf(_weight, 0.35)
		_ripples.append({"at": _line(_dist), "t": 0.0, "k": 0.35})


## How far the floor sinks at p: the light's well, deeper with a tap's weight, and the ripples
## running out from where taps landed (a ring of rise and fall, fading as it spreads).
func _height(p: Vector2) -> float:
	var d2 := p.distance_squared_to(_well)
	var depth := DEPTH * (1.0 + TAP_WEIGHT * _weight * _weight)
	var h := -depth * exp(-d2 / (WIDTH * WIDTH * (1.0 + 0.3 * _weight)))
	for r in _ripples.slice(-8):
		var front: float = r.t * RIPPLE_SPEED
		var d: float = p.distance_to(r.at)
		var x := d - front
		var fade: float = (1.0 - r.t / RIPPLE_LIFE) * r.k / (1.0 + front * 0.15)
		h += 0.55 * fade * sin(x * 1.6) * exp(-x * x * 0.35)
	return h + _pull(p)


## The hole's pull: far off, the floor sinks away towards it, more as it comes nearer. Same as the
## mesh's shader.
func _pull(p: Vector2) -> float:
	var cam := Vector2(_well.x * 0.6, _dist - CAM_BACK)
	var far := clampf((p.y - cam.y) / FAR, 0.0, 1.0)
	var dx := p.x - cam.x
	var sp := 5.0 + 12.0 * far
	return -_pull_k() * pow(far, 2.2) * exp(-dx * dx / (2.0 * sp * sp))


func _pull_k() -> float:
	return PULL * (0.6 + 0.8 * _near) * (1.0 - 0.75 * _immerse()) * (1.0 + 7.0 * pow(_fall_k(), 1.6))


## The taps' voice, made here: a tone with a slow beat in it (two sines a few cents apart), a soft
## overtone that fades first, a gentle attack and a long tail, played in a big reverb.
func _build_voice() -> void:
	var rate := 44100
	var n := int(rate * 4.5)
	var data := PackedByteArray()
	data.resize(n * 2)
	var f := 440.0 * pow(2.0, (VOICE_MIDI - 69.0) / 12.0)
	for i in n:
		var t := float(i) / rate
		var env := (1.0 - exp(-t / 0.05)) * exp(-t / 1.4)
		var v := sin(TAU * f * t) + 0.7 * sin(TAU * f * 1.0045 * t) \
			+ 0.3 * exp(-t / 0.7) * sin(TAU * 2.0 * f * t) + 0.1 * exp(-t / 0.3) * sin(TAU * 3.01 * f * t)
		data.encode_s16(i * 2, int(clampf(v * env * 0.45, -1.0, 1.0) * 32767.0))
	_voice = AudioStreamWAV.new()
	_voice.format = AudioStreamWAV.FORMAT_16_BITS
	_voice.mix_rate = rate
	_voice.data = data
	var bus := AudioServer.get_bus_index(VOICE_BUS)
	if bus == -1:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, VOICE_BUS)
		AudioServer.set_bus_send(bus, &"Master")
		var verb := AudioEffectReverb.new()
		verb.room_size = 0.95
		verb.damping = 0.25
		verb.spread = 1.0
		verb.wet = 0.55
		verb.dry = 0.75
		verb.hipass = 0.15
		AudioServer.add_bus_effect(bus, verb)
	for i in 10:
		var pl := AudioStreamPlayer.new()
		pl.bus = VOICE_BUS
		add_child(pl)
		_players.append(pl)


## One note of the voice, at a MIDI pitch (the sample sped up or slowed down).
func _note(midi: float, db: float) -> void:
	var pl := _players[_player_i % _players.size()]
	_player_i += 1
	pl.stream = _voice
	pl.pitch_scale = pow(2.0, (midi - VOICE_MIDI) / 12.0)
	pl.volume_db = db
	pl.play()


func _chord(notes: Array, db: float) -> void:
	for m in notes:
		_note(m, db)


## World (x on the floor across, z ahead, h up) to the screen. The camera follows the light.
func _project(x: float, z: float, h: float) -> Vector3:
	var vp := get_viewport_rect().size
	var cam_z := _dist - CAM_BACK
	var cam_x := _well.x * 0.6
	var dz := z - cam_z
	if dz < 0.5:
		return Vector3(0, 0, -1)
	var s := FOCAL * (vp.y / 720.0) / dz
	return Vector3(vp.x * 0.5 + (x - cam_x) * s, vp.y * _horizon() + (_cam_h() - h) * s, dz)


## The sky: a full-screen rect behind everything, the black hole drawn by its shader.
func _build_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	_sky_layer = layer
	_sky = ColorRect.new()
	_sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = load("res://shaders/black_hole.gdshader")
	_sky.material = _sky_mat
	layer.add_child(_sky)
	add_child(layer)


## The mesh is drawn on the GPU (shaders/spacetime.gdshader): a grid of short line pieces around
## the camera, moved along by `origin` in whole steps so it seems to stay put on the floor.
func _build_mesh() -> void:
	var pts := PackedVector2Array()
	var piece := STEP / SUB
	var xs := int(SPAN_X / STEP) + 1
	var zs := int(FAR / STEP) + 2
	for zi in zs + 1:
		for xi in range(-xs * SUB, xs * SUB):
			pts.append(Vector2(xi * piece, zi * STEP))
			pts.append(Vector2((xi + 1) * piece, zi * STEP))
	for xi in range(-xs, xs + 1):
		for zi in zs * SUB:
			pts.append(Vector2(xi * STEP, zi * piece))
			pts.append(Vector2(xi * STEP, (zi + 1) * piece))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	# never culled: the shader moves every vertex far from where the mesh says it is
	mesh.custom_aabb = AABB(Vector3(-1e5, -1e5, -1), Vector3(2e5, 2e5, 2))
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/spacetime.gdshader")
	_mat2 = ShaderMaterial.new()
	_mat2.shader = _mat.shader
	_mat2.set_shader_parameter("image", -1.0)
	_mp("ink", LINE)
	_mp("blue", LINE_SUNK)
	_mp("cam_h", CAM_H)
	_mp("focal", FOCAL)
	_mp("horizon", HORIZON)
	_mp("far_span", FAR)
	_grid = MeshInstance2D.new()
	_grid.mesh = mesh
	_grid.material = _mat
	_grid2 = MeshInstance2D.new()
	_grid2.mesh = mesh
	_grid2.material = _mat2
	add_child(_grid2)
	add_child(_grid)
	_top = Node2D.new()
	_top.draw.connect(func() -> void:
		_draw_path()
		_draw_notes()
		_draw_light())
	add_child(_top)


func _update_mesh() -> void:
	var cam := Vector2(_well.x * 0.6, _dist - CAM_BACK)
	var vp := get_viewport_rect().size
	_sky_mat.set_shader_parameter("aspect", vp.x / vp.y)
	_spin += get_process_delta_time() * (0.25 + 1.2 * _fall_k())   # dragged round faster as you fall
	_sky_mat.set_shader_parameter("spin", _spin)
	# the hole hardly moves: it is that far; the camera's sway shifts it only a touch
	var fk := _fall_k()
	var grow := pow(fk, 3.0)
	var im := _immerse()
	var radius := 0.2 + 0.14 * _near + 0.3 * im * im + 0.25 * smoothstep(0.0, 0.6, fk) + 2.6 * grow
	_sky_mat.set_shader_parameter("radius", radius)
	var at := Vector2(0.5 - cam.x * 0.004, HORIZON - 0.55 * (0.2 + 0.14 * _near))
	at = at.lerp(Vector2(0.46, 0.74), smoothstep(0.0, 1.0, im))   # a dome standing on the horizon
	_hole_uv = at.lerp(Vector2(0.5, 0.5), smoothstep(0.0, 0.7, fk))
	_hole_r = radius
	_sky_mat.set_shader_parameter("center", _hole_uv)
	var inside := 0.0
	if _through >= 0.0:
		inside = smoothstep(0.0, 2.5, _through)
	_sky_mat.set_shader_parameter("inside", inside)
	_sky_mat.set_shader_parameter("fall", fk)
	_sky_mat.set_shader_parameter("te", _sky_te())
	_sky_mat.set_shader_parameter("immerse", im)
	_sky_mat.set_shader_parameter("horizon", _horizon())
	_sky_mat.set_shader_parameter("cam_h", _cam_h())
	_sky_mat.set_shader_parameter("focal_k", FOCAL / 720.0)
	_sky_mat.set_shader_parameter("cam_pos", cam)
	_sky_mat.set_shader_parameter("flow", _spin * 0.6)
	_mp("cam_h", _cam_h())
	_mp("horizon", _horizon())
	# the mesh: pale on the dark far off, dark ink on the bright disk close in
	_mp("ink", LINE.lerp(Color(0.32, 0.13, 0.04), im))
	_mp("blue", LINE_SUNK.lerp(Color(0.2, 0.06, 0.02), im))
	var hole := _hole_px()
	_mp("hole_px", Vector2(hole.x, hole.y))
	_mp("hole_r_px", hole.z)
	_mp("mesh_te", _mesh_te())
	# the theme muffles and fades as you fall in, as if its sound stretched away
	Music.muffle = lerpf(20000.0, 500.0, pow(smoothstep(0.1, 0.9, fk), 0.6))
	var bus := AudioServer.get_bus_index(Music.TRACK_BUS)
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, lerpf(0.0, -14.0, smoothstep(0.3, 1.0, fk)) if _through < 0.0
			else lerpf(-14.0, -4.0, smoothstep(0.0, 6.0, _through)))
	_sky_mat.set_shader_parameter("travel", _travel)
	_sky_mat.set_shader_parameter("reveal", smoothstep(0.03, 0.45, fk))
	_sky_mat.set_shader_parameter("twist", _twist())
	_mp("twist", _mesh_twist())
	_mat2.set_shader_parameter("image_alpha", smoothstep(0.35, 0.9, _lens_k()) * 0.9 * (1.0 - _immerse()))
	_sky_mat.set_shader_parameter("white", smoothstep(THROUGH - 4.0, THROUGH, _through) if _through >= 0.0 else 0.0)
	_grid.modulate.a = 1.0 - smoothstep(0.45, 0.85, fk)
	_grid2.modulate.a = _grid.modulate.a
	_mp("pull", _pull_k())
	_mp("origin", Vector2(snappedf(cam.x, STEP), floorf((cam.y + NEAR) / STEP) * STEP))
	_mp("cam", cam)
	_mp("screen", get_viewport_rect().size)
	_mp("well", _well)
	_mp("depth", DEPTH * (1.0 + TAP_WEIGHT * _weight * _weight))
	_mp("width2", WIDTH * WIDTH * (1.0 + 0.3 * _weight))
	var rs: Array[Vector4] = []
	for r in _ripples.slice(-8):
		var front: float = r.t * RIPPLE_SPEED
		rs.append(Vector4(r.at.x, r.at.y, front, (1.0 - r.t / RIPPLE_LIFE) * r.k / (1.0 + front * 0.15)))
	_mp("ripple_count", rs.size())
	while rs.size() < 8:
		rs.append(Vector4.ZERO)
	_mp("ripples", rs)


## The light's line: lit behind it, faint ahead; it sinks with the mesh where the light is.
func _draw_path() -> void:
	var pts_lit := PackedVector2Array()
	var pts_ahead := PackedVector2Array()
	var d := _dist - CAM_BACK + NEAR
	while d < _dist + FAR - CAM_BACK:
		var p := _line(d)
		var q := _project(p.x, p.y, _height(p) + 0.02)
		if q.z > 0.0:
			var at := _lens(Vector2(q.x, q.y), clampf((d - (_dist - CAM_BACK)) / FAR, 0.0, 1.0))
			if d <= _dist:
				pts_lit.append(at)
			else:
				if pts_ahead.is_empty() and not pts_lit.is_empty():
					pts_ahead.append(pts_lit[pts_lit.size() - 1])
				pts_ahead.append(at)
		d += 0.25
	var show := 1.0 - smoothstep(0.35, 0.7, _fall_k())
	if pts_ahead.size() > 1:
		_top.draw_polyline(pts_ahead, Color(LINE.lerp(Color(0.25, 0.1, 0.03), _immerse()), 0.55 * show), 1.5, true)
	if pts_lit.size() > 1:
		_top.draw_polyline(pts_lit, Color(Palette.GOLD.darkened(0.15 + 0.4 * _immerse()), 0.9 * show), 3.0, true)


## The notes coming down the line to the light: the k-th lands on the k-th beat from now.
func _draw_notes() -> void:
	var show := 1.0 - smoothstep(0.0, 0.25, _fall_k())
	if show <= 0.0:
		return
	var ph := Music.heard_phase()
	var vp := get_viewport_rect().size
	for k in NOTES:
		var ahead := (k + 1.0 - ph) * NOTE_GAP
		var d := _dist + ahead
		var p := _line(d)
		var q := _project(p.x, p.y, _height(p) + 0.12)
		if q.z <= 0.0:
			continue
		var at := _lens(Vector2(q.x, q.y), clampf((d - (_dist - CAM_BACK)) / FAR, 0.0, 1.0))
		var near := 1.0 - ahead / (NOTE_GAP * NOTES)
		var a := show * smoothstep(0.0, 0.3, near)
		var size := clampf(0.16 * FOCAL * (vp.y / 720.0) / q.z, 1.5, 9.0)
		var col := Color(0.75, 0.88, 1.0).lerp(Palette.GOLD, smoothstep(0.55, 0.92, near))
		# on the bright disk: deep blue notes with a dark rim, so they show
		col = col.lerp(Color(0.1, 0.18, 0.4).lerp(Color(0.35, 0.12, 0.02), smoothstep(0.55, 0.92, near)), _immerse())
		_top.draw_circle(at, size * 1.35, Color(0.05, 0.03, 0.02, 0.35 * a * _immerse()))
		_top.draw_circle(at, size * 2.6, Color(col, 0.18 * a))
		_top.draw_circle(at, size, Color(col, 0.95 * a))
	# the beat: the note lands in the light and opens a ring
	var land := 1.0 - minf(1.0, ph / 0.25)
	if land > 0.0:
		var lp := _line(_dist)
		var lq := _project(lp.x, lp.y, _height(lp) + 0.15)
		if lq.z > 0.0:
			_top.draw_arc(Vector2(lq.x, lq.y), lerpf(12.0, 30.0, 1.0 - land), 0.0, TAU, 40,
				Color(Palette.GOLD, 0.75 * land * show), 1.8, true)


## The light, sitting at the bottom of its well.
func _draw_light() -> void:
	var p := _line(_dist)
	var q := _project(p.x, p.y, _height(p) + 0.15)
	if q.z <= 0.0:
		return
	var c := Vector2(q.x, q.y)
	var s := 1.0 + 0.35 * _weight
	var fk := _fall_k()
	if fk > 0.0:
		# drawn into the hole: to its centre, smaller and smaller
		var vp := get_viewport_rect().size
		var e := smoothstep(0.35, 0.95, fk)
		c = c.lerp(vp * 0.5, e)
		s *= 1.0 - 0.85 * e
		if _through >= 0.0:
			return
	var ph := Music.heard_phase()
	var beat := pow(1.0 - minf(1.0, fposmod(ph + 0.06, 1.0) / 0.3), 2.0)
	for i in 5:
		var k := i / 4.0
		_top.draw_circle(c, lerpf(46.0, 12.0, k) * s, Color(Palette.GOLD, (0.05 + 0.04 * beat) * (0.5 + k)))
	_top.draw_circle(c, 9.0 * s, Color(0.08, 0.04, 0.02, 0.45 * _immerse()))   # a dark rim on the bright disk
	_top.draw_circle(c, 7.0 * s, Color(1.0, 0.97, 0.88))
	_top.draw_circle(c, 3.5 * s, Palette.GOLD.darkened(0.2))
