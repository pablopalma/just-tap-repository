class_name Structures
extends RefCounted
## Giant background structures, one per zone, built bottom-up in ten pieces: one per barrier.
## Each piece is {"lines": Array[PackedVector2Array], "fill": PackedVector2Array}. Coordinates are
## local to the structure's foot, y up is negative. Fills are star-shaped so a fan can fill them.

const PIECES := 10
const KINDS := ["arch", "bridge", "tower", "trees", "dome", "rings", "trees", "bridge", "rings", "lighthouse"]


static func build(z: int) -> Array[Dictionary]:
	var r := RandomNumberGenerator.new()
	r.seed = 9000 + z * 101
	var out: Array[Dictionary] = []
	match KINDS[(z - 1) % KINDS.size()]:
		"arch": out = _arch(r)
		"bridge": out = _bridge(r)
		"tower": out = _tower(r, false)
		"lighthouse": out = _tower(r, true)
		"trees": out = _trees(r)
		"dome": out = _dome(r)
		_: out = _rings(r)
	return out


# --- Shapes -----------------------------------------------------------------

static func _p(lines: Array, fill := PackedVector2Array()) -> Dictionary:
	var typed: Array[PackedVector2Array] = []
	for l in lines:
		typed.append(l)
	return {"lines": typed, "fill": fill}


static func _seg(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b])


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x, y - h), Vector2(x + w, y - h), Vector2(x + w, y),
		Vector2(x, y)])


static func _arc(c: Vector2, r: float, a0: float, a1: float, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, i / float(n))) * r)
	return pts


static func _ellipse(c: Vector2, rx: float, ry: float, rot: float, n := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## Ground: a long horizon stroke the landscape grows from.
static func _ground(r: RandomNumberGenerator, w: float) -> Array:
	var y := 0.0
	var lines := [_seg(Vector2(-w, y), Vector2(w, y))]
	lines.append(_seg(Vector2(-w * 0.7 + r.randf() * 80.0, y + 14.0), Vector2(w * 0.5, y + 14.0)))
	lines.append(_seg(Vector2(-w * 0.3, y + 26.0), Vector2(w * 0.9 - r.randf() * 120.0, y + 26.0)))
	return lines


static func _arch(r: RandomNumberGenerator) -> Array[Dictionary]:
	var half := 150.0 + r.randf() * 40.0
	var pw := 54.0
	var h1 := 240.0
	var h2 := 470.0
	var c := Vector2(0, -h2)
	var out: Array[Dictionary] = []
	out.append(_p(_ground(r, 620.0) + [_rect(-half - pw - 30, 0, (half + pw + 30) * 2, 22)]))
	out.append(_p([_rect(-half - pw, -22, pw, h1)], _rect(-half - pw, -22, pw, h1)))
	out.append(_p([_rect(half, -22, pw, h1)], _rect(half, -22, pw, h1)))
	out.append(_p([_rect(-half - pw, -22 - h1, pw, h2 - h1 - 22)], _rect(-half - pw, -22 - h1, pw, h2 - h1 - 22)))
	out.append(_p([_rect(half, -22 - h1, pw, h2 - h1 - 22)], _rect(half, -22 - h1, pw, h2 - h1 - 22)))
	out.append(_p([_seg(Vector2(-half - pw - 14, -h2), Vector2(-half + 14, -h2)),
		_seg(Vector2(half - 14, -h2), Vector2(half + pw + 14, -h2))]))
	out.append(_p([_arc(c, half + pw, PI, TAU)], _arc(c, half + pw, PI, TAU)))
	out.append(_p([_arc(c, half, PI, TAU)]))
	out.append(_p([_rect(-16, -h2 - half - pw + 4, 32, 40), _seg(Vector2(-half - pw - 20, -h2 - half - pw - 36),
		Vector2(half + pw + 20, -h2 - half - pw - 36))]))
	var top := Vector2(0, -h2 - half - pw - 80)
	var rays := [_arc(top, 22, 0, TAU, 24)]
	for i in 8:
		var d := Vector2.from_angle(TAU * i / 8.0)
		rays.append(_seg(top + d * 30.0, top + d * 60.0))
	out.append(_p(rays))
	return out


static func _bridge(r: RandomNumberGenerator) -> Array[Dictionary]:
	var deck := -260.0 - r.randf() * 60.0
	var span := 160.0
	var out: Array[Dictionary] = []
	var water := _ground(r, 700.0)
	for i in 3:
		water.append(_seg(Vector2(-500 + i * 260, 46 + i * 10), Vector2(-380 + i * 260, 46 + i * 10)))
	out.append(_p(water))
	for i in 4:
		var x := -span * 1.5 + i * span
		out.append(_p([_seg(Vector2(x - span * 0.5, 0), Vector2(x - span * 0.5, deck)),
			_arc(Vector2(x, deck + span * 0.35), span * 0.5, PI, TAU, 20)]))
	out.append(_p([_seg(Vector2(-span * 2.4, deck), Vector2(span * 2.4, deck)),
		_seg(Vector2(-span * 2.4, deck - 16), Vector2(span * 2.4, deck - 16))],
		PackedVector2Array([Vector2(-span * 2, deck), Vector2(-span * 2, deck - 16), Vector2(span * 2, deck - 16),
			Vector2(span * 2, deck)])))
	var rail := PackedVector2Array()
	for i in 25:
		var x := -span * 2.4 + i * span * 0.2
		rail.append(Vector2(x, deck - 16 - (12.0 if i % 2 == 0 else 0.0)))
	out.append(_p([rail]))
	for s in [-1.0, 1.0]:
		var x: float = s * span * 2.0
		out.append(_p([_rect(x - 24, deck - 16, 48, 300), _arc(Vector2(x, deck - 340), 20, PI, TAU, 16)],
			_rect(x - 24, deck - 16, 48, 300)))
	var cables := []
	for s in [-1.0, 1.0]:
		var top := Vector2(s * span * 2.0, deck - 316)
		for k in 4:
			cables.append(_seg(top, Vector2(s * span * (1.6 - k * 0.4), deck - 16)))
	out.append(_p(cables))
	return out


static func _tower(r: RandomNumberGenerator, rays: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(_p(_ground(r, 560.0) + [_rect(-150, 0, 300, 30)], _rect(-150, 0, 300, 30)))
	var y := -30.0
	var w := 230.0 - r.randf() * 30.0
	for i in 7:
		var h := 78.0 - i * 4.0
		var lines := [_rect(-w * 0.5, y, w, h)]
		for k in 3:
			var wx := -w * 0.3 + k * w * 0.3
			lines.append(_arc(Vector2(wx, y - h * 0.45), 8.0, PI, TAU, 8))
			lines.append(_seg(Vector2(wx - 8, y - h * 0.45), Vector2(wx - 8, y - h * 0.15)))
			lines.append(_seg(Vector2(wx + 8, y - h * 0.45), Vector2(wx + 8, y - h * 0.15)))
		out.append(_p(lines, _rect(-w * 0.5, y, w, h)))
		y -= h
		w *= 0.88
	var roof := PackedVector2Array([Vector2(-w * 0.6, y), Vector2(0, y - 120), Vector2(w * 0.6, y), Vector2(-w * 0.6, y)])
	out.append(_p([roof], roof))
	var top := Vector2(0, y - 150)
	var last := [_seg(Vector2(0, y - 120), top), _arc(top, 14, 0, TAU, 20)]
	if rays:
		for i in 12:
			var d := Vector2.from_angle(TAU * i / 12.0)
			last.append(_seg(top + d * 28.0, top + d * (120.0 if i % 2 == 0 else 70.0)))
	out.append(_p(last))
	return out


static func _tree(base: Vector2, h: float, crown: float, r: RandomNumberGenerator) -> Array:
	var top := base + Vector2(r.randf_range(-20, 20), -h)
	var trunk := [_seg(base, top), _seg(base + Vector2(-10, 0), top + Vector2(-3, 30))]
	var branches := []
	for k in 5:
		var at := base.lerp(top, 0.35 + k * 0.13)
		var s := -1.0 if k % 2 == 0 else 1.0
		var tip := at + Vector2(s * crown * (0.5 + r.randf() * 0.3), -40.0 - r.randf() * 50.0)
		branches.append(_seg(at, tip))
		branches.append(_arc(tip, 5, 0, TAU, 10))
	var c := top + Vector2(0, -crown * 0.2)
	var crown_line := [_ellipse(c, crown, crown * 0.75, 0.0, 40), _ellipse(c + Vector2(0, crown * 0.1), crown * 0.6, crown * 0.42, 0.0, 30)]
	return [_p(trunk), _p(branches), _p(crown_line, _ellipse(c, crown, crown * 0.75, 0.0, 40))]


static func _trees(r: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = [_p(_ground(r, 640.0))]
	out.append_array(_tree(Vector2(-230, 0), 330.0 + r.randf() * 60.0, 110.0, r))
	out.append_array(_tree(Vector2(20, 0), 480.0 + r.randf() * 60.0, 150.0, r))
	out.append_array(_tree(Vector2(260, 0), 280.0 + r.randf() * 60.0, 95.0, r))
	return out


static func _dome(r: RandomNumberGenerator) -> Array[Dictionary]:
	var w := 320.0 + r.randf() * 40.0
	var col_h := 220.0
	var out: Array[Dictionary] = []
	out.append(_p(_ground(r, 600.0) + [_rect(-w * 0.6, 0, w * 1.2, 26), _rect(-w * 0.55, -26, w * 1.1, 18)]))
	for k in 4:
		var x := -w * 0.45 + k * w * 0.3
		out.append(_p([_seg(Vector2(x - 10, -44), Vector2(x - 10, -44 - col_h)),
			_seg(Vector2(x + 10, -44), Vector2(x + 10, -44 - col_h)),
			_seg(Vector2(x - 18, -44 - col_h), Vector2(x + 18, -44 - col_h))]))
	var ey := -44 - col_h
	out.append(_p([_rect(-w * 0.55, ey, w * 1.1, 30)], _rect(-w * 0.55, ey, w * 1.1, 30)))
	out.append(_p([_rect(-w * 0.4, ey - 30, w * 0.8, 60)], _rect(-w * 0.4, ey - 30, w * 0.8, 60)))
	var c := Vector2(0, ey - 90)
	out.append(_p([_arc(c, w * 0.4, PI, TAU, 40)], _arc(c, w * 0.4, PI, TAU, 40)))
	var ribs := []
	for k in 5:
		var a := PI + PI * (k + 1) / 6.0
		ribs.append(_seg(c + Vector2.from_angle(a) * w * 0.4, c + Vector2(0, -w * 0.4)))
	out.append(_p(ribs))
	var lan := c + Vector2(0, -w * 0.4)
	out.append(_p([_rect(-16, lan.y, 32, 46), _arc(lan + Vector2(0, -64), 12, 0, TAU, 16)]))
	return out


static func _rings(r: RandomNumberGenerator) -> Array[Dictionary]:
	var c := Vector2(0, -420.0 - r.randf() * 40.0)
	var R := 190.0
	var out: Array[Dictionary] = []
	out.append(_p(_ground(r, 580.0) + [PackedVector2Array([Vector2(-90, 0), Vector2(-50, -40), Vector2(50, -40),
		Vector2(90, 0)])]))
	out.append(_p([_seg(Vector2(-14, -40), Vector2(-14, c.y + R)), _seg(Vector2(14, -40), Vector2(14, c.y + R))],
		_rect(-14, -40, 28, -40 - (c.y + R))))
	out.append(_p([_ellipse(c, R, R, 0.0, 64)], _ellipse(c, R, R, 0.0, 64)))
	out.append(_p([_ellipse(c, R * 0.35, R, 0.0, 48)]))
	out.append(_p([_ellipse(c, R, R * 0.3, 0.0, 48)]))
	out.append(_p([_ellipse(c, R * 0.95, R * 0.3, 0.6, 48)]))
	out.append(_p([_ellipse(c, R * 0.62, R * 0.62, 0.0, 48)]))
	var spokes := []
	for i in 12:
		var d := Vector2.from_angle(TAU * i / 12.0)
		spokes.append(_seg(c + d * R * 0.62, c + d * R))
	out.append(_p(spokes))
	out.append(_p([_ellipse(c, 34, 34, 0.0, 24)], _ellipse(c, 34, 34, 0.0, 24)))
	var star := []
	for i in 8:
		var d := Vector2.from_angle(TAU * i / 8.0 - PI * 0.5)
		star.append(_seg(c + d * (R + 14), c + d * (R + (70.0 if i % 2 == 0 else 36.0))))
	out.append(_p(star))
	return out
