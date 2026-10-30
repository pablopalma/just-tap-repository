class_name Loc
extends RefCounted
## Game texts in English and Spanish. The language is SaveSystem.lang; the voice is always English.
## "just tap", "if you had a bad day…" and "you made colour" stay in English on purpose: they are
## the game's voice, like the narration.

const S := {
	"per_tap": {"es": "%s por tap", "en": "%s per tap"},
	"tree": {"es": "árbol", "en": "tree"},
	"voice": {"es": "voz", "en": "voice"},
	"hint_tap": {"es": "tap", "en": "tap"},
	"hint_tree": {"es": "mejorá el árbol", "en": "grow the tree"},
	"zone_label": {"es": "zona %s · %s", "en": "zone %s · %s"},
	"zone_done": {"es": "zona %s completa", "en": "zone %s complete"},
	"colour_back": {"es": "el color vuelve", "en": "the colour returns"},
	"tap_start": {"es": "tocá para empezar", "en": "tap to begin"},
	"continue": {"es": "continuar", "en": "continue"},
	"new_game": {"es": "empezar de nuevo", "en": "start over"},
	"confirm_new": {"es": "¿borrar la partida? tocá otra vez", "en": "erase your progress? tap again"},
	"rebirth": {"es": "renacer  ·  ×2 para siempre", "en": "be reborn  ·  ×2 forever"},
	"needs": {"es": "%s · necesita %s %d", "en": "%s · needs %s %d"},
	"level_line": {"es": "%s — %s · nivel %d: %s", "en": "%s — %s · level %d: %s"},
	"max": {"es": "máximo", "en": "max"},
	"demo_end": {"es": "La demo termina acá. El resto del día te espera.", "en": "The demo ends here. The rest of the day is waiting."},
	"wishlist": {"es": "agregar a deseados en Steam", "en": "wishlist on Steam"},
	"continue_tap": {"es": "tocá para seguir", "en": "tap to continue"},
}

## The creator's letter (end of the game). {taps} is the player's own count of taps.
## The line marked with "*" is the one that lands: larger, in gold, with a longer pause.
const LETTER := {
	"es": [
		"Hola. No nos conocemos.",
		"Soy quien hizo este juego.",
		"No sé qué día tuviste hoy, ni por lo que estás pasando.",
		"Pero tocaste {taps} veces para llegar hasta acá.",
		"Un toque a la vez. Eso no es poco.",
		"Sea lo que sea, tiene salida. Siempre la hay.",
		"Y quiero que lo sepas:",
		"Creaste todo esto.",
		"*estoy orgulloso de vos.",
		"— Pablo",
	],
	"en": [
		"Hi. We've never met.",
		"I'm the one who made this game.",
		"I don't know what kind of day you had, or what you're going through.",
		"But you tapped {taps} times to get here.",
		"One tap at a time. That's not nothing.",
		"Whatever it is, there's a way through. There always is.",
		"And I want you to know:",
		"You made all of this.",
		"*I'm proud of you.",
		"— Pablo",
	],
}

## The demo's short letter: a promise, not the ending. The full letter stays for the full game.
const DEMO_LETTER := {
	"es": [
		"Gracias por jugar hasta acá.",
		"Tocaste {taps} veces.",
		"*El resto del camino todavía está por dibujarse.",
		"— Pablo",
	],
	"en": [
		"Thank you for playing this far.",
		"You tapped {taps} times.",
		"*The rest of the way is still waiting to be drawn.",
		"— Pablo",
	],
}

const ZONES := {
	"es": ["semilla", "raíz", "tallo", "hoja", "flor", "fruto", "bosque", "cielo", "estrella", "luz"],
	"en": ["seed", "root", "stem", "leaf", "flower", "fruit", "forest", "sky", "star", "light"],
}

const CHAPTERS := {
	"es": ["gris", "rojo", "verde", "azul", "amarillo"],
	"en": ["grey", "red", "green", "blue", "yellow"],
}

const UPGRADES := {
	"fuerza": {"es": ["Fuerza", "Cuánto empuja cada tap"], "en": ["Strength", "How hard each tap pushes"]},
	"ganancia": {"es": ["Ganancia", "Más luz por barrera y por tap"], "en": ["Gain", "More light per barrier and per tap"]},
	"pulso": {"es": ["Pulso", "La línea late sola"], "en": ["Pulse", "The line beats on its own"]},
	"resonancia": {"es": ["Resonancia", "Taps seguidos cargan combo"], "en": ["Resonance", "Taps in a row build a combo"]},
	"corrosion": {"es": ["Corrosión", "Las barreras se regeneran más lento"], "en": ["Corrosion", "Barriers regenerate more slowly"]},
	"eco": {"es": ["Eco", "Cada tap puede repetirse"], "en": ["Echo", "Each tap may repeat"]},
	"destello": {"es": ["Destello", "Crítico ×4"], "en": ["Flash", "Critical ×4"]},
}

const EFFECTS := {
	"fuerza": {"es": "daño ×%s", "en": "damage ×%s"},
	"ganancia": {"es": "luz ×%s", "en": "light ×%s"},
	"pulso": {"es": "%s taps/s", "en": "%s taps/s"},
	"resonancia": {"es": "+%s %% por combo", "en": "+%s %% per combo"},
	"corrosion": {"es": "regeneración ×%s", "en": "regeneration ×%s"},
	"eco": {"es": "%s %% de repetir", "en": "%s %% chance to repeat"},
	"destello": {"es": "%s %% de crítico", "en": "%s %% critical chance"},
}


static func letter(taps: int, demo := false) -> Array:
	var sep := "." if lang() == "es" else ","
	var out := []
	for line in (DEMO_LETTER if demo else LETTER)[lang()]:
		out.append(String(line).replace("{taps}", Fmt.grouped(taps, sep)))
	return out


static func lang() -> String:
	return SaveSystem.lang


static func t(key: String) -> String:
	var e: Dictionary = S.get(key, {})
	return e.get(lang(), e.get("es", key))


static func zone_name(z: int) -> String:
	return ZONES[lang()][z - 1]


static func chapter_name(idx: int) -> String:
	return CHAPTERS[lang()][clampi(idx, 0, 4)]


static func upgrade_name(id: String) -> String:
	return UPGRADES[id][lang()][0]


static func upgrade_desc(id: String) -> String:
	return UPGRADES[id][lang()][1]


static func effect(id: String, value: String) -> String:
	return EFFECTS[id][lang()] % value
