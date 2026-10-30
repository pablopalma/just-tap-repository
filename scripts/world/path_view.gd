extends Node2D
## The path: a faint layer drawn once, and the lit line up to the tip, coloured by chapter (§6.2).

const LINE_W := 2.2

var path: PathData
var lit := 0.0:
	set(v):
		if not is_equal_approx(v, lit):
			lit = v
			queue_redraw()


func setup(p: PathData) -> void:
	path = p
	var faint := FaintLayer.new()
	faint.path = p
	add_child(faint)
	move_child(faint, 0)


func _draw() -> void:
	if path == null:
		return
	for n in range(1, PathData.FINAL + 1):
		var a := 0 if n == 1 else path.gate_vertex[n - 1]
		var b := path.gate_vertex[n]
		if path.lengths[a] >= lit:
			break
		var pts := PackedVector2Array()
		for v in range(a, b + 1):
			if path.lengths[v] <= lit:
				pts.append(path.points[v])
			else:
				pts.append(path.pos_at(lit))
				break
		if pts.size() >= 2:
			draw_polyline(pts, Palette.line_col(n), LINE_W, true)

	# Branches of the barriers already passed light up in their colour.
	var reached := GameState.stage - (0 if GameState.finished else 1)
	for br in path.branches:
		var n: int = br.n
		if n > reached:
			break
		var col := Color(Palette.line_col(n), 0.75)
		draw_polyline(br.pts, col, 1.2, true)
		draw_arc(br.ring, 4.0, 0.0, TAU, 18, col, 1.2, true)


## Static faint path and branches: drawn once, never redrawn.
class FaintLayer extends Node2D:
	var path: PathData

	func _draw() -> void:
		var ink := Color(Palette.INK, 0.14)
		draw_polyline(path.points, ink, 2.2, true)
		var thin := Color(Palette.INK, 0.10)
		for br in path.branches:
			draw_polyline(br.pts, thin, 1.1, true)
			draw_arc(br.ring, 4.0, 0.0, TAU, 18, thin, 1.1, true)
