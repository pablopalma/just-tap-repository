extends Camera2D
## Manual exponential smoothing toward a target set by Main (§6.4). Zoom is smoothed in log space.

var target_pos := Vector2.ZERO
var target_zoom := 1.0
var k := 2.2

var _shake := 0.0


func _process(delta: float) -> void:
	var a := 1.0 - exp(-k * delta)
	position = position.lerp(target_pos, a)
	var z := exp(lerpf(log(zoom.x), log(target_zoom), a))
	zoom = Vector2(z, z)
	_shake = maxf(0.0, _shake - delta * 6.0)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 2.0 * _shake


## In Gris the camera barely trembles: 2 px.
func shake() -> void:
	_shake = 1.0


func snap() -> void:
	position = target_pos
	zoom = Vector2(target_zoom, target_zoom)
