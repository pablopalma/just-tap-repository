class_name Watercolor
extends RefCounted
## "Deformed polygon in layers" watercolour (design doc §8). Deformation is radial only, so the
## polygons never self-intersect and always triangulate. Shapes are unit-sized: scale when drawing.


static func blob(seed_value: int, layers := 7) -> Array[PackedVector2Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var angles := PackedFloat32Array()
	var radii := PackedFloat32Array()
	for i in 10:
		angles.append(TAU * i / 10.0)
		radii.append(1.0)
	_deform(angles, radii, 2, rng, 0.18)
	var out: Array[PackedVector2Array] = []
	for l in layers:
		var a := angles.duplicate()
		var r := radii.duplicate()
		_deform(a, r, 3, rng, 0.09)
		var pts := PackedVector2Array()
		for i in a.size():
			pts.append(Vector2(cos(a[i]), sin(a[i])) * r[i])
		out.append(pts)
	return out


## Recursive midpoint subdivision; each new point gets a gaussian radial offset proportional to
## the length of the side it splits.
static func _deform(angles: PackedFloat32Array, radii: PackedFloat32Array, depth: int,
		rng: RandomNumberGenerator, amount: float) -> void:
	for d in depth:
		var na := PackedFloat32Array()
		var nr := PackedFloat32Array()
		var n := angles.size()
		for i in n:
			var a0 := angles[i]
			var a1 := angles[(i + 1) % n] + (TAU if i == n - 1 else 0.0)
			na.append(a0)
			nr.append(radii[i])
			var r_mid := (radii[i] + radii[(i + 1) % n]) * 0.5
			var side := (a1 - a0) * r_mid
			na.append((a0 + a1) * 0.5)
			nr.append(maxf(0.25, r_mid + rng.randfn(0.0, side * amount)))
		angles.resize(na.size())
		radii.resize(nr.size())
		for i in na.size():
			angles[i] = na[i]
			radii[i] = nr[i]


## Draw layered blot on `item`. Meant for a multiply-blended canvas item, so "transparency" is a
## lerp toward white rather than alpha.
static func draw_multiply(item: CanvasItem, layers: Array[PackedVector2Array], pos: Vector2,
		radius: float, color: Color, strength: float, rot := 0.0) -> void:
	var c := Color.WHITE.lerp(color, clampf(strength, 0.0, 1.0))
	item.draw_set_transform(pos, rot, Vector2(radius, radius))
	for pts in layers:
		item.draw_colored_polygon(pts, c)
	item.draw_set_transform(Vector2.ZERO)


## Same blot with ordinary alpha, for UI on a plain background.
static func draw_alpha(item: CanvasItem, layers: Array[PackedVector2Array], pos: Vector2,
		radius: float, color: Color, alpha: float) -> void:
	item.draw_set_transform(pos, 0.0, Vector2(radius, radius))
	for pts in layers:
		item.draw_colored_polygon(pts, Color(color, alpha))
	item.draw_set_transform(Vector2.ZERO)
