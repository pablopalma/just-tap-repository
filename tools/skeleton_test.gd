extends Node
## The twelve chapters end to end (the skeleton, 11/11/2026): jumps to the last barrier of each zone,
## breaks it, waits for the zone's end (the dive, the colour, the story) and logs what the next zone
## is: its name, colour chapter, direction, theme and tempo. At the last one, the ending must start.
## godot --headless --path . --fixed-fps 30 res://tools/skeleton_test.tscn

const WAIT := 80.0   # seconds of game time for each zone's end (the black hole's fall takes about 40)

var _main: Node
var _z := 0
var _t := 0.0
var _finished := false
var _colours := []


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "es"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameState.game_finished.connect(func() -> void: _finished = true)
	GameState.chapter_unlocked.connect(func(i: int) -> void: _colours.append(Loc.chapter_name(i)))
	print("final: %d barreras, %d zonas" % [Zones.FINAL, Zones.COUNT])
	_next()


func _next() -> void:
	_z += 1
	_t = 0.0
	_main._on_dev("edge", _z * 10)


func _process(delta: float) -> void:
	_t += delta
	if _z == Zones.COUNT:
		if _finished:
			print("zona %d rota: empieza el final" % _z)
			print("colores que vuelven: %s" % [_colours])
			print("OK")
			get_tree().quit(0)
		elif _t > WAIT:
			print("FALLA: la barrera %d no termina el juego" % Zones.FINAL)
			get_tree().quit(1)
		return
	if GameState.stage == _z * 10 + 1 and _t > 12.0:
		var z := Zones.of(GameState.stage)
		print("zona %2d %-9s barrera %3d · color %-8s · giro %4d° · tema %-10s · %d bpm" % [z, Loc.zone_name(z),
			GameState.stage, Loc.chapter_name(Palette.chapter_of(GameState.stage)),
			roundi(rad_to_deg(_main._zone_angle(z))), Songs.zone_track(z) if Songs.zone_track(z) != "" else "(generada)",
			roundi(Music._song().get("bpm", Zones.BPM[z - 1]))])
		_next()
	elif _t > WAIT:
		print("FALLA: atascado en la zona %d (barrera %d)" % [_z, GameState.stage])
		get_tree().quit(1)
