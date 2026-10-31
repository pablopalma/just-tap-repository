extends "res://tools/trailer.gd"
## The teaser (docs/guion-trailer-teaser.md): the game first, ~31 s. One unbroken take of play with
## the HUD and the damage numbers (tap, the line climbs, the tree, a stronger tap), a barrier that
## draws a piece of the world, then a glimpse of the dark and of the whale, and the card. Little
## voice and two words on screen, so it reads with the sound off. Record it with
## tools/make_teaser.ps1.


func _init() -> void:
	length_bars = 11.0
	show_numbers = true


func _plan() -> void:
	# 0–4 · one take: tap, climb, break; open the tree, buy Strength; the next ones fall faster
	_at(0, 0.05, "start", 0)
	_at(0, 0.05, "hud", true)
	_at(0, 0.05, "layers", 2)
	_at(0, 0.05, "damage", 5.0)  # a barrier every second or two, so cause and effect read at once
	_at(0, 0.4, "voice", "tz_01")
	_at(0, 0.7, "tap", 0)
	_at(0, 0.9, "caption", ["tap", 3.0])
	_at(0, 1.0, "taps", 3.0)
	_at(2.2, 0.0, "taps", 0.0)
	_at(2.2, 0.0, "tree_open", {})
	_at(2.2, 0.2, "caption", ["grow", 2.6])
	_at(2.5, 0.0, "buy", "fuerza")
	_at(2.7, 0.0, "buy", "fuerza")
	_at(2.9, 0.0, "buy", "fuerza")
	_at(3.3, 0.0, "tree_close", true)
	_at(3.3, 0.0, "taps", 5.0)
	_at(3.3, 0.0, "layers", 3)
	# 4–7 · every barrier draws a piece of the world back; the colour returns
	_cut(4)
	_at(4, 0.0, "jump", 19)
	_at(4, 0.0, "damage", 70.0)
	_at(4, 0.0, "taps", 6.0)
	_at(4, 0.3, "voice", "tz_02")
	_cut(5.5)
	_at(5.5, 0.0, "hud", false)
	_at(5.5, 0.0, "jump", 21)
	_at(5.5, 0.0, "damage", 100000.0)
	_at(5.5, 0.0, "layers", 4)
	_at(5.5, 0.05, "pano", 0)
	_at(5.5, 0.1, "taps", 1.4)
	# 7–9 · glimpses: the dark, then the whale coming out of it
	_cut(7)
	_at(7, -CUT_OUT - 0.02, "veil_ink", 0)
	_at(7, 0.0, "jump", 42)
	_at(7, 0.0, "damage", 1.0)
	_at(7, 0.0, "taps", 4.0)
	_at(7, 0.0, "layers", 1)
	_at(7, 0.6, "quake", 0)
	_at(8, 0.0, "taps", 0.0)
	_at(8, 0.0, "whale", 0)
	_at(8, 0.0, "whale_at", 0.22)
	# 9–11 · the card
	_at(9, 0.0, "card", 0)
	_at(9, 0.4, "voice", "00")
	_shots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
