class_name VoiceLines
extends RefCounted
## The voice's script (design doc §20.3). The voice is always English; subtitles show in the
## chosen language. Audio for line <id> lives at res://audio/voices/vo_<id>.mp3 (or .ogg/.wav);
## a line without a recording still shows its subtitle.

const LINES := {
	"00": {"en": "If you had a bad day… just tap.", "es": "Si tuviste un mal día… solo toca."},
	"00b": {"en": "Welcome back. Where were we?", "es": "Volviste. ¿Dónde estábamos?"},
	# grey
	"01": {"en": "Some days, everything turns grey.", "es": "Hay días en que todo se vuelve gris."},
	"02": {"en": "It pushes back. That's alright.", "es": "Empuja de nuevo. Está bien."},
	"03": {"en": "There. Something small. It still counts.", "es": "Ahí está. Algo pequeño. Aun así, cuenta."},
	"04": {"en": "You don't have to fix the whole day. Just the next tap.",
		"es": "No tienes que arreglar el día entero. Solo el próximo toque."},
	"05": {"en": "It's heavy, isn't it? Grow a little. Then try again.",
		"es": "Pesa, ¿no? Crece un poco. Después vuelve a intentarlo."},
	"06": {"en": "Do you feel that? That's anger. It means you still care.",
		"es": "¿Lo sientes? Es enojo. Quiere decir que todavía te importa."},
	# red
	"07": {"en": "Go on. Hit it. It can take it.", "es": "Vamos. Golpéala. Puede soportarlo."},
	"08": {"en": "It keeps coming back around, doesn't it?", "es": "Vuelve y vuelve, ¿no?"},
	"09": {"en": "Anger is just energy that hasn't found its way yet.",
		"es": "El enojo es energía que todavía no encontró su camino."},
	"10": {"en": "Give it somewhere to go. Up.", "es": "Dale un lugar a dónde ir. Arriba."},
	"11": {"en": "Pushing harder isn't always stronger.", "es": "Empujar más fuerte no siempre es ser más fuerte."},
	"12": {"en": "Breathe in… and let it go.", "es": "Respira… y suéltalo."},
	# green
	"13": {"en": "You can be more than one thing at once.", "es": "Puedes ser más de una cosa a la vez."},
	# Not in the design doc's table: the gentle hint for when a branch falls behind (§19.4).
	"own_pace": {"en": "Let each part of you… go at its own pace.",
		"es": "Deja que cada parte de ti… vaya a su ritmo."},
	# §22.2: when the branches join again (convergence cinematic, not in the game yet).
	"converge": {"en": "And all of it… is still you.", "es": "Y todo eso… sigues siendo tú."},
	# The demo's ending (barrier 40): the dark comes in, then the short letter.
	"demo_1": {"en": "Not everything comes back so easily.", "es": "No todo vuelve tan fácil."},
	"demo_2": {"en": "But you're not alone in this.", "es": "Pero no estás solo en esto."},
	# The "now" cinematic at the end of the demo's dark: one line per barrier, the last as it breaks.
	"now_1": {"en": "Yesterday already happened. Tomorrow isn't here yet.", "es": "Ayer ya pasó. Mañana todavía no llegó."},
	"now_2": {"en": "All we really have… is this moment.", "es": "Lo único que tenemos de verdad… es este momento."},
	"now_3": {"en": "This tap. This breath. Right here.", "es": "Este toque. Esta respiración. Aquí."},
	"now_4": {"en": "And right now… it's enough.", "es": "Y ahora mismo… alcanza."},
	# A story (Main offers it between zones 2 and 3): the voice stops and tells a memory, if you want.
	"story_ask": {"en": "Wait… you know what? Can I tell you something?", "es": "Espera… ¿sabes qué? ¿Te puedo contar algo?"},
	"story1_1": {"en": "When I was little, I used to wait for my dad on the sidewalk outside our house.", "es": "Cuando era niño, esperaba a mi papá sentado en la acera de mi casa."},
	"story1_2": {"en": "I'd lie back and watch the leaves of the tree… and the sun slipping through them, in little pieces.", "es": "Me recostaba y miraba las hojas del árbol… y cómo el sol se colaba entre ellas, en pedacitos."},
	"story1_3": {"en": "Nothing happened. And it was perfect.", "es": "No pasaba nada. Y era perfecto."},
	"demo_letter": {"en": "Thank you for playing this far.", "es": "Gracias por jugar hasta aquí."},
	# The creator's letter at the very end (shown by Screens.Letter, not queued by the Narrator).
	# The text on screen is Loc.LETTER, with the player's real tap count; the voice says it without
	# the number.
	"letter": {"en": "Hi. We've never met. I'm the one who made this game.",
		"es": "Hola. No nos conocemos. Soy quien hizo este juego."},
	# §22.3, star circuits: when the lights first spread, and when they become one again.
	# (Not in the game yet.)
	"small_lights": {"en": "Small lights. One shape. That's you, too.",
		"es": "Lucecitas. Una sola forma. Eso también eres tú."},
	"whole": {"en": "See? It was whole all along.", "es": "¿Ves? Siempre estuvo entero."},
	"14": {"en": "Look behind you. You've been building something.", "es": "Mira atrás. Has estado construyendo algo."},
	"15": {"en": "Things grow slowly. So do you.", "es": "Las cosas crecen despacio. Tú también."},
	"16": {"en": "Resting is part of it too.", "es": "Descansar también es parte."},
	"17": {"en": "Roots grow when nothing seems to happen.", "es": "Las raíces crecen cuando parece que no pasa nada."},
	"18": {"en": "And now it hurts a little. That's how you know it's leaving.",
		"es": "Y ahora duele un poco. Así sabes que se está yendo."},
	# blue
	"19": {"en": "Breathe with it. Not against it.", "es": "Respira con eso. No contra eso."},
	"20": {"en": "You've been carrying this all day.", "es": "Estuviste cargando esto todo el día."},
	"21": {"en": "You can put it down here. I'll hold it for a while.",
		"es": "Puedes dejarlo aquí. Yo lo sostengo un rato."},
	"22": {"en": "It was never about breaking walls.", "es": "Nunca se trató de romper paredes."},
	"23": {"en": "It's okay to be sad and keep going at the same time.",
		"es": "Está bien estar triste y seguir al mismo tiempo."},
	"24": {"en": "It was about not stopping.", "es": "Se trataba de no detenerse."},
	# yellow
	"25": {"en": "All of you. Together again.", "es": "Todo tú. Juntos otra vez."},
	"26": {"en": "Do you remember this morning? Before all of it?", "es": "¿Te acuerdas de esta mañana? ¿Antes de todo?"},
	"27": {"en": "It's still there. It always was.", "es": "Sigue ahí. Siempre estuvo."},
	"28": {"en": "Almost. Don't rush the ending.", "es": "Casi. No apresures el final."},
	"29": {"en": "Slowly. The light isn't going anywhere.", "es": "Despacio. La luz no se va a ningún lado."},
	# ending
	"30": {"en": "I'm the part of you that keeps going.", "es": "Soy la parte de ti que sigue adelante."},
	"31": {"en": "You found me again.", "es": "Me volviste a encontrar."},
	# The grand reveal: as it is said, the camera pulls back over everything the player built.
	"made": {"en": "You made all of this.", "es": "Creaste todo esto."},
	"32": {"en": "Tomorrow, if it's grey again… you know what to do.",
		"es": "Mañana, si vuelve a estar gris… ya sabes qué hacer."},
	"rebirth": {"en": "Again? Of course. I'm always here.", "es": "¿Otra vez? Claro. Siempre estoy aquí."},
	"idle1": {"en": "I'll wait.", "es": "Te espero."},
	"idle2": {"en": "Take your time.", "es": "Tómate tu tiempo."},
	"idle3": {"en": "Still here.", "es": "Sigo aquí."},
	# Trailer and teaser narration (docs/guion-trailer-teaser.md): the same voice, telling the story.
	"tr_01": {"en": "This is a story about a grey day. Maybe… one like yours.",
		"es": "Esta es la historia de un día gris. Tal vez… uno como el tuyo."},
	"tr_02": {"en": "It doesn't start with anything big. Just one tap. And then… another.",
		"es": "No empieza con nada grande. Solo un toque. Y después… otro."},
	"tr_03": {"en": "Small things add up. They always have.", "es": "Las cosas pequeñas suman. Siempre lo hicieron."},
	"tr_04": {"en": "Some days fall apart. You keep tapping anyway.",
		"es": "Hay días que se desarman. Y tú sigues tocando igual."},
	"tr_05": {"en": "And slowly… everything finds its place.", "es": "Y de a poco… todo encuentra su lugar."},
	"tr_06": {"en": "Every time you fall short, you learn. And you come back… a little stronger.",
		"es": "Cada vez que no alcanza, aprendes. Y vuelves… un poco más fuerte."},
	"tz_01": {"en": "Just tap. That's all.", "es": "Solo toca. Nada más."},
	"tz_02": {"en": "Every tap… draws a little of the world back.",
		"es": "Cada toque… vuelve a dibujar un poco del mundo."},
}

## Reaching barrier n says the line once.
const ON_REACH := {3: "01", 8: "02", 14: "04", 24: "07", 35: "10", 44: "14", 55: "16", 64: "20",
	75: "22", 84: "26", 95: "28"}

## Completing zone z (1..9); zone 10 is the ending.
const ON_ZONE := {1: "03", 2: "06", 3: "09", 4: "12", 5: "15", 6: "18", 7: "21", 8: "24", 9: "27"}

## First time stuck in each chapter (0 grey .. 4 yellow).
const ON_STUCK := ["05", "11", "17", "23", "29"]

const DEMO_ENDING := ["demo_1", "demo_2"]
const NOW := ["now_1", "now_2", "now_3", "now_4"]
const ENDING := ["30", "31", "made", "32"]
const IDLE := ["idle1", "idle2", "idle3"]

# Lines 08, 13, 19 and 25 belong to chapter mechanics that are not in the game yet (§19).


static func text(id: String, lang: String) -> String:
	var l: Dictionary = LINES.get(id, {})
	return l.get(lang, l.get("en", ""))


static func audio_path(id: String) -> String:
	for ext in ["mp3", "ogg", "wav"]:
		var p := "res://audio/voices/vo_%s.%s" % [id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""
