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
var star
var forks
var fx
var camera
var hud
var tree_panel
var zone_title: Screens.ZoneTitle
var end_screen: Screens.EndScreen
var intro: Screens.Intro
var subtitle: Screens.Subtitle
var depth: DepthBackground
var bird: GiantBird
var landscape: Landscape
var colour_wave: ColourWave
var darkness: Darkness
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
	bird.passed_close.connect(_on_bird_close)

	var font := UIStyle.font()
	washes = _node("Washes", "res://scripts/world/washes.gd")
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

	camera = Camera2D.new()
	camera.set_script(load("res://scripts/world/camera.gd"))
	add_child(camera)
	camera.make_current()

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
	if mode == Mode.INTRO:
		_start()
	else:
		GameState.tap("tap")


## The intro fades in 3 s, the HUD appears in 2 s and the line climbs from below to the first barrier.
func _start() -> void:
	if intro == null:
		return
	intro.dismiss()
	intro = null
	colour_wave.pass_wave(tip.position, Palette.GOLD, 0.3)
	create_tween().tween_property(hud, "modulate:a", 1.0, 2.0).set_delay(0.6)
	Music.start()
	_demo_end = BuildFlags.DEMO and GameState.finished and GameState.stage >= BuildFlags.DEMO_LAST
	# The voice greets once the line has started climbing.
	get_tree().create_timer(2.5).timeout.connect(_greet.bind(SaveSystem.had_progress))
	if GameState.finished:
		_enter_final(true)
		return
	mode = Mode.PLAY
	GameState.running = true


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
	_start()


func _greet(returning: bool) -> void:
	if returning:
		Narrator.say("00b", false)
	else:
		Narrator.say("00")


func _process(delta: float) -> void:
	path_view.lit = tip.lit
	path_view.width_scale = maxf(1.0, 0.9 / camera.zoom.x)
	match mode:
		Mode.INTRO, Mode.PLAY:
			camera.k = 2.2
			if star.is_active():
				# The whole star in view.
				camera.target_pos = star.center() + Vector2(0, -20)
				camera.target_zoom = _base_zoom() * 0.72
			elif forks.is_active():
				var f: Vector2 = forks.focus()
				camera.target_pos = Vector2(f.x * 0.5, f.y - 70.0)
				camera.target_zoom = _base_zoom() * 0.92
			else:
				camera.target_pos = Vector2(tip.position.x * 0.5, tip.position.y - 70.0)
				camera.target_zoom = _base_zoom()
		Mode.EVENT:
			camera.k = 1.1
			camera.target_pos = _event_center
			camera.target_zoom = _event_zoom
			_event_t -= delta
			if _event_t <= 0.0:
				mode = Mode.PLAY
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
	depth.focus = landscape.grand
	depth.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size, tint)
	landscape.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size, tint)
	colour_wave.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size)
	bird.set_tint(tint)
	if GameState.running and not GameState.finished:
		_bird_wait -= delta
		if _bird_wait <= 0.0:
			_summon_bird()


func _base_zoom() -> float:
	var vs := get_viewport_rect().size
	return minf(vs.y / 640.0, vs.x / 420.0)


# --- Events -----------------------------------------------------------------

func _on_hit(damage: float, crit: bool, source: String) -> void:
	tip.kick(6.0 if source == "auto" else 12.0)
	gates.hit(0.25 if source == "auto" else 0.6)
	var p := path.gate_pos(GameState.stage) + Vector2(randf_range(-55, 55), randf_range(-26, -6))
	if crit:
		fx.float_text(p, Fmt.num(damage), Palette.chapter_color(maxi(1, Palette.chapter_of(GameState.stage))), 24)
	elif source != "auto":
		fx.float_text(p, Fmt.num(damage), Color(Palette.INK, 0.8), 15)


func _on_gate_broken(n: int) -> void:
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
	var first := path.gate_pos((z - 1) * 10 + 1)
	var last := path.gate_pos(z * 10)
	_event_center = (first + last) * 0.5
	var vs := get_viewport_rect().size
	_event_zoom = minf(vs.y / (absf(last.y - first.y) + 500.0), vs.x / 800.0)
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
		"wave":
			colour_wave.reveal(camera.position, Palette.chapter_color(randi_range(1, 4)))
		"lang":
			SaveSystem.set_lang("en" if SaveSystem.lang == "es" else "es")


func _dev_jump(n: int) -> void:
	if intro != null:
		_start()
	# Visuals first: the jump itself may start a star or a fork, which must survive.
	colour_wave.clear()
	bird.stop()
	zone_title.hide_now()
	gates.reset()
	star.reset()
	forks.reset()
	fx.clear()
	washes.clear()
	landscape.reset()
	GameState.dev_jump(n)
	GameState.running = true
	mode = Mode.PLAY
	_final_pending = -1.0
	_grand = false
	_end_shown = false
	_letter_shown = false
	end_screen.visible = false
	hud.modulate.a = 1.0
	tip.lit = maxf(0.0, path.gate_len(n) - 260.0)


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


func _enter_final(immediate: bool) -> void:
	mode = Mode.FINAL
	_final_t = END_DELAY if immediate else 0.0
	_end_shown = false
	# A finished game loaded from a save goes straight to the end: the letter was already read.
	_letter_shown = immediate
	_grand = false
	if immediate:
		_show_end()
	elif _demo_end:
		_demo_darken()
	GameState.running = false


## The demo's last barrier broke. First the colour returns as always (the zone/chapter events
## already fired), then, after that moment, the dark comes in.
func _on_demo_finished() -> void:
	_demo_end = true
	_final_pending = EVENT_TIME


## The dark creeps in from the edges, the line cracks under the tip and the bird passes, hurt.
func _demo_darken() -> void:
	darkness.to(0.85, 7.0)
	var top := path.gate_pos(BuildFlags.DEMO_LAST)
	fx.crack(top + Vector2(0, 10), 320.0, 5.0)
	fx.crack(path.gate_pos(BuildFlags.DEMO_LAST - 2), 260.0, 6.0)
	fx.crack(path.gate_pos(BuildFlags.DEMO_LAST - 5), 220.0, 7.0)
	get_tree().create_timer(2.5).timeout.connect(bird.fly.bind(true))


## "Start over" from the demo's end screen.
func _restart() -> void:
	GameState.new_game()
	SaveSystem.had_progress = false
	SaveSystem.save_game()
	_demo_end = false
	_grand = false
	darkness.amount = 0.0
	_on_reborn()
	tip.lit = 0.0
	_greet(false)


func _on_reborn() -> void:
	darkness.amount = 0.0
	tip.lit = 0.0
	gates.reset()
	star.reset()
	forks.reset()
	fx.clear()
	washes.clear()
	landscape.reset()
	end_screen.visible = false
	hud.modulate.a = 1.0
	_final_pending = -1.0
	mode = Mode.PLAY
	GameState.running = true
