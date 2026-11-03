extends Node
## Musical clock and harmony (design doc §9). Every sound uses notes of the current chord and lands
## on the grid, so nothing can sound wrong. Samples are dry; the Music bus adds a shared reverb.
## Visual feedback is immediate; only the sound is quantised.

signal note_played(midi: int, instrument: String)
## A note worth seeing (§7.4): taps and the accompaniment. bright = a high glassy one (a circle).
signal shape_note(midi: int, bright: bool)

const VOICES := 24
const REF_VOL := 0.05
const CHOIR_FADE := 1.5
const STEPS_PER_CHORD := 32
const MUSIC_BUS := &"Music"
const CHOIR_BUS := &"Choir"
const BIRD_BUS := &"Bird"
## Far away: big reverb and a low-pass, for the landscape building itself in the distance.
const DISTANT_BUS := &"Distant"
const DISTANT_VOICES := 10
## The bird itself: its wings and phrase dry, only its cry with a touch of reverb.
const BIRD_BODY_BUS := &"BirdBody"
const BIRD_VOICE_BUS := &"BirdVoice"
const BODY_VOICES := 8
## The celestial whale's song: its own wide, soft reverb, straight to Master.
const CELESTIAL_BUS := &"Celestial"
const BIRD_VOICES := 8
## The bird's calls: chord degrees, a short phrase that falls and lifts like a cry.
const BIRD_CALLS := [[7, 5, 6], [8, 6, 4], [6, 7, 5, 4], [9, 7, 8]]
const NOTE_NAMES := ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"]
const INSTRUMENTS := ["piano", "harp", "celesta", "flute", "bass", "glass"]
const WIND_KINDS := {"tap": 60, "auto": 60, "romper": 43, "zona": 43}  # kind -> lowest MIDI of its 12 files

## volume_db per sample group (LEEME, dry versions). Final = group + 20·log10(vol / 0.05).
const GROUP_DB := {
	"piano": -30.1, "harp": -31.7, "celesta": -29.9, "flute": -28.7, "bass": -28.2, "glass": -29.8,
	"wind": -34.6, "zone": -32.6, "choir": -32.8,
}

## Highest note for chord-degree sparkles before they fold an octave down.
const BRIGHT_CEILING := 93

## Each branch of a fork plays its own instrument.
const BRANCH_INSTRUMENTS := ["piano", "harp", "celesta"]

const ARP_PATTERN := [0, 1, 2, 3, 4, 3, 2, 1]
const COUNTER_PATTERN := [2, 1, 3, 2, 4, 3, 1, 2]

var tension := 0.0
var zone := 1
var layers := 0
var playing := false
## The beat made audible: a soft harp on every beat, the bar's first a little louder. Main turns it
## on while it teaches tapping with the music (zone 1 has no rhythmic layer of its own).
var pulse_on := false

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
var _bird_bus := -1
var _bird_panner: AudioEffectPanner
var _bird_voices: Array[AudioStreamPlayer] = []
var _bird_i := 0
var _bird_call_i := 0
var _bird_active := false
var _distant_voices: Array[AudioStreamPlayer] = []
var _distant_i := 0
var _body_voices: Array[AudioStreamPlayer] = []
var _body_i := 0
var _cry_voices: Array[AudioStreamPlayer] = []
var _cry_i := 0
var _body_panners: Array[AudioEffectPanner] = []
## Pool a scheduled note plays on (see _fire); empty: the usual one.
var _route := ""
## The demo's dark stretch (Main sets it): the music drops a fifth, to the zone's dominant, and
## turns minor — i(add9) VI(maj7) III(add9) VII, dark but consonant, so every tap and every
## collision still lands in the chord. The choir (recorded in the zone's major chords) rests; a low
## pedal of bass and wind holds instead. The resolution's major chord on that dominant then leads
## home to the zone's tonic when the dark ends: V → I.
var dark := false:
	set(v):
		if v == dark:
			return
		dark = v
		if dark:
			for p in _choir_players:
				if p.playing:
					create_tween().tween_property(p, "volume_db", -60.0, CHOIR_FADE * 2.0)
## How far out of the dark the player is (0..1: barrier 41 to 45): the dark's song brightens with it
## (Songs.DARK), a step at a time, taken on a bar so the harmony never turns mid-phrase.
var dark_light := 0.0
var _dark_step := 0
const DARK_DROP := 5
var _celestial: Array[AudioStreamPlayer] = []
var _celestial_i := 0
var _chaos_t := -1.0
## Air, swell, cry and resonance (scripts/atmosphere.gd), made once at start.
var _atmos := {}
## Set by a director (the trailer): zone and layers stay put whatever the game does.
var locked := false
## The title theme (the menu, and the end screen): instead of the game's layers, a melody of its own
## over the zone's chords and choir. Two phrases of four chords each (A, then A' higher with the
## flute doubling and glass), looping. Each note is [sixteenth inside the chord, chord degree].
var theme := false
const THEME := [
	[[0, 4], [6, 5], [8, 4], [12, 2], [16, 3], [28, 2]],
	[[0, 3], [6, 4], [8, 5], [12, 4], [16, 2], [28, 1]],
	[[0, 2], [6, 3], [8, 4], [12, 6], [16, 5], [24, 4], [28, 3]],
	[[0, 4], [8, 3], [12, 2], [16, 1], [24, 2]],
]
var _theme_from := 0      # the step the melody starts on (a chord boundary)
## The recorded title theme (audio/music/title_theme.ogg, 2 min, looping), played instead of the
## generated one when it is there. Its own bus, so the Music bus's reverb does not wash it again.
const TITLE_PATH := "res://audio/music/title_theme.ogg"
const TITLE_BUS := &"Title"
const TITLE_DB := -11.0   # the file is at -18 LUFS: this sits it a little above the game's music (≈ -31 LUFS)
var _title: AudioStreamPlayer
var _title_tween: Tween
## The recorded theme is sounding: the game's own accompaniment and choir rest under it.
var title_on := false
## The recorded themes (Songs.TRACKS): one plays wherever there is one (the zone's, the dark's, or a
## scene's own: the story, the letter, see play_feature). While it plays, the beat grid sits on its
## beats at its tempo, every generated note takes its key bar by bar (a major pentatonic), the game's
## own accompaniment and choir rest, and a tap on the beat sounds in the theme's own colour (its
## "taps"). Two players, to cross-fade: from one theme to the next, at its loop, and at the dark's jump
## to its climax. A low-pass filter on their bus keeps the dark's theme muffled until the light comes.
const TRACK_BUS := &"Track"
const TRACK_FADE := 3.0
## Seconds before its end where a theme loops back to its first downbeat (its fade-out is skipped).
const TRACK_TAIL := 8.0
const PENTATONIC := [0, 2, 4, 7, 9]
var track := ""
var feature := ""
var _streams := {}   # id -> AudioStream
var _track_players: Array[AudioStreamPlayer] = []
var _track_i := 0
var _track_filter: AudioEffectLowPassFilter
var _track_origin := 0.0   # clock time of the theme's position 0
var _track_jumped := false

var _time := 0.0
var _next_step_time := 0.0
var _step := 0            # sixteenths since the current zone started
var _chord_idx := 0
var _zone_origin := 0.0   # time of step 0 of the current zone
var _pending_zone := 1
var _arp_i := 0
## The song's melody under the player's taps (play_accent): when the last tap on the beat was, and
## which note of the chord's phrase comes next.
var _last_accent := -100.0
var _accent_chord := -1
var _accent_i := 0
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
	for i in BIRD_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BIRD_BUS
		add_child(p)
		_bird_voices.append(p)
	for i in DISTANT_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = DISTANT_BUS
		add_child(p)
		_distant_voices.append(p)
	for i in BODY_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BIRD_BODY_BUS
		add_child(p)
		_body_voices.append(p)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = BIRD_VOICE_BUS
		add_child(p)
		_cry_voices.append(p)
	for i in 3:
		var p := AudioStreamPlayer.new()
		p.bus = CELESTIAL_BUS
		add_child(p)
		_celestial.append(p)
	if ResourceLoader.exists(TITLE_PATH):
		if AudioServer.get_bus_index(TITLE_BUS) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, TITLE_BUS)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
		var stream: AudioStream = load(TITLE_PATH)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_title = AudioStreamPlayer.new()
		_title.stream = stream
		_title.bus = TITLE_BUS
		add_child(_title)
	_setup_tracks()
	_atmos = {"whoosh": Atmosphere.whoosh(), "swell": Atmosphere.swell(), "cry": Atmosphere.cry(), "boom": Atmosphere.boom()}
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
	GameState.progress_reset.connect(_on_reborn)
	GameState.jumped.connect(_on_jumped)
	set_enabled(SaveSystem.music_on)


func _process(delta: float) -> void:
	_update_tension(delta)
	if _choir_filter:
		_choir_filter.cutoff_hz = lerpf(900.0, 6500.0, tension)
	AudioServer.set_bus_volume_db(_choir_bus, _choir_swell)
	if _track_filter:
		var cut := 20000.0
		if track == "dark":
			cut = 700.0 * pow(28.0, clampf(dark_light / 0.5, 0.0, 1.0))
		_track_filter.cutoff_hz = lerpf(_track_filter.cutoff_hz, cut, minf(1.0, delta * 0.8))
	if not playing:
		return
	_time += delta
	var want := _wanted_track()
	if want != track:
		_switch_track(want)
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


## The title theme. The recorded one fades in over whatever is playing (the game's music rests
## under it); without the file, the generated one: it starts the clock if it is not running and the
## melody comes in on the next chord.
func play_theme() -> void:
	if _title != null:
		title_on = true
		for p in _choir_players:
			if p.playing:
				create_tween().tween_property(p, "volume_db", -60.0, CHOIR_FADE)
		if not _title.playing:
			_title.volume_db = -50.0
			_title.play()
		_fade_title(TITLE_DB, 2.0)
		return
	theme = true
	if not playing:
		start()
	_theme_from = ceili(_step / float(STEPS_PER_CHORD)) * STEPS_PER_CHORD


## Back to the game's own music: the recorded theme fades out under it (the clock keeps running).
func stop_theme() -> void:
	theme = false
	if title_on:
		title_on = false
		_fade_title(-50.0, 2.5).tween_callback(_title.stop)


func _fade_title(db: float, time: float) -> Tween:
	if _title_tween:
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "volume_db", db, time).set_trans(Tween.TRANS_SINE)
	return _title_tween


## Keep zone z's key and tempo and the given layers until unlock (the trailer's continuous score).
func lock(z: int, layer_count: int) -> void:
	locked = true
	_pending_zone = z
	if not playing:
		zone = z
	layers = layer_count


func set_enabled(on: bool) -> void:
	SaveSystem.music_on = on
	AudioServer.set_bus_mute(_music_bus, not on)
	for b in [DISTANT_BUS, BIRD_BODY_BUS, BIRD_VOICE_BUS, CELESTIAL_BUS, TITLE_BUS, TRACK_BUS]:
		var d := AudioServer.get_bus_index(b)
		if d != -1:
			AudioServer.set_bus_mute(d, not on)


func is_enabled() -> bool:
	return not AudioServer.is_bus_mute(_music_bus)


func chord() -> Array:
	if track != "":
		return PENTATONIC
	if dark:
		return Songs.DARK.steps[_dark_step].chords[_chord_idx]
	return Zones.PROGRESSIONS[zone - 1][_chord_idx]


func tonic() -> int:
	if track != "":
		return 44 + posmod(_track_key() - 8, 12)
	return Zones.TONIC[zone - 1] - (DARK_DROP if dark else 0)


## Degree `deg` of the current chord, counting up through octaves from `base`.
func chord_note(deg: int, base: int) -> int:
	var c := chord()
	var n := c.size()
	return base + int(c[posmod(deg, n)]) + 12 * floori(deg / float(n))


## 0..1 position inside the current beat, for things that breathe with the music.
func beat_phase() -> float:
	return fposmod((_time - _zone_origin) / (_s16() * 4.0), 1.0)


## How far from a beat a tap still counts as on it, as a fraction of the beat (generous: this is
## about feeling the music, not precision).
const BEAT_WINDOW := 0.2
## Between hearing the beat and the tap reaching the game, on top of the audio output's own delay.
const HEARD_LAG := 0.03


## The beat a tap falls on, by the music as the player hears it: its index, or -1 between beats.
func beat_at_tap() -> int:
	if not playing or title_on:
		return -1
	var beat := _s16() * 4.0
	var heard := _heard_time()
	var k := roundi(heard / beat)
	return k if absf(heard - k * beat) <= BEAT_WINDOW * beat else -1


## Like beat_phase(), but as the player hears it: what the tip's beat ring follows.
func heard_phase() -> float:
	return fposmod(_heard_time() / (_s16() * 4.0), 1.0)


## Index of the current half beat: holding the button taps once on each.
func half_beat() -> int:
	return floori((_time - _zone_origin) / (_s16() * 2.0))


func _heard_time() -> float:
	return _time - _zone_origin - AudioServer.get_output_latency() - HEARD_LAG


## A tap on the beat: its note lands on the beat itself (or at once, if the tap came after it),
## a step higher for every beat of the run, so a run on the beat plays a melody; from the fourth,
## glass doubles it an octave up.
func play_accent(run: int) -> void:
	if not playing:
		return
	var beat := _s16() * 4.0
	var t := maxf(_time, _zone_origin + roundf((_time - _zone_origin) / beat) * beat)
	_last_accent = _time
	if track != "" and Songs.TRACKS[track].has("taps"):
		_accent_on_track(t, run)
		return
	var n := chord().size()
	var midi := chord_note((run - 1) % (n * 2), tonic() + 12)
	var song := _song()
	if not song.is_empty() or (dark and track == ""):
		# the song's melody, note by note: each chord starts its phrase again
		var at := int(_step / float(_chord_steps()))
		if _accent_chord != at:
			_accent_chord = at
			_accent_i = 0
		var phrase: Array = _melody(song)[_chord_idx]
		midi = _fold(tonic() + 12 + int(phrase[_accent_i % phrase.size()][1]), BRIGHT_CEILING)
		_accent_i += 1
	shape_note.emit(midi, true)
	_schedule(t, "note", _tap_instrument(), midi, 0.065)
	_schedule(t, "wind", "tap", midi, 0.045)
	if _bells_now(song):
		var up := _fold(midi + 12, BRIGHT_CEILING + 5)
		_schedule(t, "note", "celesta", up, 0.03)
		_schedule(t, "note", "glass", up, 0.016)
	elif run >= 4:
		_schedule(t, "note", "glass", midi + 12, 0.028)


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
	shape_note.emit(midi, false)
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


## The giant bird sings: a short phrase of chord notes in the flute, doubled softly by the glass
## an octave up, on the grid like everything else.
func bird_call(vol: float) -> void:
	if not playing:
		return
	var phrase: Array = BIRD_CALLS[_bird_call_i % BIRD_CALLS.size()]
	_bird_call_i += 1
	var eighth := _s16() * 2.0
	var t := _grid_time(eighth)
	for i in phrase.size():
		var at := t + i * eighth
		var midi := chord_note(int(phrase[i]), tonic() + 12)
		_schedule_body(at, "flute", midi, vol * 0.5)
		_schedule_body(at, "glass", midi + 12, vol * 0.2)
	bird_cry(clampf(vol / 0.06, 0.0, 1.0))


## Rush of air from the wings as it passes close.
func bird_whoosh(vol: float) -> void:
	if not playing:
		return
	# It rushes past: air swelling in, then a whoosh that drops in pitch as it goes (Doppler).
	_schedule_atmos(_time, "swell", 0.9, -18.0, "body")
	_schedule_atmos(_time + 1.2, "whoosh", 1.25, -11.0, "body", 0.7, 1.4)
	_schedule_body(_grid_time(_s16() * 4.0), "bass", tonic() - 12, vol * 0.8)


## The bird in the dark: a falling phrase in the tonic's minor, slower, that never resolves.
func bird_call_minor(vol: float) -> void:
	if not playing:
		return
	var quarter := _s16() * 4.0
	var t := _grid_time(quarter)
	var base := tonic() + 24
	var phrase := [7, 3, 2, 0, 2]
	for i in phrase.size():
		_schedule_body(t + i * quarter * 0.75, "flute", base + phrase[i], vol)
	_schedule_body(t, "bass", tonic() - 12, vol * 0.8)


## A piece of the distant landscape draws itself (j = 0..9): a soft swish as the pen lands, then
## a bright arpeggio of glass and celesta that climbs with the pen for as long as it draws, and a
## held harp note when the stroke ends. Degrees are resolved when each note plays, so the
## arpeggio follows the chord even if it changes mid-stroke. Panned to the structure's side.
func build_piece(j: int, side: float, draw_time := 2.6) -> void:
	if not playing:
		return
	if not _bird_active:
		set_bird_pan(side * 0.6)
	var div := _tap_div()
	var t := _grid_time(div * 2.0) + div * 2.0
	# Far away, air swells in before the piece appears, then a quick harp glissando opens it.
	_schedule_atmos(maxf(_time, t - 1.45), "swell", randf_range(0.9, 1.1), -20.0, "distant")
	for i in 5:
		_schedule_deg(t + div * 0.25 * i, "harp", start_deg(j) + i, 12, 0.03)
	_schedule(t, "wind", "auto", chord_note(j, tonic() + 12), 0.05, true)
	var start := start_deg(j)
	var steps := maxi(4, floori(draw_time / (div * 2.0)))
	for i in steps:
		var at := t + div * 2.0 * i
		_schedule_deg(at, "glass", start + i, 12, 0.045 + 0.01 * i / steps)
		if i % 2 == 1:
			_schedule_deg(at, "celesta", start + i, 24, 0.02)
	var end := t + div * 2.0 * steps
	_schedule_deg(end, "harp", start + steps, 12, 0.05)
	_schedule_deg(end, "glass", start + steps + 2, 12, 0.03)
	if j == 9:
		# The structure is complete: a cascade falling through the chord over a low harp chord.
		var c0 := end + div * 4.0
		for i in 10:
			_schedule_deg(c0 + div * i, "glass", 12 - i, 12, 0.04)
			if i % 3 == 0:
				_schedule_deg(c0 + div * i, "celesta", 12 - i, 24, 0.02)
		_schedule_deg(c0, "harp", 0, 0, 0.06)
		_schedule_deg(c0 + div, "harp", 2, 0, 0.05)
		_schedule(c0, "wind", "zona", tonic(), 0.05, true)
		# and a deep resonance under it, far away, with the choir rising.
		_schedule_atmos(c0, "boom", 1.0, -9.0, "distant")
		choir_swell()


static func start_deg(j: int) -> int:
	return j % 3 + 2


## A note given as a chord degree; the pitch is picked when it plays (see _fire).
func _schedule_deg(t: float, inst: String, deg: int, octave_offset: int, vol: float) -> void:
	_queue.append({"t": t, "kind": "deg", "what": inst, "deg": deg, "base": octave_offset, "vol": vol,
		"bird": true})


## Air, swell, cry or boom on the "bird" or "distant" bus. glide: pitch multiplier reached over
## glide_time (a Doppler pass).
func _schedule_atmos(t: float, what: String, pitch: float, db: float, pool: String, glide := 1.0, glide_time := 1.0) -> void:
	_queue.append({"t": t, "kind": "atmos", "what": what, "pitch": pitch, "db": db, "pool": pool,
		"glide": glide, "glide_time": glide_time})


## A note of the bird's own, on its dry bus.
func _schedule_body(t: float, inst: String, midi: int, vol: float) -> void:
	_queue.append({"t": t, "kind": "note", "what": inst, "midi": midi, "vol": vol, "bird": true, "pool": "body"})


func _pool(name: String) -> AudioStreamPlayer:
	if name == "distant":
		var p := _distant_voices[_distant_i]
		_distant_i = (_distant_i + 1) % DISTANT_VOICES
		return p
	if name == "body":
		var p := _body_voices[_body_i]
		_body_i = (_body_i + 1) % BODY_VOICES
		return p
	if name == "celestial":
		var p := _celestial[_celestial_i]
		_celestial_i = (_celestial_i + 1) % _celestial.size()
		return p
	if name == "cry":
		var p := _cry_voices[_cry_i]
		_cry_i = (_cry_i + 1) % _cry_voices.size()
		return p
	var b := _bird_voices[_bird_i]
	_bird_i = (_bird_i + 1) % BIRD_VOICES
	return b


## A wing beat: air, louder the closer the bird is.
func bird_flap(depth: float) -> void:
	if not playing:
		return
	_schedule_atmos(_time, "whoosh", randf_range(0.85, 1.1), lerpf(-30.0, -17.0, depth), "body")


## The bird's voice, far away: a cry in the chord's key, answered a third higher.
func bird_cry(depth: float) -> void:
	if not playing:
		return
	var t := _grid_time(_s16() * 2.0)
	var a := _fold(chord_note(randi_range(4, 6), tonic() + 12), 81)
	var b := _fold(chord_note(randi_range(6, 8), tonic() + 12), 84)
	var db := lerpf(-24.0, -15.0, depth)
	_schedule_atmos(t, "cry", pow(2.0, (a - 69) / 12.0), db, "cry")
	_schedule_atmos(t + _s16() * 6.0, "cry", pow(2.0, (b - 69) / 12.0), db - 5.0, "cry")


static func _fold(midi: int, ceiling: int) -> int:
	while midi > ceiling:
		midi -= 12
	return midi


# --- The demo's dark stretch --------------------------------------------------

## Makes the dark's sounds (a few hundred ms of work) before they are needed.
func prepare_dark() -> void:
	if not _atmos.has("rumble"):
		_atmos["rumble"] = Atmosphere.rumble()
		_atmos["crumble"] = Atmosphere.crumble()
		_atmos["whale"] = Atmosphere.whale()


## Two figures of the chaos collide: a soft, low note of the chord, far away. Chaos you can hear
## trying to calm itself. strength 0..1.
func chaos_hit(strength: float) -> void:
	if not playing or _time - _chaos_t < 0.11:
		return
	_chaos_t = _time
	var inst: String = ["harp", "celesta", "harp", "glass"][randi() % 4]
	var deg := randi_range(0, 5)
	var base := tonic() + (24 if inst == "glass" else 12)
	var midi := chord_note(deg, base)
	while midi > BRIGHT_CEILING - 7:
		midi -= 12
	_queue.append({"t": _time, "kind": "note", "what": inst, "midi": midi, "bird": false,
		"vol": lerpf(0.012, 0.035, strength), "pool": "distant"})


## The ground shakes: a rumble and things falling apart. strength 0..1.
func tremor(strength: float) -> void:
	if not playing or not _atmos.has("rumble"):
		return
	_schedule_atmos(_time, "rumble", randf_range(0.8, 1.05), lerpf(-22.0, -9.0, strength), "distant")
	_schedule_atmos(_time + randf_range(0.2, 0.6), "crumble", randf_range(0.85, 1.15), lerpf(-24.0, -14.0, strength), "distant")


## A piece breaks off: a small crumble.
func crumble_bit() -> void:
	if not playing or not _atmos.has("crumble"):
		return
	_schedule_atmos(_time, "crumble", randf_range(1.0, 1.4), -24.0, "distant")


## A figure of the chaos settles into the mandala: the i-th note of a slow, rising arpeggio.
func settle_note(i: int) -> void:
	if not playing:
		return
	var t := _grid_time(_s16())
	_schedule_deg(t, "harp" if i % 2 == 0 else "celesta", i, 12 if i < 6 else 24, 0.035)


## The night's barriers are stars (scripts/world/night.gd): each lights with a clear bell, a high
## chord tone in the celesta over glass, and a harp just after it, climbing star by star.
func star_note(i: int) -> void:
	if not playing:
		return
	var t := _grid_time(_s16() * 2.0)
	_schedule_deg(t, "celesta", 4 + i % 6, 24, 0.07)
	_schedule_deg(t, "glass", 6 + i % 6, 24, 0.045)
	_schedule_deg(t + _s16() * 2.0, "harp", 2 + i % 6, 12, 0.04)


## One note of a melody that climbs (the trailer's crescendos): the i-th degree of the chord on the
## next eighth, piano and glass in turns, as loud as vol. The line folds back down after 14 notes.
func rising_note(i: int, vol: float) -> void:
	if not playing:
		return
	var deg := i % 14
	_schedule_deg(_grid_time(_s16() * 2.0), "piano" if i % 2 == 0 else "celesta", deg, 12 if deg < 7 else 24, vol)
	if i % 4 == 3:
		_schedule_deg(_grid_time(_s16() * 2.0), "glass", deg + 2, 24, vol * 0.5)


## Everything is in its place: a wide major chord, choir rising, glass falling like light.
func resolve_chord() -> void:
	if not playing:
		return
	var t := _grid_time(_s16() * 4.0)
	var root := tonic()
	for k in [0, 7, 12, 16, 19, 24]:
		_schedule(t + 0.03 * k, "note", "harp", root + k, 0.05)
	_schedule(t, "note", "bass", root - 12, 0.08)
	_schedule(t, "wind", "zona", root, 0.06)
	for i in 10:
		_schedule(t + 0.35 + _s16() * i, "note", "glass", root + 24 + [16, 12, 7, 4, 0][i % 5] - 12 * int(i / 5.0), 0.03)
	choir_swell()


## The whale sings: a long call tuned to the key (i picks the interval), with light above it.
func whale_song(i: int) -> void:
	if not playing or not _atmos.has("whale"):
		return
	var t := _grid_time(_s16() * 4.0)
	var target: int = tonic() - 12 + [0, 7, -5, 4][i % 4]
	_schedule_atmos(t, "whale", pow(2.0, (target - 57) / 12.0), -7.0, "celestial")
	for k in 4:
		_schedule_deg(t + 1.2 + _s16() * 3.0 * k, "celesta", 4 + k, 24, 0.02)
		_schedule_deg(t + 1.2 + _s16() * 3.0 * k, "glass", 6 + k, 24, 0.012)
	if i == 0:
		choir_swell()


## The bird owns the pan of its bus while it flies.
func set_bird_active(on: bool) -> void:
	_bird_active = on


## -1 left .. 1 right.
func set_bird_pan(pan: float) -> void:
	if _bird_panner:
		_bird_panner.pan = pan
	if _bird_active:
		for b in _body_panners:
			b.pan = pan


# --- Events -----------------------------------------------------------------

func _on_hit(_damage: float, crit: bool, source: String) -> void:
	if source == "auto":
		play_auto()
	elif not GameState.branches.is_empty():
		play_trio(crit)
	elif GameState.accent > 0:
		play_accent(GameState.accent)
	else:
		play_tap(GameState.progress(), crit)


## Forked: each branch is an instrument (piano, harp, celesta) and plays its own note, higher the
## more broken its barrier — three branches moving out of step sound like a trio.
func play_trio(crit: bool) -> void:
	if not playing:
		return
	var k := _next_slot()
	var used: int = _slot_use.get(k, 0)
	if used >= 2:
		return
	_slot_use[k] = used + 1
	var t := _slot_time(k)
	var n := chord().size()
	for i in GameState.branches.size():
		var b: Dictionary = GameState.branches[i]
		if b.done:
			continue
		var deg := roundi(GameState.branch_progress(b) * (n * 2 - 1)) + i
		_schedule_deg(t, BRANCH_INSTRUMENTS[i % BRANCH_INSTRUMENTS.size()], deg + used, 12, 0.035)
	if crit:
		_schedule(t, "note", "glass", chord_note(4, tonic() + 24), 0.04)


## A branch reached its barrier's end: two notes of its own instrument.
func play_branch_done(i: int) -> void:
	if not playing:
		return
	var t := _slot_time(_next_slot())
	var inst: String = BRANCH_INSTRUMENTS[i % BRANCH_INSTRUMENTS.size()]
	_schedule_deg(t, inst, 2 + i, 12, 0.045)
	_schedule_deg(t + _tap_div() * 2.0, inst, 4 + i, 12, 0.04)


## A light of a star crossed one of its small barriers: a glass note, one step higher per light.
func play_star_step(i: int, n: int) -> void:
	if not playing:
		return
	var t := _slot_time(_next_slot())
	_schedule_deg(t, "glass", 2 + (i * 7) % (n + 3), 12, 0.04)
	_schedule_deg(t, "celesta", 4 + i, 24, 0.018)


func _on_gate_broken(n: int) -> void:
	var next := mini(n + 1, GameState.FINAL)
	if not locked:
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


func _on_jumped(n: int) -> void:
	if locked:
		return
	_pending_zone = Zones.of(n)
	layers = Zones.layers_at(n)


func _on_reborn() -> void:
	_pending_zone = 1
	layers = Zones.layers_at(1)


# --- Clock and layers -------------------------------------------------------

func _on_step() -> void:
	if _step % _chord_steps() == 0:
		if _pending_zone != zone:
			zone = _pending_zone
			_step = 0
			_zone_origin = _next_step_time
			_slot_use.clear()
			_theme_from = 0
			_accent_chord = -1
		_chord_idx = int(_step / float(_chord_steps())) % 4
		_play_choir()
	if dark and _step % 16 == 0:
		var from := BuildFlags.DARK_FROM
		dark_light = clampf(float(GameState.stage - from) / float(BuildFlags.DEMO_LAST - from), 0.0, 1.0)
		_dark_step = _dark_step_for(dark_light)
	if track != "" and _track_bar_start():
		if track == "dark" and not _track_jumped and _dark_step >= 2:
			_track_jumped = true
			_track_jump(float(Songs.TRACKS.dark.climax))
		elif _track_pos() > (_streams[track] as AudioStream).get_length() - TRACK_TAIL:
			_track_jump(float(Songs.TRACKS[track].bar0))
	_accompany(_step)
	if pulse_on and _step % 4 == 0 and not title_on:
		var low := chord_note(0, tonic())
		_play("harp", low, 0.034 if _step % 16 == 0 else 0.022)
		shape_note.emit(low, false)
	_step += 1


func _accompany(s: int) -> void:
	if title_on or track != "":
		return
	if theme and not dark:
		_play_theme_step(s)
		return
	var song := _song()
	if not song.is_empty():
		_play_song_step(s, song)
		return
	var bar := s % 16
	var lay := mini(layers, 1) if dark else layers
	var c := chord()
	var root := tonic() + int(c[0])
	if dark:
		_play_dark_step(s)
		return
	if lay >= 1 and bar == 0:
		_play("bass", root - 12, 0.07)
	if lay >= 3 and bar == 10:
		_play("bass", root - 12 + 7, 0.05)
	if lay >= 2 or tension > 0.5:
		var fast := lay >= 5 and tension > 0.55
		if fast or s % 2 == 0:
			var deg: int = ARP_PATTERN[_arp_i % ARP_PATTERN.size()]
			_arp_i += 1
			var arp := chord_note(deg, tonic() + 12)
			_play(_arp_instrument(), arp, 0.018 + tension * 0.04)
			shape_note.emit(arp, false)
	if lay >= 4 and s % 8 == 4:
		var shine := chord_note(randi_range(0, c.size() - 1), tonic() + 24)
		_play("glass", shine, 0.02)
		shape_note.emit(shine, true)
	if lay >= 5 and bar == 0:
		var b := int(s / 16.0)
		_play("flute", chord_note(COUNTER_PATTERN[b % COUNTER_PATTERN.size()], tonic() + 12), 0.03)


## One sixteenth of the zone's song (data/songs.gd): its bass and groove, and its melody on the lead
## unless the player is playing it.
func _play_song_step(s: int, song: Dictionary) -> void:
	var lay := layers
	var chorus := _in_chorus()
	var bar := s % int(song.get("bar", 16))
	var root := tonic() + int(chord()[0])
	if lay >= 1:
		var first := true
		for b: Array in _part(song, "bass", chorus):
			if int(b[0]) == bar:
				_play("bass", root - 12 + int(b[1]), 0.07 if first else 0.04)
			first = false
	for a: Array in _part(song, "arp", chorus):
		if int(a[0]) == bar:
			var low := chord_note(int(a[1]), tonic() + 12 * int(a[2]) if a.size() > 2 else tonic())
			_play(song.arp_inst, low, (0.014 if lay < 2 else 0.022) + tension * 0.03)
			shape_note.emit(low, false)
	if lay >= 4 and s % 8 == 4:
		var c := chord()
		var shine := chord_note(randi_range(0, c.size() - 1), tonic() + 24)
		_play("glass", shine, 0.02)
		shape_note.emit(shine, true)
	var k := s % _chord_steps()
	for n: Array in _melody(song)[_chord_idx]:
		if int(n[0]) != k:
			continue
		var midi := _fold(tonic() + 12 + int(n[1]), BRIGHT_CEILING)
		if _player_leads():
			continue
		_play(song.lead, midi, 0.03)
		shape_note.emit(midi, false)
		if chorus and song.get("bells", false):
			_bell(midi)


## One sixteenth of the dark's song: the piano's ostinato (on every eighth, soft and low at first,
## an octave up once the light comes), the melody, and bells near the end. The low pedal of bass and
## wind is _play_choir's.
func _play_dark_step(s: int) -> void:
	var d: Dictionary = Songs.DARK
	var bar := s % 16
	var up := dark_light >= float(d.step_at[2])
	for o: Array in d.ostinato:
		if int(o[0]) != bar or (dark_light < float(d.step_at[1]) and bar % 4 != 0):
			continue
		var low := chord_note(int(o[1]), tonic() + (12 if up else 0))
		_play("piano", low, lerpf(0.016, 0.03, dark_light) + tension * 0.02)
		shape_note.emit(low, false)
	var k := s % STEPS_PER_CHORD
	for n: Array in _melody({})[_chord_idx]:
		if int(n[0]) != k or _player_leads():
			continue
		var midi := _fold(tonic() + 12 + int(n[1]), BRIGHT_CEILING)
		_play("piano", midi, lerpf(0.026, 0.04, dark_light))
		if _dark_step >= 1:
			_play("flute", midi, 0.02)
		shape_note.emit(midi, false)
		if _bells_now({}):
			_bell(midi)


## A scene's own theme over the zone's (the story, the letter); stop_feature gives the music back.
func play_feature(id: String) -> void:
	feature = id


func stop_feature() -> void:
	feature = ""


func _setup_tracks() -> void:
	var bus := AudioServer.get_bus_index(TRACK_BUS)
	if bus == -1:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, TRACK_BUS)
		AudioServer.set_bus_send(bus, &"Master")
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(bus, lp)
	_track_filter = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	for id: String in Songs.TRACKS:
		var path: String = Songs.TRACKS[id].path
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = false  # it loops on a downbeat (_on_step)
			_streams[id] = stream
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = TRACK_BUS
		add_child(p)
		_track_players.append(p)


## The theme that should be playing now: the scene's, the dark's or the zone's, if it is there.
func _wanted_track() -> String:
	if title_on or theme or locked or not Songs.on:
		return ""
	var id := feature
	if id == "":
		id = "dark" if dark else Songs.zone_track(zone)
	return id if _streams.has(id) else ""


## From one theme to the next: the old one fades out, the new one fades in from its start and the
## beat grid moves onto its beats at its tempo. To none: the game's own music comes back on the grid
## as it is.
func _switch_track(id: String) -> void:
	_fade_out(_track_players[_track_i], TRACK_FADE)
	track = id
	if id == "":
		return
	var t: Dictionary = Songs.TRACKS[id]
	_track_i = 1 - _track_i
	var p := _track_players[_track_i]
	p.stream = _streams[id]
	p.volume_db = -40.0
	p.play(0.0)
	create_tween().tween_property(p, "volume_db", float(t.db), TRACK_FADE).set_trans(Tween.TRANS_SINE)
	_track_origin = _time
	_track_jumped = false
	_zone_origin = _time + float(t.beat0)
	_next_step_time = _zone_origin
	_step = 0
	_slot_use.clear()
	if id == "dark":
		_track_filter.cutoff_hz = 700.0
	for c in _choir_players:
		if c.playing:
			create_tween().tween_property(c, "volume_db", -60.0, CHOIR_FADE)


func _fade_out(p: AudioStreamPlayer, time: float) -> void:
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -60.0, time)
	tw.tween_callback(p.stop)


## On a downbeat (called from _on_step): the theme cross-fades to `at`, moved onto a downbeat of its
## own, so the beat grid stays on it. Its loop, and the dark's jump to its climax.
func _track_jump(at: float) -> void:
	var t: Dictionary = Songs.TRACKS[track]
	var bar := _s16() * 4.0 * int(t.metre)
	var to := float(t.bar0) + roundf((at - float(t.bar0)) / bar) * bar
	var step_time := _next_step_time
	var old := _track_players[_track_i]
	_track_i = 1 - _track_i
	var p := _track_players[_track_i]
	p.stream = _streams[track]
	p.volume_db = -40.0
	p.play(to + (_time - step_time))
	_track_origin = step_time - to
	create_tween().tween_property(p, "volume_db", float(t.db), 1.5).set_trans(Tween.TRANS_SINE)
	_fade_out(old, 2.5)


## Where the theme is (s), from the clock.
func _track_pos() -> float:
	return _time - _track_origin


## The step about to sound is the first beat of one of the theme's bars.
func _track_bar_start() -> bool:
	var t: Dictionary = Songs.TRACKS[track]
	var beats := roundi((float(t.bar0) - float(t.beat0)) / (_s16() * 4.0))
	return posmod(_step - beats * 4, 4 * int(t.metre)) == 0


## The key of the bar the theme is in (pitch class of its pentatonic).
func _track_key() -> int:
	var t: Dictionary = Songs.TRACKS[track]
	var keys: Array = t.keys
	var i := floori((_track_pos() - float(t.bar0)) / (_s16() * 4.0 * int(t.metre)))
	return int(keys[clampi(i, 0, keys.size() - 1)])


## A tap on the beat over a theme, in the theme's own colour: one voice on the bar's first beat and
## another on the rest, the run walking its contour (an octave up every other time round), a little
## louder or softer each time, as a hand would play it.
func _accent_on_track(t: float, run: int) -> void:
	var tr: Dictionary = Songs.TRACKS[track]
	var taps: Dictionary = tr.taps
	var at := _track_pos() + (t - _time)
	var in_bar := posmod(roundi((at - float(tr.bar0)) / (_s16() * 4.0)), int(tr.metre))
	var v: Array = taps.down if in_bar == 0 else taps.beat
	var contour: Array = taps.contour
	var i := (run - 1) % contour.size()
	var lap := int((run - 1) / float(contour.size())) % 2
	var deg := int(contour[i]) + lap * PENTATONIC.size()
	var midi := _fold(chord_note(deg, tonic() + 12) + int(v[1]), BRIGHT_CEILING)
	var gain: float = float(v[2]) * randf_range(0.85, 1.08)
	shape_note.emit(midi, in_bar == 0)
	_schedule(t, "note", v[0], midi, 0.065 * gain)
	_schedule(t, "wind", "tap", midi, 0.03 * gain)
	if run >= int(taps.glass_from):
		_schedule(t, "note", "glass", _fold(midi + 12, BRIGHT_CEILING + 5), 0.022 * gain)
	if _bells_now({}):
		var up := _fold(midi + 12, BRIGHT_CEILING + 5)
		_schedule(t, "note", "celesta", up, 0.03)
		_schedule(t, "note", "glass", up, 0.016)


func _dark_step_for(light: float) -> int:
	var at: Array = Songs.DARK.step_at
	var i := 0
	while i + 1 < at.size() and light >= float(at[i + 1]):
		i += 1
	return i


## The melody now: the dark's step, or the song's section.
func _melody(song: Dictionary) -> Array:
	if dark:
		return Songs.DARK.steps[_dark_step].melody
	return _section(song)


## Bells on the melody: in a song's chorus, or in the dark once the light is near.
func _bells_now(song: Dictionary) -> bool:
	if dark:
		return dark_light >= float(Songs.DARK.bells_at)
	return not song.is_empty() and song.get("bells", false) and _in_chorus()


## The bells over the chorus: the melody an octave up in the celesta, glass under it.
func _bell(midi: int) -> void:
	var up := _fold(midi + 12, BRIGHT_CEILING + 5)
	_play("celesta", up, 0.026)
	_play("glass", up, 0.014)
	shape_note.emit(up, true)


## A part of the song for this section: "arp_b" in the chorus if the song has one, else "arp".
func _part(song: Dictionary, part: String, chorus: bool) -> Array:
	var key := part + ("_b" if chorus else "_a")
	return song.get(key, song.get(part, []))


func _in_chorus() -> bool:
	return layers > Zones.BASE_LAYERS[zone - 1]


## The zone's song (data/songs.gd), unless the title theme or the dark has the music.
func _song() -> Dictionary:
	if theme or dark or track != "":
		return {}
	return Songs.of(zone)


## Sixteenths in a chord: two bars of the song's metre (32 in 4/4, 24 in 3/4).
func _chord_steps() -> int:
	return int(_song().get("bar", 16)) * 2


## The tempo now: the song's own, or the zone's.
func bpm() -> float:
	if track != "":
		return float(Songs.TRACKS[track].bpm)
	return float(_song().get("bpm", Zones.BPM[zone - 1]))


## The song's section now: the chorus (B) once the zone has its extra layer (barrier 6 of 10).
func _section(song: Dictionary) -> Array:
	return song.b if _in_chorus() else song.a


## While a run on the beat lasts, the melody is the player's.
func _player_leads() -> bool:
	return GameState.beat_streak >= 2 and _time - _last_accent < _s16() * 8.0


## One sixteenth of the title theme: bass on the bar, a soft harp in eighths, and the melody on piano.
func _play_theme_step(s: int) -> void:
	var c := chord()
	var root := tonic() + int(c[0])
	var bar := s % 16
	if bar == 0:
		_play("bass", root - 12, 0.06)
	elif bar == 8:
		_play("bass", root - 12 + 7, 0.035)
	if s % 2 == 0:
		var deg: int = ARP_PATTERN[_arp_i % ARP_PATTERN.size()]
		_arp_i += 1
		var low := chord_note(deg, tonic())
		_play("harp", low, 0.02)
		shape_note.emit(low, false)
	if s < _theme_from:
		return
	var slot := int((s - _theme_from) / float(STEPS_PER_CHORD)) % 8
	var second := slot >= 4   # A': a step higher in its second half, the flute along, glass
	var k := (s - _theme_from) % STEPS_PER_CHORD
	for n: Array in THEME[slot % 4]:
		if int(n[0]) != k:
			continue
		var deg: int = int(n[1]) + (1 if second and slot % 4 >= 2 else 0)
		var midi := chord_note(deg, tonic() + 12)
		while midi > BRIGHT_CEILING:
			midi -= 12
		_play("piano", midi, 0.042)
		if second:
			_play("flute", midi, 0.022)
		shape_note.emit(midi, false)
	if second and k == 4:
		var shine := chord_note(randi_range(0, c.size() - 1), tonic() + 24)
		_play("glass", shine, 0.018)
		shape_note.emit(shine, true)


func _play_choir() -> void:
	if title_on or track != "":
		return
	if dark:
		# The low pedal: the chord's root held in the bass and the deep wind, a fifth under it.
		var root := tonic() + int(chord()[0])
		_play("bass", root - 12, 0.06)
		_play_wind("zona", root, 0.05)
		return
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
	return 60.0 / bpm() / 4.0


## Tap grid: sixteenths, or sextuplets when a sixteenth is longer than 150 ms.
func _tap_div() -> float:
	var s := _s16()
	if s <= 0.15:
		return s
	return 60.0 / bpm() / 6.0


func _current_slot() -> int:
	return floori((_time - _zone_origin) / _tap_div())


func _next_slot() -> int:
	return ceili((_time - _zone_origin) / _tap_div())


func _slot_time(k: int) -> float:
	return _zone_origin + k * _tap_div()


func _grid_time(div: float) -> float:
	return _zone_origin + ceilf((_time - _zone_origin) / div) * div


func _schedule(t: float, kind: String, what: String, midi: int, vol: float, bird := false) -> void:
	_queue.append({"t": t, "kind": kind, "what": what, "midi": midi, "vol": vol, "bird": bird})


func _fire(q: Dictionary) -> void:
	if q.kind == "atmos":
		var p := _pool(q.pool)
		p.stream = _atmos[q.what]
		p.pitch_scale = q.pitch
		p.volume_db = q.db
		p.play()
		if q.glide != 1.0:
			create_tween().tween_property(p, "pitch_scale", q.pitch * q.glide, q.glide_time)
		return
	_route = q.get("pool", "")
	if q.kind == "deg":
		var midi := chord_note(q.deg, tonic() + q.base)
		while midi > BRIGHT_CEILING:
			midi -= 12  # fold down: bright, never shrill
		_play(q.what, midi, q.vol, q.bird)
	elif q.kind == "wind":
		_play_wind(q.what, q.midi, q.vol, q.bird)
	else:
		_play(q.what, q.midi, q.vol, q.bird)
	_route = ""


# --- Voices -----------------------------------------------------------------

func _play(inst: String, midi: int, vol: float, bird := false) -> void:
	var bank: Dictionary = _bank.get(inst, {})
	if bank.is_empty():
		return
	var r: Vector2i = _range[inst]
	var src := clampi(midi, r.x, r.y)
	if not bank.has(src):
		return
	_voice(bank[src], pow(2.0, (midi - src) / 12.0), GROUP_DB[inst] + linear_to_db(vol / REF_VOL), bird)
	note_played.emit(midi, inst)


## Winds are tuned: one file per pitch class, picked by the note that sounds.
func _play_wind(kind: String, midi: int, vol: float, bird := false) -> void:
	var bank: Dictionary = _wind.get(kind, {})
	var lo: int = WIND_KINDS.get(kind, 60)
	var src := lo + posmod(midi - lo, 12)
	if not bank.has(src):
		return
	var group := "zone" if kind == "zona" else "wind"
	_voice(bank[src], 1.0, GROUP_DB[group] + linear_to_db(vol / REF_VOL), bird)


## Round robin over the pool: the next voice is always the oldest one, so it is the one stolen.
func _voice(stream: AudioStream, pitch: float, db: float, bird := false) -> void:
	var p: AudioStreamPlayer
	if _route != "":
		p = _pool(_route)
	elif bird:
		p = _bird_voices[_bird_i]
		_bird_i = (_bird_i + 1) % BIRD_VOICES
	else:
		p = _voices[_voice_i]
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
	_bird_bus = AudioServer.get_bus_index(BIRD_BUS)
	if _bird_bus == -1:
		AudioServer.add_bus()
		_bird_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bird_bus, BIRD_BUS)
		AudioServer.set_bus_send(_bird_bus, MUSIC_BUS)
		_bird_panner = AudioEffectPanner.new()
		AudioServer.add_bus_effect(_bird_bus, _bird_panner)
		var delay := AudioEffectDelay.new()
		delay.tap1_delay_ms = 340.0
		delay.tap1_level_db = -10.0
		delay.tap2_active = false
		delay.feedback_active = false
		AudioServer.add_bus_effect(_bird_bus, delay)
	_body_panners = [_bird_side_bus(BIRD_BODY_BUS, 0.0), _bird_side_bus(BIRD_VOICE_BUS, 0.12)]
	if AudioServer.get_bus_index(CELESTIAL_BUS) == -1:
		AudioServer.add_bus()
		var cb := AudioServer.bus_count - 1
		AudioServer.set_bus_name(cb, CELESTIAL_BUS)
		AudioServer.set_bus_send(cb, &"Master")
		var hall := AudioEffectReverb.new()
		hall.room_size = 0.9
		hall.damping = 0.5
		hall.wet = 0.35
		hall.dry = 0.85
		AudioServer.add_bus_effect(cb, hall)
		AudioServer.set_bus_mute(cb, AudioServer.is_bus_mute(_music_bus))
	if AudioServer.get_bus_index(DISTANT_BUS) == -1:
		AudioServer.add_bus()
		var d := AudioServer.bus_count - 1
		AudioServer.set_bus_name(d, DISTANT_BUS)
		AudioServer.set_bus_send(d, &"Master")
		var far := AudioEffectReverb.new()
		far.room_size = 0.96
		far.damping = 0.45
		far.wet = 0.55
		far.dry = 0.6
		AudioServer.add_bus_effect(d, far)
		var dull := AudioEffectLowPassFilter.new()
		dull.cutoff_hz = 2800.0
		AudioServer.add_bus_effect(d, dull)
		AudioServer.set_bus_mute(d, AudioServer.is_bus_mute(_music_bus))
	else:
		_bird_panner = AudioServer.get_bus_effect(_bird_bus, 0) as AudioEffectPanner


## A bus of the bird's own, panned with it, straight to Master (none of the music's reverb).
## wet > 0 adds a small, short reverb.
func _bird_side_bus(bus_name: StringName, wet: float) -> AudioEffectPanner:
	var i := AudioServer.get_bus_index(bus_name)
	if i != -1:
		return AudioServer.get_bus_effect(i, 0) as AudioEffectPanner
	AudioServer.add_bus()
	i = AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, &"Master")
	var pan := AudioEffectPanner.new()
	AudioServer.add_bus_effect(i, pan)
	if wet > 0.0:
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.45
		rv.damping = 0.6
		rv.wet = wet
		rv.dry = 1.0
		AudioServer.add_bus_effect(i, rv)
	AudioServer.set_bus_mute(i, AudioServer.is_bus_mute(_music_bus))
	return pan


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
