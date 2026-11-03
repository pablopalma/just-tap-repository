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
| 2 | Semilla | zona 1 | do · 64 | pendiente |
| 3 | Raíz | zona 2 | re · 66, 4/4 | canción en el juego (§9.7) |
| 4 | Tallo (vals) | zona 3 | si menor · 88, 3/4 | canción en el juego (§9.7) |
| 5 | Esperando a papá | la historia (entre zonas 2 y 3) | — | pendiente: piano solo, como un recuerdo |
| 6 | Hoja | zona 4 | la · 70 | pendiente |
| 7 | **La oscuridad** | barreras 41–45 de la demo, de menor a mayor | sol# menor → mayor · 72 | canción en el juego (§9.7); prompt de ElevenLabs listo |
| 8 | El ahora | la cinemática del final de la oscuridad | sol# mayor · 72 | puede ser el final del tema 7 |
| 9 | La carta | la carta del creador | — | pendiente |
| 10+ | Flor, Fruto, Bosque, Cielo, Estrella, Luz | zonas 5 a 10 | ver `data/zones.gd` | para el juego completo |
| — | Capítulos del juego completo | Gris, Rojo, Verde, Azul, **Tinta**, Amarillo (`docs/juego-completo.md` §3) | — | un tema por capítulo, o agrupar las zonas de cada uno |

**Para la demo alcanzan 4 o 5 temas** (1, 3, 4, 5 y 7). Ese álbum corto se puede sacar con la demo como *"Just Tap — Demo Soundtrack"*, gratis o a precio simbólico, para juntar seguidores. El álbum completo sale con el juego en Steam.

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

## Pendiente de decidir

- Si el álbum sigue las zonas (10 o más temas) o los capítulos (6 temas más largos).
- El precio del DLC y el descuento del bundle (suelen ser USD 3–5 y 10–15 %).
- Si las voces del narrador aparecen en algún tema del álbum, por ejemplo una versión de *La carta* con la voz.
