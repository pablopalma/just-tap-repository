extends Node
## The voice (design doc §10, §20.4). Lines queue up with at least 7 s between them and never
## overlap; each story line plays once per run (saved in GameState.said); while it speaks the music
## ducks 3 dB. The voice is always English; subtitles follow SaveSystem.lang.

signal line_started(id: String, text: String, duration: float)

const GAP := 7.0
const MIN_SHOW := 5.6
const DUCK_DB := -3.0
const IDLE_AFTER := 25.0
const IDLE_EVERY := 180.0
const VOICE_BUS := &"Voice"

var _queue: Array[String] = []
var _cooldown := 0.0
var _player: AudioStreamPlayer
var _idle_i := 0
var _idle_cool := 0.0
var _last_tap := 0.0
var _duck_tween: Tween
## Off while a director (the trailer) decides exactly when each line is said.
var auto := true
## While a story asks and is told (Main), queued lines wait: only say_now speaks. They play after.
var hold := false
## How far the music ducks under the voice, and which buses duck (the trailer ducks more of them).
var duck_db := DUCK_DB
var duck_buses: Array[StringName] = [&"Music"]


func _ready() -> void:
	if AudioServer.get_bus_index(VOICE_BUS) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, VOICE_BUS)
		AudioServer.set_bus_send(i, &"Master")
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.55
		rv.damping = 0.6
		rv.wet = 0.18
		AudioServer.add_bus_effect(i, rv)
	_player = AudioStreamPlayer.new()
	_player.bus = VOICE_BUS
	add_child(_player)
	_player.finished.connect(_unduck)

	GameState.gate_broken.connect(_on_gate_broken)
	GameState.zone_completed.connect(_on_zone_completed)
	GameState.game_finished.connect(_on_finished)
	GameState.demo_finished.connect(_on_demo_finished)
	GameState.reborn.connect(_on_reborn)
	GameState.progress_reset.connect(func() -> void: _queue.clear())
	GameState.hit.connect(_on_hit)


## Nothing queued, nothing speaking and the gap after the last line is over.
func is_idle() -> bool:
	return _queue.is_empty() and not _player.playing and _cooldown <= 0.0


## Queue a line. Story lines play once per run; pass once = false for idle, return and rebirth.
func say(id: String, once := true) -> void:
	if not auto or not VoiceLines.LINES.has(id):
		return
	if once:
		if GameState.said.has(id) or _queue.has(id):
			return
		GameState.said[id] = true
	_queue.append(id)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_idle_cool = maxf(0.0, _idle_cool - delta)
	if not hold and not _queue.is_empty() and _cooldown <= 0.0 and not _player.playing:
		_speak(_queue.pop_front())
	_check_stuck_and_idle()


## Say a line right now, skipping the queue and its spacing (the trailer's director).
func say_now(id: String) -> void:
	_player.stop()
	_speak(id)


func _speak(id: String) -> void:
	var duration := MIN_SHOW
	var path := VoiceLines.audio_path(id)
	if path != "" and SaveSystem.voice_on:
		var stream: AudioStream = load(path)
		_player.stream = stream
		_player.play()
		duration = maxf(MIN_SHOW, stream.get_length() + 1.5)
		_duck()
	_cooldown = maxf(GAP, duration + 1.0)
	line_started.emit(id, VoiceLines.text(id, SaveSystem.lang), duration)


## The voice's reverb (0..1); the trailer keeps it drier, so the voice sits in front.
func set_reverb(wet: float) -> void:
	var rv := AudioServer.get_bus_effect(AudioServer.get_bus_index(VOICE_BUS), 0) as AudioEffectReverb
	rv.wet = wet


func _duck() -> void:
	_tween_music(duck_db, 0.6)


func _unduck() -> void:
	_tween_music(0.0, 1.5)


func _tween_music(db: float, time: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel()
	for bus_name in duck_buses:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus == -1:
			continue
		_duck_tween.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
			AudioServer.get_bus_volume_db(bus), db, time)


# --- Triggers ---------------------------------------------------------------

func _on_gate_broken(n: int) -> void:
	var reached := n + 1
	if BuildFlags.DEMO and reached == BuildFlags.DARK_FROM:
		say(VoiceLines.DEMO_ENDING[0])  # the dark comes in
	# In the demo's dark the voice stays quiet: the chaos speaks for itself.
	if VoiceLines.ON_REACH.has(reached) and not BuildFlags.is_dark(reached):
		say(VoiceLines.ON_REACH[reached])


func _on_zone_completed(z: int) -> void:
	if VoiceLines.ON_ZONE.has(z):
		say(VoiceLines.ON_ZONE[z])


func _on_hit(_damage: float, _crit: bool, source: String) -> void:
	if source == "tap":
		_last_tap = GameState.clock


## The ending: three lines, 7 s apart by the queue's own spacing.
func _on_finished() -> void:
	for id in VoiceLines.ENDING:
		say(id)


## The dark settles and something awakens: the last line, as the whale arrives (Main times it).
func _on_demo_finished() -> void:
	pass


func _on_reborn() -> void:
	GameState.said = {}
	_queue.clear()
	say("rebirth", false)


## Same condition as the HUD's "mejorá el árbol" hint, once per chapter. And, if nobody has
## tapped for a while, a gentle reminder at most every 3 minutes.
func _check_stuck_and_idle() -> void:
	var g := GameState
	if not g.running or g.finished or g.cinematic:
		return  # in a cinematic the tip plays on its own: nobody is stuck or away
	if not BuildFlags.PHRASES and g.time_at_gate > 12.0 and g.taps_at_gate > 25 and g.progress() < 0.25:
		say(VoiceLines.ON_STUCK[Palette.chapter_of(g.stage)])
	if g.clock - _last_tap > IDLE_AFTER and _idle_cool <= 0.0 and _queue.is_empty():
		_idle_cool = IDLE_EVERY
		say(VoiceLines.IDLE[_idle_i % VoiceLines.IDLE.size()], false)
		_idle_i += 1
