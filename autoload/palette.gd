extends Node
## Colour chapters (Gris style): the world starts grey and colour comes back by chapters.

const PAPER := Color("#ebe6de")
const INK := Color("#3b3835")
const GOLD := Color("#e2b65a")
const VIGNETTE := Color(110 / 255.0, 100 / 255.0, 90 / 255.0, 0.3)

const GREYS := [Color("#b3ada6"), Color("#c2bcb4"), Color("#a29c95")]
const CHAPTERS := [
	{"name": "gris", "color": Color("#a29c95")},
	{"name": "rojo", "color": Color("#c95a4f")},
	{"name": "verde", "color": Color("#6c9c72")},
	{"name": "azul", "color": Color("#4d84b3")},
	{"name": "amarillo", "color": Color("#d9a948")},
]


## Chapter index (0..4) of zone z (1..10).
func chapter_of_zone(z: int) -> int:
	return clampi(int((z - 1) / 2.0), 0, CHAPTERS.size() - 1)


func chapter_of(n: int) -> int:
	return chapter_of_zone(Zones.of(n))


func chapter_color(idx: int) -> Color:
	return CHAPTERS[clampi(idx, 0, CHAPTERS.size() - 1)].color


func chapter_name(idx: int) -> String:
	return CHAPTERS[clampi(idx, 0, CHAPTERS.size() - 1)].name


## Colour of the line stretch that leads to barrier n.
func line_col(n: int) -> Color:
	var c := chapter_of(n)
	if c == 0:
		return INK.lerp(GREYS[n % 3], 0.45)
	return chapter_color(c).darkened(0.08)


## Watercolour colour for piece j of zone z. Zone 10 mixes every chapter.
func paint_col(z: int, j: int) -> Color:
	if z >= 10:
		return chapter_color(1 + j % 4)
	var c := chapter_of_zone(z)
	if c == 0:
		return GREYS[j % 3]
	return chapter_color(c)
