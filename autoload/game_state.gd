extends Node
## Economy and barrier state (design doc §2, §4). Knows nothing about graphics or audio:
## visuals and music listen to its signals.

signal hit(damage: float, is_crit: bool, source: String)  # "tap" | "auto" | "echo"
signal gate_broken(n: int)
signal zone_completed(z: int)
signal chapter_unlocked(idx: int)
signal upgrade_bought(id: String, level: int)
signal light_changed(value: float)
signal game_finished
## The demo's last barrier broke (BuildFlags.DEMO): its own ending instead of the game's.
signal demo_finished
signal reborn
## Everything erased from the intro's "start over": no rebirth bonus, no story said.
signal progress_reset
## Dev menu: the game jumped to another barrier.
signal jumped(n: int)
## A star circuit or a fork started or ended at the current barrier (see star and ranches).
signal special_changed
signal star_light_broke(i: int, seg: int)
signal star_completed(n: int)
signal branch_broke(i: int)

## Star circuits (§22.3): barrier -> [points n, skip k]. The tip becomes n lights running a star.
const STAR_BARRIERS := {16: [4, 2], 27: [5, 2], 37: [6, 2], 67: [7, 3], 77: [5, 2], 87: [6, 2], 96: [7, 2]}
## Each light crosses six small barriers: two on its chord, two on its arc, two on its ray.
const STAR_SEGMENTS := 6
## Life of each small barrier against a normal one. Six in a row, so a star weighs about two
## barriers (tuned to keep the demo's length).
const STAR_HP := 0.35
## Forks (§19.4): two branches from FORK_FROM, three from FORK_THREE, joined again after FORK_TO.
const FORK_FROM := 41
const FORK_THREE := 51
const FORK_TO := 60
const FINAL := 100
const GAP := 150.0
const COMBO_MAX := 30.0
const COMBO_WINDOW := 0.45
const COMBO_DECAY := 25.0
const ECHO_DELAY := 0.12

var stage := 1
var hp := 1.0
var light := 0.0
var up := {}
var rebirths := 0
var seen := {}
## Voice lines already said this run (§20.4).
var said := {}
## Every manual tap of the whole game (kept across rebirths): the creator's letter quotes it.
var total_taps := 0
## Dev menu only: multiplies damage so any barrier can be tested quickly.
var dev_damage := 1.0
## Story moments already played as a cinematic this run (barrier -> true); saved.
var cinemas := {}
## While a cinematic plays the tip taps on its own and the barrier does not heal.
var cinematic := false
## Cinematic hits break a barrier in about this many beats.
const CINE_HITS := 7.0
## The demo's "now" cinematic: the tip breaks each of the last barriers in exactly this many hits.
const NOW_HITS := 8.0
var finished := false
## False during the intro and the ending: taps and regeneration wait.
var running := false

var combo := 0.0
var clock := 0.0
var last_hit_time := -100.0
var time_at_gate := 0.0
var taps_at_gate := 0

## The beat (JUST_TAP_GODOT.md §1, "tocar con la música"): a tap on the music's beat hits BEAT_MULT
## harder, BEAT_STEP more for every beat of a clean run, up to BEAT_MAX. A run allows rests of up
## to BEAT_GAP beats (half time is fine); any tap off the beat, or a second one in the same beat,
## ends it. So a calm player tapping with the music keeps up with one mashing, with far fewer taps.
const BEAT_MULT := 2.0
const BEAT_STEP := 0.375
const BEAT_MAX := 5.0
const BEAT_GAP := 2
## Holding taps twice a beat, each worth this much: a little under a median player tapping by hand
## (tools/full_run_test.tscn, `-- hold` against `-- median`).
const HOLD_WORTH := 1.6
## Accents keep the combo (resonancia) alive across a whole beat, not just COMBO_WINDOW.
const BEAT_COMBO_WINDOW := 1.2
var beat_streak := 0
## During a hit's signal: the run's length if that tap fell on the beat, else 0.
var accent := 0
var _last_beat := -100
## Per barrier, for telemetry: taps on the beat, taps from holding, the longest run.
var beat_taps_at_gate := 0
var hold_taps_at_gate := 0
var best_streak_at_gate := 0

var _combo_timer := 0.0
var _auto_acc := 0.0
var _echoes: Array[float] = []

## While the current barrier is a star: {"n": points, "k": skip, "lights": [{seg, hp, max}]}.
var star := {}
## While the current barrier is forked: one {hp, max, done} per branch.
var branches: Array[Dictionary] = []


func _ready() -> void:
	hp = max_hp(stage)
	_enter_stage()


func _process(delta: float) -> void:
	if not running or finished:
		return
	clock += delta
	time_at_gate += delta

	if _combo_timer > 0.0:
		_combo_timer -= delta
	else:
		combo = maxf(0.0, combo - COMBO_DECAY * delta)

	if not cinematic and not BuildFlags.PHRASES:   # a phrase does not heal: what you caught stays
		hp = minf(max_hp(stage), hp + regen(stage) * delta)
		_regen_special(delta)

	var rate := 0.6 * lv("pulso")
	if rate > 0.0:
		_auto_acc += rate * delta
		while _auto_acc >= 1.0 and not finished:
			_auto_acc -= 1.0
			tap("auto")

	for i in range(_echoes.size() - 1, -1, -1):
		_echoes[i] -= delta
		if _echoes[i] <= 0.0:
			_echoes.remove_at(i)
			tap("echo")


# --- Formulas (§4) ---------------------------------------------------------

func lv(id: String) -> int:
	return int(up.get(id, 0))


## Early barriers get extra life so the first zone lasts a couple of minutes instead of seconds;
## the boost fades out by barrier EARLY_UNTIL. Each chapter can then be scaled on its own
## (the single curve of the design doc does not hold for 100 barriers).
const EARLY_BOOST := 5.0
const EARLY_UNTIL := 18
const INTRO_START := 0.2
const INTRO_UNTIL := 7
## Tuned with tools/sim_time.tscn (with the gentler regeneration and fatigue): grey ×8 and red ×10 make the
## demo (barriers 1–40) about 19 min for an efficient player and 31 for a casual one, and nobody spends
## more than ~1.5 min on one barrier. ×7 for 41–60 keeps the demo's dark stretch (41–45) around 3–4 min.
## Later chapters are still on the original curve.
var chapter_hp := [8.0, 10.0, 7.0, 1.0, 1.0]


## The opening flows (3/11/2026): the play data and a player's video showed barrier 4 as the first
## wall (82 taps after three of a few seconds) and the most players leaving there. Barriers up to
## FLOW_UNTIL take FLOW_LOW of their life, then it rises evenly to the full curve at FLOW_FULL.
const FLOW_LOW := 0.3
const FLOW_UNTIL := 7
const FLOW_FULL := 18   # was 14: barriers 15–16 became a wall, the most players leaving at 15 (3/11/2026)


func max_hp(n: int) -> float:
	var base := float(n) if n <= 12 else 12.0 * pow(1.15, n - 12) + (n - 12) * 3
	var early := lerpf(EARLY_BOOST, 1.0, clampf((n - 1) / float(EARLY_UNTIL - 1), 0.0, 1.0))
	# The very first barriers fall in a handful of taps (§2): the first impression is reward.
	var intro := lerpf(INTRO_START, 1.0, clampf((n - 1) / float(INTRO_UNTIL - 1), 0.0, 1.0))
	var flow := lerpf(FLOW_LOW, 1.0, clampf(float(n - FLOW_UNTIL) / (FLOW_FULL - FLOW_UNTIL), 0.0, 1.0))
	if n <= 2:
		flow = [1.0, 0.55][n - 1]   # the first two keep a few taps each: the lesson starts on them
	return maxf(1.0, roundf(base * early * intro * flow * chapter_hp[clampi(int((n - 1) / 20.0), 0, 4)]))


## Fraction of max HP regenerated per second. Gentler than the design doc's 0.025·(n−7): the demo's
## chapters multiply life ×5–×6 and regeneration grows with it, which made walls no tapping could beat.
const REGEN_STEP := 0.012
const REGEN_MAX := 0.3
## The longer you stay on one barrier, the more it tires: regeneration halves after FATIGUE seconds,
## to a third after twice that… Nothing here is an absolute wall (design pillar: "relaxation").
const FATIGUE := 20.0


func regen_frac(n: int) -> float:
	if n < 8:
		return 0.0
	return minf(REGEN_MAX, REGEN_STEP * (n - 7))


func regen(n: int) -> float:
	return max_hp(n) * regen_frac(n) * pow(0.9, lv("corrosion")) * fatigue()


## 1 when you arrive at a barrier, falling as you keep at it.
func fatigue() -> float:
	return 1.0 / (1.0 + time_at_gate / FATIGUE)


func reward(n: int) -> float:
	return ceilf(pow(1.14, n)) * gain()


func light_per_tap(n: int) -> float:
	return n * 0.04 * gain()


func rebirth_mult() -> float:
	return pow(2.0, rebirths)


func power() -> float:
	var l := lv("fuerza")
	return (1 + l) * pow(1.075, l) * rebirth_mult() * dev_damage


func gain() -> float:
	return pow(1.15, lv("ganancia")) * rebirth_mult()


## 0..1, how broken the current barrier is (for a star: how much of the circuit is done; for a
## fork: the average of its branches).
func progress() -> float:
	if not star.is_empty():
		var done := 0.0
		for l in star.lights:
			done += l.seg + (0.0 if l.seg >= STAR_SEGMENTS else 1.0 - l.hp / l.max)
		return clampf(done / (STAR_SEGMENTS * star.lights.size()), 0.0, 1.0)
	if not branches.is_empty():
		var sum := 0.0
		for b in branches:
			sum += branch_progress(b)
		return sum / branches.size()
	return clampf(1.0 - hp / max_hp(stage), 0.0, 1.0)


func branch_progress(b: Dictionary) -> float:
	return 1.0 if b.done else clampf(1.0 - b.hp / b.max, 0.0, 1.0)


func fork_count(n: int) -> int:
	if n < FORK_FROM or n > FORK_TO or (BuildFlags.DEMO and n <= BuildFlags.DEMO_LAST):
		return 0  # the demo's dark stretch is one line, alone
	return 2 if n < FORK_THREE else 3


# --- Tapping ---------------------------------------------------------------

## `beat`: for a player's tap, the index of the music's beat it fell on (Music.beat_at_tap()), or
## -1 between beats. `held`: a tap from holding the button down (steady, on the half beat), which
## neither starts nor breaks a run.
func tap(source := "tap", beat := -1, held := false) -> void:
	accent = 0
	if not running or finished:
		return
	# In a cinematic (or a story) only its own hits count: the pulse and the echoes wait, so its
	# pace (and the voice over it) stays the same whatever the build.
	if cinematic and source != "cine" and source != "now":
		return
	var d := power()
	# A tap on the beat is worth several taps: in damage, and in everything a tap brings (light,
	# the chance of a flash or an echo, the combo), so tapping less, with the music, never falls behind.
	var worth := 1.0
	if source == "tap" and held:
		hold_taps_at_gate += 1
		worth = HOLD_WORTH
		d *= worth
	elif source == "tap":
		if beat >= 0 and beat != _last_beat:
			var gap := beat - _last_beat
			beat_streak = beat_streak + 1 if gap >= 1 and gap <= BEAT_GAP else 1
			_last_beat = beat
			accent = beat_streak
			worth = beat_worth(beat_streak)
			d *= worth
			beat_taps_at_gate += 1
			best_streak_at_gate = maxi(best_streak_at_gate, beat_streak)
		else:
			beat_streak = 0
	if source == "cine":
		# The tip taps on its own, on the beat: about CINE_HITS hits per barrier, whatever your build.
		d = maxf(d, max_hp(stage) * 1.25 / CINE_HITS)
	if source == "auto":
		d *= 0.6
	d *= 1.0 + combo * 0.015 * lv("resonancia")
	if source == "now":
		# Its own steady pace, whatever your build: the music, not the player, sets it.
		d = max_hp(stage) * 1.02 / NOW_HITS
	var crit := source != "cine" and source != "now" and randf() < 0.03 * lv("destello") * worth
	if crit:
		d *= 4.0
	if source == "tap":
		combo = minf(COMBO_MAX, combo + worth)
		_combo_timer = maxf(_combo_timer, BEAT_COMBO_WINDOW if accent > 0 else COMBO_WINDOW)
		taps_at_gate += 1
		total_taps += 1
		if randf() < 0.06 * lv("eco") * worth:
			_echoes.append(ECHO_DELAY)
	last_hit_time = clock
	add_light(light_per_tap(stage) * (0.5 if source == "auto" else worth))
	if not star.is_empty():
		hit.emit(d, crit, source)
		_hit_star(d)
		return
	if not branches.is_empty():
		hit.emit(d, crit, source)
		_hit_branches(d)
		return
	hp -= d
	hit.emit(d, crit, source)
	if hp <= 0.0:
		_break_gate()


## One tap hits every light at once; a light that breaks its small barrier moves on to the next.
func _hit_star(d: float) -> void:
	var all_done := true
	for i in star.lights.size():
		var l: Dictionary = star.lights[i]
		if l.seg >= STAR_SEGMENTS:
			continue
		l.hp -= d
		if l.hp <= 0.0:
			l.seg += 1
			l.hp = l.max
			add_light(reward(stage) * 0.06)
			star_light_broke.emit(i, l.seg)
		if l.seg < STAR_SEGMENTS:
			all_done = false
	if all_done:
		var n := stage
		add_light(reward(n) * 0.5)
		star_completed.emit(n)
		_break_gate()


## One tap hits every branch with its full damage; the barrier passes when all have arrived.
func _hit_branches(d: float) -> void:
	var all_done := true
	for i in branches.size():
		var b: Dictionary = branches[i]
		if b.done:
			continue
		b.hp -= d
		if b.hp <= 0.0:
			b.done = true
			branch_broke.emit(i)
		else:
			all_done = false
	if all_done:
		_break_gate()


func _regen_special(delta: float) -> void:
	var f := regen_frac(stage) * pow(0.9, lv("corrosion")) * fatigue() * delta
	if f <= 0.0:
		return
	for l in star.get("lights", []):
		if l.seg < STAR_SEGMENTS:
			l.hp = minf(l.max, l.hp + l.max * f)
	for b in branches:
		if not b.done:
			b.hp = minf(b.max, b.hp + b.max * f)


## Sets up the star or the fork of the current barrier, if it has one.
func _enter_stage() -> void:
	star = {}
	branches = []
	# (no star on the spiral: the line itself is the figure there)
	if BuildFlags.PHRASES:
		pass   # stars and forks as phrases of several lights: a later stage of the phrases
	elif STAR_BARRIERS.has(stage) and not finished and not PathData.in_spiral(stage):
		var spec: Array = STAR_BARRIERS[stage]
		var lights: Array[Dictionary] = []
		for i in int(spec[0]):
			var m := max_hp(stage) * STAR_HP * (1.0 + 0.15 * sin(i * 1.9 + stage))
			lights.append({"seg": 0, "hp": m, "max": m})
		star = {"n": int(spec[0]), "k": int(spec[1]), "lights": lights}
	elif fork_count(stage) > 0 and not finished:
		for i in fork_count(stage):
			var m := max_hp(stage) * (1.0 + 0.18 * sin(i * 2.3 + stage * 1.7))
			branches.append({"hp": m, "max": m, "done": false})
	special_changed.emit()


## A phrase played whole (PhraseLine): the barrier breaks.
func break_phrase() -> void:
	if running and not finished:
		hp = 0.0
		_break_gate()


func _break_gate() -> void:
	var n := stage
	add_light(reward(n))
	gate_broken.emit(n)
	if n % 10 == 0:
		var z := int(n / 10.0)
		zone_completed.emit(z)
		if z in [2, 4, 6, 8]:
			chapter_unlocked.emit(int(z / 2.0))
	# Exactly the last one: the dev menu can still jump past it to test the full game's ending.
	if BuildFlags.DEMO and n == BuildFlags.DEMO_LAST:
		finished = true
		hp = 0.0
		demo_finished.emit()
		return
	if n >= FINAL:
		finished = true
		hp = 0.0
		game_finished.emit()
		return
	stage += 1
	hp = max_hp(stage)
	time_at_gate = 0.0
	_reset_gate_counts()
	_enter_stage()


## What a tap on the beat is worth with a run of `run` beats (1 = the first on the beat).
## Runs on the beat that are celebrated: a flourish of notes and a burst of gold (Main._on_hit).
const BEAT_MILESTONES := [4, 8, 12, 16, 24, 32, 48, 64, 96, 128]


func beat_worth(run: int) -> float:
	return minf(BEAT_MAX, BEAT_MULT + BEAT_STEP * (run - 1))


## A new barrier: its counters start again (a run on the beat carries on across barriers).
func _reset_gate_counts() -> void:
	taps_at_gate = 0
	beat_taps_at_gate = 0
	hold_taps_at_gate = 0
	best_streak_at_gate = 0


func add_light(v: float) -> void:
	light += v
	light_changed.emit(light)


# --- Upgrades (§5) ----------------------------------------------------------

func cost(id: String) -> float:
	var d: Dictionary = Upgrades.DATA[id]
	return ceilf(d.base * pow(d.growth, lv(id)))


## 0 hidden, 1 peeking (parent has a level), 2 open (requirement met).
func state_of(id: String) -> int:
	var d: Dictionary = Upgrades.DATA[id]
	if d.req == "":
		return 2
	if lv(d.req) >= d.req_lv:
		return 2
	if lv(d.req) >= 1:
		return 1
	return 0


func is_maxed(id: String) -> bool:
	return lv(id) >= int(Upgrades.DATA[id].max)


func can_buy(id: String) -> bool:
	return state_of(id) == 2 and not is_maxed(id) and light >= cost(id)


func any_buyable() -> bool:
	for id in Upgrades.ORDER:
		if can_buy(id):
			return true
	return false


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	light -= cost(id)
	up[id] = lv(id) + 1
	light_changed.emit(light)
	upgrade_bought.emit(id, lv(id))
	return true


# --- Rebirth and save -------------------------------------------------------

func rebirth() -> void:
	rebirths += 1
	stage = 1
	hp = max_hp(1)
	light = 0.0
	up = {}
	seen = {}
	cinemas = {}
	cinematic = false
	finished = false
	combo = 0.0
	_echoes.clear()
	_auto_acc = 0.0
	time_at_gate = 0.0
	_reset_gate_counts()
	light_changed.emit(light)
	_enter_stage()
	reborn.emit()


func new_game() -> void:
	rebirths = 0
	stage = 1
	hp = max_hp(1)
	light = 0.0
	up = {}
	seen = {}
	said = {}
	total_taps = 0
	cinemas = {}
	cinematic = false
	finished = false
	combo = 0.0
	_echoes.clear()
	_auto_acc = 0.0
	time_at_gate = 0.0
	_reset_gate_counts()
	light_changed.emit(light)
	_enter_stage()
	progress_reset.emit()


## Dev menu: move to barrier n as if every earlier one were broken. Lines for earlier moments are
## marked as said so the voice does not replay the whole story at once.
func dev_jump(n: int) -> void:
	stage = clampi(n, 1, FINAL)
	hp = max_hp(stage)
	finished = false
	combo = 0.0
	_echoes.clear()
	time_at_gate = 0.0
	_reset_gate_counts()
	for k in VoiceLines.ON_REACH:
		if k <= stage:
			said[VoiceLines.ON_REACH[k]] = true
	for z in VoiceLines.ON_ZONE:
		if z * 10 < stage:
			said[VoiceLines.ON_ZONE[z]] = true
	_enter_stage()
	jumped.emit(stage)


func to_dict() -> Dictionary:
	return {"stage": stage, "hp": hp, "light": light, "up": up, "reb": rebirths, "seen": seen,
		"finished": finished, "said": said.keys(), "taps": total_taps, "cine": cinemas.keys()}


func from_dict(d: Dictionary) -> void:
	stage = clampi(int(d.get("stage", 1)), 1, FINAL)
	finished = bool(d.get("finished", false))
	hp = clampf(float(d.get("hp", max_hp(stage))), 0.0, max_hp(stage))
	if hp <= 0.0 and not finished:
		hp = max_hp(stage)
	light = float(d.get("light", 0.0))
	rebirths = int(d.get("reb", 0))
	total_taps = int(d.get("taps", 0))
	cinemas = {}
	for k in d.get("cine", []):
		cinemas[int(k)] = true
	up = {}
	var u: Dictionary = d.get("up", {})
	for k in u:
		if Upgrades.DATA.has(k):
			up[k] = int(u[k])
	said = {}
	for id in d.get("said", []):
		said[str(id)] = true
	seen = {}
	var s: Dictionary = d.get("seen", {})
	for k in s:
		seen[k] = int(s[k])
	_enter_stage()
