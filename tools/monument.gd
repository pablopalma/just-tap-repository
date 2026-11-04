extends Node2D
## Prototype (docs/pendientes.md, "El monumento que se parte"): the line climbs a colossal stone
## woman, kneeling with her head bowed: the Divine Mother. She stands against a huge moon, with ruins
## behind her in layers that fade into the haze and dark rubble close in front, so she feels enormous
## next to the light. The camera opens wide at her feet and closes in as the light climbs, nearest at
## her face. Each barrier broken cracks the stone; at the crown the cracks fill with gold and she
## bursts into pieces that hang in the air, the light of her heart showing. Then the light goes down
## on its own, one note of a falling melody on every beat, and the pieces fly back together as it
## passes, but into something new: the Mother standing, in her dress and veil, her cracks mended in
## gold, her hand held out to the little light at her feet. The camera pulls back to show them both;
## she opens her eyes and speaks to it, as a mother to her child. Then the light goes on its way.
## Tap (space, click, a gamepad's A) to break the barriers; on the beat it counts double.
## `-- auto` taps on its own, on the beat; `-- end` starts near the top; `-- rojo` the red chapter's
## colours instead of the blue. To record it:
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/monument.tscn -- auto end

const H := 2000.0            # her height, in world px
const SHARDS := 70
const BARRIERS := 32          # many, close together: the climb lasts the theme's piano and build
const BARRIER_HP := 6.0
const LINE_OFF := 16.0       # the line runs this far outside the stone
const CRACK_REACH := 320.0   # how far a broken barrier's cracks run
const NEAR_ZOOM := 0.62      # the camera close to the light (screen px per world px)
const FOLLOW := 1.4          # how fast the camera's framing changes (1/s): slow, fluid
const OPENING := 3.0         # seconds the first shot shows everything before closing in
## The ending: the gold spreading, the break, the pieces hanging, then the way down.
const GOLD_TIME := 2.6
const BREAK_AT := 1.2 + GOLD_TIME
const DESC_AT := BREAK_AT + 2.2
const DESC_BEATS := 12
const RETURN_BEATS := 1.6    # how long a piece takes to fly home
## Streamers of her veil and dress, loose in the wind: where each starts on her (units of H, y up),
## how long it is, how wide at the root.
const STREAMERS := [
	[Vector2(-0.16, 1.1), 0.75, 0.05], [Vector2(-0.22, 0.95), 0.95, 0.045], [Vector2(-0.27, 0.75), 0.7, 0.04],
	[Vector2(-0.46, 0.06), 0.55, 0.035], [Vector2(-0.4, 0.12), 0.4, 0.03],
]

## Whole again, standing: her gold seams shine and fade as the stone comes alive; she opens her
## eyes, bends down, takes the light in her hand, rises again holding it out on her open palm, and
## speaks to it. Then the light rises from her palm and goes on its way, and the glow comes.
const ALIVE_AT := 0.6
const ALIVE_TIME := 2.0
const EYES_AT := 2.0
const BEND_AT := 2.8
const BEND_TIME := 2.0
const TAKE_AT := BEND_AT + BEND_TIME
const TAKE_TIME := 0.8
const RISE_AT := TAKE_AT + TAKE_TIME
const RISE_TIME := 2.4
## When she is whole the theme is at about 95 s (the break on 84, the way down 12 beats); her words go
## over the climax, and the last line's "…are the ones that shine now" (3.6 s into it) on the drop.
const LINE_AT := [9.4, 15.6, 21.2]
const LINE_TIME := [6.3, 5.1, 6.4]   # each voice's length and a little after it
const GO_AT := 27.6
const GO_TIME := 4.0
const WHOLE_HOLD := GO_AT + 3.0   # when the glow begins
const GLOW_TIME := 2.5
const GLOW_HOLD := 1.2
## Her joints (x right, y up, in units of H): she bows from the waist, her arm turns at the shoulder.
const WAIST := Vector2(0.08, 0.5)
const SHOULDER := Vector2(0.22, 0.78)
const CHEST := Vector2(0.06, 0.8)     # the spine bends here too, so it curves as she bows
const NECK := Vector2(0.15, 0.88)
const BOW := 0.95            # radians, bent down
const REACH := -0.25         # the arm, bent down: reaching forward
const OFFER := -0.85         # the arm, standing again: raised, the palm held out
## The Mother's words to the light (Spanish in neutral tuteo).
const LINES := {
	"es": ["Mi pequeña luz…\na veces crees que estás rota.", "Pero si sigues,\ntodo vuelve a su lugar.",
		"Y las grietas que tanto dolieron\nson las que ahora brillan."],
	"en": ["My little light…\nsometimes you believe you are broken.", "But if you keep going,\neverything finds its place again.",
		"And the cracks that hurt so much\nare the ones that shine now."],
}
## Her heart, where the light inside shows and the pieces push away from (units of H, y down).
const HEART := Vector2(0.0, -0.5)
## The falling melody, as degrees of the theme's key: phrases stepping down, each starting a little
## lower, the last one coming home.
const MELODY := [9, 8, 7, 6, 7, 6, 5, 4, 4, 2, 1, 0]

## Her outline (x right, y up from the ground, in units of H), smoothed when built: kneeling, facing
## right, her robe on the ground, her knees, her hands joined at her chest, her head bowed (chin,
## lips, nose, forehead), the crown, and her hair falling down her back.
const OUTLINE := [
	Vector2(-0.42, 0.0), Vector2(0.4, 0.0), Vector2(0.43, 0.04), Vector2(0.38, 0.1),       # robe, knee
	Vector2(0.27, 0.15), Vector2(0.22, 0.24), Vector2(0.24, 0.34), Vector2(0.215, 0.42),   # lap, hands
	Vector2(0.15, 0.45), Vector2(0.16, 0.52),                                             # chest, chin
	Vector2(0.19, 0.555), Vector2(0.2, 0.59), Vector2(0.23, 0.615), Vector2(0.205, 0.66),  # lips, nose
	Vector2(0.19, 0.72), Vector2(0.14, 0.78), Vector2(0.06, 0.83), Vector2(-0.04, 0.84),   # forehead, crown
	Vector2(-0.12, 0.8), Vector2(-0.16, 0.7), Vector2(-0.18, 0.56), Vector2(-0.22, 0.42),  # her hair
	Vector2(-0.27, 0.28), Vector2(-0.33, 0.14), Vector2(-0.42, 0.05),
]
const CLIMB_FROM := 2        # the climb follows the outline from this point (the knee)...
const CLIMB_TO := 17         # ...to this one (the crown); the way down, from there to the robe
const SUB := 8               # smoothed points per outline segment
## Where her hair meets her face and shoulders, from the hairline down to the robe.
const HAIRLINE := [Vector2(0.14, 0.78), Vector2(0.09, 0.72), Vector2(0.05, 0.64), Vector2(0.01, 0.54),
	Vector2(-0.04, 0.42), Vector2(-0.1, 0.28), Vector2(-0.18, 0.14), Vector2(-0.3, 0.04)]
## Her arm, from the shoulder to the hands, and the robe's folds.
const ARM := [Vector2(0.02, 0.48), Vector2(0.03, 0.36), Vector2(0.09, 0.28), Vector2(0.18, 0.29), Vector2(0.23, 0.34)]
const FOLDS := [
	[Vector2(0.22, 0.14), Vector2(0.15, 0.07), Vector2(0.09, 0.0)],
	[Vector2(0.07, 0.22), Vector2(0.0, 0.11), Vector2(-0.07, 0.0)],
	[Vector2(-0.1, 0.2), Vector2(-0.17, 0.1), Vector2(-0.26, 0.0)],
]
## The Mother standing, rebuilt (x right, y up, in units of H): her dress to the ground, her waist,
## her arm held out and down with the hand open, her chest, her face bowed towards the light (chin,
## lips, nose, brow), the veil over her head falling down her back to the ground.
const STAND := [
	Vector2(-0.5, 0.0), Vector2(0.36, 0.0), Vector2(0.3, 0.12), Vector2(0.22, 0.32), Vector2(0.16, 0.52),
	Vector2(0.18, 0.62), Vector2(0.21, 0.5), Vector2(0.27, 0.42), Vector2(0.34, 0.43),             # the sleeve, hanging
	Vector2(0.4, 0.455), Vector2(0.455, 0.42), Vector2(0.5, 0.37),                                 # wrist, hand
	Vector2(0.515, 0.395), Vector2(0.465, 0.47), Vector2(0.38, 0.54), Vector2(0.3, 0.64),          # forearm, elbow
	Vector2(0.27, 0.72), Vector2(0.23, 0.79),                                                     # upper arm
	Vector2(0.18, 0.86), Vector2(0.205, 0.9), Vector2(0.225, 0.93), Vector2(0.255, 0.965),        # neck..nose
	Vector2(0.235, 1.0), Vector2(0.225, 1.05), Vector2(0.25, 1.1), Vector2(0.17, 1.2),            # brow, veil
	Vector2(0.04, 1.25), Vector2(-0.1, 1.23), Vector2(-0.2, 1.13), Vector2(-0.25, 0.95),
	Vector2(-0.3, 0.7), Vector2(-0.36, 0.45), Vector2(-0.42, 0.22), Vector2(-0.5, 0.05),
]
const STAND_TOP := 1.25
const STAND_VEIL_FROM := 22  # the veil's edge in the outline, from here to the end
## The veil's inner edge, framing her face and falling over her shoulder down her back.
const VEIL_EDGE := [Vector2(0.245, 1.09), Vector2(0.16, 1.06), Vector2(0.11, 0.98), Vector2(0.09, 0.86),
	Vector2(0.06, 0.76), Vector2(-0.05, 0.55), Vector2(-0.18, 0.3), Vector2(-0.3, 0.1), Vector2(-0.38, 0.0)]
const STAND_LINES := [
	[Vector2(0.16, 0.55), Vector2(0.05, 0.56), Vector2(-0.06, 0.55)],          # her waist
	[Vector2(0.1, 0.5), Vector2(0.13, 0.25), Vector2(0.2, 0.0)],               # the dress's folds
	[Vector2(0.0, 0.5), Vector2(-0.01, 0.25), Vector2(0.03, 0.0)],
	[Vector2(-0.08, 0.47), Vector2(-0.14, 0.22), Vector2(-0.18, 0.0)],
	[Vector2(0.3, 0.63), Vector2(0.28, 0.55), Vector2(0.3, 0.47)],             # the sleeve's fold
	[Vector2(0.37, 0.53), Vector2(0.33, 0.48), Vector2(0.32, 0.44)],
]
const STAND_EYE := Vector2(0.195, 0.995)
const HAND := Vector2(0.49, 0.38)
const STAND_SHARDS := 56
const RADIAL := 20           # points each piece is reshaped with as it flies into its new place

## The two looks: the red chapter's dusk, where the climb begins, and the blue night under the moon it
## turns into as the light climbs (_night, 0..1; `-- rojo` keeps the dusk, `-- azul` the night).
const LOOKS := {
	"azul": {"sky_top": Color("#16223d"), "sky_low": Color("#4d6f9f"), "moon": Color("#f4f0de"),
		"far": Color("#6f90bd"), "mid": Color("#3b5784"), "stone": Color("#2c446c"), "rim": Color("#9cbbe0"),
		"near": Color("#0c1424"), "line": Color("#eae6d6"), "rays": Color("#cfdcff")},
	"rojo": {"sky_top": Color("#e8a597"), "sky_low": Color("#f7dccf"), "moon": Color("#fff8f2"),
		"far": Color("#e07a6e"), "mid": Color("#b03c35"), "stone": Color("#7d1f1f"), "rim": Color("#f0a090"),
		"near": Color("#3a0b0b"), "line": Color("#fff3ea"), "rays": Color("#ffc98a")},
}

var _look: Dictionary
var _night := 0.0
var _night_pin := -1.0
var _sky_grad: Gradient
var _stars_node: Node2D
var _sky_stars: Array[Vector3] = []
var _stone := PackedVector2Array()
var _hair := PackedVector2Array()     # her hair, as a polygon
var _path := PackedVector2Array()     # the climb, a point every 4 px
var _path_len := 0.0
var _desc := PackedVector2Array()     # the way down her back, a point every 4 px
var _gates: Array[float] = []         # where each barrier is along the climb
var _shards: Array[Dictionary] = []
var _cracks: Array[Vector2] = []      # (shard a, shard b) pairs that share an edge
var _edges := {}
var _s := 0.0                         # the light, along the climb
var _target := 0.0
var _gate := 0
var _hp := BARRIER_HP
var _run := 0
var _last_beat := -100
var _kick := 0.0
var _rings: Array[Dictionary] = []    # {p, t}
var _dust: Array[Dictionary] = []     # chips and puffs where the stone breaks
var _specks: Array[Dictionary] = []   # dark flakes drifting in the air, on the screen
var _auto := false
var _t := 0.0
var _ending := -1.0                   # seconds since the crown was reached, or -1
var _desc_start := 0.0                # the music's time of the descent's first beat
var _beat_len := 1.0
var _beats := -1.0                    # beats into the descent, or -1
var _desc_beat := -1
var _whole_t := -1.0                  # seconds since she was whole again, or -1
var _glow := 0.0
var _rng := RandomNumberGenerator.new()
## The camera: how much of everything it shows (0 close on the light, 1 all of her) and where.
var _cam: Camera2D
var _reveal := 1.0
var _reveal_to := 1.0
var _face_s := 0.0                   # where the climb reaches her face
var _lang := "es"
var _font: Font
var _subs: Node2D
var _stand := PackedVector2Array()
var _veil := PackedVector2Array()
var _seams: Array = []               # [a, b]: where the Mother's pieces meet, mended in gold
var _all_c := Vector2(-0.05, -0.47) * H   # what the camera frames when it shows everything
var _all_h := 1.12
var _eyes := 0.0                      # 0 closed, 1 open
var _go := 0.0                        # 0..1, the light going on its way
var _at_crown := false
var _crown_t := 0.0
var _alive := 0.0                     # 0 stone in pieces, 1 one living figure
var _bend := 0.0
var _reach := 0.0
var _offer := 0.0
var _take := 0.0                      # 0 the light on the ground, 1 on her palm
var _gust := 0.0                      # the wind's strength, rising and falling
var _speak := 0.0                     # 0..1, while she holds the light and speaks
var _last_fig := PackedVector2Array()
var _last_veil := PackedVector2Array()
var _last_cam := Vector2.ZERO
var _layers: Array[Dictionary] = []
## The air: volumetric fog between the planes and in front of her, god rays behind and in front.
var _fog_far: ColorRect
var _fog_mid: ColorRect
var _fog_front: ColorRect
var _rays_back: ColorRect
var _rays_front: ColorRect   # {node, k}: the planes behind and in front of her


func _ready() -> void:
	var args: Array = Array(OS.get_cmdline_user_args()) + DevMenu.proto_args
	_auto = "auto" in args
	_night_pin = 0.0 if "rojo" in args else (1.0 if "azul" in args else -1.0)
	_night = maxf(_night_pin, 0.0)
	_tint()
	_lang = "en" if "en" in args else ("es" if "es" in args else SaveSystem.lang)
	_font = load(UIStyle.ITALIC)
	SaveSystem.enabled = false
	Music.zone = 1
	Music._pending_zone = 1
	Music.start()
	Music.prepare_dark()
	Music.play_feature("monument")   # its theme: the climb on the piano and the build, the break on its drop
	_rng.seed = 5
	_stone = _smooth(_flip(OUTLINE), true)
	# her hair: the hairline, then her back from the robe up to the crown
	_hair = _smooth(_flip(HAIRLINE), false)
	var back := PackedVector2Array()
	for i in range((CLIMB_TO + 1) * SUB, OUTLINE.size() * SUB):
		back.append(_stone[i])
	back.reverse()
	_hair.append_array(back)
	_path = _resample(_along(CLIMB_FROM * SUB, CLIMB_TO * SUB))
	_path_len = (_path.size() - 1) * 4.0
	# the way down: from the crown, swaying through the air, to the ground at the Mother's feet,
	# under her open hand
	var down: Array = [_stone[CLIMB_TO * SUB] + Vector2(0, -LINE_OFF)]
	for q in [Vector2(0.35, 0.92), Vector2(0.72, 0.72), Vector2(0.62, 0.4), Vector2(0.66, 0.14), Vector2(0.58, 0.0)]:
		down.append(Vector2(q.x, -q.y) * H)
	down[down.size() - 1] += Vector2(0, -LINE_OFF)
	_desc = _resample(_smooth(down, false))
	_stand = _smooth(_flip(STAND), true)
	_veil = _smooth(_flip(VEIL_EDGE), false)
	_veil.append(Vector2(-0.5, 0.0) * H)
	var vback := PackedVector2Array()
	for i in range(STAND_VEIL_FROM * SUB, STAND.size() * SUB):
		vback.append(_stand[i])
	vback.reverse()
	_veil.append_array(vback)
	var kneel := _pieces(_stone, _hair, SHARDS, Rect2(-0.46 * H, -0.88 * H, 0.92 * H, 0.88 * H))
	var mother := _pieces(_stand, _veil, STAND_SHARDS, Rect2(-0.52 * H, -1.27 * H, 1.1 * H, 1.27 * H))
	_shards.assign(kneel)
	for a in _shards.size():
		for b in range(a + 1, _shards.size()):
			if _shards[a].c.distance_to(_shards[b].c) < 0.32 * H and _touch(_home_poly(a), _home_poly(b)):
				_cracks.append(Vector2(a, b))
	_pair(mother)
	while _face_s < _path_len and _pos_at(_face_s).y > -0.5 * H:
		_face_s += 8.0
	for i in BARRIERS:
		_gates.append(_path_len * (0.1 + 0.9 * (i + 1) / float(BARRIERS)) - 30.0)
	if "end" in args:
		_gate = BARRIERS - 3
		_s = _gates[_gate - 1] + 20.0
		for i in _gate:
			_crack_from(_pos_at(_gates[i]), 0.0)
	_target = _s
	_build_sky()
	# the planes, far to near: the moon, the far ruins, the near ruins; she is at 1; rubble in front
	for spec in [[0.12, _draw_moon, -3], [0.3, _draw_far, -2], [0.55, _draw_mid, -1], [1.35, _draw_near, 2]]:
		var n := Node2D.new()
		n.z_index = spec[2]
		n.draw.connect(spec[1].bind(n))
		add_child(n)
		_layers.append({"node": n, "k": spec[0]})
	# the air, in depth order: fog over the far ruins, fog over the near ones, the rays behind her;
	# in front of her a low mist and fainter rays, so the light is in the air around her too
	_fog_far = _volume("res://shaders/volumetric_fog.gdshader", -2)
	_fog_mid = _volume("res://shaders/volumetric_fog.gdshader", -1)
	_rays_back = _volume("res://shaders/godrays.gdshader", -1)
	_fog_front = _volume("res://shaders/volumetric_fog.gdshader", 1)
	_rays_front = _volume("res://shaders/godrays.gdshader", 1)
	_fog_mid.material.set_shader_parameter("seed", 3.0)
	_fog_front.material.set_shader_parameter("seed", 7.0)
	_rays_front.material.set_shader_parameter("seed", 11.0)
	z_index = 0
	for i in 160:
		_specks.append({"p": Vector2(_rng.randf() * 1280.0, _rng.randf() * 720.0), "v": Vector2(_rng.randf_range(8, 30), _rng.randf_range(-6, 10)),
			"r": _rng.randf_range(1.0, 3.2), "a": _rng.randf() * TAU, "k": _rng.randf_range(0.4, 1.6)})
	var specks := Node2D.new()
	specks.draw.connect(_draw_specks.bind(specks))
	var top := CanvasLayer.new()
	top.layer = 3
	top.add_child(specks)
	_subs = Node2D.new()
	_subs.draw.connect(_draw_subs)
	top.add_child(_subs)
	add_child(top)
	_cam = Camera2D.new()
	add_child(_cam)
	_frame.call_deferred(0.0, true)


## Each piece of her kneeling gets a piece of the Mother standing to become: both sorted top to
## bottom, matched by rank (there are fewer of hers, so each of them is covered). Both shapes are
## sampled the same way around their centres so one can turn into the other.
func _pair(mother: Array) -> void:
	var order := range(_shards.size())
	order.sort_custom(func(a: int, b: int) -> bool: return _shards[a].c.y < _shards[b].c.y)
	var theirs := range(mother.size())
	theirs.sort_custom(func(a: int, b: int) -> bool: return mother[a].c.y < mother[b].c.y)
	for r in order.size():
		var sh: Dictionary = _shards[order[r]]
		var to: Dictionary = mother[theirs[mini(int(r * mother.size() / float(order.size())), mother.size() - 1)]]
		sh.pr = _radial(sh.poly)
		sh.to_c = to.c
		sh.to_pr = _radial(to.poly)
		sh.to_col = to.col
		# the top of her comes back first: the light passes it first
		sh.home_at = clampf((1.0 + to.c.y / (STAND_TOP * H)) * (DESC_BEATS - RETURN_BEATS - 1.0), 0.0, DESC_BEATS - RETURN_BEATS - 1.0)
	# where her pieces meet, once, for the gold seams
	for a in mother.size():
		for b in range(a + 1, mother.size()):
			if mother[a].c.distance_to(mother[b].c) < 0.36 * H:
				var pa := _shift(mother[a].poly, mother[a].c)
				var pb := _shift(mother[b].poly, mother[b].c)
				var shared: Array = []
				for q in pa:
					for w in pb:
						if q.distance_squared_to(w) < 4.0:
							shared.append(q)
							break
				if shared.size() >= 2:
					_seams.append([shared[0], shared[shared.size() - 1]])


func _shift(poly: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in poly:
		out.append(q + by)
	return out


## A piece's shape as RADIAL points around its centre, one per direction (as far as it reaches).
func _radial(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in RADIAL:
		var dir := Vector2.from_angle(TAU * k / RADIAL)
		var far := 0.0
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var hit = Geometry2D.segment_intersects_segment(Vector2.ZERO, dir * 1e5, a, b)
			if hit != null:
				far = maxf(far, (hit as Vector2).length())
		out.append(dir * far)
	return out


## A sky from deep to pale, behind everything.
func _build_sky() -> void:
	var g := Gradient.new()
	g.set_color(0, _look.sky_top)
	g.set_color(1, _look.sky_low)
	_sky_grad = g
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := CanvasLayer.new()
	bg.layer = -5
	bg.add_child(rect)
	_stars_node = Node2D.new()
	_stars_node.draw.connect(_draw_sky_stars)
	bg.add_child(_stars_node)
	add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 140:
		_sky_stars.append(Vector3(rng.randf(), pow(rng.randf(), 1.6) * 0.7, rng.randf() * TAU))


## The colours now: dusk turning to night.
func _tint() -> void:
	var out := {}
	for key in LOOKS.rojo:
		out[key] = (LOOKS.rojo[key] as Color).lerp(LOOKS.azul[key], _night)
	_look = out
	if _sky_grad:
		_sky_grad.set_color(0, _look.sky_top)
		_sky_grad.set_color(1, _look.sky_low)


## Stars coming out as the night falls, twinkling.
func _draw_sky_stars() -> void:
	var a := smoothstep(0.45, 0.95, _night)
	if a <= 0.0:
		return
	var vp := get_viewport_rect().size
	for st in _sky_stars:
		var tw := 0.6 + 0.4 * sin(_t * 1.7 + st.z * 3.0)
		var p := Vector2(st.x * vp.x, st.y * vp.y)
		_stars_node.draw_circle(p, 1.0 + 1.2 * fposmod(st.z, 1.0), Color(1.0, 0.97, 0.9, 0.7 * a * tw))


## The outline from index a to b, pushed outward by LINE_OFF.
func _along(a: int, b: int) -> PackedVector2Array:
	var line := PackedVector2Array()
	for i in range(a, b + 1):
		var p := _stone[maxi(i - 2, 0)]
		var q := _stone[mini(i + 2, _stone.size() - 1)]
		var n := (q - p).normalized().orthogonal()
		if Geometry2D.is_point_in_polygon(_stone[i] + n * 5.0, _stone):
			n = -n   # outward
		line.append(_stone[i] + n * LINE_OFF)
	return line


## Points in units of H, y up, to world px.
func _flip(pts: Array) -> Array:
	var out: Array = []
	for p in pts:
		out.append(Vector2(p.x, -p.y) * H)
	return out


## Catmull-Rom through the points, SUB points per segment.
func _smooth(pts: Array, closed: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	var segs := n if closed else n - 1
	for i in segs:
		var p0: Vector2 = pts[(i - 1 + n) % n] if closed else pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if closed else pts[mini(i + 2, n - 1)]
		for k in SUB:
			var t := k / float(SUB)
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	if not closed:
		out.append(pts[n - 1])
	return out


## The same line with a point every 4 px.
func _resample(line: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array([line[0]])
	var carry := 0.0
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var d := a.distance_to(b)
		var at := 4.0 - carry
		while at <= d:
			out.append(a.lerp(b, at / d))
			at += 4.0
		carry = d - (at - 4.0)
	return out


func _on(line: PackedVector2Array, s: float) -> Vector2:
	var x := clampf(s / 4.0, 0.0, line.size() - 1.001)
	var i := int(x)
	return line[i].lerp(line[i + 1], x - i)


func _pos_at(s: float) -> Vector2:
	return _on(_path, s)


## Voronoi cells over a figure, each clipped to its outline: {poly (around c), c, col, ...}.
func _pieces(outline: PackedVector2Array, dark: PackedVector2Array, count: int, box: Rect2) -> Array:
	var seeds: Array[Vector2] = []
	while seeds.size() < count:
		var p := Vector2(_rng.randf_range(box.position.x, box.end.x), _rng.randf_range(box.position.y, box.end.y))
		if Geometry2D.is_point_in_polygon(p, outline):
			seeds.append(p)
	var big := PackedVector2Array([box.position - Vector2(50, 50), Vector2(box.end.x + 50, box.position.y - 50),
		box.end + Vector2(50, 50), Vector2(box.position.x - 50, box.end.y + 50)])
	var out: Array = []
	for i in seeds.size():
		var cell := big
		for j in seeds.size():
			if i != j:
				cell = _clip_half(cell, seeds[i], seeds[j])
		for piece in Geometry2D.intersect_polygons(cell, outline):
			var c := Vector2.ZERO
			for p in piece:
				c += p
			c /= piece.size()
			var local := PackedVector2Array()
			for p in piece:
				local.append(p - c)
			# backlit by the moon: dark stone, a little lighter towards the face and the top; the hair
			# or the veil darker still
			var top := -box.position.y
			var light := clampf(0.4 + c.x / H * 0.8 - (c.y / top + 0.4) * 0.6, 0.0, 1.0)
			var shade := Vector3(light, 1.0 if Geometry2D.is_point_in_polygon(c, dark) else 0.0, _rng.randf_range(-0.015, 0.015))
			out.append({"poly": local, "c": c, "crack": 0.0, "col": shade, "v": Vector2.ZERO, "w": 0.0,
				"rot": 0.0, "off": Vector2.ZERO, "delay": 0.0, "glint": 0.0, "home_at": 0.0, "from_off": Vector2.ZERO,
				"from_rot": 0.0, "home": false, "m": 0.0, "pr": PackedVector2Array(), "to_c": c,
				"to_pr": PackedVector2Array(), "to_col": shade})
	return out


## A piece's stone in the light of the moment: (how lit, hair or veil, a touch of its own).
func _stone_col(shade: Vector3) -> Color:
	if shade.y > 0.5:
		return _look.stone.darkened(0.25).lerp(_look.rim, 0.04 + 0.1 * shade.x)
	return _look.stone.lerp(_look.rim, 0.06 + 0.22 * shade.x + shade.z)


## The part of `poly` nearer to `a` than to `b`.
func _clip_half(poly: PackedVector2Array, a: Vector2, b: Vector2) -> PackedVector2Array:
	var mid := (a + b) * 0.5
	var n := (b - a).normalized()
	var out := PackedVector2Array()
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var dp := (p - mid).dot(n)
		var dq := (q - mid).dot(n)
		if dp <= 0.0:
			out.append(p)
		if (dp <= 0.0) != (dq <= 0.0):
			out.append(p.lerp(q, dp / (dp - dq)))
	return out


func _touch(pa: PackedVector2Array, pb: PackedVector2Array) -> bool:
	var n := 0
	for p in pa:
		for q in pb:
			if p.distance_squared_to(q) < 4.0:
				n += 1
				if n >= 2:
					return true
	return false


func _home_poly(i: int) -> PackedVector2Array:
	var sh: Dictionary = _shards[i]
	var out := PackedVector2Array()
	for p in sh.poly:
		out.append(sh.c + p)
	return out


func _world_poly(i: int) -> PackedVector2Array:
	var sh: Dictionary = _shards[i]
	var out := PackedVector2Array()
	if sh.m <= 0.0:
		for p in sh.poly:
			out.append(sh.c + sh.off + (p as Vector2).rotated(sh.rot))
		return out
	var m: float = sh.m
	for k in RADIAL:
		var from: Vector2 = sh.c + sh.from_off + (sh.pr[k] as Vector2).rotated(sh.from_rot)
		out.append(from.lerp(sh.to_c + sh.to_pr[k], m))
	return out


## A barrier broke at p: the stone around it cracks, more the nearer it is.
func _crack_from(p: Vector2, dust: float) -> void:
	for sh in _shards:
		var d: float = sh.c.distance_to(p)
		sh.crack = maxf(sh.crack, clampf(1.0 - d / CRACK_REACH, 0.0, 1.0))
	for k in int(dust):
		_dust.append({"p": p + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-20, 20)),
			"v": Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-90, 10)), "t": 0.0, "life": _rng.randf_range(0.8, 1.8),
			"r": _rng.randf_range(3, 9)})


func _process(delta: float) -> void:
	_t += delta
	var dusk := smoothstep(0.03, 0.97, _s / _path_len) if _ending < 0.0 and not _at_crown else 1.0
	_night = _night_pin if _night_pin >= 0.0 else maxf(_night, dusk)
	_tint()
	_stars_node.queue_redraw()
	_gust = 0.5 + 0.5 * sin(_t * 0.37) * sin(_t * 0.23 + 1.0)
	_kick *= exp(-8.0 * delta)
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < 1.4)
	for i in range(_dust.size() - 1, -1, -1):
		var m: Dictionary = _dust[i]
		m.t += delta
		m.v.y += 120.0 * delta
		m.p += m.v * delta
		if m.t > m.life:
			_dust.remove_at(i)
	if _ending >= 0.0:
		_process_ending(delta)
	else:
		_process_climb(delta)
	_frame(delta, false)
	queue_redraw()
	_subs.queue_redraw()


func _process_climb(delta: float) -> void:
	if _at_crown:
		# at the crown: she breaks on the theme's climax. Early, the light rests here and the camera
		# draws back while the build swells; late, the theme jumps ahead to it.
		_s = lerpf(_s, _path_len, 1.0 - exp(-4.0 * delta))
		_reveal_to = 0.7
		var start := float(Songs.TRACKS.monument.climax) - BREAK_AT
		if Music.track != "monument" or Music._track_pos() >= start - 0.05:
			_begin_ending()
		elif _t - _crown_t > (1.0 if DevMenu.proto_has("end") else 12.0):   # from near the top: no long wait
			Music._track_jump(start)
			_begin_ending()
		return
	if _auto and _t > OPENING:
		var k: int = Music.beat_at_tap()
		if k >= 0 and k != _last_beat and absf(fposmod(Music.heard_phase() + 0.5, 1.0) - 0.5) < 0.04:
			_tap()
	if _at_crown:
		return
	var stop := _gates[_gate] - 10.0
	_target = minf(_target, stop)
	_s = lerpf(_s, _target, 1.0 - exp(-6.0 * delta))
	# the opening shot shows all of her, from her feet; the camera closes in as the light climbs,
	# nearest when it reaches her face
	_reveal_to = 1.0 if _t < OPENING else 1.0 - smoothstep(0.0, _face_s, _s)


## The camera: between close on the light and all of her, always easing, never cutting.
func _frame(delta: float, snap: bool) -> void:
	if not is_inside_tree():
		return   # the scene is being reloaded
	var vp := get_viewport_rect().size
	var whole := minf(vp.y / (H * _all_h), vp.x / (H * _all_h * 1.34))
	_reveal = _reveal_to if snap else lerpf(_reveal, _reveal_to, 1.0 - exp(-FOLLOW * delta))
	var r := smoothstep(0.0, 1.0, _reveal)
	var focus := _focus()
	var all := _all_c
	var zoom := exp(lerpf(log(NEAR_ZOOM), log(whole), r))
	var at := focus.lerp(all, r) + Vector2(0, -60) * (1.0 - r)
	if snap:
		_cam.position = at
	else:
		_cam.position = _cam.position.lerp(at, 1.0 - exp(-3.0 * delta))
	_cam.zoom = Vector2.ONE * zoom
	_cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _kick * 4.0 / zoom
	# the planes: each scaled and moved by its depth around the camera, so far things barely move
	# and change little with the zoom, near ones sweep past
	for l in _layers:
		var k: float = l.k
		var s := k * pow(zoom / whole, k - 1.0)
		l.node.scale = Vector2.ONE * s
		l.node.position = _cam.position * (1.0 - s)
		l.node.queue_redraw()
	_update_air(vp, zoom)
	# the flakes in the air drift with the wind and a little with the camera
	var moved := (_cam.position - _last_cam) * zoom
	_last_cam = _cam.position
	for sp in _specks:
		var blow := 1.0 + 1.5 * _gust * _alive
		sp.p += sp.v * blow * delta - (moved * sp.k * 0.6 if not snap else Vector2.ZERO)
		sp.a += delta * sp.k
		sp.p = Vector2(fposmod(sp.p.x, vp.x), fposmod(sp.p.y, vp.y))


## What the camera follows: the light, wherever it is.
func _focus() -> Vector2:
	if _whole_t >= 0.0:
		return _mother_light()
	if _beats >= 0.0:
		return _desc_light()
	if _ending >= 0.0:
		return _pos_at(_path_len)
	return _pos_at(_s)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		DevMenu.back_to_game(get_tree())
		return
	var pressed: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A)
	if pressed and _ending < 0.0 and _t > 1.0:
		_tap()


func _tap() -> void:
	if _at_crown:
		return
	var k: int = Music.beat_at_tap()
	var on := k >= 0 and k != _last_beat
	if on:
		_run = _run + 1 if k - _last_beat <= 2 else 1
		_last_beat = k
		Music.play_accent(_run)
	else:
		_run = 0
		Music.play_tap(1.0 - _hp / BARRIER_HP, false)
	_kick = 1.0
	_hp -= 2.0 if on else 1.0
	var stop := _gates[_gate]
	_target = lerpf(_s, stop, 0.35)
	if _hp > 0.0:
		return
	var p := _pos_at(stop)
	_rings.append({"p": p, "t": 0.0})
	_crack_from(p, 14)
	Music.crumble_bit()
	_kick = 2.0
	_gate += 1
	_hp = BARRIER_HP
	_target = stop + 30.0
	if _gate >= BARRIERS:
		_at_crown = true
		_crown_t = _t


## The crown is reached: pull back to see her whole, the gold runs through every crack, she breaks.
func _begin_ending() -> void:
	print("MONUMENT crown at %.1f s, break at theme %.1f s" % [_t, Music._track_pos() + BREAK_AT])
	_ending = 0.0
	_gate = BARRIERS - 1
	_reveal_to = 1.0
	Music.play_milestone(5)
	var top := _pos_at(_path_len)
	for sh in _shards:
		var c: Vector2 = sh.c
		# pieces nearer the crown go first; all of them push away from her heart and hang there
		sh.delay = c.distance_to(top) / H * 1.4
		sh.v = (c - HEART * H).normalized() * _rng.randf_range(160.0, 340.0) + Vector2(_rng.randf_range(-40, 40), -60.0)
		sh.w = _rng.randf_range(-0.5, 0.5)


func _process_ending(delta: float) -> void:
	var was := _ending
	_ending += delta
	# gold runs down from the crown through every crack, the ground shaking more and more
	if _ending < BREAK_AT + 0.5:
		var g := clampf((_ending - 1.2) / GOLD_TIME, 0.0, 1.0)
		var top := _pos_at(_path_len)
		for sh in _shards:
			sh.crack = maxf(sh.crack, clampf((g * H * 1.3 - sh.c.distance_to(top)) / 300.0, 0.0, 1.0))
		if int(was * 3.0) != int(_ending * 3.0) and _ending > 1.2 and _ending < BREAK_AT:
			Music.chaos_hit(g)
			_kick = 0.6 + g
	if was < BREAK_AT and _ending >= BREAK_AT:
		Music.tremor(0.0)   # the rumble is loud even at its softest: once, at the break
		Music.resolve_chord()
		_kick = 6.0
		for sh in _shards:
			sh.crack = 1.0
			_crack_from(sh.c, 1)
	if _ending > BREAK_AT:
		var f := _ending - BREAK_AT
		for sh in _shards:
			sh.glint = maxf(0.0, sh.glint - delta / 1.2)
			if sh.home:
				continue
			var tt: float = f - sh.delay * 0.4
			if tt <= 0.0:
				continue
			# they burst out, slow down and hang in the air, turning, drifting
			sh.v *= exp(-1.1 * delta)
			sh.off += sh.v * delta + Vector2(0, sin(_t * 0.8 + sh.c.x * 0.01) * 6.0 * delta)
			sh.rot += sh.w * delta * exp(-0.3 * tt)
		if int((f - delta) * 5.0) != int(f * 5.0) and f < 2.0:
			Music.crumble_bit()
	if was < DESC_AT and _ending >= DESC_AT:
		_begin_descent()
	if _desc_start > 0.0:
		_process_descent(delta)


## The light goes down her back on its own: every note of the falling melody is scheduled now, on
## the beat, and the light moves with the music's clock, a beat's worth of line on each note.
func _begin_descent() -> void:
	_beat_len = Music._s16() * 4.0
	_desc_start = Music._grid_time(_beat_len)
	Music.choir_swell()
	for b in DESC_BEATS:
		var t := _desc_start + b * _beat_len
		var deg: int = MELODY[b]
		# softly: the theme's own release carries the descent, the notes are the light's
		Music._schedule_deg(t, "celesta" if b % 2 == 0 else "harp", deg, 24 if deg >= 5 else 12, 0.03)
		if b % 2 == 0:
			Music._schedule_deg(t, "glass", deg + 2, 24, 0.014)
		if b % 4 == 0:
			Music._schedule_deg(t, "harp", deg - 4, 0, 0.02)


func _process_descent(delta: float) -> void:
	_beats = maxf(0.0, (Music._time - _desc_start) / _beat_len)
	_reveal_to = 0.55
	_all_c = _all_c.lerp(Vector2(0.12, -0.66) * H, 1.0 - exp(-0.8 * delta))
	_all_h = lerpf(_all_h, 1.45, 1.0 - exp(-0.8 * delta))
	# the pieces fly together as the light passes, into the Mother standing
	for sh in _shards:
		if sh.home:
			continue
		var k: float = (_beats - sh.home_at) / RETURN_BEATS
		if k <= 0.0:
			sh.from_off = sh.off
			sh.from_rot = sh.rot
			continue
		sh.m = smoothstep(0.0, 1.0, minf(k, 1.0))
		if k >= 1.0:
			sh.home = true
			sh.m = 1.0
			sh.glint = 1.0
	var b := int(floor(_beats))
	if b > _desc_beat and b < DESC_BEATS:
		_desc_beat = b
		_rings.append({"p": _desc_light(), "t": 0.0})
	if _beats >= DESC_BEATS:
		for sh in _shards:
			sh.home = true
			sh.m = 1.0
		if _whole_t < 0.0:
			_whole_t = 0.0
			print("MONUMENT whole at %.1f s (theme %.1f s)" % [_t, Music._track_pos()])
			Music.resolve_chord()
			_kick = 1.5
		_whole_t += delta
		_process_mother(delta)
		if _whole_t > WHOLE_HOLD:
			_glow = minf(1.0, _glow + delta / GLOW_TIME)
			if _whole_t > WHOLE_HOLD + GLOW_TIME + GLOW_HOLD:
				get_tree().reload_current_scene()   # the next level; in the prototype, her again


## The Mother, whole: the camera pulls back to frame her and the little light at her feet; her hand
## glows, she opens her eyes and speaks; then the light goes on its way along the ground.
func _process_mother(delta: float) -> void:
	_reveal_to = 1.0
	# frame her and the light; nearer, on her face and palm, while she speaks
	var speaking := smoothstep(RISE_AT, RISE_AT + RISE_TIME + 1.0, _whole_t) * (1.0 - smoothstep(GO_AT, GO_AT + 1.5, _whole_t))
	_speak = speaking
	var vp := get_viewport_rect().size
	var upright := vp.y > vp.x   # a phone held upright: frame her a little further right, so her hand shows
	var c := (Vector2(0.2, -0.7) * H).lerp(Vector2(0.64 if upright else 0.38, -0.82) * H, speaking)
	_all_c = _all_c.lerp(c, 1.0 - exp(-0.9 * delta))
	_all_h = lerpf(_all_h, lerpf(1.55, 1.05, speaking), 1.0 - exp(-0.9 * delta))
	_alive = smoothstep(ALIVE_AT, ALIVE_AT + ALIVE_TIME, _whole_t)
	var was := _eyes
	_eyes = smoothstep(EYES_AT, EYES_AT + 1.0, _whole_t)
	if was <= 0.0 and _eyes > 0.0:
		Music.choir_swell()
	# down to it, the arm reaching; then up again, the arm raised and the palm held out
	var down := smoothstep(BEND_AT, BEND_AT + BEND_TIME, _whole_t)
	var up := smoothstep(RISE_AT, RISE_AT + RISE_TIME, _whole_t)
	_bend = down * (1.0 - up)
	_reach = down * (1.0 - up)
	_offer = up
	var took := _take
	_take = smoothstep(TAKE_AT, TAKE_AT + TAKE_TIME, _whole_t)
	if took <= 0.0 and _take > 0.0:
		Music.play_celesta(2)
		Music.play_celesta(4)
	if took < 1.0 and _take >= 1.0:
		Music.choir_swell()
	for i in LINE_AT.size():
		if _whole_t - delta < LINE_AT[i] and _whole_t >= LINE_AT[i]:
			_say(i)
	var g := clampf((_whole_t - GO_AT) / GO_TIME, 0.0, 1.0)
	if _go <= 0.0 and g > 0.0:
		Music.play_milestone(3)
	_go = g
	if _go > 0.0:
		_reveal_to = 1.0 - 0.5 * smoothstep(0.2, 0.7, _go)


## Her voice: line i, in the language of the subtitles (in English while only that one is recorded),
## through the narrator's voice bus.
func _say(i: int) -> void:
	var path := "res://audio/voices/madre_%02d_%s.mp3" % [i + 1, _lang]
	if not ResourceLoader.exists(path):
		path = "res://audio/voices/madre_%02d_en.mp3" % (i + 1)
	if not ResourceLoader.exists(path):
		return
	# the narrator's voice bus, so she sounds in the same room (its reverb), and the music ducks
	# under her the same way
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = Narrator.VOICE_BUS
	add_child(p)
	p.play()
	Narrator._duck()
	p.finished.connect(func() -> void:
		Narrator._unduck()
		p.queue_free())


## Where a point of her (as she stands at rest) is now: the wind in her veil and her hem, her arm
## turned at the shoulder, her body bowed from the waist, a breath.
func _pose(p: Vector2) -> Vector2:
	var x := p.x / H
	var y := -p.y / H
	var q := p + _wind(x, y)
	var at := func(v: Vector2) -> Vector2: return Vector2(v.x, -v.y) * H
	# the arm and its sleeve turn at the shoulder, rigid from a little way out
	var arm := smoothstep(0.2, 0.3, x) * smoothstep(0.33, 0.36, y) * (1.0 - smoothstep(0.78, 0.82, y)) \
		* smoothstep(0.02, 0.1, (Vector2(x, y) - SHOULDER).length())
	if arm > 0.0:
		var hold := sin(_t * 0.9) * 0.03 * _offer     # the palm drifts a little, holding the light
		q = at.call(SHOULDER) + (q - at.call(SHOULDER)).rotated((REACH * _reach + OFFER * _offer + hold) * arm)
	# the head nods towards the palm while she speaks
	var head := smoothstep(0.85, 0.92, y)
	if head > 0.0 and _speak > 0.0:
		var nod := (0.08 + 0.04 * sin(_t * 1.3)) * _speak
		q = at.call(NECK) + (q - at.call(NECK)).rotated(nod * head)
	# she bows from the waist and again from the chest, so her back curves; a breath
	var chest := maxf(smoothstep(0.74, 0.86, y), arm * 0.7)
	if chest > 0.0:
		q = at.call(CHEST) + (q - at.call(CHEST)).rotated(BOW * 0.4 * _bend * chest)
	var body := maxf(smoothstep(0.44, 0.62, y), arm)
	if body > 0.0:
		var breath := sin(_t * 1.1) * 0.012
		q = at.call(WAIST) + (q - at.call(WAIST)).rotated((BOW * 0.6 * _bend + breath) * body)
	return q


## The wind: her veil streams back and ripples, more towards its end; her hem stirs.
func _wind(x: float, y: float) -> Vector2:
	if _alive <= 0.0:
		return Vector2.ZERO
	var veil := smoothstep(-0.12, -0.32, x) * smoothstep(1.15, 0.35, y)
	var hem := smoothstep(0.22, 0.0, y)
	var g := _alive * (0.6 + 0.4 * _gust)
	var d := Vector2(-0.035 - 0.03 * _gust + sin(_t * 1.7 + y * 6.0) * 0.025, sin(_t * 1.3 + y * 5.0 + x * 3.0) * 0.012) * veil
	d += Vector2(sin(_t * 2.1 + x * 9.0) * 0.012 - 0.008, sin(_t * 1.6 + x * 7.0) * 0.004) * hem
	var sleeve := smoothstep(0.2, 0.24, x) * (1.0 - smoothstep(0.36, 0.4, x)) * smoothstep(0.52, 0.42, y)
	d += Vector2(sin(_t * 2.4 + y * 10.0) * 0.008 - 0.006, sin(_t * 1.9 + x * 8.0) * 0.006) * sleeve
	return d * H * g


func _pose_line(line: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in line:
		out.append(_pose(q))
	return out


func _palm() -> Vector2:
	return _pose(Vector2(HAND.x, -HAND.y) * H) + Vector2(0, -38 - 8.0 * sin(_t * 1.6) * _offer)


## The little light once she is whole: on the ground at her feet, then rising into her hand, held on
## her palm while she speaks, then rising from it and going on its way.
func _mother_light() -> Vector2:
	var ground := _desc[_desc.size() - 1]
	var held := ground.lerp(_palm(), smoothstep(0.0, 1.0, _take))
	if _go <= 0.0:
		return held
	var e := _go * _go * (3.0 - 2.0 * _go)
	return held + Vector2(e * 1.8 * H, -sin(e * PI) * 0.25 * H - e * 0.1 * H)


func _desc_light() -> Vector2:
	return _on(_desc, (_desc.size() - 1) * 4.0 * clampf(_beats / DESC_BEATS, 0.0, 1.0))


# ---- drawing ------------------------------------------------------------------------------------

## A plane's own point for where it should show at the whole view: planes are drawn in their own
## space, shrunk by their depth around the camera.
func _lp(k: float, p: Vector2) -> Vector2:
	var ref := Vector2(-0.05, -0.47) * H
	return ref + (p - ref) / k


func _draw_moon(n: Node2D) -> void:
	var k := 0.12
	# the sun, big and warm, sinking behind the ruins to the right as she is climbed
	var sun_a := 1.0 - smoothstep(0.75, 0.92, _night)
	if sun_a > 0.0:
		var c := _lp(k, _sun_at())
		var r := 0.46 * H / k
		var warm := Color("#fff1d8").lerp(Color("#ff9a5c"), smoothstep(0.2, 0.8, _night))
		for i in 18:
			var f := i / 17.0
			n.draw_circle(c, r * lerpf(2.6, 1.02, f), Color(warm, (0.03 + 0.025 * f) * sun_a))
		n.draw_circle(c, r, Color(warm, sun_a))
	# the moon, rising behind her head as the dark comes
	var moon_a := smoothstep(0.45, 0.9, _night)
	if moon_a > 0.0:
		var c := _lp(k, _moon_at())
		var r := 0.5 * H / k
		var col: Color = LOOKS.azul.moon
		for i in 18:
			var f := i / 17.0
			n.draw_circle(c, r * lerpf(2.2, 1.02, f), Color(col, (0.025 + 0.02 * f) * moon_a))
		n.draw_circle(c, r, Color(col, moon_a))
		n.draw_arc(c, r * 1.06, 0.0, TAU, 128, Color(col, 0.35 * moon_a), r * 0.006, true)


## Where the sun and the moon are, as seen at the whole view (units of H, y down).
func _sun_at() -> Vector2:
	var e := smoothstep(0.0, 0.85, _night)
	return Vector2(lerpf(0.05, 0.55, e), lerpf(-0.6, 0.25, e)) * H


func _moon_at() -> Vector2:
	return Vector2(0.0, lerpf(-0.3, -0.62, smoothstep(0.45, 1.0, _night))) * H


## Where a point of the sky plane is now, in her space (the plane is shrunk and moved by its depth).
func _sky_world(p: Vector2) -> Vector2:
	var n: Node2D = _layers[0].node
	return n.position + n.scale * _lp(0.12, p)


## A rect over the view with a shader, at depth z (its place among the planes).
func _volume(shader: String, z: int) -> ColorRect:
	var r := ColorRect.new()
	r.z_index = z
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load(shader)
	r.material = m
	add_child(r)
	return r


## The fog and the rays follow the view; the rays come from the sun, then the moon; each plane's
## fog sits on that plane's ground and drifts with it.
func _update_air(vp: Vector2, zoom: float) -> void:
	var view := vp / zoom
	var corner := _cam.position + _cam.offset - view * 0.5
	var uv := func(w: Vector2) -> Vector2: return (w - corner) / view
	for r: ColorRect in [_fog_far, _fog_mid, _rays_back, _fog_front, _rays_front]:
		r.position = corner
		r.size = view
		(r.material as ShaderMaterial).set_shader_parameter("aspect", vp.x / vp.y)
	var sun_i := 1.0 - smoothstep(0.6, 0.9, _night)
	var moon_i := smoothstep(0.55, 1.0, _night) * 0.75
	var src := _sky_world(_sun_at()) if sun_i >= moon_i else _sky_world(_moon_at())
	var light: Vector2 = uv.call(src)
	var ray_col: Color = _look.rays
	for pair in [[_rays_back, 1.8], [_rays_front, 0.55]]:
		var m: ShaderMaterial = pair[0].material
		m.set_shader_parameter("origin", light)
		m.set_shader_parameter("color", ray_col)
		m.set_shader_parameter("intensity", float(pair[1]) * maxf(sun_i, moon_i))
	# fog: far and thick and pale; nearer, thinner; in front, a low mist at her feet
	var planes := [[_fog_far, 1, 0.02, 0.8, 0.5, 0.16, 1.6], [_fog_mid, 2, 0.03, 0.65, 0.34, 0.08, 2.2],
		[_fog_front, -1, 0.0, 0.45, 0.16, 0.0, 3.0]]
	for spec in planes:
		var m: ShaderMaterial = (spec[0] as ColorRect).material
		var ground: Vector2
		var k := 1.0
		if int(spec[1]) >= 0:
			var layer: Dictionary = _layers[int(spec[1])]
			k = layer.k
			ground = layer.node.position + layer.node.scale * _lp(k, Vector2(0, float(spec[2]) * H))
		else:
			ground = Vector2(0, 0)
		m.set_shader_parameter("ground", (uv.call(ground) as Vector2).y)
		m.set_shader_parameter("density", float(spec[3]))
		m.set_shader_parameter("thickness", float(spec[4]))
		m.set_shader_parameter("base", float(spec[5]))
		m.set_shader_parameter("scale", float(spec[6]))
		m.set_shader_parameter("scroll", _cam.position / H * k * float(spec[6]) * Vector2(1.0, 0.3))
		m.set_shader_parameter("light", light)
		m.set_shader_parameter("color", _look.sky_low.lerp(_look.far, 0.25).lerp(_look.mid, 0.25 * (1.0 if int(spec[1]) == -1 else 0.0)))
		m.set_shader_parameter("lit", ray_col.lerp(_look.moon, 0.4))
		m.set_shader_parameter("drift", Vector2(0.03 + 0.03 * _gust * _alive, 0.0) * (1.0 + 0.5 * k))


## Far ruins: towers, domes and arches, pale in the haze, then a band of fog at their feet.
func _draw_far(n: Node2D) -> void:
	var k := 0.3
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var col: Color = _look.far.lerp(_look.sky_low, 0.35)
	for i in 16:
		var x := lerpf(-3.4, 3.4, i / 15.0) + rng.randf_range(-0.12, 0.12)
		if absf(x) < 0.5:
			continue   # leave the moon clear behind her
		var h := rng.randf_range(0.25, 0.75)
		var w := rng.randf_range(0.12, 0.26)
		_ruin(n, k, Vector2(x, 0.02) * H, w * H, h * H, col, _look.sky_low.lerp(_look.moon, 0.3), rng)


## Near ruins: bigger, darker, broken; fog at their feet too.
func _draw_mid(n: Node2D) -> void:
	var k := 0.55
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	for i in 9:
		var x := lerpf(-2.6, 2.6, i / 8.0) + rng.randf_range(-0.15, 0.15)
		if absf(x) < 0.7:
			continue
		var h := rng.randf_range(0.3, 0.6)
		var w := rng.randf_range(0.18, 0.32)
		_ruin(n, k, Vector2(x, 0.03) * H, w * H, h * H, _look.mid, _look.sky_low.lerp(_look.moon, 0.15), rng)
	# the ground she kneels on, dark, sweeping off to both sides
	var g := PackedVector2Array()
	for i in 41:
		var x := lerpf(-5.0, 5.0, i / 40.0)
		g.append(_lp(k, Vector2(x, 0.03 - 0.02 * sin(x * 2.3)) * H))
	g.append(_lp(k, Vector2(5.0, 1.5) * H))
	g.append(_lp(k, Vector2(-5.0, 1.5) * H))
	n.draw_colored_polygon(g, _look.mid.darkened(0.2))


## In front of everything, close: dark rubble and a broken column, sliding past as the camera moves.
func _draw_near(n: Node2D) -> void:
	var k := 1.35
	var col: Color = _look.near
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	for spec in [[-1.45, 0.1, 0.3], [-2.4, 0.16, 0.45], [3.2, 0.14, 0.4]]:
		var cx: float = spec[0]
		var top: float = spec[1]
		var w: float = spec[2]
		var rock := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			var rr := w * rng.randf_range(0.75, 1.1)
			rock.append(_lp(k, Vector2(cx + cos(a) * rr, top * 0.0 + sin(a) * (top + 0.05) * rng.randf_range(0.8, 1.2) + 0.12) * H))
		rock.append(_lp(k, Vector2(cx + w, 0.6) * H))
		rock.append(_lp(k, Vector2(cx - w, 0.6) * H))
		n.draw_colored_polygon(rock, col)
	# a broken column leaning in from the left
	var c0 := Vector2(-1.0, 0.2) * H
	var dir := Vector2(0.3, -1.0).normalized()
	var side := dir.orthogonal() * 0.07 * H
	var top2 := c0 + dir * 0.55 * H
	n.draw_colored_polygon(PackedVector2Array([_lp(k, c0 - side), _lp(k, c0 + side), _lp(k, top2 + side * 0.9 + Vector2(10, 30)),
		_lp(k, top2 - side * 0.9)]), col)


## One ruin: a tower with a dome or a broken top, arched windows lit by the sky behind.
func _ruin(n: Node2D, k: float, base: Vector2, w: float, h: float, col: Color, window: Color, rng: RandomNumberGenerator) -> void:
	var l := base.x - w * 0.5
	var r := base.x + w * 0.5
	var t := base.y - h
	var body := PackedVector2Array([_lp(k, Vector2(l, base.y)), _lp(k, Vector2(l, t)), _lp(k, Vector2(r, t)), _lp(k, Vector2(r, base.y))])
	n.draw_colored_polygon(body, col)
	var kind := rng.randi() % 3
	if kind == 0:   # a dome and a spire
		var dome := PackedVector2Array()
		for i in 17:
			var a := PI + PI * i / 16.0
			dome.append(_lp(k, Vector2(base.x + cos(a) * w * 0.45, t + sin(a) * w * 0.5)))
		n.draw_colored_polygon(dome, col)
		n.draw_line(_lp(k, Vector2(base.x, t - w * 0.5)), _lp(k, Vector2(base.x, t - w * 1.1)), col, w * 0.04 / k)
	elif kind == 1:   # broken top
		var jag := PackedVector2Array([_lp(k, Vector2(l, t))])
		for i in 6:
			jag.append(_lp(k, Vector2(lerpf(l, r, (i + 0.5) / 6.0), t - rng.randf_range(0.0, 0.18) * h)))
		jag.append(_lp(k, Vector2(r, t)))
		n.draw_colored_polygon(jag, col)
	else:   # a narrower storey on top
		n.draw_colored_polygon(PackedVector2Array([_lp(k, Vector2(l + w * 0.2, t)), _lp(k, Vector2(l + w * 0.2, t - h * 0.25)),
			_lp(k, Vector2(r - w * 0.2, t - h * 0.25)), _lp(k, Vector2(r - w * 0.2, t))]), col)
	# arched windows, in a row or two
	var rows := 1 + rng.randi() % 2
	var cols := 2 + rng.randi() % 2
	for row in rows:
		for c in cols:
			var wx := lerpf(l, r, (c + 0.5) / cols)
			var wy := t + h * (0.18 + 0.32 * row)
			var ww := w / cols * 0.4
			var wh := h * 0.2
			var win := PackedVector2Array([_lp(k, Vector2(wx - ww * 0.5, wy + wh)), _lp(k, Vector2(wx - ww * 0.5, wy))])
			for i in 9:
				var a := PI + PI * i / 8.0
				win.append(_lp(k, Vector2(wx + cos(a) * ww * 0.5, wy + sin(a) * ww * 0.5)))
			win.append(_lp(k, Vector2(wx + ww * 0.5, wy + wh)))
			n.draw_colored_polygon(win, Color(window, 0.55))


## The Mother's words, warm gold, under everything, fading in and out.
func _draw_subs() -> void:
	if _whole_t < 0.0:
		return
	var vp := get_viewport_rect().size
	var lines: Array = LINES[_lang]
	for i in lines.size():
		var t: float = _whole_t - LINE_AT[i]
		var dur: float = LINE_TIME[i]
		if t < 0.0 or t > dur:
			continue
		var a := smoothstep(0.0, 0.6, t) * (1.0 - smoothstep(dur - 0.7, dur, t))
		var rows: PackedStringArray = String(lines[i]).split("\n")
		for r in rows.size():
			var size := int(vp.y * 0.05)
			var w := _font.get_string_size(rows[r], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			while w > vp.x * 0.9 and size > 12:   # narrow screens (a phone held upright): fit the width
				size -= 2
				w = _font.get_string_size(rows[r], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var at := Vector2((vp.x - w) * 0.5, vp.y * 0.89 + r * size * 1.25 - (rows.size() - 1) * size * 0.6)
			for k in 12:
				var o := Vector2.from_angle(TAU * k / 12.0) * size * 0.08
				_subs.draw_string(_font, at + o, rows[r], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_look.sky_top, 0.55 * a))
			_subs.draw_string(_font, at, rows[r], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_look.moon.lerp(Palette.GOLD, 0.35), a))


func _draw_specks(n: Node2D) -> void:
	# streaks of wind, faint, while she is alive
	if _alive > 0.0:
		var vp := get_viewport_rect().size
		for i in 7:
			var y := fposmod(i * 97.0 + sin(_t * 0.3 + i) * 30.0, vp.y)
			var x := fposmod(_t * (220.0 + i * 40.0) * (0.6 + 0.6 * _gust) + i * 310.0, vp.x + 400.0) - 200.0
			var a := 0.08 * _alive * (0.4 + 0.6 * _gust)
			var pts := PackedVector2Array()
			for k in 12:
				pts.append(Vector2(x + k * 16.0, y + sin(_t * 2.0 + k * 0.5 + i) * 4.0))
			n.draw_polyline(pts, Color(_look.moon, a), 1.5, true)
	for sp in _specks:
		var r: float = sp.r * sp.k
		var a: float = sp.a
		var pts := PackedVector2Array([sp.p + Vector2(r, 0).rotated(a), sp.p + Vector2(0, r * 0.5).rotated(a),
			sp.p + Vector2(-r, 0).rotated(a), sp.p + Vector2(0, -r * 0.5).rotated(a)])
		n.draw_colored_polygon(pts, Color(_look.near, 0.55))


func _draw() -> void:
	var unit := 1.0 / _cam.zoom.x   # one screen px in world px
	var gold := Palette.GOLD
	var broke := _ending >= BREAK_AT
	var f := _ending - BREAK_AT if broke else 0.0
	var whole := _whole_t >= 0.0
	# the light inside her, showing through as she opens, closing as she comes back together
	if broke and not whole:
		var u := clampf(_beats / DESC_BEATS, 0.0, 1.0) if _beats >= 0.0 else 0.0
		var g := smoothstep(0.0, 2.0, f) * (1.0 - u)
		for i in 14:
			var k := i / 13.0
			draw_circle(HEART * H, H * lerpf(0.7, 0.04, k) * (0.5 + g), Color(1.0, 0.92, 0.7, 0.05 * g + 0.05 * g * k))
	# the stone: every shard; while it hangs apart, each with its own edge
	var apart := broke and not whole
	for i in _shards.size():
		var sh: Dictionary = _shards[i]
		var poly := _world_poly(i)
		if sh.m > 0.0 and sh.m < 1.0:
			poly = Geometry2D.convex_hull(poly)   # turning from one shape into the other: keep it whole
			poly.remove_at(poly.size() - 1)
		var col: Color = _stone_col(sh.col).lerp(_stone_col(sh.to_col), sh.m)
		if _alive >= 1.0:
			continue
		draw_colored_polygon(poly, Color(col, 1.0 - _alive * _alive))
		if sh.glint > 0.0:
			draw_colored_polygon(poly, Color(1.0, 0.88, 0.55, 0.55 * sh.glint))
		if apart and not sh.home:
			var closed := poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, Color(_look.rim, 0.5), 2.0 * unit, true)
			draw_polyline(closed, Color(gold, 0.6 * (1.0 - smoothstep(0.0, 2.0, f))), 5.0 * unit, true)
	if not broke:
		_draw_cracks(unit)
		_draw_figure(unit)
		_draw_edge(_stone, unit)
	elif whole:
		_draw_mother(unit)
	if not broke:
		_draw_climb(unit)
	elif _beats < 0.0:
		_draw_light(_pos_at(_path_len), unit)
	elif not whole:
		_draw_descent(unit)
	for m in _dust:
		var k: float = m.t / m.life
		draw_circle(m.p, m.r * (1.0 + k), Color(_look.rim, 0.4 * (1.0 - k)))
	for r in _rings:
		var k: float = r.t / 1.4
		draw_arc(r.p, lerpf(10.0, 90.0, 1.0 - pow(1.0 - k, 3.0)) * unit, 0.0, TAU, 48, Color(gold, 0.8 * (1.0 - k)), 3.0 * unit, true)
	if whole:
		_draw_light(_mother_light(), unit)
	if _glow > 0.0:
		var vp := get_viewport_rect().size / _cam.zoom
		draw_rect(Rect2(_cam.position - vp, vp * 2.0), Color(1.0, 0.94, 0.78, _glow))


## Her edge: dark, with the moon's light catching it.
func _draw_edge(outline: PackedVector2Array, unit: float) -> void:
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color(_look.rim, 0.55), 4.0 * unit, true)
	draw_polyline(closed, _look.near, 1.5 * unit, true)


## The Mother standing: her seams in gold, the veil's edge, her dress, her eyes (closed, then open
## and looking down at the light), and her open hand glowing.
func _draw_mother(unit: float) -> void:
	# a soft light around her as she comes alive
	var halo := _pose(Vector2(0.12, -0.95) * H)
	for i in 12:
		var k := i / 11.0
		draw_circle(halo, H * lerpf(0.75, 0.1, k), Color(1.0, 0.94, 0.78, 0.018 * _alive))
	# the living figure: one body, lit from the moon behind, her veil over it; drawn whole once the
	# stone has come alive
	if _alive > 0.0:
		_draw_streamers()
		var body := _pose_line(_stand)
		if Geometry2D.triangulate_polygon(body).is_empty():
			body = _last_fig
		else:
			_last_fig = body
		var veil := _pose_line(_veil)
		if Geometry2D.triangulate_polygon(veil).is_empty():
			veil = _last_veil
		else:
			_last_veil = veil
		if body.size() > 2:
			var cols := PackedColorArray()
			for q in body:
				var up := clampf(-q.y / (STAND_TOP * H), 0.0, 1.0)
				cols.append(Color(_look.stone.lerp(_look.rim, 0.12 + 0.3 * up), _alive))
			draw_polygon(body, cols)
		if veil.size() > 2:
			var vcols := PackedColorArray()
			for q in veil:
				var up := clampf(-q.y / (STAND_TOP * H), 0.0, 1.0)
				vcols.append(Color(_look.stone.darkened(0.2).lerp(_look.rim, 0.05 + 0.18 * up), _alive))
			draw_polygon(veil, vcols)
	# the gold seams shine as she comes back, then fade: what was broken is healed
	var seam_a := 1.0 - smoothstep(0.0, 0.8, _alive)
	if seam_a > 0.0:
		for seam in _seams:
			draw_line(seam[0], seam[1], Color(1.0, 0.88, 0.55, 0.2 * seam_a), 10.0 * unit, true)
			draw_line(seam[0], seam[1], Color(Palette.GOLD.lightened(0.2), 0.9 * seam_a), 2.0 * unit, true)
	if _alive <= 0.0:
		_draw_edge(_stand, unit)
		return
	_draw_edge(_pose_line(_stand), unit)
	var ink := Color(_look.near, 0.65 * _alive)
	draw_polyline(_pose_line(_smooth(_flip(VEIL_EDGE), false)), ink, 3.0 * unit, true)
	for l in STAND_LINES:
		draw_polyline(_pose_line(_smooth(_flip(l), false)), Color(ink, 0.35 * _alive), 2.5 * unit, true)
	# her eye: closed, then open, looking down at the light, wherever it is
	var eye := _pose(Vector2(STAND_EYE.x, -STAND_EYE.y) * H)
	var tilt := 0.45 + BOW * _bend
	var open := _eyes
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in 13:
		var a := lerpf(0.0, PI, i / 12.0)
		upper.append(eye + Vector2(cos(a) * 0.028 * H, -sin(a) * 0.012 * H * open).rotated(tilt))
		lower.append(eye + Vector2(cos(a) * 0.028 * H, sin(a) * 0.009 * H).rotated(tilt))
	if open > 0.05:
		var white := upper.duplicate()
		var back := lower.duplicate()
		back.reverse()
		white.append_array(back)
		draw_colored_polygon(white, Color(_look.moon, 0.9 * open))
		var look := (_mother_light() - eye).normalized() * 0.009 * H
		draw_circle(eye + look * Vector2(1.0, 0.4), 0.0075 * H * open, Color(_look.near, open))
		draw_polyline(upper, ink, 3.0 * unit, true)
	draw_polyline(lower, ink, 3.0 * unit, true)
	# her hand, open, cupped a little: a palm and fingers curving up at its end
	var wrist := _pose(Vector2(0.435, -0.45) * H)
	var tip := _pose(Vector2(0.51, -0.38) * H)
	var along := (tip - wrist).normalized()
	var up := along.orthogonal()
	if up.y > 0.0:
		up = -up
	var palm := PackedVector2Array()
	for k in 9:
		var u := k / 8.0
		palm.append(wrist.lerp(tip, u) + up * (sin(u * PI) * 0.012 * H - 0.012 * H))
	for k in 4:
		var u := k / 3.0
		palm.append(tip + along * 0.012 * H * u + up * 0.035 * H * u * u)   # the fingers, curling up
	palm.append(wrist + up * 0.02 * H)
	draw_colored_polygon(palm, Color(_look.stone.lerp(_look.rim, 0.3), _alive))
	palm.append(palm[0])
	draw_polyline(palm, Color(_look.near, 0.6 * _alive), 2.0 * unit, true)
	# it glows for the light
	var hand := _palm()
	var g := smoothstep(BEND_AT, TAKE_AT, _whole_t) * (1.0 - 0.6 * _go)
	for i in 10:
		var k := i / 9.0
		draw_circle(hand, lerpf(260.0, 30.0, k), Color(1.0, 0.9, 0.62, 0.05 * g + 0.04 * g * k))


## Loose streamers of veil and dress, rippling back in the wind, thinning to their ends.
func _draw_streamers() -> void:
	for i in STREAMERS.size():
		var spec: Array = STREAMERS[i]
		var root: Vector2 = spec[0]
		var length: float = spec[1] * H * _alive
		var width: float = spec[2] * H
		var base := _pose(Vector2(root.x, -root.y) * H)
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var n := 18
		var prev := base
		for k in n + 1:
			var u := k / float(n)
			var wave := sin(_t * (1.8 + 0.2 * i) - u * 5.0 + i * 1.7) * 0.12 * u * (0.6 + 0.6 * _gust)
			var dir := Vector2(-1.0, 0.35 - 0.25 * u).normalized().rotated(wave)
			var pt := prev + dir * (length / n) if k > 0 else base
			var side := dir.orthogonal() * width * (1.0 - u) * 0.5
			left.append(pt + side)
			right.append(pt - side)
			prev = pt
		right.reverse()
		left.append_array(right)
		var col := Color(_look.stone.darkened(0.15).lerp(_look.rim, 0.1), 0.85 * _alive)
		if not Geometry2D.triangulate_polygon(left).is_empty():
			draw_colored_polygon(left, col)


## Her few strokes, kneeling: the hairline, a closed eye on her bowed face, her lips, her arm, the
## robe's folds.
func _draw_figure(unit: float) -> void:
	var ink := Color(_look.near, 0.6)
	draw_polyline(_smooth(_flip(HAIRLINE), false), ink, 3.0 * unit, true)
	draw_polyline(_smooth(_flip(ARM), false), ink, 3.0 * unit, true)
	for fold in FOLDS:
		draw_polyline(_smooth(_flip(fold), false), Color(ink, 0.35), 2.5 * unit, true)
	var eye := Vector2(0.16, -0.665) * H
	var tilt := 0.5
	var lid := PackedVector2Array()
	for i in 13:
		var a := lerpf(0.15, PI - 0.15, i / 12.0)
		lid.append(eye + Vector2(cos(a) * 0.032 * H, sin(a) * 0.01 * H).rotated(tilt))
	draw_polyline(lid, ink, 3.0 * unit, true)
	for i in 4:
		var x := lerpf(-0.022, 0.03, i / 3.0) * H
		var root := eye + Vector2(x, 0.012 * H).rotated(tilt)
		draw_line(root, root + Vector2(-0.004, 0.014).rotated(tilt) * H, ink, 2.0 * unit, true)
	draw_line(Vector2(0.185, -0.567) * H, Vector2(0.163, -0.572) * H, ink, 2.5 * unit, true)


## The cracks: dark where the stone has cracked; gold as the end nears, and gold for good once she is
## back together (mended, not hidden).
func _draw_cracks(unit: float) -> void:
	var gold_k := clampf((_ending - 1.2) / GOLD_TIME, 0.0, 1.0) if _ending >= 0.0 else 0.0
	for e in _cracks:
		var a: Dictionary = _shards[int(e.x)]
		var b: Dictionary = _shards[int(e.y)]
		var k := minf(a.crack, b.crack)
		if k <= 0.02:
			continue
		var seg := _shared_edge(int(e.x), int(e.y))
		if seg.is_empty():
			continue
		var m: Vector2 = (seg[0] + seg[1]) * 0.5
		var p0: Vector2 = m.lerp(seg[0], k)
		var p1: Vector2 = m.lerp(seg[1], k)
		if gold_k > 0.0:
			draw_line(p0, p1, Color(1.0, 0.88, 0.55, 0.3 * gold_k * k), 16.0 * unit, true)
		draw_line(p0, p1, Color(_look.near.lerp(Palette.GOLD.lightened(0.2), gold_k), 0.9 * k), lerpf(1.5, 3.5, k) * unit, true)


## Where two of her kneeling pieces meet, measured once, at home.
func _shared_edge(a: int, b: int) -> Array:
	var key := a * 1000 + b
	if _edges.has(key):
		return _edges[key]
	var pa := _home_poly(a)
	var pb := _home_poly(b)
	var shared: Array = []
	for p in pa:
		for q in pb:
			if p.distance_squared_to(q) < 4.0:
				shared.append(p)
				break
	var out: Array = [shared[0], shared[shared.size() - 1]] if shared.size() >= 2 else []
	_edges[key] = out
	return out


## The line up her, its barriers, the light and its notes of light.
func _draw_climb(unit: float) -> void:
	var line: Color = _look.line
	draw_polyline(_path, Color(line, 0.85), 5.0 * unit, true)
	for i in range(_gate, BARRIERS):
		var s := _gates[i]
		var p := _pos_at(s)
		var across := (_pos_at(s + 4.0) - p).normalized().orthogonal()
		var hurt := 1.0 - _hp / BARRIER_HP if i == _gate else 0.0
		var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * hurt * 3.0 * _kick
		draw_line(p - across * 34.0 + shake, p + across * 34.0 + shake, line, 6.0 * unit, true)
	var light := _pos_at(_s)
	BeatNotes.draw(self, light, func(d: float) -> Vector2: return _pos_at(_s - d) if _s - d > 0.0 else Vector2.INF, 1.0, 0.6)
	_draw_light(light, unit)


## The way down draws itself a little ahead of the light, gold behind it.
func _draw_descent(unit: float) -> void:
	var s := (_desc.size() - 1) * 4.0 * clampf(_beats / DESC_BEATS, 0.0, 1.0)
	var here := int(s / 4.0)
	var ahead := mini(_desc.size(), int((s + 300.0) / 4.0))
	if here > 1:
		draw_polyline(_desc.slice(0, here + 1), Color(Palette.GOLD, 0.75), 4.0 * unit, true)
	for i in range(here, ahead - 1):
		var k := (i - here) / float(ahead - here)
		draw_line(_desc[i], _desc[i + 1], Color(_look.line, 0.8 * (1.0 - k)), 4.0 * unit, true)
	var light := _desc_light()
	BeatNotes.draw(self, light, func(d: float) -> Vector2: return _on(_desc, s + d) if s + d < (_desc.size() - 1) * 4.0 else Vector2.INF, 1.0, 1.0)
	_draw_light(light, unit)


func _draw_light(at: Vector2, unit: float) -> void:
	for i in 6:
		var k := i / 5.0
		draw_circle(at, lerpf(60.0, 10.0, k) * unit * (1.0 + 0.15 * _kick), Color(Palette.GOLD.lightened(0.4), 0.08 + 0.2 * k))
	draw_circle(at, 9.0 * unit, Color(1.0, 0.98, 0.9))
