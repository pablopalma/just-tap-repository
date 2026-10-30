extends Node
## Plays from barrier 1 until the first story cinematic (barrier 3) and captures it, plus the
## barrier's figure and the musical shapes in normal play. godot --path . res://tools/cine_test.tscn

var _main: Node
var _t := 0.0
var _acc := 0.0
var _shots := {}
var _cine_seen_at := -1.0


func _ready() -> void:
	SaveSystem.enabled = false
	SaveSystem.lang = "en"
	GameState.new_game()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 and _main.intro != null:
		_main._start()
	if _main.intro == null and not _main._cine:
		_acc += 4.0 * delta
		while _acc >= 1.0:
			_acc -= 1.0
			GameState.tap("tap")
	if _main._cine and _cine_seen_at < 0.0:
		_cine_seen_at = _t
		print("CINE start t=%.1f stage=%d" % [_t, GameState.stage])
	if _cine_seen_at > 0.0 and _t - _cine_seen_at > 3.0:
		_shot("80_cinematic")
	if _t > 5.0 and _cine_seen_at < 0.0:
		_shot("81_figure_shapes")
	if _cine_seen_at > 0.0 and not _main._cine and not _shots.has("done"):
		_shots["done"] = true
		print("CINE end t=%.1f stage=%d hud=%.2f" % [_t, GameState.stage, _main.hud.modulate.a])
	if _t > 40.0 or (_shots.has("done") and _t - _cine_seen_at > 14.0):
		get_tree().quit()


func _shot(name: String) -> void:
	if _shots.has(name):
		return
	_shots[name] = true
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)
	print("SHOT %s stage=%d" % [name, GameState.stage])