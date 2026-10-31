# Página de itch.io — Just Tap (demo)

Todo lo que va en la página, listo para copiar. Las imágenes están en `Builds/itch/` (se regeneran con `tools/make_itch_images.ps1`).

---

## Datos del proyecto (Edit game)

| Campo | Valor |
|---|---|
| **Title** | Just Tap |
| **Project URL** | `just-tap` |
| **Short description or tagline** | If you had a bad day… just tap. |
| **Classification** | Games |
| **Kind of project** | HTML |
| **Release status** | In development |
| **Pricing** | No payments (o "Donate" con mínimo 0) |
| **Uploads** | `Builds/just_tap_web.zip` → marcar **This file will be played in the browser**. Y `Builds/just_tap_windows.zip` → plataforma **Windows**, nombre visible: *Download for Windows — smoother audio and visuals* |
| **Genre** | Simulation (alternativa: Other) |
| **Tags** | `clicker`, `incremental`, `relaxing`, `cozy`, `atmospheric`, `emotional`, `watercolor`, `music`, `short`, `godot` |
| **AI generation disclosure** | Marcar lo que corresponda: las voces se hicieron con ElevenLabs |
| **App store links / Community** | Comments: activado |
| **Visibility** | Draft hasta probarlo; después Public |

### Embed options

| Opción | Valor |
|---|---|
| Embed in page | Manually set size: **1280 × 720** |
| Mobile friendly | Sí (orientación: landscape) |
| Automatically start on page load | No (que el jugador haga clic: así el audio arranca bien) |
| Fullscreen button | Sí |
| Enable scrollbars | No |
| SharedArrayBuffer support | **Sí** (el build web usa hilos para que el audio no se trabe) |

---

## Descripción (inglés)

> Pegar en **Description**. Arriba de todo, el GIF `just_tap_colour.gif`.

**If you had a bad day… just tap.**

Just Tap is a small, gentle incremental game about getting through a grey day, one tap at a time.

A single line of ink climbs through barriers. Every tap pushes it a little further — and as it climbs, the world is drawn around you: arches, bridges and towers sketch themselves in the distance, a giant bird circles the tower, and every sound you make falls on the music's beat. Nothing punishes you. Some barriers push back; you grow a little, and try again.

And slowly, the colour comes back.

**In this demo**
- Climb the first 40 barriers of the day — about 30 minutes.
- Two chapters: the grey, and the red.
- Star circuits: your light splits into many and runs a turning star.
- A tree of upgrades that grows upward, like the line.
- An original, fully harmonic score: taps, breaks and constructions are all notes of the same piece.
- A voice that keeps you company — and something that happens at the end of the demo.
- English and Spanish.

**How to play**
Click, tap or press **Space**. That's it. Open the **tree** when the barriers start pushing back.

*The full game continues through the rest of the day — the green, the blue, the night, and the morning after.*

**About the beta.** This is a beta: to balance it, the game sends anonymous play data — how long each barrier takes and what you buy in the tree, with a random id and no personal information. You can turn it off on the title screen. (docs/beta-datos.md)

---

## Descripción (español)

> Opcional, debajo de la inglesa, separada por una línea.

**Si tuviste un mal día… simplemente tocá.**

Just Tap es un juego incremental chico y amable sobre atravesar un día gris, un toque a la vez.

Una línea de tinta sube rompiendo barreras. Cada toque la empuja un poco más, y mientras sube el mundo se dibuja alrededor: arcos, puentes y torres se trazan a lo lejos, un ave gigante rodea la torre y cada sonido cae en el pulso de la música. Nada te castiga. Algunas barreras empujan de vuelta; crecés un poco y volvés a intentar.

Y de a poco, el color vuelve.

**En esta demo**
- Las primeras 40 barreras del día: unos 30 minutos.
- Dos capítulos: el gris y el rojo.
- Estrellas-circuito: tu luz se divide en muchas y recorre una estrella que gira.
- Un árbol de mejoras que crece hacia arriba, como la línea.
- Música original y armónica: cada toque, cada barrera y cada construcción son notas de la misma pieza.
- Una voz que te acompaña, y algo que pasa al final de la demo.
- En inglés y español.

**Cómo se juega**
Clic, toque o **Espacio**. Nada más. Abrí el **árbol** cuando las barreras empiecen a empujar.

---

## Tema de la página (Edit theme)

| Elemento | Color |
|---|---|
| Background | `#ebe6de` (papel) |
| Background image | `Builds/itch/paper_tile.png`, repeat |
| Page background (columna) | `#f3efe8` |
| Text | `#3b3835` (tinta) |
| Links | `#c95a4f` (rojo del capítulo) |
| Buttons | `#3b3835`, texto `#ebe6de` |
| Font | Header: **Cormorant Garamond** (o "Georgia" si no aparece). Body: la misma |
| Banner | `Builds/itch/banner.png` |
| Layout | Una columna, screenshots a la derecha |

---

## Imágenes

| Archivo | Uso | Tamaño |
|---|---|---|
| `cover.png` | **Cover image** (miniatura en itch) | 630 × 500 |
| `banner.png` | Banner del tema | 960 × 300 |
| `screenshot_1..6.png` | **Screenshots** | 1920 × 1080 |
| `just_tap_colour.gif` | Arriba de la descripción | 960 de ancho |
| `just_tap_trailer.mp4` | Subir a YouTube y pegar el enlace en **Gameplay video or trailer** | 1080p |

---

## Primer devlog (opcional)

**Title:** Just Tap — the demo is out

> A small game about getting through a grey day. One line of ink, a lot of barriers, and the colour slowly coming back. The demo covers the first 40 barriers (about half an hour). I'd love to know how the ending made you feel. — Pablo
