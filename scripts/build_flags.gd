class_name BuildFlags
extends RefCounted
## What kind of build this is. The demo ends at DEMO_LAST with its own ending (docs/juego-completo.md §2);
## the full game goes on to barrier 100. Change DEMO before exporting.

const DEMO := true
const DEMO_LAST := 40

## Shown in the play data so balance can be compared between builds.
const VERSION := "0.9.0-beta"

## Google Apps Script web app that receives the beta play data (docs/beta-datos.md). Empty: nothing
## is recorded and the title screen does not offer the switch.
const TELEMETRY_URL := "https://script.google.com/macros/s/AKfycbymBcAgdGNKFZroeHRA1b4oxmpAjul-0zDKcY0jI_1buBkDJThyapyx0orRLs3kvG9W/exec"

## Store page for the wishlist button. Empty hides the button until the page exists.
const STEAM_URL := ""


static func last_barrier() -> int:
	return DEMO_LAST if DEMO else 100
