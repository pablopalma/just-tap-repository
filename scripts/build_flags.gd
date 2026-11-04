class_name BuildFlags
extends RefCounted
## What kind of build this is. The demo ends at DEMO_LAST with its own ending (docs/juego-completo.md §2);
## the full game goes on to barrier 100. Change DEMO before exporting.

const DEMO := true
const DEMO_LAST := 45
## The demo's dark stretch: from here to DEMO_LAST the world crumbles and the background is chaos,
## until the last barrier breaks and everything settles (docs/juego-completo.md §2).
const DARK_FROM := 41
## The last barriers of the dark break on their own, in one run, while the voice talks about this
## moment (Main's "now" cinematic).
const NOW_BARRIERS := 3

## Prototype: between zones the camera falls into the tip and comes out in the next zone (the Droste
## dive, scripts/world/droste.gd), and some zones run their own way (Main.ZONE_ANGLE). False: the
## old pull-back over the zone.
const DROSTE := true

## The upgrade tree is drawn beside the line and bought by tapping it, without pausing
## (scripts/world/inline_tree.gd); false brings back the panel. The dev menu (F1) switches it.
const TREE_INLINE := true

## Shown in the play data so balance can be compared between builds.
const VERSION := "0.17.2-beta"

## Google Apps Script web app that receives the beta play data (docs/beta-datos.md). Empty: nothing
## is recorded and the title screen does not offer the switch.
const TELEMETRY_URL := "https://script.google.com/macros/s/AKfycbymBcAgdGNKFZroeHRA1b4oxmpAjul-0zDKcY0jI_1buBkDJThyapyx0orRLs3kvG9W/exec"

## The game's itch.io page: the demo's end asks for a rating there.
const ITCH_URL := "https://floppykey.itch.io/just-tap"

## Store page for the wishlist button. Empty hides the button until the page exists.
const STEAM_URL := ""


static func is_dark(n: int) -> bool:
	return DEMO and n >= DARK_FROM and n <= DEMO_LAST


## The first barrier of the "now" cinematic.
static func now_from() -> int:
	return DEMO_LAST - NOW_BARRIERS + 1


static func last_barrier() -> int:
	return DEMO_LAST if DEMO else 100
