extends Node2D
## Watercolour washes with multiply blending (§7.5, §8): an aura that spreads when a barrier breaks
## and the giant blot that opens when a colour comes back.

var _shapes: Array = []  # a few prebuilt blots, reused
var _items: Array[Dictionary] = []


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	material = mat
	for i in 6:
		_shapes.append(Watercolor.blob(1000 + i * 17, 6))


func clear() -> void:
	_items.clear()
	queue_redraw()


## Spreads from 30 to 260 px in 3 s and fades.
func aura(pos: Vector2, color: Color) -> void:
	_add(pos, color, 30.0, 260.0, 3.0, 0.035)


## The colour coming back: a huge blot opening from the centre over 6 s.
func bloom(pos: Vector2, color: Color, radius: float) -> void:
	_add(pos, color, radius * 0.1, radius, 6.0, 0.045)


func _add(pos: Vector2, color: Color, r0: float, r1: float, life: float, strength: float) -> void:
	_items.append({"pos": pos, "color": color, "r0": r0, "r1": r1, "t": 0.0, "life": life,
		"strength": strength, "shape": randi() % _shapes.size(), "rot": randf() * TAU})


func _process(delta: float) -> void:
	if _items.is_empty():
		return
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		it.t += delta
		if it.t >= it.life:
			_items.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for it in _items:
		var k: float = it.t / it.life
		var e := 1.0 - pow(1.0 - k, 3.0)
		var fade := minf(1.0, k * 6.0) * (1.0 - k)
		var layers: Array[PackedVector2Array] = _shapes[it.shape]
		Watercolor.draw_multiply(self, layers, it.pos, lerpf(it.r0, it.r1, e), it.color,
			it.strength * fade, it.rot)
