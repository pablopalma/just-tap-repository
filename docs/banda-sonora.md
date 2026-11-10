# Just Tap — banda sonora

Nota del 2/11/2026. Idea: cada escena o capítulo del juego tiene **un tema principal grabado**, terminado como una canción que se puede escuchar sola. Sirven para dos cosas:

1. **En el juego**: el tema grabado suena en su momento (como `title_theme.ogg` en el título), y la música generada de §9.7 de `JUST_TAP_GODOT.md` (canciones por zona) lo acompaña o lo reemplaza mientras se juega.
2. **Para vender**: la banda sonora como DLC en Steam (*Just Tap — Soundtrack*) y en un bundle *juego + soundtrack* con descuento. También en itch (como extra pagado o en el paquete "supporter") y, más adelante, en Bandcamp o en plataformas de streaming.

## Regla para cada tema

- Una pieza de **2 a 3 minutos**, en loop limpio para el juego y con un final propio para el álbum.
- **Misma tonalidad y tempo** que la música del juego en ese momento (`data/zones.gd` y `data/songs.gd`), para que los toques del jugador y las campanas queden afinados encima.
- Partir de la **melodía de la canción del juego**, así el jugador reconoce el tema cuando lo escucha en el álbum.
- Instrumentos de la casa: piano, arpa, celesta, flauta, cristal, coro suave y cuerdas discretas. Nada épico ni con batería fuerte.
- Si el tema se genera con ElevenLabs Music, describir el estilo **sin nombrar artistas ni obras** (como el prompt de la oscuridad, más abajo) y revisar los términos de uso comercial del plan antes de vender.
- Guardar el máster en alta calidad (WAV 48 kHz) en `Builds/music_source/` y el OGG del juego en `audio/music/`.

## Lista de temas

| # | Tema | Momento del juego | Tono · tempo | Estado |
|---|---|---|---|---|
| 1 | **Just Tap** (tema principal) | título y pantalla final | 80 BPM | ✅ grabado (`title_theme.ogg`) |
| 2 | **After the Hard Day** (semilla) | zona 1 | 80 BPM | ✅ grabado (`after_the_hard_day.ogg`) |
| 3 | **Rooted Light** (raíz) | zona 2 | 66 BPM, 4/4 | ✅ grabado (`rooted_light.ogg`) |
| 4 | **Reach Toward Light** (tallo) | zona 3 | 88 BPM, vals 3/4 | ✅ grabado (`reach_toward_light.ogg`) |
| 5 | **Sun Through the Leaves** | la historia (entre zonas 2 y 3) | 60 BPM | ✅ grabado (`sun_through_the_leaves.ogg`) |
| 6 | **Starlit Drift** (la noche) | zona 4, la noche estrellada | 70 BPM | ✅ grabado (`starlit_drift.ogg`) |
| 7 | **Light After the Dark** (la oscuridad) | barreras 41–45 de la demo | si♭ mayor · 72 | ✅ grabado (`dark_theme.ogg`, máster en `Builds/music_source/`) |
| 8 | **Letter to the Player** (la carta) | la carta del final de la demo | 66 BPM | ✅ grabado (`letter_to_the_player.ogg`) |
| 9 | **Who I Am** (el prólogo) | el prólogo de la primera partida: la luz cae en el blanco y habla con el Padre | la mayor · sin pulso, ambiental | ✅ grabado (`who_i_am.ogg`, 6/11/2026) |
| 10 | **What Breaks, Returns** (la Madre) | el monumento del juego completo (`tools/monument.tscn`) | re menor → re mayor · 80 BPM | ✅ grabado (`what_breaks_returns.ogg`, fuera de la demo exportada) |
| 11 | **Before the Vastness** (la malla del espacio-tiempo) | capítulo 10, Estrella (`tools/spacetime.tscn`): un agujero negro colosal en el horizonte y la caída | re menor (se pidió la menor) · 70 BPM · 4:00 | ✅ grabado (`before_the_vastness.ogg`, 11/11/2026, fuera de la demo exportada) |
| 10+ | Flor, Fruto, Bosque, Cielo, Estrella, Luz | zonas 5 a 10 | ver `data/zones.gd` | para el juego completo |
| — | Capítulos del juego completo | Gris, Rojo, Verde, Azul, **Tinta**, Amarillo (`docs/juego-completo.md` §3) | — | un tema por capítulo, o agrupar las zonas de cada uno |

**La demo usa 9 temas** (1 a 9), y están todos grabados (6/11/2026). Los másters están en `Builds/music_source/`; los datos medidos de cada uno, en `Songs.TRACKS`. El ahora queda dentro de *Light After the Dark*. Ese álbum corto se puede sacar con la demo como *"Just Tap — Demo Soundtrack"*, gratis o a precio simbólico, para juntar seguidores. El álbum completo sale con el juego en Steam.

## Prompt de ElevenLabs · La oscuridad

Referencia de estilo, que no se pone en el prompt: el tema de Zoey de *Escape Room*.

```
Instrumental cinematic piano piece, intimate and emotional, 72 BPM, 4/4, key of G-sharp minor turning to G-sharp major at the end. No vocals, no drums.

It begins in darkness: a soft, repeating low-register piano ostinato in steady eighth notes, close-miked with a gentle felt tone and long sustain pedal, over a deep sub-bass drone. Above it, a simple, sparse melody in the piano's middle register that sighs downward step by step, with lots of space between phrases. Chords: i(add9) – VI(maj7) – III(add9) – VII. Melancholic, lonely, like being lost in the dark.

Second section: a crack of light. The ostinato continues; the melody rises an octave and a soft solo flute doubles it. Warm low strings enter very quietly underneath. The harmony reaches toward hope: VI – VII – III – V7, ending on the major dominant, full of anticipation.

Final section: coming out into the light. The same melody returns transformed in G-sharp major (I(add9) – vi – IV(maj7) – V), the ostinato moves up an octave and gets brighter, strings swell gently, and delicate celesta and glass bells double the melody an octave higher, sparkling like stars. It grows to a warm, luminous, tender climax without becoming loud or epic, then resolves on a long, open G-sharp major chord that rings out and fades.

Mood arc: darkness, fragility, then quiet hope, then light. Minimal, emotional, modern film-score piano, reverb-rich but clear, slow build.
```

Secciones: *Darkness* 0:00–0:30 · *Crack of light* 0:30–0:55 · *Into the light* 0:55–1:30.

## Prompts de ElevenLabs · el resto de la demo (usados)

Cómo usarlos: modelo de música, **instrumental**, duración 2:30 a 3:00. Generar 3 o 4 tomas y quedarse con la que tenga el pulso más claro. ElevenLabs suele respetar el tempo pero no siempre la tonalidad; no importa, porque el juego mide en la grabación las notas de cada compás y los toques las siguen (como en la oscuridad). **El tempo sí tiene que ser exacto**: si una toma sale a otro tempo, descartarla.

Para que el jugador toque encima, las zonas tienen que tener **un pulso claro y parejo** (un ostinato, un arpegio o un bajo que marque los tiempos) y **dejar lugar arriba**: la melodía principal en registro medio, sin solos agudos que tapen las notas de los toques.

### 2 · Gray Morning (zona 1, semilla)
```
Instrumental, 64 BPM, 4/4, key of C major (chords Am – F – C – G, two bars each). No vocals, no drums, no percussion.
A gray, quiet morning after a bad night. Soft felt piano playing a steady, gentle pulse of repeated notes on every beat, very sparse, with long sustain pedal. A low, warm pad underneath, barely there. After a while a simple, hesitant melody appears in the middle register, a few notes at a time with lots of silence between them, as if someone is just waking up. In the second half a delicate harp joins with slow broken chords and the melody grows a little warmer and more confident, like a small seed of hope. Minimal, intimate, numb but tender, lo-fi warmth, close and soft. Seamless and loopable, no big ending.
```

### 3 · Roots (zona 2, raíz)
```
Instrumental, 66 BPM, 4/4, key of D major / B minor (chords Bm – F#m – G – D, two bars each). No vocals, no drums.
Earthy and grounded. First half: a half-time feel, a deep warm bass note on the first beat of each bar and a harp playing three slow notes per bar, with space to breathe; a soft wooden flute plays a low, singable melody that walks down step by step and climbs back. Second half (the chorus): the harp and bass start rocking in a 3-3-2 rhythm (dotted, swaying) with small sixteenth-note pushes, the flute melody rises an octave, and gentle celesta and glass bells double it like soft chimes. Warm, folk-like, rooted, hopeful, steady pulse. Seamless and loopable.
```

### 4 · Growing Waltz (zona 3, tallo)
```
Instrumental waltz, 88 BPM, 3/4 time, key of B minor (chords Bm – A – D – Em, two bars each). No vocals, no drums.
Something growing upward. A harp plays a gentle waltz accompaniment: a soft bass note on beat one and light chords on beats two and three, very clear and steady. A celesta plays a graceful, slightly bittersweet melody over it. In the second half the harp flows in running eighth notes between the chords, the melody climbs higher, and sparkling glass bells double it an octave up. Delicate, music-box-like but warm, a little melancholic turning hopeful, like a stem reaching for the light. Seamless and loopable.
```

### 5 · Waiting for Dad (la historia)
```
Instrumental solo piano, 60 BPM, 4/4, key of D major. No vocals, no drums, no other instruments except a very faint warm pad.
A childhood memory: a child lying on the sidewalk outside their house on a summer afternoon, waiting for their dad, watching sunlight slip through the leaves of a tree. Slow, tender, nostalgic solo piano with soft felt tone and long pedal, gentle broken chords in the low and middle register, and a simple lullaby-like melody that appears only now and then, leaving lots of space, because a narrator will be speaking over it. Warm, golden, peaceful, a little bittersweet, nothing dramatic. Quiet throughout, no climax, ends softly on a held D major chord.
```

### 6 · Under the Stars (zona 4, la noche estrellada)
```
Instrumental, 70 BPM, 4/4, key of A minor (chords Am7 – Fmaj7 – Dm7 – Em7, two bars each). No vocals, no drums.
A clear night sky, stars lighting up one by one. A harp plays a steady, flowing arpeggio in eighth notes that marks every beat. Celesta and glass bells play sparse, high, twinkling notes like stars appearing, and a soft choir pad breathes underneath. A calm, wondering melody on celesta. In the second half the texture grows: more bells, a gentle flute counter-melody, the choir opens up, full of wonder. In the last part a slight unease creeps in, the harmony gets darker and lower, as if clouds are covering the stars. Dreamy, spacious, magical, reverb-rich but clear. Seamless and loopable.
```

### 8 · You Made All of This (la carta)
```
Instrumental, 66 BPM, 4/4, key of C major. No vocals, no drums.
A heartfelt letter from the person who made this game to the player. Soft solo piano begins alone, warm and close, simple chords and a gentle melody, leaving space for a narrator's voice over it. Slowly, warm strings enter underneath, then a soft harp, and celesta bells sparkle on the melody near the end. It grows into a quiet, tender, grateful climax, never loud or epic, like a hug, then settles back to solo piano and ends on a long, open C major chord. Emotional, hopeful, intimate, sincere. About 2 minutes 30 seconds.
```

## Prompt de ElevenLabs · Before the Vastness (capítulo 10, el agujero negro)

Referencia de estilo, que no se pone en el prompt: la banda sonora de *Interstellar*. Es la excepción a la regla de "nada épico": el nivel tiene que dar escala, y la luz es un puntito frente a algo enorme. El pulso lo marca un tic suave en cada tiempo, como un reloj, que no es batería y deja claro dónde tocar. Al principio el tema es casi vacío, para que las notas de las frases se oigan arriba.

```
Instrumental, 70 BPM, 4/4, key of A minor turning to C major. No vocals, no drums, no percussion except a soft, dry ticking like a clock on every beat, steady from start to end.
Vast, cosmic, awe-struck. Begins almost empty: the soft ticking, and a church pipe organ holding a low, quiet chord, breathing in and out. A felt piano enters with a simple, hypnotic ostinato of repeated notes in eighth notes, two notes rocking back and forth, very steady, in the middle register (chords Am – F – C – G, two bars each). Slowly the organ adds higher stops and the ostinato climbs, layer by layer, with long sustained strings underneath, a minimalist build that never changes tempo. In the middle the harmony lifts to C major and the organ swells to a wide, luminous, overwhelming chord, like standing before something immense, while the ticking keeps going. Then it falls away suddenly to the lone piano ostinato and the ticking, and a soft choir pad hums the theme, small and tender, like a tiny light in front of a giant. Reverb-rich, spacious, deep sub-bass under the organ, emotional but restrained, no fast notes in the high register. Seamless and loopable, no big ending.
```

Secciones: *Empty space* 0:00–0:40 · *The build* 0:40–1:40 · *The weight* 1:40–2:10 · *Tiny light* 2:10–2:45.

## Pendiente de decidir

- Si el álbum sigue las zonas (10 o más temas) o los capítulos (6 temas más largos).
- ~~El precio del DLC y el descuento del bundle.~~ **Decidido el 3/11/2026:** el DLC *Just Tap — Soundtrack* a **USD 3,99** y el bundle juego + banda sonora con **10–15 % de descuento**; el juego, a USD 7,99 (`docs/brief-juego-completo.md` §11).
- Si las voces del narrador aparecen en algún tema del álbum, por ejemplo una versión de *La carta* con la voz.
