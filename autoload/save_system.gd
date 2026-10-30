extends Node
## Saves to user://save.json every 3 s, on each broken barrier, on each purchase and when the app pauses.

const PATH := "user://save.json"
const INTERVAL := 3.0

var music_on := true
var voice_on := true
## True when a save with progress existed at startup.
var had_progress := false

var _t := 0.0


func _ready() -> void:
	load_game()
	GameState.gate_broken.connect(func(_n: int) -> void: save_game.call_deferred())
	GameState.upgrade_bought.connect(func(_id: String, _l: int) -> void: save_game())
	GameState.reborn.connect(save_game)


func _process(delta: float) -> void:
	if not GameState.running:
		return
	_t += delta
	if _t >= INTERVAL:
		_t = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func save_game() -> void:
	var d := GameState.to_dict()
	d["music_on"] = music_on
	d["voice_on"] = voice_on
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(d))


func load_game() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		push_warning("Save file is corrupt; starting fresh.")
		return
	var d: Dictionary = parsed
	GameState.from_dict(d)
	music_on = bool(d.get("music_on", true))
	voice_on = bool(d.get("voice_on", true))
	had_progress = GameState.stage > 1 or GameState.light > 0.0


func delete_save() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
