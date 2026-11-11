extends Node
## The black hole's chapter in the game (chapter 10, Estrella): jumps to a barrier of it and plays its
## phrases like a good player (every note on time, the long ones held), logging the hole as it comes
## near, the fall and the way out into Alba. Stops once the dive into chapter 11 is over.
## godot --path . --write-movie x.avi --fixed-fps 30 res://tools/hole_test.tscn -- 98
## (the number: the barrier to start from, 91 by default)

const LIMIT := 600.0

var _main: Node
var _t := 0.0
var _from := 91
var _release := -1.0
var _pressed := {}
var _fell := false
var _through := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			_from = int(a)
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.gate_broken.connect(func(n: int) -> void:
		_log("barrera %d rota · cerca %.2f" % [n, _main.hole.near_to if _main.hole else -1.0]))
	get_tree().create_timer(0.5).timeout.connect(func() -> void: _main._on_dev("jump", _from))


func _log(s: String) -> void:
	print("[%6.1f s] %s" % [_t, s])


func _process(delta: float) -> void:
	_t += delta
	if _t > LIMIT:
		print("FALLA: se acabó el tiempo en la barrera %d" % GameState.stage)
		get_tree().quit(1)
		return
	var hole: SpacetimeView = _main.hole
	if hole and not _seen("hole"):
		_log("aparece el agujero")
	if _main._hole_fall and not _fell:
		_fell = true
		_log("la caída")
	if _fell and not _main._hole_fall and not _through:
		_through = true
		_log("la luz blanca: sale a la zona %d" % Zones.of(GameState.stage))
	if _through and not _main.droste.is_playing() and Zones.of(GameState.stage) == 11 and _t > 2.0:
		if not _seen("alba"):
			_log("en Alba, barrera %d" % GameState.stage)
			get_tree().create_timer(3.0).timeout.connect(func() -> void:
				print("OK")
				get_tree().quit(0))
	_play()


var _flags := {}


func _seen(k: String) -> bool:
	if _flags.has(k):
		return true
	_flags[k] = true
	return false


## Taps each note as it lands (as heard), holding the long ones for their length.
func _play() -> void:
	if _release >= 0.0 and _t >= _release:
		Input.action_release("tap")
		_release = -1.0
	var pl: PhraseLine = _main.phrase_line
	if pl == null or not pl.active:
		return
	for n in pl.upcoming():
		if n.state != 0 or n.ahead > 0.02 or n.ahead < -0.15:
			continue
		var key := snappedf(pl._now() + n.ahead, 0.01)
		if _pressed.has(key):
			continue
		_pressed[key] = true
		_main._press()
		if n.len > 0.0:
			Input.action_press("tap")
			_release = _t + (n.len + 0.1) * pl._beat_len()
