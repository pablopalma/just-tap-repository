extends Node2D
## Builds the layers, routes taps to GameState and drives the camera through events (§11, §13).
## Input is never blocked: the player can keep tapping during every cinematic.

enum Mode { INTRO, PLAY, EVENT, FINAL }

const EVENT_TIME := 6.0
const FINAL_DELAY := 6.4
const END_DELAY := 5.0
## The bird also shows up on its own every few minutes of play.
const BIRD_EVERY := Vector2(150.0, 240.0)

var path := PathData.new()
var mode := Mode.INTRO

# Untyped on purpose: they carry scripts attached at runtime.
var washes
var path_view
var gates
var tip
var figure
var shapes
var star
var forks
var fx
var spark
## Between zones: the Droste dive into the tip (scripts/world/droste.gd).
var droste
var _droste_zone := 0
## The voice has stopped the game to tell a story (scripts/ui/story.gd).
var _story := false
## The starry night (scripts/world/night.gd): zone NIGHT_ZONE, just before the dark.
var night
const NIGHT_ZONE := 4
## Beings asleep along the way that wake when their barriers break (scripts/world/creature.gd).
var creatures: Array = []
var camera
var hud
var tree_panel
## Prototype: the tree beside the line instead of the panel (BuildFlags.TREE_INLINE, F1 switches it).
var inline_tree
var tree_inline := BuildFlags.TREE_INLINE
var zone_title: Screens.ZoneTitle
var end_screen: Screens.EndScreen
var intro: Screens.Intro
var subtitle: Screens.Subtitle
var cinema: Screens.Cinema
## Story cinematics (§22.1). A director (the trailer) turns them off.
var cinematics_enabled := true
const CINE_DELAY := 0.6
const CINE_TAIL := 2.6
const CINE_MAX := 16.0
var _cine := false
## Panoramas (a few seconds of pulled-back camera over the city being built).
const PANO_TIME := 6.0
## How far a panorama pulls back, against the normal zoom: far enough that the distant landscape and the
## tower line up (the landscape's parallax factor), so each structure stands beside its own zone.
const PANO_ZOOM := 0.13
var _pano := 0.0
var _cine_t := 0.0
var _cine_tail := -1.0
var _cine_gate := 0
var _cine_beat := 0.0
## The demo's "now" cinematic (the end of the dark): the tip breaks the last barriers on its own, on
## the beat, in one continuous run, while the voice talks about this moment.
var _now := false
var _now_t := 0.0
var _now_beat := 0.0
var _now_note := 0
## Holding the button (or space) down taps on its own, once every half beat, after HOLD_DELAY:
## gentler than tapping, but the arm rests (JUST_TAP_GODOT.md §1, "tocar con la música").
const HOLD_DELAY := 0.4
var _holding := false
var _hold_t := 0.0
var _hold_half := 0
const NOW_START := 1.6  # seconds of bars and silence before the first hit
var depth: DepthBackground
var bird: GiantBird
var landscape: Landscape
var colour_wave: ColourWave
var darkness: Darkness
## The demo's dark stretch (BuildFlags.DARK_FROM..DEMO_LAST): chaos behind, the tower crumbling,
## and at its end the whale.
var chaos: Chaos
var crumble
var whale: CelestialWhale
var _dark := false
var flash: ColorRect
## Only in debug builds (editor, debug exports).
var dev_menu: DevMenu

var _event_t := 0.0
var _event_center := Vector2.ZERO
var _event_zoom := 1.0
var _final_pending := -1.0
var _final_t := 0.0
var _end_shown := false
var _letter_shown := false
## The ending's grand reveal has started ("You made all of this").
var _grand := false
var _grand_t := 0.0
## The demo ended at its last barrier (BuildFlags.DEMO): its own ending runs instead of the game's.
var _demo_end := false
## Give up waiting for the voice after this long in the ending.
const LETTER_MAX_WAIT := 60.0
var _bird_wait := 0.0
var _flash_tween: Tween


func _ready() -> void:
	_build()
	GameState.hit.connect(_on_hit)
	GameState.gate_broken.connect(_on_gate_broken)
	GameState.zone_completed.connect(_on_zone_completed)
	GameState.chapter_unlocked.connect(_on_chapter_unlocked)
	GameState.game_finished.connect(_on_finished)
	GameState.demo_finished.connect(_on_demo_finished)
	GameState.reborn.connect(_on_reborn)
	camera.target_pos = Vector2(0, PathData.START_Y - 260)
	camera.target_zoom = _base_zoom()
	camera.snap()
	_bird_wait = randf_range(BIRD_EVERY.x, BIRD_EVERY.y)
	# The title theme plays on the menu, until the first tap (a director keeps its own score).
	if not Music.locked:
		Music.play_theme()


func _build() -> void:
	var paper_layer := CanvasLayer.new()
	paper_layer.layer = -10
	add_child(paper_layer)
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/paper.gdshader")
	paper.material = mat
	paper_layer.add_child(paper)

	depth = DepthBackground.new()
	add_child(depth)
	landscape = Landscape.new()
	add_child(landscape)
	colour_wave = ColourWave.new()
	add_child(colour_wave)
	darkness = Darkness.new()
	add_child(darkness)
	bird = GiantBird.new()
	add_child(bird)
	chaos = Chaos.new()
	add_child(chaos)
	chaos.settled.connect(_on_chaos_settled)
	whale = CelestialWhale.new()
	add_child(whale)
	whale.passing.connect(_on_whale_passing)
	whale.gone.connect(_on_whale_gone)
	bird.passed_close.connect(_on_bird_close)

	var font := UIStyle.font()
	washes = _node("Washes", "res://scripts/world/washes.gd")
	shapes = _node("MusicShapes", "res://scripts/world/music_shapes.gd")
	figure = _node("BarrierFigure", "res://scripts/world/barrier_figure.gd")
	figure.path = path
	path_view = _node("Path", "res://scripts/world/path_view.gd")
	path_view.setup(path)
	gates = _node("Gates", "res://scripts/world/gates.gd")
	gates.path = path
	gates.font = font
	forks = _node("Forks", "res://scripts/world/forks.gd")
	forks.path = path
	forks.font = font
	forks.split_burst.connect(_on_split_burst)
	forks.join_burst.connect(_on_join_burst)
	star = _node("Star", "res://scripts/world/star_circuit.gd")
	star.path = path
	star.burst.connect(_on_star_burst)
	tip = _node("Tip", "res://scripts/world/tip.gd")
	tip.path = path
	fx = _node("FX", "res://scripts/world/fx.gd")
	fx.font = UIStyle.italic()
	spark = _node("Spark", "res://scripts/world/spark.gd")
	spark.tip = tip
	spark.visible = false
	spark.landed.connect(_on_spark_landed)
	droste = load("res://scripts/world/droste.gd").new()
	add_child(droste)
	droste.turned.connect(_on_droste_turned)
	droste.done.connect(_on_droste_done)
	night = load("res://scripts/world/night.gd").new()
	night.path = path
	night.first = (NIGHT_ZONE - 1) * 10 + 1
	night.last = NIGHT_ZONE * 10
	add_child(night)
	# What you connect gives life: a firefly in the first zone, a deer of stars in the night (the
	# whale, in the dark, is the third).
	creatures = [
		_creature("firefly", [3, 5, 7, 9], Vector2(0.8, 0.3), 0.1),
		_creature("deer", [31, 33, 35, 37, 39], Vector2(0.24, 0.32), 0.19),
	]
	creatures[1].inverted = true  # it lives in the night, under the world's negative
	crumble = _node("Crumble", "res://scripts/world/crumble.gd")
	crumble.path = path
	crumble.quaked.connect(_on_quake)
	inline_tree = _node("InlineTree", "res://scripts/world/inline_tree.gd")
	inline_tree.tip = tip
	inline_tree.path = path
	inline_tree.fx = fx
	inline_tree.font = font

	camera = Camera2D.new()
	camera.set_script(load("res://scripts/world/camera.gd"))
	add_child(camera)
	camera.make_current()
	spark.camera = camera
	inline_tree.camera = camera

	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UIStyle.theme()
	ui_layer.add_child(ui)

	flash = ColorRect.new()
	flash.color = Color(1.0, 0.985, 0.95, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)

	hud = Control.new()
	hud.set_script(load("res://scripts/ui/hud.gd"))
	hud.modulate.a = 0.0
	ui.add_child(hud)
	zone_title = Screens.ZoneTitle.new()
	ui.add_child(zone_title)
	cinema = Screens.Cinema.new()
	ui.add_child(cinema)
	subtitle = Screens.Subtitle.new()
	ui.add_child(subtitle)
	Narrator.line_started.connect(_on_line)
	end_screen = Screens.EndScreen.new(BuildFlags.DEMO)
	end_screen.rebirth_pressed.connect(GameState.rebirth)
	end_screen.new_game_pressed.connect(_restart)
	ui.add_child(end_screen)
	tree_panel = Control.new()
	tree_panel.set_script(load("res://scripts/ui/tree_panel.gd"))
	ui.add_child(tree_panel)
	hud.tree_pressed.connect(tree_panel.open_panel)
	tree_panel.visibility_changed.connect(func() -> void: Telemetry.tree_visible(tree_panel.visible))
	_set_tree_inline(tree_inline)
	if OS.is_debug_build():
		dev_menu = DevMenu.new()
		dev_menu.action.connect(_on_dev)
		ui.add_child(dev_menu)
	intro = Screens.Intro.new(SaveSystem.had_progress)
	intro.continue_pressed.connect(_start)
	intro.new_game_pressed.connect(_new_game)
	ui.add_child(intro)


func _node(node_name: String, script_path: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	n.set_script(load(script_path))
	add_child(n)
	return n


func _unhandled_input(e: InputEvent) -> void:
	var pressed := false
	if e is InputEventMouseButton:
		pressed = e.is_pressed() and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	elif e is InputEventScreenTouch:
		# The first finger arrives as an emulated mouse click; extra fingers count on their own.
		pressed = e.is_pressed() and (e as InputEventScreenTouch).index > 0
	elif dev_menu and e is InputEventKey and e.is_pressed() and (e as InputEventKey).keycode == KEY_F1:
		dev_menu.toggle()
		return
	elif dev_menu and e is InputEventKey and e.is_pressed() and (e as InputEventKey).keycode == KEY_F9:
		# For recording: replay the colour coming back where the camera is.
		colour_wave.reveal(camera.position, Palette.chapter_color(randi_range(1, 4)))
		return
	elif e is InputEventKey:
		pressed = e.is_pressed() and not e.is_echo() and (e as InputEventKey).keycode == KEY_SPACE
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if not e is InputEventKey and inline_tree.try_tap(e.get("position")):
		return  # a node of the tree: bought, never a hit
	if _cine or _now or _story:
		return  # in a cinematic the tip plays on its own; in a story, we listen
	if mode == Mode.INTRO:
		_start()
	else:
		GameState.tap("tap", Music.beat_at_tap())
		_holding = true
		_hold_t = 0.0
		_hold_half = Music.half_beat()


## While the tap that started it is still held: one soft tap on every half beat.
func _process_hold(delta: float) -> void:
	if not _holding:
		return
	var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)
	if not down or mode != Mode.PLAY or _cine or _now or _story or droste.is_playing():
		_holding = false
		return
	_hold_t += delta
	var half := Music.half_beat()
	if half != _hold_half:
		_hold_half = half
		if _hold_t >= HOLD_DELAY:
			GameState.tap("tap", -1, true)


## The intro fades in 3 s, the spark comes down onto the tip, the HUD appears in 2 s and the line
## climbs from below to the first barrier.
func _start() -> void:
	if intro == null:
		return
	intro.dismiss()
	intro = null
	spark.play()
	create_tween().tween_property(hud, "modulate:a", 1.0, 2.0).set_delay(0.6)
	Music.start()
	Music.stop_theme()
	_demo_end = BuildFlags.DEMO and GameState.finished and GameState.stage >= BuildFlags.DEMO_LAST
	_face_zone()  # a save inside a zone that runs its own way
	# The voice greets once the line has started climbing.
	get_tree().create_timer(2.5).timeout.connect(_greet.bind(SaveSystem.had_progress))
	if GameState.finished:
		_enter_final(true)
		return
	mode = Mode.PLAY
	GameState.running = true
	if BuildFlags.is_dark(GameState.stage):
		_enter_dark(true)  # a save from inside the dark


## The spark has become the tip: a soft wave of gold from it, and a note.
func _on_spark_landed() -> void:
	colour_wave.pass_wave(tip.position, Palette.GOLD, 0.3)
	Music.play_celesta(0)


func _on_line(id: String, text: String, duration: float) -> void:
	subtitle.show_line(text, duration)
	if id == "made":
		_begin_grand()


## Start over from the intro: erase the save, rebuild the world from barrier 1 and begin.
func _new_game() -> void:
	GameState.new_game()
	SaveSystem.had_progress = false
	SaveSystem.save_game()
	tip.lit = 0.0
	gates.reset()
	landscape.reset()
	fx.clear()
	washes.clear()
	for c in creatures:
		c.reset()
	_start()


# --- Panoramas ----------------------------------------------------------------

## The camera pulls back for a few seconds and the distant landscape comes closer and takes some
## colour: the city being built, seen whole for a moment. Taps keep working all along.
func _panorama() -> void:
	if not cinematics_enabled or mode != Mode.PLAY or _cine or star.is_active() or GameState.finished:
		return
	_pano = PANO_TIME


# --- Story cinematics (§22.1) -------------------------------------------------

## Reaching a barrier the voice talks about plays it as a cinematic, once per run.
func _maybe_cinematic(n: int) -> void:
	if not cinematics_enabled or not VoiceLines.ON_REACH.has(n) or GameState.cinemas.has(n) or BuildFlags.is_dark(n):
		return
	if GameState.finished or mode != Mode.PLAY:
		return
	GameState.cinemas[n] = true
	get_tree().create_timer(CINE_DELAY).timeout.connect(_begin_cinematic.bind(n))


## Bars in, HUD out, subtitles into the bottom bar; the tip taps on its own on every beat.
func _begin_cinematic(n: int) -> void:
	if GameState.stage != n or GameState.finished or _cine:
		return
	_cine = true
	_cine_t = 0.0
	_cine_tail = -1.0
	_cine_gate = n
	_cine_beat = Music.beat_phase()
	GameState.cinematic = true
	cinema.show_bars(true)
	subtitle.cinema = true
	tip.trail = true
	create_tween().tween_property(hud, "modulate:a", 0.0, 1.0)


func _process_cinematic(delta: float) -> void:
	_cine_t += delta
	if _cine_tail >= 0.0:
		_cine_tail -= delta
		if _cine_tail < 0.0:
			_stop_cinematic(false)
		return
	if GameState.stage != _cine_gate or GameState.finished:
		_cine_tail = CINE_TAIL
		return
	# One hit on every beat, once the bars are in: the ball plays a little melody.
	var phase := Music.beat_phase()
	if phase < _cine_beat and _cine_t > 1.0:
		GameState.tap("cine")
		fx.ring(tip.position, Palette.line_col(GameState.stage), 46.0, 0.9)
	_cine_beat = phase
	if _cine_t > CINE_MAX:
		GameState.hp = 0.0
		GameState.tap("cine")


func _stop_cinematic(instant: bool) -> void:
	if not _cine and not instant:
		return
	_cine = false
	GameState.cinematic = false
	subtitle.cinema = false
	tip.trail = false
	if instant:
		cinema.amount = 0.0
		return
	if mode != Mode.EVENT:
		cinema.show_bars(false, 1.2)
	if mode == Mode.PLAY:
		create_tween().tween_property(hud, "modulate:a", 1.0, 1.2)


func _greet(returning: bool) -> void:
	if returning:
		Narrator.say("00b", false)
	else:
		Narrator.say("00")


func _process(delta: float) -> void:
	if _cine:
		_process_cinematic(delta)
	if _now:
		_process_now(delta)
	_process_hold(delta)
	path_view.lit = tip.lit
	tip.scale = Vector2.ONE * path.grow_at(tip.lit)  # grows towards the spiral's centre
	inline_tree.active = tree_inline and GameState.running and not GameState.finished \
		and mode == Mode.PLAY and not _cine and not _now and _pano <= 0.0 and not droste.is_playing() \
		and not _story
	subtitle.high = inline_tree.active and inline_tree.is_narrow()
	shapes.focus = camera.position
	path_view.width_scale = maxf(1.0, 0.9 / camera.zoom.x)
	droste.tip_screen = tip.get_global_transform_with_canvas().origin
	_tend_creatures()
	if whale.sleeping:
		# its threads run down to the dark's barriers, wherever they are on screen
		var ct := get_viewport().get_canvas_transform()
		var at := PackedVector2Array()
		for i in CelestialWhale.NODES.size():
			at.append(ct * path.gate_pos(BuildFlags.DARK_FROM + i))
		whale.anchors = at
	match mode:
		Mode.INTRO, Mode.PLAY:
			camera.k = 2.2
			if droste.is_playing():
				# Falling into the tip (and, turned, out into the next zone).
				camera.k = 9.0
				camera.target_pos = tip.position
				camera.target_zoom = _base_zoom() * droste.zoom_mul()
			elif star.is_active():
				# The whole star in view.
				camera.target_pos = star.center() + Vector2(0, -20)
				camera.target_zoom = _base_zoom() * 0.72
			elif forks.is_active():
				var f: Vector2 = forks.focus()
				camera.target_pos = Vector2(f.x * 0.5, f.y - 70.0)
				camera.target_zoom = _base_zoom() * 0.92
			elif _pano > 0.0:
				_pano -= delta
				camera.k = 0.8
				# Look down at what has been built, with the tip near the top of the view.
				camera.target_pos = Vector2(0.0, tip.position.y + 1100.0)
				camera.target_zoom = _base_zoom() * PANO_ZOOM
			elif _now:
				# Slowly back, until the landscape around this moment is in view.
				var s := smoothstep(0.0, 20.0, _now_t)
				camera.k = 0.7
				camera.target_pos = Vector2(tip.position.x * 0.4, tip.position.y + lerpf(-50.0, 240.0, s))
				camera.target_zoom = _base_zoom() * lerpf(1.12, 0.5, s)
			elif _cine:
				camera.k = 1.4
				camera.target_pos = Vector2(tip.position.x * 0.6, tip.position.y - 50.0)
				camera.target_zoom = _base_zoom() * 1.18
			elif path.on_spiral(tip.lit):
				# On the spiral: right with the tip as it winds round, and a little back so the
				# spiral shows, while the tip grows towards its centre.
				camera.target_pos = tip.position
				camera.target_zoom = _base_zoom() * 0.7
			else:
				camera.target_pos = Vector2(tip.position.x * 0.5, tip.position.y - 70.0 + inline_tree.lift())
				camera.target_zoom = _base_zoom()
		Mode.EVENT:
			camera.k = 1.1
			camera.target_pos = _event_center
			camera.target_zoom = _event_zoom
			_event_t -= delta
			if _event_t <= 0.0:
				mode = Mode.PLAY
				if not _cine:
					cinema.show_bars(false, 1.2)
		Mode.FINAL:
			var vs := get_viewport_rect().size
			if _grand:
				# Pull all the way back, slowly: the tower and the city built around it.
				camera.k = 0.35
				# The whole city (≈16 400 world units, from the first arch to the lighthouse) fits in the
				# upper part of the screen, so the end screen's text never covers it.
				var z := minf((vs.y - 220.0) / 17600.0, vs.x / 9000.0)
				camera.target_zoom = z
				camera.target_pos = Vector2(0, -7600.0 + 110.0 / z)
			else:
				# Until then, stay with the top of the tower.
				camera.k = 1.0
				camera.target_pos = path.gate_pos(BuildFlags.last_barrier() if _demo_end else PathData.FINAL) + Vector2(0, 120)
				camera.target_zoom = _base_zoom() * 0.75
			_final_t += delta
			if _demo_end:
				# The dark, the voice, then the sketched city, then the short letter.
				if not _grand and _final_t >= END_DELAY and (Narrator.is_idle() or _final_t > LETTER_MAX_WAIT):
					_begin_grand()
				elif _grand and not _letter_shown and _final_t - _grand_t > 11.0:
					_show_letter()
			# The voice says its last lines, then the creator's letter, then "you made colour".
			elif not _letter_shown and _final_t >= END_DELAY and (Narrator.is_idle() or _final_t > LETTER_MAX_WAIT):
				_show_letter()
	if _final_pending >= 0.0:
		_final_pending -= delta
		if _final_pending < 0.0:
			_enter_final(false)

	var tint := Palette.chapter_color(Palette.chapter_of(GameState.stage))
	# The landscape lines up with the tower as far as the camera has pulled back.
	if mode == Mode.PLAY or mode == Mode.EVENT:
		var zb := _base_zoom()
		landscape.glimpse = clampf(log(zb / camera.zoom.x) / log(1.0 / PANO_ZOOM), 0.0, 1.0)
	depth.focus = maxf(landscape.grand, landscape.glimpse * 0.6)
	depth.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size, tint)
	landscape.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size, tint)
	colour_wave.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size)
	crumble.view_center = camera.position
	crumble.view_half = get_viewport_rect().size * 0.5 / camera.zoom.x
	bird.set_tint(tint)
	if GameState.running and not GameState.finished and not _dark:
		_bird_wait -= delta
		if _bird_wait <= 0.0:
			_summon_bird()


func _base_zoom() -> float:
	# 640 along the line and 420 across it, whichever way the zone's line runs on screen.
	var vs := get_viewport_rect().size
	if absf(sin(camera.angle)) > 0.5:
		vs = Vector2(vs.y, vs.x)
	return minf(vs.y / 640.0, vs.x / 420.0)


# --- The Droste dive between zones ----------------------------------------------

## Which way zone z's line runs on screen (radians, the camera's angle). The line does not always
## climb: inside the last zone, the next one runs its own way, like thoughts do. 0 is up, -PI/2 to
## the right, PI/2 to the left, PI down. The dark (zone 5) and the last zone climb again, so the
## endings look at the city upright.
## Zone 3 is the spiral (PathData.SPIRAL_ZONE): it turns every way on its own, so it is seen upright.
const ZONE_ANGLE := {1: 0.0, 2: -PI / 2.0, 3: 0.0, 4: PI / 2.0, 5: 0.0, 6: PI, 7: PI / 4.0,
	8: -PI / 2.0, 9: -3.0 * PI / 4.0, 10: 0.0}
## A director (the trailer) keeps the view upright, so its shots stay as they were framed.
var turn_zones := true
var _turn_tween: Tween


func _zone_angle(z: int) -> float:
	return ZONE_ANGLE.get(z, 0.0) if turn_zones else 0.0


## Turns the view slowly, the short way round (where there is no dive to hide it: into the dark).
func _turn_to(target: float, time: float) -> void:
	if _turn_tween:
		_turn_tween.kill()
	var from: float = camera.angle
	var to := from + wrapf(target - from, -PI, PI)
	_turn_tween = create_tween()
	_turn_tween.tween_property(camera, "angle", to, time).set_trans(Tween.TRANS_SINE)


## The view the current barrier's zone is seen at, at once (a new game, a save, a jump).
func _face_zone() -> void:
	if _turn_tween:
		_turn_tween.kill()
	camera.angle = _zone_angle(Zones.of(GameState.stage))
	night.light_up_to(GameState.stage)
	_night_on(Zones.of(GameState.stage) == NIGHT_ZONE and not BuildFlags.is_dark(GameState.stage), 0.0)


## Between these two zones the voice stops and offers a story (scripts/ui/story.gd), once per run;
## told or not, the dive follows.
const STORY_AFTER_ZONE := 2
const STORY_KEY := "story1"


func _offer_story(z: int) -> void:
	GameState.cinemas[STORY_KEY] = true
	_story = true
	GameState.cinematic = true  # the barrier does not heal while we talk
	create_tween().tween_property(hud, "modulate:a", 0.0, 1.0)
	var s = load("res://scripts/ui/story.gd").new()
	s.finished.connect(_on_story_done.bind(z))
	# under the subtitles, so the words show over the memory
	subtitle.get_parent().add_child(s)
	subtitle.get_parent().move_child(s, subtitle.get_index())


func _on_story_done(_told: bool, z: int) -> void:
	_story = false
	GameState.cinematic = false
	create_tween().tween_property(hud, "modulate:a", 1.0, 1.2)
	_begin_droste(z)


## Each zone is the line inside the last one: fall into the tip and come out in the next zone.
func _begin_droste(z: int) -> void:
	_droste_zone = z
	droste.play()
	camera.add_trauma(0.25)


## The screen is all dot: turn the view to the next zone's direction, unseen (and, coming out
## into the night, the night is already there).
func _on_droste_turned() -> void:
	camera.angle = _zone_angle(_droste_zone + 1)
	camera.snap()
	_night_on(_droste_zone + 1 == NIGHT_ZONE, 0.0)


func _creature(kind: String, bars: Array, home: Vector2, size: float) -> Node:
	var c = load("res://scripts/world/creature.gd").new()
	c.kind = kind
	c.path = path
	c.tip = tip
	c.barriers.assign(bars)
	c.home = home
	c.size = size
	add_child(c)
	return c


## Each being falls asleep on the screen as the player comes near its barriers.
func _tend_creatures() -> void:
	for c in creatures:
		var first: int = c.barriers[0]
		var last: int = c.barriers[c.barriers.size() - 1]
		var near: bool = GameState.stage >= first - 2 and GameState.stage <= last
		if c.kind == "deer" and not night.is_on():
			continue  # a constellation: it only shows in the night sky
		if near and turn_zones and mode == Mode.PLAY and not GameState.finished and c._state == 0:
			c.sleep(GameState.stage)


## The night: the world in its negative, gently, and the sky full of stars. A director keeps the
## classic look (turn_zones).
func _night_on(on: bool, time: float) -> void:
	on = on and turn_zones
	if on == night.is_on():
		return
	night.set_on(on, time)
	if _dark:
		return  # the dark keeps its own darkness
	if time <= 0.0:
		darkness.amount = 0.12 if on else 0.0
		darkness.invert = 1.0 if on else 0.0
	else:
		darkness.to(0.12 if on else 0.0, time)
		darkness.invert_to(1.0 if on else 0.0, time)


func _on_droste_done() -> void:
	var z := _droste_zone
	var last := path.gate_pos(z * 10)
	_summon_bird()
	if not z in [2, 4, 6, 8]:
		colour_wave.pass_wave(tip.position, Palette.chapter_color(maxi(1, Palette.chapter_of(z * 10))))
		zone_title.show_title(Loc.t("zone_done") % Zones.ROMAN[z - 1], Loc.zone_name(z), Palette.INK)
	fx.ring(last, Palette.INK, 220.0, 2.4)


# --- Events -----------------------------------------------------------------

func _on_hit(damage: float, crit: bool, source: String) -> void:
	var run := GameState.accent
	tip.kick(6.0 if source == "auto" else (16.0 if run > 0 else 12.0))
	if run > 0:
		tip.accent(run)
	if _dark and source == "tap":
		crumble.tap(GameState.stage)
	gates.hit(0.25 if source == "auto" else (0.9 if run > 0 else 0.6))
	var p := path.gate_pos(GameState.stage) + Vector2(randf_range(-55, 55), randf_range(-26, -6))
	if crit:
		fx.float_text(p, Fmt.num(damage), Palette.chapter_color(maxi(1, Palette.chapter_of(GameState.stage))), 24)
	elif run > 0:
		fx.float_text(p, Fmt.num(damage), Palette.GOLD.darkened(0.25), 15 + mini(run, 8))
	elif source != "auto":
		fx.float_text(p, Fmt.num(damage), Color(Palette.INK, 0.8), 15)


func _on_gate_broken(n: int) -> void:
	_maybe_cinematic(n + 1)
	if _dark and BuildFlags.is_dark(n):
		whale.light(n - BuildFlags.DARK_FROM)  # what you connect gives life: one of its stars
	if night.is_on():
		night.light(n)  # at night the barriers are stars
	for c in creatures:
		c.light(n)
	if BuildFlags.DEMO and n == BuildFlags.DARK_FROM - 1:
		# The colour of the zone comes back for a moment… then the dark.
		get_tree().create_timer(EVENT_TIME * 0.7).timeout.connect(_enter_dark.bind(false))
	elif _dark and n < BuildFlags.DEMO_LAST:
		_dark_step(n)
		if _now:
			Narrator.say_now(VoiceLines.NOW[n - BuildFlags.now_from() + 1])
		elif n + 1 == BuildFlags.now_from():
			_maybe_now()
	# Halfway through every zone, step back and look at what is being built.
	if n % 10 == 5:
		get_tree().create_timer(1.2).timeout.connect(_panorama)
	var p := path.gate_pos(n)
	var col := Palette.paint_col(Zones.of(n), n)
	washes.aura(p, col)
	fx.aura(p, col)
	fx.float_text(p + Vector2(0, -30), "+◆ " + Fmt.num(GameState.reward(n)),
		Palette.chapter_color(Palette.chapter_of(n)).darkened(0.2), 20, 1.8)
	hud.pulse()
	landscape.build_piece(n)


## The camera pulls back to take in the zone's ten barriers.
func _on_zone_completed(z: int) -> void:
	if BuildFlags.DROSTE and cinematics_enabled and not BuildFlags.is_dark(z * 10 + 1):
		if z == STORY_AFTER_ZONE and not GameState.cinemas.has(STORY_KEY):
			_offer_story(z)
		else:
			_begin_droste(z)
		return
	# No dive (into the dark, or a director's cut): the world turns slowly to the next zone's way.
	if absf(wrapf(_zone_angle(z + 1) - camera.angle, -PI, PI)) > 0.01:
		_turn_to(_zone_angle(z + 1), EVENT_TIME)
	cinema.show_bars(true)
	var first := path.gate_pos((z - 1) * 10 + 1)
	var last := path.gate_pos(z * 10)
	_event_center = (first + last) * 0.5
	var vs := get_viewport_rect().size
	# Pull back far enough to see the city growing around the zone (see PANO_ZOOM).
	_event_zoom = _base_zoom() * PANO_ZOOM * 1.3
	_event_t = EVENT_TIME
	mode = Mode.EVENT
	fx.ring(last, Palette.INK, 220.0, 2.4)
	# Screen shake is kept for the big moments only: a zone, a colour, the bird passing close.
	camera.add_trauma(0.8)
	camera.punch(0.06)
	_flash(0.3, 1.2)
	_summon_bird()
	if not z in [2, 4, 6, 8]:
		colour_wave.pass_wave(last, Palette.chapter_color(maxi(1, Palette.chapter_of(z * 10))))
		zone_title.show_title(Loc.t("zone_done") % Zones.ROMAN[z - 1], Loc.zone_name(z), Palette.INK)


func _on_chapter_unlocked(idx: int) -> void:
	var col := Palette.chapter_color(idx)
	zone_title.show_title(Loc.t("colour_back"), Loc.chapter_name(idx), col.darkened(0.1))
	washes.bloom(_event_center, col, 1400.0)
	colour_wave.reveal(_event_center, col)
	camera.add_trauma(1.0)
	_flash(0.45, 2.0)


## The star is complete: the lights meet at the centre and burst; one light goes on.
func _on_star_burst(pos: Vector2) -> void:
	for i in 3:
		fx.ring(pos, Palette.GOLD if i != 1 else Palette.chapter_color(maxi(1, Palette.chapter_of(GameState.stage))), 160.0 + i * 70.0, 1.8 + i * 0.3)
	fx.aura(pos, Palette.GOLD)
	washes.aura(pos, Palette.GOLD)
	colour_wave.pass_wave(pos, Palette.GOLD)
	Music.choir_swell()
	Music.build_piece(9, 0.0, 1.5)
	camera.add_trauma(0.6)
	camera.punch(0.06)
	_flash(0.4, 1.6)


## The line splits: golden rings closing in, a flash, and the branches shoot out.
func _on_split_burst(pos: Vector2, _count: int) -> void:
	for i in 3:
		fx.ring(pos, Palette.GOLD, 120.0 + i * 60.0, 1.4 + i * 0.3)
	washes.aura(pos, Palette.GOLD)
	colour_wave.pass_wave(pos, Palette.GOLD)
	Music.choir_swell()
	Music.build_piece(4, 0.0, 1.2)
	camera.add_trauma(0.5)
	camera.punch(0.05)
	_flash(0.35, 1.3)


## The last join: every branch back into one line.
func _on_join_burst(pos: Vector2) -> void:
	for i in 3:
		fx.ring(pos, Palette.GOLD, 100.0 + i * 50.0, 1.6)
	colour_wave.pass_wave(pos, Palette.GOLD)
	Music.build_piece(9, 0.0, 1.5)
	_flash(0.25, 1.4)


func _summon_bird() -> void:
	_bird_wait = randf_range(BIRD_EVERY.x, BIRD_EVERY.y)
	bird.fly()


func _on_bird_close() -> void:
	colour_wave.pass_wave(camera.position, Palette.chapter_color(maxi(1, Palette.chapter_of(GameState.stage))))
	camera.add_trauma(0.35)
	_flash(0.15, 1.0)


## Brief cream flash over the whole screen.
func _flash(alpha: float, duration: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	flash.color.a = maxf(flash.color.a, alpha)
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_finished() -> void:
	colour_wave.reveal(path.gate_pos(PathData.FINAL), Palette.GOLD)
	_final_pending = FINAL_DELAY


## "You made all of this": everything built comes into view, in colour.
func _begin_grand() -> void:
	if _grand:
		return
	_grand = true
	_grand_t = _final_t
	if _demo_end:
		# The dark lifts on a city that is mostly still a sketch.
		darkness.to(0.0, 4.0)
		landscape.set_grand(true, 7.0, true)
		colour_wave.pass_wave(path.gate_pos(BuildFlags.DEMO_LAST), Palette.GOLD, 1.0)
		Music.choir_swell()
		create_tween().tween_property(hud, "modulate:a", 0.0, 2.0)
		return
	landscape.set_grand(true)
	colour_wave.pass_wave(path.gate_pos(PathData.FINAL), Palette.GOLD)
	colour_wave.pass_wave(path.gate_pos(50), Palette.GOLD, 1.5)
	colour_wave.pass_wave(path.gate_pos(1), Palette.GOLD, 3.0)
	Music.choir_swell()
	Music.build_piece(9, 0.0, 6.0)
	bird.fly()
	_flash(0.25, 2.5)
	# Nothing between the player and what they built.
	create_tween().tween_property(hud, "modulate:a", 0.0, 2.0)


# --- Dev menu (debug builds only) -------------------------------------------

func _on_dev(id: String, arg: int) -> void:
	match id:
		"jump":
			_dev_jump(arg)
		"edge":
			# Arrive at the barrier and break it a moment later, so its event plays out.
			_dev_jump(arg)
			get_tree().create_timer(1.4).timeout.connect(_dev_break)
		"grand":
			_dev_jump(PathData.FINAL)
			GameState.finished = true
			GameState.hp = 0.0
			_enter_final(false)
			# Just the city: no letter opening on top of it.
			_letter_shown = true
			get_tree().create_timer(1.5).timeout.connect(_begin_grand)
		"letter":
			_show_letter()
		"end":
			_show_end()
		"break":
			_dev_break()
		"damage":
			GameState.dev_damage = 1.0 if arg == 1 else GameState.dev_damage * arg
		"light":
			GameState.add_light(arg)
		"bird":
			_summon_bird()
		"quake":
			if _dark:
				crumble.quake(1.0)
			else:
				camera.add_trauma(0.6)
		"whale":
			whale.swim()
		"wave":
			colour_wave.reveal(camera.position, Palette.chapter_color(randi_range(1, 4)))
		"lang":
			SaveSystem.set_lang("en" if SaveSystem.lang == "es" else "es")
		"tree_inline":
			_set_tree_inline(not tree_inline)


## With the tree beside the line, the HUD's tree button and the panel step aside.
func _set_tree_inline(on: bool) -> void:
	tree_inline = on
	hud._tree.visible = not on
	if on and tree_panel.visible:
		tree_panel.close_panel()


func _dev_jump(n: int) -> void:
	if intro != null:
		_start()
	_stop_cinematic(true)
	_pano = 0.0
	# Visuals first: the jump itself may start a star or a fork, which must survive.
	colour_wave.clear()
	bird.stop()
	zone_title.hide_now()
	gates.reset()
	star.reset()
	forks.reset()
	figure.reset()
	shapes.clear()
	fx.clear()
	washes.clear()
	landscape.reset()
	_clear_dark()
	GameState.dev_jump(n)
	_face_zone()
	camera.snap()
	GameState.running = true
	mode = Mode.PLAY
	_final_pending = -1.0
	_grand = false
	_end_shown = false
	_letter_shown = false
	end_screen.visible = false
	hud.modulate.a = 1.0
	tip.lit = maxf(0.0, path.gate_len(n) - 260.0)
	if BuildFlags.is_dark(n):
		_enter_dark(true)


func _dev_break() -> void:
	if GameState.finished:
		return
	GameState.hp = 0.0
	GameState.tap("tap")


func _show_letter() -> void:
	_letter_shown = true
	var letter := Screens.Letter.new(GameState.total_taps, _demo_end)
	letter.finished.connect(_show_end)
	hud.get_parent().add_child(letter)


func _show_end() -> void:
	if _end_shown:
		return
	_end_shown = true
	end_screen.show_end()
	Music.play_theme()  # the title theme again, under the end screen


func _enter_final(immediate: bool) -> void:
	mode = Mode.FINAL
	_final_t = END_DELAY if immediate else 0.0
	_end_shown = false
	# A finished game loaded from a save goes straight to the end: the letter was already read.
	_letter_shown = immediate
	_grand = false
	if immediate:
		_show_end()
	GameState.running = false


# --- The demo's dark stretch ---------------------------------------------------

## How much chaos at the current barrier: full when the dark begins, calmer with each barrier.
func _dark_level() -> float:
	var k := float(GameState.stage - BuildFlags.DARK_FROM) / float(BuildFlags.DEMO_LAST - BuildFlags.DARK_FROM)
	return lerpf(1.0, 0.35, clampf(k, 0.0, 1.0))


## The dark comes in: the world turns white on black, the line cracks, what was built starts to
## break apart, the background turns to chaos and the tower crumbles. immediate: arriving inside it (a save, the dev menu), no build-up.
func _enter_dark(immediate: bool) -> void:
	if _dark or not BuildFlags.is_dark(GameState.stage) or GameState.finished:
		return
	_dark = true
	Music.dark = true
	Music.prepare_dark()
	var level := _dark_level()
	darkness.to(lerpf(0.25, 0.5, level), 0.5 if immediate else 6.0)
	darkness.invert_to(1.0, 0.5 if immediate else 4.0)
	chaos.start(level, immediate)
	crumble.start(level)
	# The whale sleeps in the sky through the dark; each barrier broken here lights one of its stars.
	whale.sleep(GameState.stage - BuildFlags.DARK_FROM)
	night.set_on(false, 0.5 if immediate else 6.0)  # the night deepens into the dark
	if immediate:
		landscape.break_to(0.5, 0.5)
		return
	landscape.break_to(0.3, 2.5)
	var at := path.gate_pos(BuildFlags.DARK_FROM - 1)
	fx.crack(at + Vector2(0, 10), 320.0, 5.0)
	fx.crack(path.gate_pos(BuildFlags.DARK_FROM - 3), 260.0, 6.0)
	fx.crack(path.gate_pos(BuildFlags.DARK_FROM - 6), 220.0, 7.0)
	camera.add_trauma(0.6)
	landscape.tremble = 1.0
	Music.tremor(1.0)
	get_tree().create_timer(2.5).timeout.connect(bird.fly.bind(true))


## A barrier broken in the dark: it calms a little, but the line cracks where it broke.
func _dark_step(n: int) -> void:
	if _now:
		camera.add_trauma(0.15)  # the quiet holds: no cracks, no chaos
		return
	var level := _dark_level()
	chaos.calm(level)
	crumble.intensity = level
	darkness.to(lerpf(0.25, 0.5, level), 3.0)
	fx.crack(path.gate_pos(n) + Vector2(0, 10), 200.0, 3.0)
	camera.add_trauma(0.3)


## Reaching the demo's last barriers in the dark plays the "now" cinematic, once per run.
func _maybe_now() -> void:
	if not cinematics_enabled or GameState.cinemas.has(BuildFlags.now_from()):
		return
	GameState.cinemas[BuildFlags.now_from()] = true
	get_tree().create_timer(CINE_DELAY).timeout.connect(_begin_now)


## Bars in, HUD out; the chaos quiets, and from here the tip goes on alone: one hit on every beat,
## a rising arpeggio on every half beat, each barrier giving way in NOW_HITS hits with its figure
## drawn whole. The voice says one line per barrier; the last one breaking ends the demo.
func _begin_now() -> void:
	if not _dark or GameState.finished or GameState.stage != BuildFlags.now_from() or _now:
		return
	_stop_cinematic(true)
	_now = true
	_now_t = 0.0
	_now_beat = Music.beat_phase()
	_now_note = 0
	GameState.cinematic = true
	cinema.show_bars(true)
	subtitle.cinema = true
	tip.trail = true
	create_tween().tween_property(hud, "modulate:a", 0.0, 1.0)
	# The noise of the dark falls away: only this moment is left.
	chaos.calm(0.12)
	crumble.intensity = 0.08
	landscape.tremble = 0.0
	landscape.break_to(0.2, 8.0)
	darkness.to(0.2, 12.0)
	Music.choir_swell()
	Narrator.say_now(VoiceLines.NOW[0])


func _process_now(delta: float) -> void:
	_now_t += delta
	if GameState.finished or not _dark:
		return
	var phase := Music.beat_phase()
	var half := fmod(phase * 2.0, 1.0)
	var prev_half := fmod(_now_beat * 2.0, 1.0)
	if _now_t > NOW_START and half < prev_half:
		# Every half beat a note of one long arpeggio that never stops between barriers…
		Music.settle_note(_now_note % 10)
		_now_note += 1
		# …and on the beat itself, the tip hits.
		if phase < _now_beat:
			GameState.tap("now")
			fx.ring(tip.position, Color(Palette.GOLD, 0.9), 54.0, 1.1)
	_now_beat = phase


func _end_now() -> void:
	if not _now:
		return
	_now = false
	GameState.cinematic = false
	tip.trail = false


func _on_quake(strength: float) -> void:
	camera.add_trauma(0.25 + 0.45 * strength)
	landscape.tremble = maxf(landscape.tremble, strength)
	landscape.break_to(minf(1.0, landscape.broken + 0.05 + 0.12 * strength))


## The demo's last barrier broke: the chaos finds its order, the cracks fill with gold, and
## something awakens.
func _on_demo_finished() -> void:
	if _now:
		Narrator.say_now(VoiceLines.NOW[VoiceLines.NOW.size() - 1])
	_end_now()
	_demo_end = true
	crumble.active = false  # what is already falling keeps falling
	# Step back to take in the mandala around the tip.
	mode = Mode.EVENT
	_event_center = tip.position + Vector2(0, -40)
	_event_zoom = _base_zoom() * 0.8
	_event_t = 60.0
	cinema.show_bars(true)
	create_tween().tween_property(hud, "modulate:a", 0.0, 1.5)
	if chaos.active:
		chaos.resolve()
	else:
		_on_chaos_settled()


func _on_chaos_settled() -> void:
	if not _demo_end:
		return
	Music.resolve_chord()  # major, on the dark's root: the zone's dominant…
	Music.dark = false     # …so the zone's own key that follows feels like coming home (V → I)
	_flash(0.22, 2.5)
	colour_wave.pass_wave(tip.position, Palette.GOLD, 0.6)
	# Still dark enough for the whale's light to shine; it lifts as the whale passes. What broke
	# comes back together, with golden seams.
	darkness.to(0.15, 3.0)
	landscape.tremble = 0.0
	landscape.mend(4.0)
	fx.clear()  # the cracks close under the light
	get_tree().create_timer(2.5).timeout.connect(_awaken)


func _awaken() -> void:
	if whale.sleeping:
		whale.wake()  # all its stars lit: it fills with light where it slept and swims on
	else:
		whale.swim()
	get_tree().create_timer(4.0).timeout.connect(Narrator.say.bind(VoiceLines.DEMO_ENDING[1]))


func _on_whale_passing() -> void:
	darkness.to(0.0, 6.0)
	darkness.invert_to(0.0, 6.0)


func _on_whale_gone() -> void:
	_dark = false
	chaos.stop()
	crumble.stop()
	cinema.show_bars(false, 1.2)
	_enter_final(false)


func _clear_dark() -> void:
	_end_now()
	night.reset()
	for c in creatures:
		c.reset()
	_dark = false
	Music.dark = false
	chaos.stop()
	crumble.stop()
	whale.stop()
	darkness.amount = 0.0
	darkness.invert = 0.0
	landscape.tremble = 0.0
	landscape.unbreak()

## "Start over" from the demo's end screen.
func _restart() -> void:
	GameState.new_game()
	SaveSystem.had_progress = false
	SaveSystem.save_game()
	Music.stop_theme()
	_demo_end = false
	_grand = false
	_clear_dark()
	_on_reborn()
	tip.lit = 0.0
	_greet(false)


func _on_reborn() -> void:
	_stop_cinematic(true)
	_clear_dark()
	_face_zone()
	tip.lit = 0.0
	gates.reset()
	star.reset()
	forks.reset()
	figure.reset()
	shapes.clear()
	fx.clear()
	washes.clear()
	landscape.reset()
	end_screen.visible = false
	hud.modulate.a = 1.0
	_final_pending = -1.0
	mode = Mode.PLAY
	GameState.running = true
