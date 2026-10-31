extends Node
## Key art for the store capsules (docs/capsulas.md), rendered by the game itself: the finished city
## in colour, the ink line and the giant bird, with no HUD or text. Renders off-screen at any size.
## godot --path . res://tools/capsule_art.tscn -- --size=3840x2160 --zoom=0.42 --y=0 --bird=0.3 --out=Builds/capsule/art.png
##   zoom: camera zoom relative to the game's base zoom (smaller shows more city)
##   y:    where the camera looks, as a barrier number along the line (the city centre is ~50)
##   bird: the bird's place in its flight, 0..1 (0.3 is closest and biggest); -1 hides it
##   x:    camera offset to the side, in world units
##   cy:   where the camera looks, in world units (instead of y)
##   dir:  1 the bird flies to the right, -1 to the left
##   zoom 0 keeps the ending's own camera
##   bscale, bx, by: the bird's size multiplier and its place as fractions of the frame (after the
##   bird has placed itself; bx/by empty keep its own place)

const WAIT := 11.0  # the city's colour fades in over several seconds

var _main: Node
var _vp: SubViewport
var _t := 0.0
var _args := {"size": "3840x2160", "zoom": "0", "y": "50", "cy": "", "bird": "0.3", "x": "0", "dir": "1", "bscale": "1", "bx": "", "by": "",
	"out": "Builds/capsule/art.png"}
var _saved := false


func _ready() -> void:
	process_priority = 100  # after Main and the camera: this node has the last word on the frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.trim_prefix("--").split("=", true, 1)
			_args[kv[0]] = kv[1]
	SaveSystem.enabled = false
	Narrator.auto = false
	Music.set_enabled(false)
	GameState.new_game()
	var wh: PackedStringArray = _args.size.split("x")
	_vp = SubViewport.new()
	_vp.size = Vector2i(int(wh[0]), int(wh[1]))
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_main = load("res://scenes/main.tscn").instantiate()
	_vp.add_child(_main)
	_main.fx.font = null


func _process(delta: float) -> void:
	_t += delta
	if int(_t) != int(_t - delta):
		print("CAPSULE t=%d intro=%s finished=%s" % [int(_t), _main.intro != null, GameState.finished])
	if _t > 0.3 and _main.intro != null:
		_main._start()
	if _t > 0.6 and _t - delta <= 0.6:
		_main._on_dev("grand", 0)
	_main.hud.modulate.a = 0.0
	_main.subtitle.visible = false
	_main.zone_title.hide_now()
	if _t > 3.0:
		var cam = _main.camera
		if float(_args.zoom) <= 0.0:
			if int(_t) != int(_t - delta):
				print("CAPSULE cam pos=%s zoom=%.3f base=%.3f" % [cam.position, cam.zoom.x, _main._base_zoom()])
		else:
			var cy: float = float(_args.cy) if _args.cy != "" else _main.path.gate_pos(int(_args.y)).y
			cam.target_pos = Vector2(float(_args.x), cy)
			cam.target_zoom = _main._base_zoom() * float(_args.zoom)
			cam.trauma = 0.0
			cam.snap()
	if _t > 3.0:
		var b := float(_args.bird)
		if b < 0.0:
			_main.bird.stop()
		else:
			if not _main.bird.active:
				_main.bird.fly()
			_main.bird._t = b * GiantBird.DURATION
			_main.bird._dir = float(_args.dir)
			# The bird has already placed itself this frame (it processes before this node).
			_main.bird.scale *= float(_args.bscale)
			if _args.bx != "" and _args.by != "":
				_main.bird.offset = Vector2(float(_args.bx) * _vp.size.x, float(_args.by) * _vp.size.y)
	if _t >= WAIT and not _saved:
		_saved = true
		await RenderingServer.frame_post_draw
		var out: String = _args.out
		var path := out if out.contains(":") else ProjectSettings.globalize_path("res://" + out)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		_vp.get_texture().get_image().save_png(path)
		print("CAPSULE saved %s" % path)
		get_tree().quit()
