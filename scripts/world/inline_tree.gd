extends Node2D
## The upgrade tree (BuildFlags.TREE_INLINE; F1 switches back to the panel): not a diagram beside
## the game but branches that grow out of the line itself, around the tip, curving outward and up
## like a plant's. Each upgrade is a node at the end of its branch; an upgrade's branch sprouts from
## the line, or from the branch of the upgrade it needs, the moment it opens, drawing itself with a
## note. The branches ride with the tip as it climbs, and are bought by tapping their nodes, without
## pausing. Main routes taps here first (try_tap); a tap on a node never reaches the barrier.

const FOLLOW := 3.0
const APPEAR := 1.1
const INFO_TIME := 2.6
const NEAR := 55.0     # nodes start this far from the line
const FAR := 330.0     # and reach at most this far out: short, so the world behind stays in view
## Each node hangs on a spring towards its place: when the tip climbs the branches trail a little,
## stretch and swing back. Under-damped, so they bounce once or twice, like a twig.
const SPRING := 26.0
const DAMP := 5.5
## The wind: every branch sways on its own, more at its tip, and more while the line climbs fast.
const SWAY := 7.0
## Where each branch goes. side: +1 right, -1 left; out: 0..1 of the room on that side; dy: height
## against the tip (y down: positive is below it, on the stretch of line already climbed), measured
## along the line, so a node sits beside the line where the line really is, bends and kinks included.
## Branches of upgrades without a requirement, or with "from_line", sprout from the line at line_dy.
const LAYOUT := {
	"fuerza": {"side": 1, "out": 0.22, "dy": 70.0, "line_dy": 190.0},
	"ganancia": {"side": -1, "out": 0.32, "dy": 10.0, "line_dy": 150.0, "from_line": true},
	"pulso": {"side": 1, "out": 0.55, "dy": -40.0},
	"resonancia": {"side": 1, "out": 0.72, "dy": 150.0},
	"corrosion": {"side": -1, "out": 0.78, "dy": -110.0},
	"eco": {"side": 1, "out": 0.82, "dy": -150.0},
	"destello": {"side": 1, "out": 1.0, "dy": 30.0},
}

var camera: Camera2D
var tip: Node2D
var path: PathData
var fx: Node2D
var font: Font
## Main turns it on only while playing (not in the intro, events, cinematics, panoramas or the ending).
var active := false

var _anchor := Vector2.ZERO   # where the tip is, followed a little behind
var _lit := 0.0               # how far up the line, followed a little behind (tip.lit)
var _have_anchor := false
var _p := {}                  # id -> where its node is now (on its spring)
var _v := {}                  # id -> its node's velocity
var _phase := {}              # id -> its own place in the wind
var _wind_t := 0.0
var _gust := 0.0              # 0.. how hard the wind blows: the line climbing fast
var _r := 18.0                # node radius, world units
var _shown := {}              # id -> state already drawn
var _appear := {}             # id -> 0..1 the branch growing and its node drawing itself
var _pop := {}                # id -> 0..1 bounce after buying
var _nudge := {}              # id -> 0..1 shake when it can't be bought yet
var _info_id := ""
var _info_t := 0.0
var _synced := false


func _ready() -> void:
	z_index = 5
	modulate.a = 0.0
	GameState.reborn.connect(_reset)
	GameState.progress_reset.connect(_reset)


func _reset() -> void:
	_shown.clear()
	_appear.clear()
	_synced = false


func _process(delta: float) -> void:
	modulate.a = move_toward(modulate.a, 1.0 if active else 0.0, delta * (2.0 if active else 4.0))
	visible = modulate.a > 0.0
	if camera == null or not visible:
		return
	_sync(delta)
	var lit: float = tip.lit
	if not _have_anchor or absf(lit - _lit) > 900.0:
		# first frame, or a jump: everything straight to its place
		_anchor = tip.position
		_lit = lit
		_have_anchor = true
		_p.clear()
		_v.clear()
	else:
		# Rides with the tip but a little behind it, like something growing in the world.
		var a := 1.0 - exp(-FOLLOW * delta)
		_gust = lerpf(_gust, clampf(absf(lit - _lit) / maxf(delta, 0.001) / 160.0, 0.0, 2.0), minf(1.0, delta * 2.0))
		_anchor = _anchor.lerp(tip.position, a)
		_lit = lerpf(_lit, lit, a)
	_r = clampf(16.0 / camera.zoom.x, 12.0, 26.0)
	_wind_t += delta * (1.0 + 0.8 * _gust)
	_swing(delta)
	for id in _pop.keys():
		_pop[id] = maxf(0.0, _pop[id] - delta * 1.8)
	for id in _nudge.keys():
		_nudge[id] = maxf(0.0, _nudge[id] - delta * 3.0)
	_info_t = maxf(0.0, _info_t - delta)
	queue_redraw()


## Branches sprout the first time their state goes up, each with a celesta note, one after another;
## the states the player has already seen come in silently.
func _sync(delta: float) -> void:
	var i := 0
	for id in Upgrades.ORDER:
		var st := GameState.state_of(id)
		var was: int = _shown.get(id, 0)
		if st > was:
			_shown[id] = st
			if _synced:
				_appear[id] = -0.25 * i
				get_tree().create_timer(0.25 * i).timeout.connect(Music.play_celesta.bind(i))
				i += 1
			else:
				_appear[id] = 1.0
		elif st < was:
			_shown[id] = st
		if _appear.has(id):
			_appear[id] = minf(1.0, _appear[id] + delta / APPEAR)
	_synced = true


## A phone held upright: little room on either side, so the subtitles go up out of the way.
func is_narrow() -> bool:
	return _room() < 260.0


## Main used to hold the camera lower for the old layout; the branches need no room of their own.
func lift() -> float:
	return 0.0


## How far out a node can go on either side of the line, in world units.
func _room() -> float:
	var half_w := View.size(get_viewport_rect().size).x * 0.5 / camera.zoom.x
	return clampf(half_w - 40.0 / camera.zoom.x - absf(_anchor.x - camera.position.x), NEAR + 60.0, FAR)


## Where the line is, `back` units below the tip along it (negative: above it).
func _on_line(back: float) -> Vector2:
	return path.pos_at(maxf(0.0, _lit - back))


## Where node `id` wants to be: beside the line, at its height, swaying in the wind.
func _target(id: String) -> Vector2:
	var l: Dictionary = LAYOUT[id]
	var out := lerpf(NEAR, _room(), float(l.out))
	var at := _on_line(float(l.dy) * _scale_y()) + Vector2(out * int(l.side), 0.0)
	if not _phase.has(id):
		_phase[id] = float(Upgrades.ORDER.find(id)) * 1.7
	var ph: float = _phase[id]
	var reach := (0.5 + float(l.out)) * SWAY * (1.0 + 0.9 * _gust)
	return at + Vector2(sin(_wind_t * 1.1 + ph) + 0.4 * sin(_wind_t * 2.7 + ph * 2.3),
		0.6 * cos(_wind_t * 0.9 + ph * 1.3)) * reach


## The springs: each node is pulled to its place and overshoots a little.
func _swing(delta: float) -> void:
	var steps := maxi(1, ceili(delta / 0.008))
	var dt := delta / steps
	for id in Upgrades.ORDER:
		var goal := _target(id)
		if not _p.has(id):
			_p[id] = goal
			_v[id] = Vector2.ZERO
			continue
		var p: Vector2 = _p[id]
		var v: Vector2 = _v[id]
		for i in steps:
			v += ((goal - p) * SPRING - v * DAMP) * dt
			p += v * dt
		_p[id] = p
		_v[id] = v


func _point(id: String) -> Vector2:
	return _p.get(id, _target(id))


## Narrow views are taller than wide: spread the branches up and down a little more there.
func _scale_y() -> float:
	return 1.25 if is_narrow() else 1.0


## Where the branch of `id` starts: on the line, or on its parent's node.
func _root(id: String) -> Vector2:
	var l: Dictionary = LAYOUT[id]
	var req: String = Upgrades.DATA[id].req
	if req == "" or l.get("from_line", false):
		return _on_line(float(l.get("line_dy", 150.0)) * _scale_y())
	return _point(req)


## The branch as a curve: it leaves its root sideways and bends up into its node, like the stems
## of a plant reaching for the light.
func _branch(id: String) -> PackedVector2Array:
	var a := _root(id)
	var b := _point(id)
	var side := float(LAYOUT[id].side)
	var span := absf(b.x - a.x)
	var c1 := a + Vector2(side * span * 0.6, 0.0)
	var c2 := b + Vector2(-side * span * 0.05, maxf(40.0, absf(b.y - a.y) * 0.6))
	# Moving, the stem bows back against its node's motion, like a twig through the air.
	var v: Vector2 = _v.get(id, Vector2.ZERO)
	c2 -= v * 0.12
	c1 += v * 0.04
	var pts := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		var u := 1.0 - t
		pts.append(u * u * u * a + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * b)
	return pts


## Called by Main before a tap counts as a hit. True if it landed on a node (it's then used up).
func try_tap(screen_pos: Vector2) -> bool:
	if not visible or modulate.a < 0.5:
		return false
	var world := get_global_transform_with_canvas().affine_inverse() * screen_pos
	# Just the node and a little finger around it (~20 px at least): a tap meant for the barrier that
	# lands near a branch still goes to the barrier.
	var reach := maxf(_r * 1.1, 20.0 / camera.zoom.x)
	var best := ""
	var best_d := reach
	for id in Upgrades.ORDER:
		if int(_shown.get(id, 0)) < 2:
			continue
		var d := world.distance_to(_point(id))
		if d < best_d:
			best = id
			best_d = d
	if best == "":
		return false
	_choose(best)
	return true


func _choose(id: String) -> void:
	_info_id = id
	_info_t = INFO_TIME
	if GameState.buy(id):
		_pop[id] = 1.0
		if fx:
			fx.float_text(_point(id) + Vector2(0, -_r - 6), "%s %d" % [Loc.upgrade_name(id), GameState.lv(id)],
				_col().darkened(0.15), 15)
	else:
		_nudge[id] = 1.0


## The chapter's colour, as the panel uses it: grey until colour comes back.
func _col() -> Color:
	return Palette.chapter_color(Palette.chapter_of(GameState.stage))


func _draw() -> void:
	if font == null:
		return
	var col := _col()
	# Sizes are in world units: with the camera zoom they stay a steady size on screen.
	var z := camera.zoom.x
	var name_size := int(clampf(15.0 / z, 11.0, 44.0))
	var price_size := int(clampf(14.0 / z, 10.0, 40.0))
	var line_w := 1.4 / z
	var beat := pow(1.0 - Music.beat_phase(), 3.0)

	# The branches, growing out of the line (or out of their parent) as they open. A branch that is
	# still closed is a faint dashed sketch of where it will grow.
	for id in Upgrades.ORDER:
		var st: int = _shown.get(id, 0)
		if st == 0:
			continue
		var k := clampf(float(_appear.get(id, 1.0)), 0.0, 1.0)
		if k <= 0.0:
			continue
		var pts := _branch(id)
		var n := maxi(2, int(pts.size() * (1.0 - pow(1.0 - k, 3.0))))
		var grown := pts.slice(0, n)
		if st == 1:
			for i in range(0, grown.size() - 1, 2):
				draw_line(grown[i], grown[i + 1], Color(Palette.INK, 0.3), line_w, true)
		else:
			# thicker where it leaves the line, thinner towards the node
			for i in grown.size() - 1:
				var w := lerpf(2.4, 1.0, float(i) / pts.size()) * line_w
				draw_line(grown[i], grown[i + 1], Color(Palette.INK, 0.7), w, true)

	for id in Upgrades.ORDER:
		var st: int = _shown.get(id, 0)
		if st == 0:
			continue
		var k := clampf((float(_appear.get(id, 1.0)) - 0.55) / 0.45, 0.0, 1.0)  # after its branch
		if k <= 0.0:
			continue
		var c := _point(id) + Vector2(sin(float(_nudge.get(id, 0.0)) * 26.0) * 4.0 * float(_nudge.get(id, 0.0)), 0)
		var pop := sin(float(_pop.get(id, 0.0)) * PI) * 0.22
		var r := _r * (1.0 + pop)
		var sweep := TAU * (1.0 - pow(1.0 - k, 3.0))
		var below := c + Vector2(0, r + name_size + 1)
		if st == 1:
			# a closed bud
			draw_arc(c, r * 0.6, -PI * 0.5, -PI * 0.5 + sweep, 24, Color(Palette.INK, 0.35), line_w, true)
			_text(below, Loc.upgrade_name(id), name_size, Color(Palette.INK, 0.35 * k))
			continue
		var maxed := GameState.is_maxed(id)
		var buyable := GameState.can_buy(id)
		if buyable:
			# Breathes with the beat: a halo opening out on each beat and a bolder rim.
			var ph := Music.beat_phase()
			draw_arc(c, r + (3.0 + 10.0 * ph) / z, 0.0, TAU, 48, Color(col, 0.45 * (1.0 - ph) * k), line_w, true)
			draw_circle(c, r * (1.0 + 0.05 * beat), Color(col, 0.10 + 0.12 * beat))
		draw_circle(c, r, Color(col, k) if maxed else Color(Palette.PAPER, 0.85 * k))
		var rim := col.darkened(0.15) if buyable else Color(Palette.INK, 0.85)
		draw_arc(c, r * (1.0 + (0.05 * beat if buyable else 0.0)), -PI * 0.5, -PI * 0.5 + sweep, 40, rim,
			line_w * (1.9 + 1.0 * beat if buyable else 1.0), true)
		_text(c + Vector2(0, r * 0.36), str(GameState.lv(id)), int(r), Color(Palette.PAPER if maxed else Palette.INK, k))
		_text(below, Loc.upgrade_name(id), name_size, Color(Palette.INK, 0.8 * k))
		var price := Loc.t("max") if maxed else "◆ " + Fmt.num(GameState.cost(id))
		_text(below + Vector2(0, price_size + 2), price, price_size,
			Color(col.darkened(0.2), k) if buyable else Color(Palette.INK, 0.45 * k))

	# What the last touched node does, for a moment, under it.
	if _info_t > 0.0 and _info_id != "":
		var a := minf(1.0, _info_t / 0.5)
		var l := GameState.lv(_info_id)
		var text: String
		if GameState.state_of(_info_id) < 2:
			var d: Dictionary = Upgrades.DATA[_info_id]
			text = Loc.t("needs") % [Loc.upgrade_name(_info_id), Loc.upgrade_name(d.req), d.req_lv]
		elif GameState.is_maxed(_info_id):
			text = "%s · %s" % [Loc.upgrade_name(_info_id), Upgrades.effect_text(_info_id, l)]
		else:
			text = "%s  →  %s" % [Upgrades.effect_text(_info_id, l), Upgrades.effect_text(_info_id, l + 1)]
		var at := _point(_info_id) + Vector2(0, _r + name_size + price_size * 2 + 10)
		_text(at, text, price_size, Color(Palette.INK, 0.7 * a))


func _text(baseline_center: Vector2, text: String, size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# Turned around its own centre so it reads upright whichever way the view is turned (View.angle).
	draw_set_transform(baseline_center, View.angle)
	draw_string(font, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	draw_set_transform(Vector2.ZERO)
