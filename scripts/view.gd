class_name View
extends RefCounted
## The angle the world is seen at. The line does not always climb: each zone, inside the last one,
## can run its own way (Main turns the camera between zones, through the Droste dive). Everything
## that draws apart from the camera (the landscape, the far layers, the colour wave) turns with it,
## and text drawn in the world is turned back so it always reads upright.

## Radians; the camera sets it every frame (without its shake).
static var angle := 0.0


## The world-aligned box a screen of size `vs` covers at the current angle (for culling).
static func size(vs: Vector2) -> Vector2:
	var c := absf(cos(angle))
	var s := absf(sin(angle))
	return Vector2(vs.x * c + vs.y * s, vs.x * s + vs.y * c)


## An offset of `v` as seen on screen, in the world's own axes: text laid out "below" or "above"
## something stays below or above it on screen whatever the angle.
static func screen(v: Vector2) -> Vector2:
	return v.rotated(angle)


## draw_string, upright on screen whatever the angle. `at` is where the text starts (its baseline).
static func text(ci: CanvasItem, font: Font, at: Vector2, s: String, align: HorizontalAlignment,
		width: float, size_px: int, col: Color) -> void:
	if angle == 0.0:
		ci.draw_string(font, at, s, align, width, size_px, col)
		return
	ci.draw_set_transform(at, angle)
	ci.draw_string(font, Vector2.ZERO, s, align, width, size_px, col)
	ci.draw_set_transform(Vector2.ZERO)
