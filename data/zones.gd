class_name Zones
extends RefCounted
## Per-zone tables: names, music and layers (design doc §3, §9.3).

const COUNT := 10
const NAMES := ["semilla", "raíz", "tallo", "hoja", "flor", "fruto", "bosque", "cielo", "estrella", "luz"]
const ROMAN := ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x"]

# Tonic of each zone as MIDI (130.81 Hz = C3 = 48).
const TONIC := [48, 50, 47, 45, 49, 46, 48, 43, 50, 52]
const BPM := [64, 66, 68, 70, 72, 74, 72, 76, 80, 84]
const TAP_INSTRUMENT := ["piano", "piano", "piano", "harp", "piano", "harp", "celesta", "piano", "celesta", "piano"]
const BASE_LAYERS := [0, 1, 1, 2, 2, 3, 3, 4, 4, 5]

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
	[[0, 4, 7, 11], [2, 6, 9], [0, 4, 7, 11], [2, 6, 9]],                   # Imaj7 II (lydian) x2
	[[0, 4, 7, 11], [4, 7, 11, 14], [5, 9, 12, 16], [7, 11, 14, 17]],       # Imaj7 iii7 IVmaj7 V7
]


## Zone (1..10) of barrier n.
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
