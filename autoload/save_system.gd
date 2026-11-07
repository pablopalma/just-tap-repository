extends Node
## Saves to user://save.json every 3 s, on each broken barrier, on each purchase and when the app pauses.

signal lang_changed

const PATH := "user://save.json"
const INTERVAL := 3.0

var music_on := true
var voice_on := true
## Game language: "en" or "es". English by default; a player who switches keeps the choice in the save.
## The voice itself is always English.
var lang := "en"
## True when a save with progress existed at startup.
var had_progress := false
## How the player chose to play the phrases (PhraseLine.MODES): "" until asked.
var play_mode := ""
## Off while recording the trailer or running tests that must not touch the player's save.
var enabled := true

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


func set_lang(l: String) -> void:
	lang = l
	save_game()
	lang_changed.emit()


func save_game() -> void:
	if not enabled:
		return
	var d := GameState.to_dict()
	d["music_on"] = music_on
	d["voice_on"] = voice_on
	d["lang"] = lang
	d["play_mode"] = play_mode
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
	lang = str(d.get("lang", lang))
	play_mode = str(d.get("play_mode", ""))
	had_progress = GameState.stage > 1 or GameState.light > 0.0


func delete_save() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
