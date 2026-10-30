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
var flash: ColorRect

var _event_t := 0.0
var _event_center := Vector2.ZERO
var _event_zoom := 1.0
var _final_pending := -1.0
var _final_t := 0.0
var _end_shown := false
var _bird_wait := 0.0
var _flash_tween: Tween


func _ready() -> void:
	_build()
	GameState.hit.connect(_on_hit)
	GameState.gate_broken.connect(_on_gate_broken)
	GameState.zone_completed.connect(_on_zone_completed)
	GameState.chapter_unlocked.connect(_on_chapter_unlocked)
	GameState.game_finished.connect(_on_finished)
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
	end_screen = Screens.EndScreen.new()
	end_screen.rebirth_pressed.connect(GameState.rebirth)
	ui.add_child(end_screen)
	tree_panel = Control.new()
	tree_panel.set_script(load("res://scripts/ui/tree_panel.gd"))
	ui.add_child(tree_panel)
	hud.tree_pressed.connect(tree_panel.open_panel)
	intro = Screens.Intro.new(SaveSystem.had_progress)
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
	intro.dismiss()
	intro = null
	create_tween().tween_property(hud, "modulate:a", 1.0, 2.0).set_delay(0.6)
	Music.start()
	# The voice greets once the line has started climbing.
	get_tree().create_timer(2.5).timeout.connect(_greet.bind(SaveSystem.had_progress))
	if GameState.finished:
		_enter_final(true)
		return
	mode = Mode.PLAY
	GameState.running = true


func _on_line(_id: String, text: String, duration: float) -> void:
	subtitle.show_line(text, duration)


func _greet(returning: bool) -> void:
	if returning:
		Narrator.say("00b", false)
	else:
		Narrator.say("00")


func _process(delta: float) -> void:
	path_view.lit = tip.lit
	match mode:
		Mode.INTRO, Mode.PLAY:
			camera.k = 2.2
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
			camera.k = 1.0
			camera.target_pos = Vector2(0, -PathData.FINAL * PathData.GAP * 0.5)
			var vs := get_viewport_rect().size
			camera.target_zoom = minf(vs.y / (PathData.FINAL * PathData.GAP + 900.0), vs.x / 900.0)
			_final_t += delta
			if _final_t >= END_DELAY and not _end_shown:
				_end_shown = true
				end_screen.show_end()
	if _final_pending >= 0.0:
		_final_pending -= delta
		if _final_pending < 0.0:
			_enter_final(false)

	var tint := Palette.chapter_color(Palette.chapter_of(GameState.stage))
	depth.update_view(camera.position, camera.zoom.x, camera.offset, get_viewport_rect().size, tint)
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
		zone_title.show_title("zona %s completa" % Zones.ROMAN[z - 1], Zones.NAMES[z - 1], Palette.INK)


func _on_chapter_unlocked(idx: int) -> void:
	var col := Palette.chapter_color(idx)
	zone_title.show_title("el color vuelve", Palette.chapter_name(idx), col.darkened(0.1))
	washes.bloom(_event_center, col, 1400.0)
	camera.add_trauma(1.0)
	_flash(0.45, 2.0)


func _summon_bird() -> void:
	_bird_wait = randf_range(BIRD_EVERY.x, BIRD_EVERY.y)
	bird.fly()


func _on_bird_close() -> void:
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
	_final_pending = FINAL_DELAY


func _enter_final(immediate: bool) -> void:
	mode = Mode.FINAL
	_final_t = END_DELAY if immediate else 0.0
	_end_shown = false
	GameState.running = false


func _on_reborn() -> void:
	tip.lit = 0.0
	gates.reset()
	fx.clear()
	washes.clear()
	end_screen.visible = false
	_final_pending = -1.0
	mode = Mode.PLAY
	GameState.running = true
