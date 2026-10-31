extends Node2D
## For the trailer and the teaser: shows where each of the player's taps lands, so a viewer can tell
## a tap from what happens on its own (docs/guion-trailer-teaser.md). A soft dot and a ring that
## opens on the barrier being hit. It lives in the world, under the darkness, so in the demo's dark
## it turns white on black with everything else. Same size on screen whatever the camera's zoom.

var camera: Camera2D
var path: PathData
## Directors switch it off for shots where taps should not show.
var enabled := true

var _rings: Array[Dictionary] = []


func tap() -> void:
	if not enabled:
		return
	var at := path.gate_pos(GameState.stage) + Vector2(randf_range(-26, 26), randf_range(-14, 6))
	_rings.append({"p": at, "t": 0.0})


func clear() -> void:
	_rings.clear()
	queue_redraw()


func _process(delta: float) -> void:
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i].t += delta
		if _rings[i].t > 0.7:
			_rings.remove_at(i)
	queue_redraw()


func _draw() -> void:
	var px := 1.0 / maxf(0.05, camera.zoom.x)  # one screen pixel in world units
	for r in _rings:
		var k: float = r.t / 0.7
		var e := 1.0 - pow(1.0 - k, 3.0)
		var a := 1.0 - k
		draw_arc(r.p, lerpf(10.0, 58.0, e) * px, 0.0, TAU, 40, Color(Palette.INK, 0.75 * a), 3.0 * px, true)
		if r.t < 0.22:
			draw_circle(r.p, 9.0 * px, Color(Palette.INK, 0.35 * (1.0 - r.t / 0.22)))
