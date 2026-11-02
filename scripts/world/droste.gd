extends CanvasLayer
## Between zones, the Droste dive (BuildFlags.DROSTE): each zone is the line inside the last one.
## The camera falls into the tip while the line splits into finer threads; the dot grows until it is
## all there is; then, from its centre, the next zone opens (already turned its own way, View.angle)
## while the camera goes on falling in. One continuous move inward, never a cut. The music is heard
## from inside something as it falls, and opens when it arrives.
## Main drives the camera with zoom_mul() and turns the view on `turned`.

signal turned
signal done

const DIVE := 1.5
const EMERGE := 1.8
const DIVE_ZOOM := 22.0      # how far in the camera falls before the dot fills the screen
const EMERGE_ZOOM := 5.0     # and how far in the next zone starts, settling back to normal
const THREADS := 7

## The tip on screen; Main sets it every frame.
var tip_screen := Vector2.ZERO

var _t := -1.0
var _turned := false
var _canvas: Node2D
var _filter: AudioEffectLowPassFilter
var _filter_at := -1


func _ready() -> void:
	layer = 7  # over the world and its colour, under the HUD and the subtitles
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_dive)
	add_child(_canvas)


func is_playing() -> bool:
	return _t >= 0.0


func play() -> void:
	_t = 0.0
	_turned = false
	_muffle(true)


## How far in the camera is, against its normal zoom.
func zoom_mul() -> float:
	if _t < 0.0:
		return 1.0
	if _t < DIVE:
		var e := _t / DIVE
		return pow(DIVE_ZOOM, e * e)
	var k := clampf((_t - DIVE) / EMERGE, 0.0, 1.0)
	return pow(EMERGE_ZOOM, pow(1.0 - k, 2.2))


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if not _turned and _t >= DIVE:
		_turned = true
		turned.emit()
		_muffle(false)
	if _t >= DIVE + EMERGE:
		_t = -1.0
		done.emit()
	_canvas.queue_redraw()


func _draw_dive() -> void:
	if _t < 0.0:
		return
	var vs := _canvas.get_viewport_rect().size
	var far := vs.length()
	var ink := Palette.INK
	if _t < DIVE:
		var e := _t / DIVE
		# The line splits into threads along its own direction, spreading as the camera falls in.
		var along := Vector2(0, -1).rotated(-View.angle)
		var across := along.orthogonal()
		for i in THREADS:
			var off := (i - (THREADS - 1) * 0.5) * lerpf(1.0, 22.0, e * e)
			var p := tip_screen + across * off
			draw_thread(p - along * far, p + along * far, Color(ink, 0.35 * e * (1.0 - absf(off) / 90.0)))
		# The dot grows until it is all there is.
		var r := lerpf(6.0, far, pow(e, 3.2))
		_canvas.draw_circle(tip_screen, r, Color(ink, smoothstep(0.0, 0.25, e)))
		_canvas.draw_arc(tip_screen, r * 1.08 + 4.0, 0.0, TAU, 96, Color(ink, 0.25 * e), 1.5, true)
		return
	# Inside: the next zone opens from the middle of the dot, a ring of ink rolling out of the screen.
	var k := clampf((_t - DIVE) / EMERGE, 0.0, 1.0)
	var inner := far * (1.0 - pow(1.0 - k, 2.6))
	var outer := far * 1.05
	if inner < outer:
		_canvas.draw_arc(vs * 0.5, (inner + outer) * 0.5, 0.0, TAU, 128, ink, outer - inner, true)
		# the pen's edge of the opening, a little ragged
		_canvas.draw_arc(vs * 0.5, inner, 0.0, TAU, 128, Color(ink, 0.5), 2.0 + 6.0 * (1.0 - k), true)


func draw_thread(a: Vector2, b: Vector2, col: Color) -> void:
	if col.a > 0.003:
		_canvas.draw_line(a, b, col, 1.2, true)


## Falling in, the music is heard from inside something (a low-pass closing); arriving, it opens.
func _muffle(on: bool) -> void:
	var bus := AudioServer.get_bus_index(Music.MUSIC_BUS)
	if bus == -1:
		return
	if _filter == null:
		_filter = AudioEffectLowPassFilter.new()
		_filter.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(bus, _filter)
		_filter_at = AudioServer.get_bus_effect_count(bus) - 1
	AudioServer.set_bus_effect_enabled(bus, _filter_at, true)
	var tw := create_tween()
	if on:
		tw.tween_property(_filter, "cutoff_hz", 380.0, DIVE).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(_filter, "cutoff_hz", 20000.0, EMERGE).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: AudioServer.set_bus_effect_enabled(bus, _filter_at, false))
