extends Node2D
## The demo's dark stretch: the tower crumbles. Ink shards break off the line and the barriers and
## fall, turning; dust puffs out where they break; now and then the ground quakes and debris rains
## across the whole view. Main decides when (tap(), quake()); the camera and the landscape shake on
## their own side. In world space, under the tip.

signal quaked(strength: float)

const GRAVITY := 900.0
const MAX_BITS := 260

var path: PathData
## Where the camera looks and how much of the world it shows (Main sets them every frame).
var view_center := Vector2.ZERO
var view_half := Vector2(640, 360)
var active := false
## 0..1: how often it quakes and how much falls.
var intensity := 0.0

var _bits: Array[Dictionary] = []
var _dust: Array[Dictionary] = []
var _quake_t := 4.0


func start(level: float) -> void:
	active = true
	intensity = level
	_quake_t = 2.5


func stop() -> void:
	active = false
	_bits.clear()
	_dust.clear()
	queue_redraw()


## A tap on a barrier in the dark: a few chips fly off it.
func tap(n: int) -> void:
	if not active:
		return
	var g := path.gate_pos(n)
	for i in randi_range(1, 3):
		_shard(g + Vector2(randf_range(-60, 60), randf_range(-8, 8)), Vector2(randf_range(-120, 120), randf_range(-260, -60)))
	if randf() < 0.25:
		Music.crumble_bit()


## The ground gives: debris rains across the view and pieces break off the line below the tip.
func quake(strength: float) -> void:
	var top := view_center.y - view_half.y
	for i in int(lerpf(14.0, 46.0, strength)):
		var p := Vector2(view_center.x + randf_range(-view_half.x, view_half.x), top - randf_range(0.0, view_half.y * 0.4))
		_shard(p, Vector2(randf_range(-40, 40), randf_range(0, 120)), randf_range(1.0, 2.2))
	var n := GameState.stage
	for k in 3:
		var at := path.gate_pos(maxi(1, n - k)) + Vector2(randf_range(-30, 30), randf_range(20, 160))
		for i in 6:
			_shard(at, Vector2(randf_range(-200, 200), randf_range(-220, 40)))
		_dust.append({"p": at, "t": 0.0, "r": randf_range(50, 90)})
	Music.tremor(strength)
	quaked.emit(strength)


func _shard(p: Vector2, v: Vector2, size_mul := 1.0) -> void:
	if _bits.size() >= MAX_BITS:
		_bits.pop_front()
	var s := randf_range(3.0, 9.0) * size_mul
	var pts := PackedVector2Array()
	var corners := randi_range(3, 4)
	for k in corners:
		pts.append(Vector2.from_angle(TAU * k / corners + randf_range(-0.4, 0.4)) * s * randf_range(0.6, 1.2))
	_bits.append({"p": p, "v": v, "rot": randf() * TAU, "spin": randf_range(-6.0, 6.0), "pts": pts,
		"t": 0.0, "life": randf_range(1.4, 2.6), "dark": randf_range(0.55, 0.9)})


func _process(delta: float) -> void:
	if active:
		_quake_t -= delta
		if _quake_t <= 0.0:
			_quake_t = lerpf(11.0, 4.5, intensity) * randf_range(0.8, 1.2)
			quake(clampf(intensity * randf_range(0.7, 1.1), 0.25, 1.0))
		# a slow drizzle of grit along the line, always
		if randf() < delta * lerpf(1.0, 6.0, intensity):
			var g := path.gate_pos(GameState.stage) + Vector2(randf_range(-40, 40), randf_range(0, 400))
			_shard(g, Vector2(randf_range(-30, 30), 0.0), 0.6)
	for i in range(_bits.size() - 1, -1, -1):
		var b: Dictionary = _bits[i]
		b.t += delta
		b.v.y += GRAVITY * delta
		b.v.x *= 1.0 - delta * 0.5
		b.p += b.v * delta
		b.rot += b.spin * delta
		if b.t >= b.life:
			_bits.remove_at(i)
	for i in range(_dust.size() - 1, -1, -1):
		_dust[i].t += delta
		if _dust[i].t > 1.6:
			_dust.remove_at(i)
	if active or not _bits.is_empty() or not _dust.is_empty():
		queue_redraw()


func _draw() -> void:
	for d in _dust:
		var k: float = d.t / 1.6
		draw_circle(d.p, d.r * (0.4 + k), Color(Palette.INK, 0.10 * (1.0 - k)))
	for b in _bits:
		var a := 1.0 - pow(b.t / b.life, 2.0)
		draw_set_transform(b.p, b.rot)
		draw_colored_polygon(b.pts, Color(Palette.INK, b.dark * a))
		draw_set_transform(Vector2.ZERO)
