class_name Songs
extends RefCounted
## Each zone's own song (JUST_TAP_GODOT.md §9.7): over the zone's four chords, its own tempo, metre,
## groove and a melody in two sections, A for barriers 1-5 of the zone and B (the chorus) from
## barrier 6. The melody hums by itself until the player taps with the music; then the player plays
## it, each tap on the beat sounding its next note. A zone without a song keeps the old layers (§9.4).
##
##   bpm:  the song's tempo (else the zone's); bar: sixteenths in a bar, 16 in 4/4, 12 in 3/4.
##   bass: [sixteenth in the bar, semitones above the chord's root] an octave down; the first is the
##         loudest. arp: [sixteenth in the bar, chord degree, octave] from the tonic, on arp_inst.
##         "bass_a"/"bass_b" and "arp_a"/"arp_b" give each section its own; "bass"/"arp" serve both.
##   a, b: per chord (two bars), [sixteenth in the chord, semitones above the tonic an octave up].
##   bells: in the chorus, celesta and glass double the melody an octave up.

const SONGS := {
	# Raíz: the verse breathes in half time; the chorus rocks in 3-3-2 with pushes, under bells.
	2: {
		"lead": "flute",
		"arp_inst": "harp",
		"bells": true,
		"bass_a": [[0, 0]],
		"arp_a": [[0, 0], [6, 1], [12, 2]],
		"bass_b": [[0, 0], [6, 7], [10, 12]],
		"arp_b": [[0, 0], [3, 1], [6, 2], [8, 3], [10, 4], [11, 2], [14, 1], [15, 3]],
		"a": [
			[[0, 4], [8, 2], [12, 0], [16, -3], [24, 0], [28, 2]],       # Bm: F# E D B D E
			[[0, 4], [8, 7], [16, 4], [20, 2], [24, -1]],                # F#m: F# A F# E C#
			[[0, 9], [8, 7], [12, 5], [16, 7], [24, 9]],                 # G: B A G A B
			[[0, 7], [8, 4], [12, 2], [16, 0], [28, 2]],                 # D: A F# E D E
		],
		"b": [
			[[0, 16], [8, 14], [12, 12], [16, 9], [28, 11]],             # Bm: F# E D B C#
			[[0, 11], [8, 9], [12, 7], [16, 4], [24, 7]],                # F#m: C# B A F# A
			[[0, 12], [6, 14], [8, 12], [16, 9], [24, 7]],               # G: D E D B A
			[[0, 12], [8, 11], [12, 9], [16, 7], [24, 14]],              # D: D C# B A E
		],
	},
	# Tallo: a waltz, quicker, the harp's chords on two and three; the chorus flows in eighths.
	3: {
		"bpm": 88,
		"bar": 12,
		"lead": "celesta",
		"arp_inst": "harp",
		"bells": true,
		"bass": [[0, 0]],
		"arp_a": [[4, 1, 1], [4, 2, 1], [8, 1, 1], [8, 2, 1]],
		"arp_b": [[2, 2], [4, 1, 1], [4, 2, 1], [6, 3], [8, 1, 1], [8, 2, 1], [10, 4]],
		"a": [
			[[0, 7], [8, 5], [12, 3], [20, 2]],                          # Bm: F# E D C#
			[[0, 2], [8, 0], [12, -2], [20, 0]],                         # A: C# B A B
			[[0, 3], [4, 7], [8, 10], [12, 12], [16, 10]],               # D: D F# A B A
			[[0, 8], [8, 7], [12, 5], [16, 3], [20, 5]],                 # Em: G F# E D E
		],
		"b": [
			[[0, 15], [8, 14], [12, 12], [20, 10]],                      # Bm: D C# B A
			[[0, 14], [8, 12], [12, 10], [20, 12]],                      # A: C# B A B
			[[0, 15], [4, 19], [8, 17], [12, 15], [20, 14]],             # D: D F# E D C#
			[[0, 17], [8, 15], [12, 12], [16, 10], [20, 12]],            # Em: E D B A B
		],
	},
}


## The demo's dark (barriers 41-45): a piano ostinato in the low register and a melody that sighs,
## in three steps that brighten as the player comes out of it, minor to major. The music is on the
## dark's root (the zone's dominant, Music.DARK_DROP), so the major at the end leads home (V → I).
## Each step: four chords (semitones from the dark's tonic) and a melody over them, as in a song.
## light (0..1, Music.dark_light) picks the step: from STEP_AT; bells from BELLS_AT.
const DARK := {
	"ostinato": [[0, 0], [2, 2], [4, 1], [6, 2], [8, 0], [10, 2], [12, 1], [14, 3]],
	"step_at": [0.0, 0.25, 0.5],   # 41 the deep, 42 a crack of light, 43-45 out
	"bells_at": 0.7,               # 44 and 45
	"steps": [
		{   # the deep: i(add9) VI(maj7) III(add9) VII, low, sighing a step down
			"chords": [[0, 3, 7, 14], [8, 12, 15, 19], [3, 7, 10, 14], [10, 14, 17]],
			"melody": [
				[[0, 7], [6, 5], [8, 3], [24, 2]],                       # D# C# B · A#
				[[0, 8], [8, 7], [12, 3], [24, 0]],                      # E D# B · G#
				[[0, 10], [8, 7], [16, 5], [20, 3]],                     # F# D# C# B
				[[0, 5], [8, 2], [16, -2], [24, 2]],                     # C# A# F# A#
			],
		},
		{   # a crack of light: VI VII III V7, the melody an octave up, reaching
			"chords": [[8, 12, 15, 19], [10, 14, 17], [3, 7, 10, 14], [7, 11, 14, 17]],
			"melody": [
				[[0, 15], [8, 19], [16, 20], [24, 19]],                  # B D# E D#
				[[0, 17], [8, 14], [16, 10], [24, 14]],                  # C# A# F# A#
				[[0, 15], [8, 14], [12, 10], [16, 15], [24, 19]],        # B A# F# B D#
				[[0, 17], [8, 14], [16, 11], [24, 14]],                  # C# A# G A#
			],
		},
		{   # out: the same root in major, I(add9) vi IV(maj7) V, high, open
			"chords": [[0, 4, 7, 14], [9, 12, 16], [5, 9, 12, 16], [7, 11, 14]],
			"melody": [
				[[0, 19], [8, 16], [12, 14], [16, 12], [24, 14]],        # D# B# A# G# A#
				[[0, 16], [8, 21], [16, 16], [24, 12]],                  # B# E# B# G#
				[[0, 17], [8, 21], [16, 24], [24, 21]],                  # C# E# G# E#
				[[0, 19], [8, 23], [16, 14], [24, 11]],                  # D# G A# G
			],
		},
	],
}


## False plays every zone the old way (to compare, tools/song_test.gd).
static var on := true


static func of(zone: int) -> Dictionary:
	return SONGS.get(zone, {}) if on else {}
