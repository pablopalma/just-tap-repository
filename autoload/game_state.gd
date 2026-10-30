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
signal reborn
## Everything erased from the intro's "start over": no rebirth bonus, no story said.
signal progress_reset
## Dev menu: the game jumped to another barrier.
signal jumped(n: int)

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
var finished := false
## False during the intro and the ending: taps and regeneration wait.
var running := false

var combo := 0.0
var clock := 0.0
var last_hit_time := -100.0
var time_at_gate := 0.0
var taps_at_gate := 0

var _combo_timer := 0.0
var _auto_acc := 0.0
var _echoes: Array[float] = []


func _ready() -> void:
	hp = max_hp(stage)


func _process(delta: float) -> void:
	if not running or finished:
		return
	clock += delta
	time_at_gate += delta

	if _combo_timer > 0.0:
		_combo_timer -= delta
	else:
		combo = maxf(0.0, combo - COMBO_DECAY * delta)

	hp = minf(max_hp(stage), hp + regen(stage) * delta)

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


func max_hp(n: int) -> float:
	if n <= 12:
		return float(n)
	return roundf(12.0 * pow(1.15, n - 12) + (n - 12) * 3)


## Fraction of max HP regenerated per second.
func regen_frac(n: int) -> float:
	if n < 8:
		return 0.0
	return minf(0.5, 0.025 * (n - 7))


func regen(n: int) -> float:
	return max_hp(n) * regen_frac(n) * pow(0.9, lv("corrosion"))


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


## 0..1, how broken the current barrier is.
func progress() -> float:
	return clampf(1.0 - hp / max_hp(stage), 0.0, 1.0)


# --- Tapping ---------------------------------------------------------------

func tap(source := "tap") -> void:
	if not running or finished:
		return
	var d := power()
	if source == "auto":
		d *= 0.6
	d *= 1.0 + combo * 0.015 * lv("resonancia")
	var crit := randf() < 0.03 * lv("destello")
	if crit:
		d *= 4.0
	if source == "tap":
		combo = minf(COMBO_MAX, combo + 1.0)
		_combo_timer = COMBO_WINDOW
		taps_at_gate += 1
		total_taps += 1
		if randf() < 0.06 * lv("eco"):
			_echoes.append(ECHO_DELAY)
	last_hit_time = clock
	add_light(light_per_tap(stage) * (0.5 if source == "auto" else 1.0))
	hp -= d
	hit.emit(d, crit, source)
	if hp <= 0.0:
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
	if n >= FINAL:
		finished = true
		hp = 0.0
		game_finished.emit()
		return
	stage += 1
	hp = max_hp(stage)
	time_at_gate = 0.0
	taps_at_gate = 0


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
	finished = false
	combo = 0.0
	_echoes.clear()
	_auto_acc = 0.0
	time_at_gate = 0.0
	taps_at_gate = 0
	light_changed.emit(light)
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
	finished = false
	combo = 0.0
	_echoes.clear()
	_auto_acc = 0.0
	time_at_gate = 0.0
	taps_at_gate = 0
	light_changed.emit(light)
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
	taps_at_gate = 0
	for k in VoiceLines.ON_REACH:
		if k <= stage:
			said[VoiceLines.ON_REACH[k]] = true
	for z in VoiceLines.ON_ZONE:
		if z * 10 < stage:
			said[VoiceLines.ON_ZONE[z]] = true
	jumped.emit(stage)


func to_dict() -> Dictionary:
	return {"stage": stage, "hp": hp, "light": light, "up": up, "reb": rebirths, "seen": seen,
		"finished": finished, "said": said.keys(), "taps": total_taps}


func from_dict(d: Dictionary) -> void:
	stage = clampi(int(d.get("stage", 1)), 1, FINAL)
	finished = bool(d.get("finished", false))
	hp = clampf(float(d.get("hp", max_hp(stage))), 0.0, max_hp(stage))
	if hp <= 0.0 and not finished:
		hp = max_hp(stage)
	light = float(d.get("light", 0.0))
	rebirths = int(d.get("reb", 0))
	total_taps = int(d.get("taps", 0))
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
