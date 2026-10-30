extends Node
## Plays the creator's letter with its recorded voice in real time, prints when each line appears
## and captures the end. godot --path . res://tools/letter_voice_test.tscn

var _main: Node
var _t := 0.0
var _letter: Control
var _seen := {}
var _done := false


func _ready() -> void:
	GameState.new_game()
	GameState.total_taps = 18304
	SaveSystem.lang = "es"
	SaveSystem.voice_on = true
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	var s: AudioStream = load(VoiceLines.audio_path("letter"))
	print("VOICE length=%.1f s" % s.get_length())


func _process(delta: float) -> void:
	_t += delta
	if _letter == null and _t > 0.5:
		_main._start()
		_letter = Screens.Letter.new(GameState.total_taps)
		_main.hud.get_parent().add_child(_letter)
	if _letter == null:
		return
	for l in _letter._lines:
		if l.modulate.a > 0.5 and not _seen.has(l):
			_seen[l] = true
			print("LINE %5.1f s  %s" % [_t - 0.5, l.text])
	if not _done and _letter._ready_to_leave:
		_done = true
		var path := "user://shots/32_letter_voiced.png"
		get_viewport().get_texture().get_image().save_png(path)
		print("DONE %.1f s" % (_t - 0.5))
		get_tree().quit()