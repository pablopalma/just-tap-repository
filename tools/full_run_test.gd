extends Node
## The whole demo, played like a player would: taps six times a second, buys on the tree's branches
## whatever it can, says "tell me" to the story, and goes on to the end screen. Logs every big moment
## (zones, dives, the story, the night, the dark, the whale, the end) with its time, and stops if
## anything gets stuck. Run it headless and fast:
## godot --headless --path . --fixed-fps 30 res://tools/full_run_test.tscn

const TAPS := 6.0
const LIMIT := 1800.0   # seconds of game time before giving up

var _main: Node
var _t := 0.0
var _acc := 0.0
var _buy := 0.0
var _last_stage := 0
var _stuck := 0.0
var _seen := {}


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.gate_broken.connect(func(n: int) -> void:
		if n % 5 == 0 or n >= 40:
			_log("barrera %d" % n))
	GameState.demo_finished.connect(func() -> void: _log("FIN DE LA DEMO (45)"))
	Narrator.line_started.connect(func(id: String, _x: String, _d: float) -> void:
		if id.begins_with("story") or id.begins_with("now") or id.begins_with("demo"):
			_log("voz " + id))


func _log(s: String) -> void:
	print("[%6.1f s] %s" % [_t, s])


func _once(key: String, cond: bool, s: String) -> void:
	if cond and not _seen.has(key):
		_seen[key] = true
		_log(s)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	_once("droste%d" % _main._droste_zone, _main.droste.is_playing(), "zambullida al terminar la zona %d" % _main._droste_zone)
	_once("night", _main.night.is_on(), "noche estrellada")
	_once("dark", _main._dark, "entra la oscuridad")
	_once("spiral", _main.path.on_spiral(_main.tip.lit), "entra al espiral")
	_once("now", _main._now, "cinemática del ahora")
	_once("wake", _main.whale.active and not _main.whale.sleeping, "la ballena despierta")
	_once("letter", _main._letter_shown, "la carta")
	if _main._story:
		_once("story", true, "pausa: historia")
		for c in _main.subtitle.get_parent().get_children():
			if c.has_method("_tell") and not c._telling and _t > float(_seen.get("story_t", 0.0)):
				if not _seen.has("story_t"):
					_seen["story_t"] = _t + 2.0
				elif _t > float(_seen["story_t"]):
					c._tell()
	# leave the letter as a player would
	for c in _main.hud.get_parent().get_children():
		if c is Screens.Letter and c._ready_to_leave:
			c._leave()
	if _main._end_shown:
		_log("pantalla final. barrera %d, %d toques" % [GameState.stage, GameState.total_taps])
		get_tree().quit()
		return
	if GameState.running and not GameState.finished and not _main._story:
		_acc += delta * TAPS
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap")
		_buy += delta
		if _buy > 1.5:
			_buy = 0.0
			var best := ""
			for id in Upgrades.ORDER:
				if GameState.can_buy(id) and (best == "" or GameState.cost(id) < GameState.cost(best)):
					best = id
			if best != "":
				_main.inline_tree._choose(best)
	if GameState.stage != _last_stage:
		_last_stage = GameState.stage
		_stuck = 0.0
	elif not GameState.finished:
		_stuck += delta
		if _stuck > 240.0:
			_log("TRABADO en la barrera %d" % GameState.stage)
			get_tree().quit(1)
	if _t > LIMIT:
		_log("TIEMPO AGOTADO en la barrera %d" % GameState.stage)
		get_tree().quit(1)