class_name Zones
extends RefCounted
## Per-zone tables: names, music and layers (design doc §3, §9.3).
## Twelve chapters of ten barriers (docs/brief-juego-completo.md §5): the old ten plus Noche (9, the
## ink) and Alba (11, the dawn); Estrella moved to 10 and Luz to 12.

const COUNT := 12
## The last barrier of the full game.
const FINAL := COUNT * 10
const NAMES := ["semilla", "raíz", "tallo", "hoja", "flor", "fruto", "bosque", "cielo", "noche", "estrella",
	"alba", "luz"]
const ROMAN := ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii"]

## The colour comes back at the end of these zones, in order (Palette.CHAPTERS 1..4): red after Raíz,
## green after Hoja, blue after Fruto, yellow after Estrella. Noche (the ink) and Estrella (the
## starry night) are still blue for now.
const COLOUR_AFTER := [2, 4, 6, 10]
## Each zone's colour chapter (Palette.CHAPTERS).
const CHAPTER := [0, 0, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4]

## The skeleton (11/11/2026): what each zone's end is still missing from the brief (§5). Debug builds
## write it over the last barrier, so a run through the whole game shows where the holes are.
const PENDING := {
	3: "el anillo se abre en pétalos",
	6: "las ramas se funden en una flor · historia 2",
	7: "la marea baja y deja ver algo enterrado",
	8: "soltar: la barrera que solo cae si no la tocas",
	9: "el ave sanada vuelve a volar · historia 3",
	10: "la caída al agujero negro · el ave de estrellas",
	11: "el sol sale · historia 4",
	12: "el puntito vuelve al Padre",
}

# Tonic of each zone as MIDI (130.81 Hz = C3 = 48).
const TONIC := [48, 50, 47, 45, 49, 46, 48, 43, 45, 50, 50, 52]
const BPM := [64, 66, 68, 70, 72, 74, 72, 76, 70, 70, 80, 84]
const TAP_INSTRUMENT := ["piano", "piano", "piano", "harp", "piano", "harp", "celesta", "piano", "piano", "celesta",
	"harp", "piano"]
const BASE_LAYERS := [0, 1, 1, 2, 2, 3, 3, 4, 3, 4, 4, 5]

# Four chords per zone, in semitones from the tonic.
const PROGRESSIONS := [
	[[9, 12, 16], [5, 9, 12], [0, 4, 7], [7, 11, 14]],                      # vi IV I V
	[[9, 12, 16], [4, 7, 11], [5, 9, 12], [0, 4, 7]],                       # vi iii IV I
	[[0, 3, 7], [-2, 2, 5], [3, 7, 10], [5, 9, 12]],                        # i VII III iv
	[[0, 3, 7, 10], [8, 12, 15], [5, 8, 12], [7, 10, 14]],                  # i7 VI iv v
	[[0, 4, 7, 11], [9, 12, 16], [5, 9, 12, 16], [7, 11, 14]],              # Imaj7 vi IVmaj7 V
	[[0, 4, 7], [2, 5, 9], [5, 9, 12], [7, 11, 14]],                        # I ii IV V
	[[0, 3, 7], [5, 8, 12], [-2, 2, 5], [3, 7, 10, 14]],                    # i iv VII III7
	[[9, 12, 16, 19], [5, 9, 12, 16], [0, 4, 7, 11], [7, 11, 14, 17]],      # vi7 IVmaj7 Imaj7 V7
	[[0, 3, 7], [8, 12, 15], [5, 8, 12], [7, 10, 14]],                      # i VI iv v (the ink)
	[[0, 4, 7, 11], [2, 6, 9], [0, 4, 7, 11], [2, 6, 9]],                   # Imaj7 II (lydian) x2
	[[0, 4, 7], [7, 11, 14], [9, 12, 16], [5, 9, 12]],                      # I V vi IV (the dawn)
	[[0, 4, 7, 11], [4, 7, 11, 14], [5, 9, 12, 16], [7, 11, 14, 17]],       # Imaj7 iii7 IVmaj7 V7
]


## Zone (1..COUNT) of barrier n.
static func of(n: int) -> int:
	return clampi(int((n - 1) / 10.0) + 1, 1, COUNT)


## "zona iii · tallo" / "zone iii · stem"
static func label(z: int) -> String:
	return Loc.t("zone_label") % [ROMAN[z - 1], Loc.zone_name(z)]


## Active accompaniment layers: the zone's base plus one more from barrier 6 of 10.
static func layers_at(n: int) -> int:
	var z := of(n)
	var extra := 1 if (n - 1) % 10 >= 5 else 0
	return mini(5, BASE_LAYERS[z - 1] + extra)
