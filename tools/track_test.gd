extends Node
## The recorded themes (Songs.TRACKS): jumps through zones 1-4 and into the dark, and logs which theme
## plays, its tempo, the key the taps take, and how far the beat grid is from the theme's beats (it
## should be 0; zone 1's theme is pushed near its end at 6 s, to see it loop). Headless:
## godot --headless --path . --fixed-fps 30 res://tools/track_test.tscn

const STOPS := [2, 12, 22, 32]
const STAY := 14.0

var _main: Node
var _t := 0.0
var _i := -1
var _last := 0.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.voice_on = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	var i := int((_t - 1.0) / STAY)
	if _t > 1.0 and i != _i and i < STOPS.size():
		_i = i
		_main._dev_jump(STOPS[i])
	elif _t > 1.0 and i != _i and i == STOPS.size():
		_i = i
		_main._on_dev("jump", 40)
		_main._dev_break()
	# near the end of zone 1's theme, to see it loop on a downbeat
	if _t > 6.0 and _t - delta <= 6.0:
		var length := (Music._streams["z1"] as AudioStream).get_length()
		Music._track_origin = Music._time - (length - 9.0)
	if _t - _last >= 3.0:
		_last = _t
		_log()
	if GameState.running and fmod(_t, 0.9) < delta:
		GameState.tap("tap", Music.beat_at_tap())
	if _t > STAY * (STOPS.size() + 1) + 1.0:
		get_tree().quit()


func _log() -> void:
	var m := Music
	var off := 0.0
	if m.track != "":
		var tr: Dictionary = Songs.TRACKS[m.track]
		var beat := 60.0 / float(tr.bpm)
		off = fposmod(m._zone_origin - m._track_origin - float(tr.beat0) + beat * 0.5, beat) - beat * 0.5
	print("[%5.1f s] barrera %d zona %d tema '%s' bpm %.0f tónica %d pos %.1f s desfase %.3f s" % [_t,
		GameState.stage, m.zone, m.track, m.bpm(), m.tonic(), m._track_pos() if m.track != "" else 0.0, off])
