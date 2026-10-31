extends Node
## The demo's dark stretch from barrier 40 to the whale: break 40, play 41–45 in the dark, then the
## mandala, the light and the whale.
## godot --path . --write-movie Builds/dark_test.avi --fixed-fps 30 res://tools/dark_test.tscn

const LENGTH := 66.0
const BREAKS := [1.0, 9.0, 14.0, 19.0, 24.0, 29.0]  # 40, then 41..45

var _main: Node
var _t := 0.0
var _i := 0
## Notes heard while the music is dark, and how many fell outside its natural minor scale.
var _dark_notes := 0
var _off_scale := {}


func _ready() -> void:
	SaveSystem.enabled = false
	Narrator.auto = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Music.note_played.connect(_on_note)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.3 and _t - delta <= 0.3:
		_main._on_dev("jump", 40)
	# Taps all along, so the crumbling chips fly; each barrier breaks on schedule.
	if GameState.running and not GameState.finished and fmod(_t, 0.25) < delta:
		GameState.tap("tap")
	if _i < BREAKS.size() and _t >= BREAKS[_i]:
		_i += 1
		_main._dev_break()
	if _t >= LENGTH:
		print("DARK stage=%d finished=%s mode=%d dark_notes=%d off_scale=%s" % [GameState.stage, GameState.finished,
			_main.mode, _dark_notes, _off_scale])
		get_tree().quit()

func _on_note(midi: int, inst: String) -> void:
	if not Music.dark:
		return
	_dark_notes += 1
	if not posmod(midi - Music.tonic(), 12) in [0, 2, 3, 5, 7, 8, 10]:
		_off_scale[inst] = _off_scale.get(inst, 0) + 1
