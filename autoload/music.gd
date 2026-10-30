extends Node
## Musical clock and harmony (design doc §9). Every sound uses notes of the current chord and lands
## on the grid, so nothing can sound wrong. Samples are dry; the Music bus adds a shared reverb.
## Visual feedback is immediate; only the sound is quantised.

signal note_played(midi: int, instrument: String)

const VOICES := 24
const REF_VOL := 0.05
const CHOIR_FADE := 1.5
const STEPS_PER_CHORD := 32
const MUSIC_BUS := &"Music"
const CHOIR_BUS := &"Choir"
const NOTE_NAMES := ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"]
const INSTRUMENTS := ["piano", "harp", "celesta", "flute", "bass", "glass"]
const WIND_KINDS := {"tap": 60, "auto": 60, "romper": 43, "zona": 43}  # kind -> lowest MIDI of its 12 files

## volume_db per sample group (LEEME, dry versions). Final = group + 20·log10(vol / 0.05).
const GROUP_DB := {
	"piano": -30.1, "harp": -31.7, "celesta": -29.9, "flute": -28.7, "bass": -28.2, "glass": -29.8,
	"wind": -34.6, "zone": -32.6, "choir": -32.8,
}

const ARP_PATTERN := [0, 1, 2, 3, 4, 3, 2, 1]
const COUNTER_PATTERN := [2, 1, 3, 2, 4, 3, 1, 2]

var tension := 0.0
var zone := 1
var layers := 0
var playing := false

var _bank := {}    # instrument -> {midi: AudioStream}
var _range := {}   # instrument -> Vector2i(lowest, highest) MIDI
var _wind := {}    # kind -> {midi: AudioStream}
var _choir := {}   # zone * 10 + chord (1..4) -> AudioStream
var _voices: Array[AudioStreamPlayer] = []
var _voice_i := 0
var _choir_players: Array[AudioStreamPlayer] = []
var _choir_i := 0
var _choir_filter: AudioEffectLowPassFilter
var _choir_swell := 0.0
var _choir_bus := -1
var _music_bus := -1

var _time := 0.0
var _next_step_time := 0.0
var _step := 0            # sixteenths since the current zone started
var _chord_idx := 0
var _zone_origin := 0.0   # time of step 0 of the current zone
var _pending_zone := 1
var _arp_i := 0
var _queue: Array[Dictionary] = []
var _slot_use := {}       # tap slot -> notes already in it


func _ready() -> void:
	_setup_buses()
	_load_samples()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC_BUS
		add_child(p)
		_voices.append(p)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = CHOIR_BUS
		add_child(p)
		_choir_players.append(p)
	_pending_zone = Zones.of(GameState.stage)
	zone = _pending_zone
	layers = Zones.layers_at(GameState.stage)
	GameState.hit.connect(_on_hit)
	GameState.gate_broken.connect(_on_gate_broken)
	GameState.zone_completed.connect(_on_zone_completed)
	GameState.chapter_unlocked.connect(func(_i: int) -> void: choir_swell())
	GameState.upgrade_bought.connect(func(_id: String, _l: int) -> void: play_buy())
	GameState.reborn.connect(_on_reborn)
	set_enabled(SaveSystem.music_on)


func _process(delta: float) -> void:
	_update_tension(delta)
	if _choir_filter:
		_choir_filter.cutoff_hz = lerpf(900.0, 6500.0, tension)
	AudioServer.set_bus_volume_db(_choir_bus, _choir_swell)
	if not playing:
		return
	_time += delta
	while _time >= _next_step_time:
		_on_step()
		_next_step_time += _s16()
	for i in range(_queue.size() - 1, -1, -1):
		var q: Dictionary = _queue[i]
		if q.t <= _time:
			_queue.remove_at(i)
			_fire(q)
	if _slot_use.size() > 64:
		var now := _current_slot()
		for k in _slot_use.keys():
			if k < now - 4:
				_slot_use.erase(k)


# --- Public API -------------------------------------------------------------

func start() -> void:
	if playing:
		return
	playing = true
	_time = 0.0
	_next_step_time = 0.0
	_step = 0
	_zone_origin = 0.0
	zone = _pending_zone


func set_enabled(on: bool) -> void:
	SaveSystem.music_on = on
	AudioServer.set_bus_mute(_music_bus, not on)


func is_enabled() -> bool:
	return not AudioServer.is_bus_mute(_music_bus)


func chord() -> Array:
	return Zones.PROGRESSIONS[zone - 1][_chord_idx]


func tonic() -> int:
	return Zones.TONIC[zone - 1]


## Degree `deg` of the current chord, counting up through octaves from `base`.
func chord_note(deg: int, base: int) -> int:
	var c := chord()
	var n := c.size()
	return base + int(c[posmod(deg, n)]) + 12 * floori(deg / float(n))


## 0..1 position inside the current beat, for things that breathe with the music.
func beat_phase() -> float:
	return fposmod((_time - _zone_origin) / (_s16() * 4.0), 1.0)


func play_tap(progress: float, crit: bool) -> void:
	if not playing:
		return
	var k := _next_slot()
	var used: int = _slot_use.get(k, 0)
	if used >= 2:
		return
	_slot_use[k] = used + 1
	var n := chord().size()
	# Higher the more broken the barrier; the second note in a slot climbs a degree to build a chord.
	var deg := roundi(progress * (n * 2 - 1)) + used
	var midi := chord_note(deg, tonic() + 12)
	var t := _slot_time(k)
	_schedule(t, "note", _tap_instrument(), midi, 0.05)
	_schedule(t, "wind", "tap", midi, 0.04)
	if crit:
		_schedule(t, "note", "glass", chord_note(4, tonic() + 24), 0.04)
		_schedule(t + _tap_div(), "note", "glass", chord_note(5, tonic() + 24), 0.04)


func play_auto() -> void:
	if not playing:
		return
	_schedule(_slot_time(_next_slot()), "wind", "auto", chord_note(0, tonic() + 12), 0.03)


func play_buy() -> void:
	if not playing:
		return
	var t := _slot_time(_next_slot())
	for i in 3:
		_schedule(t + i * _tap_div(), "note", "celesta", chord_note(i + 2, tonic() + 12), 0.04)


## One celesta note of the chord, used by the tree's cascading reveal.
func play_celesta(deg: int) -> void:
	if not playing:
		return
	_schedule(_slot_time(_next_slot()), "note", "celesta", chord_note(deg, tonic() + 24), 0.035)


## Chorus swells to twice its volume for 5 s and settles back in 2.5 s.
func choir_swell() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_choir_swell", 6.0, 1.2)
	tw.tween_interval(3.8)
	tw.tween_property(self, "_choir_swell", 0.0, 2.5)


# --- Events -----------------------------------------------------------------

func _on_hit(_damage: float, crit: bool, source: String) -> void:
	if source == "auto":
		play_auto()
	else:
		play_tap(GameState.progress(), crit)


func _on_gate_broken(n: int) -> void:
	var next := mini(n + 1, GameState.FINAL)
	_pending_zone = Zones.of(next)
	layers = Zones.layers_at(next)
	if not playing:
		return
	var eighth := _s16() * 2.0
	var t := _grid_time(eighth)
	_schedule(t, "wind", "romper", tonic(), 0.06)
	for i in 5:
		_schedule(t + i * eighth, "note", _tap_instrument(), chord_note(i, tonic() + 12), 0.045)


func _on_zone_completed(_z: int) -> void:
	if not playing:
		return
	var quarter := _s16() * 4.0
	var t := _grid_time(quarter)
	_schedule(t, "wind", "zona", tonic(), 0.06)
	for i in 8:
		_schedule(t + i * quarter * 0.5, "note", _tap_instrument(), chord_note(i, tonic() + 12), 0.04)


func _on_reborn() -> void:
	_pending_zone = 1
	layers = Zones.layers_at(1)


# --- Clock and layers -------------------------------------------------------

func _on_step() -> void:
	if _step % STEPS_PER_CHORD == 0:
		if _pending_zone != zone:
			zone = _pending_zone
			_step = 0
			_zone_origin = _next_step_time
			_slot_use.clear()
		_chord_idx = int(_step / float(STEPS_PER_CHORD)) % 4
		_play_choir()
	_accompany(_step)
	_step += 1


func _accompany(s: int) -> void:
	var bar := s % 16
	var c := chord()
	var root := tonic() + int(c[0])
	if layers >= 1 and bar == 0:
		_play("bass", root - 12, 0.07)
	if layers >= 3 and bar == 10:
		_play("bass", root - 12 + 7, 0.05)
	if layers >= 2 or tension > 0.5:
		var fast := layers >= 5 and tension > 0.55
		if fast or s % 2 == 0:
			var deg: int = ARP_PATTERN[_arp_i % ARP_PATTERN.size()]
			_arp_i += 1
			_play(_arp_instrument(), chord_note(deg, tonic() + 12), 0.018 + tension * 0.04)
	if layers >= 4 and s % 8 == 4:
		_play("glass", chord_note(randi_range(0, c.size() - 1), tonic() + 24), 0.02)
	if layers >= 5 and bar == 0:
		var b := int(s / 16.0)
		_play("flute", chord_note(COUNTER_PATTERN[b % COUNTER_PATTERN.size()], tonic() + 12), 0.03)


func _play_choir() -> void:
	var stream: AudioStream = _choir.get(zone * 10 + _chord_idx + 1)
	if stream == null:
		return
	var old := _choir_players[_choir_i]
	_choir_i = (_choir_i + 1) % _choir_players.size()
	var p := _choir_players[_choir_i]
	p.stream = stream
	p.volume_db = GROUP_DB.choir
	p.play()
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, CHOIR_FADE)
		tw.tween_callback(old.stop)


func _update_tension(delta: float) -> void:
	var g := GameState
	var target := 0.0
	if g.running and not g.finished:
		target = g.progress() * exp(-(g.clock - g.last_hit_time) / 1.4)
	tension = lerpf(tension, target, minf(1.0, delta * 2.5))


# --- Grid -------------------------------------------------------------------

func _s16() -> float:
	return 60.0 / Zones.BPM[zone - 1] / 4.0


## Tap grid: sixteenths, or sextuplets when a sixteenth is longer than 150 ms.
func _tap_div() -> float:
	var s := _s16()
	if s <= 0.15:
		return s
	return 60.0 / Zones.BPM[zone - 1] / 6.0


func _current_slot() -> int:
	return floori((_time - _zone_origin) / _tap_div())


func _next_slot() -> int:
	return ceili((_time - _zone_origin) / _tap_div())


func _slot_time(k: int) -> float:
	return _zone_origin + k * _tap_div()


func _grid_time(div: float) -> float:
	return _zone_origin + ceilf((_time - _zone_origin) / div) * div


func _schedule(t: float, kind: String, what: String, midi: int, vol: float) -> void:
	_queue.append({"t": t, "kind": kind, "what": what, "midi": midi, "vol": vol})


func _fire(q: Dictionary) -> void:
	if q.kind == "wind":
		_play_wind(q.what, q.midi, q.vol)
	else:
		_play(q.what, q.midi, q.vol)


# --- Voices -----------------------------------------------------------------

func _play(inst: String, midi: int, vol: float) -> void:
	var bank: Dictionary = _bank.get(inst, {})
	if bank.is_empty():
		return
	var r: Vector2i = _range[inst]
	var src := clampi(midi, r.x, r.y)
	if not bank.has(src):
		return
	_voice(bank[src], pow(2.0, (midi - src) / 12.0), GROUP_DB[inst] + linear_to_db(vol / REF_VOL))
	note_played.emit(midi, inst)


## Winds are tuned: one file per pitch class, picked by the note that sounds.
func _play_wind(kind: String, midi: int, vol: float) -> void:
	var bank: Dictionary = _wind.get(kind, {})
	var lo: int = WIND_KINDS.get(kind, 60)
	var src := lo + posmod(midi - lo, 12)
	if not bank.has(src):
		return
	var group := "zone" if kind == "zona" else "wind"
	_voice(bank[src], 1.0, GROUP_DB[group] + linear_to_db(vol / REF_VOL))


## Round robin over the pool: the next voice is always the oldest one, so it is the one stolen.
func _voice(stream: AudioStream, pitch: float, db: float) -> void:
	var p := _voices[_voice_i]
	_voice_i = (_voice_i + 1) % VOICES
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


func _tap_instrument() -> String:
	return Zones.TAP_INSTRUMENT[zone - 1]


func _arp_instrument() -> String:
	return "celesta" if _tap_instrument() == "harp" else "harp"


# --- Setup ------------------------------------------------------------------

func _setup_buses() -> void:
	_music_bus = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus == -1:
		AudioServer.add_bus()
		_music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus, MUSIC_BUS)
		AudioServer.set_bus_send(_music_bus, &"Master")
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.8
		rv.damping = 0.5
		rv.wet = 0.35
		AudioServer.add_bus_effect(_music_bus, rv)
	_choir_bus = AudioServer.get_bus_index(CHOIR_BUS)
	if _choir_bus == -1:
		AudioServer.add_bus()
		_choir_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_choir_bus, CHOIR_BUS)
		AudioServer.set_bus_send(_choir_bus, MUSIC_BUS)
		_choir_filter = AudioEffectLowPassFilter.new()
		_choir_filter.cutoff_hz = 900.0
		AudioServer.add_bus_effect(_choir_bus, _choir_filter)
	else:
		_choir_filter = AudioServer.get_bus_effect(_choir_bus, 0) as AudioEffectLowPassFilter


static func note_name(m: int) -> String:
	return "%s%d" % [NOTE_NAMES[m % 12], floori(m / 12.0) - 1]


## Everything is preloaded at start: no loading while playing.
func _load_samples() -> void:
	for inst in INSTRUMENTS:
		var bank := {}
		var lo := 28 if inst == "bass" else 55
		var hi := 64 if inst == "bass" else 96
		for m in range(lo, hi + 1):
			var path := "res://audio/instruments/%s/%s_%03d_%s.ogg" % [inst, inst, m, note_name(m)]
			if ResourceLoader.exists(path):
				bank[m] = load(path)
		_bank[inst] = bank
		_range[inst] = Vector2i(lo, hi)
	for kind in WIND_KINDS:
		var bank := {}
		var lo: int = WIND_KINDS[kind]
		for m in range(lo, lo + 12):
			var path := "res://audio/wind/%s/viento_%s_%03d_%s.ogg" % [kind, kind, m, note_name(m)]
			if ResourceLoader.exists(path):
				bank[m] = load(path)
		_wind[kind] = bank
	for z in range(1, Zones.COUNT + 1):
		for c in range(1, 5):
			var path := "res://audio/choir/coro_zona%02d_acorde%d.ogg" % [z, c]
			if ResourceLoader.exists(path):
				_choir[z * 10 + c] = load(path)
