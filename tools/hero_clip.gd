extends Node
## A clean clip for the website's hero: the colour coming back, with no HUD, subtitles or titles.
## godot --path . --write-movie Builds/web_hero.avi --fixed-fps 30 res://tools/hero_clip.tscn

const LENGTH := 9.0

var _main: Node
var _t := 0.0
var _broke := false


func _ready() -> void:
	SaveSystem.enabled = false
	Narrator.auto = false
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_main.fx.font = null


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.1 and _main.intro != null:
		_main._dev_jump(20)
	_main.hud.modulate.a = 0.0
	_main.zone_title.hide_now()
	_main.subtitle.visible = false
	if not _broke and _t > 1.6:
		_broke = true
		GameState.hp = 0.0
		GameState.tap("tap")
	if _t >= LENGTH:
		get_tree().quit()