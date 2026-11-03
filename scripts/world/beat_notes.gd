class_name BeatNotes
extends RefCounted
## The notes of light that show the beat (JUST_TAP_GODOT.md §1, "Tocar con la música"): a few
## notes climbing a path towards a light, each reaching it as its beat sounds, a small gold ring as it
## lands. The tip draws them on the line; a star's or a fork's lights on their own paths.

const NOTES := 3
const GAP := 64.0   # px between notes


## How clearly they show: faint at first, clear while a run on the beat lasts.
static func strength() -> float:
	var g := GameState
	if not g.running or g.finished or g.cinematic or g.total_taps <= 0:
		return 0.0
	return 0.35 + 0.65 * minf(1.0, g.beat_streak / 4.0)


## Draws them on `ci` for a light at `light` (in ci's space). `back` gives the point `d` px behind the
## light along its path (or a Vector2.INF where the path ends).
static func draw(ci: CanvasItem, light: Vector2, back: Callable, ring: float, bold := 0.0) -> void:
	if ring <= 0.01:
		return
	var ph := Music.heard_phase()
	var gap := lerpf(GAP, GAP * 1.25, bold)
	for k in NOTES:
		var d := (k + 1.0 - ph) * gap
		var p: Vector2 = back.call(d)
		if p == Vector2.INF:
			continue
		var near := 1.0 - d / (gap * NOTES)
		var a := ring * lerpf(0.35, 0.85, bold) * smoothstep(0.0, 0.35, near)
		var r := lerpf(3.0, 5.5, near) * lerpf(1.0, 1.3, bold)
		var col := Palette.INK.lerp(Palette.GOLD.darkened(0.2), smoothstep(0.55, 0.9, near) * maxf(bold, 0.5))
		ci.draw_circle(p, r * 2.2, Color(col, a * 0.18))
		ci.draw_circle(p, r, Color(col, a))
	# the moment of the beat: the note lands in the light and opens a small ring
	var land := 1.0 - minf(1.0, ph / 0.25)
	if land > 0.0:
		ci.draw_arc(light, lerpf(12.0, 26.0, 1.0 - land), 0.0, TAU, 40,
			Color(Palette.GOLD.darkened(0.2), 0.5 * land * ring), 1.5, true)
