extends Camera2D
## Manual exponential smoothing toward a target set by Main (§6.4). Zoom is smoothed in log space.
## Shake is trauma-based: events add trauma, which decays; offset and a slight roll grow with
## trauma², so small hits barely move and big moments really land. A zoom punch adds weight.

const MAX_OFFSET := 11.0
const MAX_ROLL := 0.014
const TRAUMA_DECAY := 1.3

var target_pos := Vector2.ZERO
var target_zoom := 1.0
var k := 2.2
var trauma := 0.0
## Which way the world is seen (View.angle): the zone's own direction. The shake rolls around it.
var angle := 0.0

var _z := 1.0
var _punch := 0.0
var _t := 0.0


func _ready() -> void:
	ignore_rotation = false
	_z = zoom.x


func _process(delta: float) -> void:
	var a := 1.0 - exp(-k * delta)
	position = position.lerp(target_pos, a)
	_z = exp(lerpf(log(_z), log(target_zoom), a))
	_punch *= exp(-7.0 * delta)
	zoom = Vector2.ONE * _z * (1.0 + _punch)

	_t += delta
	trauma = maxf(0.0, trauma - TRAUMA_DECAY * delta)
	var s := trauma * trauma
	offset = Vector2(_wave(1.0), _wave(2.0)) * MAX_OFFSET * s / maxf(0.2, _z)
	rotation = angle + _wave(3.0) * MAX_ROLL * s
	View.angle = angle


## 0..1; 0.1 is a nudge, 1 is the biggest moment.
func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


## Brief zoom-in, e.g. 0.04 = 4 %.
func punch(amount: float) -> void:
	_punch = maxf(_punch, amount)


func snap() -> void:
	position = target_pos
	_z = target_zoom
	zoom = Vector2(_z, _z)


## Smooth pseudo-noise: two incommensurate sines per axis.
func _wave(seed_value: float) -> float:
	return sin(_t * 31.0 + seed_value * 17.0) * 0.6 + sin(_t * 53.0 + seed_value * 7.3) * 0.4
