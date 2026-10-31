# Guion del tráiler y del teaser (con narración)

Decidido el 31/10/2026, a partir de las primeras reacciones al teaser:

- Lo que funcionó: *"tap, and the line climbs"* al empezar, el papel y la calma, y **la ballena** (*"es lo que me dio curiosidad"*).
- Lo que no: *"no sé de qué va el gameplay"*; *"después del puente y la oscuridad no sé qué pasa por mi toque y qué es automático"*; *"mostrá un momento completo de tocar y subir, bien claro, en los primeros segundos"*; *"no entiendo cómo se llega de lo primero a lo de que todo encaja"*.

De ahí salen tres reglas para los dos videos:

1. **Un inicio largo y sin cortes**: una sola toma de tocar → la línea sube → la barrera se rompe → luz. Con un **indicador de toque** en pantalla (un círculo que se abre donde tocás) mientras dure la secuencia, y que aparezca **solo en tus toques**: lo que pasa sin indicador es automático.
2. **Un puente**: la voz cuenta lo que pasa y por qué, para que el salto a la oscuridad y al final se entienda como una historia.
3. **Duración**: tráiler ≤ 60 s (más narrativa y cinemática), teaser ~30 s (más juego: es lo primero que se ve en Steam y en X).

La voz es la del juego (Eleven v3, mismos ajustes que `docs/voces-elevenlabs.md`). Siempre en inglés; los subtítulos, en inglés en los videos (y en español si se hace una versión para hispanohablantes). El tempo es el del tráiler actual: **84 BPM, un compás = 2,86 s**; los cortes caen en compases.

---

## Tráiler (≈64 s, 22,5 compases): *"a story about a grey day"*

**Revisión del 31/10/2026.** Al ver el primer corte: *"le falta mostrar más el tema del build… que el jugador sienta que su progreso mejora"*, y algunos sonidos tapaban la voz. Cambios:

- El acto 2 pasa a ser **aprender**: la barrera no cede (números chicos) → *"Grow a little. Then try again."* (**05**, ya grabada) → el árbol se abre vacío y el build crece nodo por nodo (20 compras, cada una desbloquea la siguiente) → la misma barrera cae enseguida, el pulso toca solo, y **tr_06** (*"Every time you fall short, you learn…"*). Sale la toma del color (el panorama ya lo muestra) y **tr_03** no se usa en el tráiler.
- Números de daño visibles en los actos 1 y 2.
- Mezcla: la voz con menos reverb (0,06 en vez de 0,18) y todo lo demás, también la ballena, el ave y lo lejano, baja 9 dB mientras habla (en el juego siguen 3 dB y solo la música).

La tabla de abajo es la versión anterior; los tiempos vigentes están en `tools/trailer.gd`.

| Compases | Tiempo | Imagen | Voz |
|---|---|---|---|
| **Acto 1 · Un día gris** | | | |
| 0–2 | 0–5,7 s | Negro → papel. La línea, quieta, abajo. Un toque solo: el primer círculo, la primera nota. | **tr_01** |
| 2–5 | 5,7–14,3 s | **Una sola toma, sin cortes**: toques con indicador, cada uno una nota; la línea sube, la barrera se agrieta y se rompe, +luz. Una segunda barrera. Con HUD (contador y luz). | **tr_02** |
| **Acto 2 · Lo chico suma** | | | |
| 5–6,5 | 14,3–18,6 s | Se abre el árbol; un nodo se compra. Al cerrar, la línea late **sola** (pulso automático, **sin** indicador) mientras tus toques siguen con indicador. | **tr_03** |
| 6,5–8 | 18,6–22,9 s | El color vuelve (rojo): la ola desde la punta. | — (la música crece) |
| 8–10 | 22,9–28,6 s | La cámara se aleja: cada barrera rota dibuja una pieza de la ciudad a lo lejos; el ave pasa. | **14** (ya grabada) |
| **Acto 3 · La oscuridad** | | | |
| 10–11 | 28,6–31,4 s | Se rompe la 40: el verde un instante… y todo pasa a blanco sobre negro. | **demo_1** (ya grabada) |
| 11–14 | 31,4–40 s | El caos: figuras que chocan, las estructuras se rompen en trazos, temblores. **Seguís tocando**: el indicador, ahora blanco, sigue ahí. | **tr_04** |
| 14–15 | 40–42,9 s | La última barrera de la oscuridad cede. | — |
| **Acto 4 · Todo se acomoda** | | | |
| 15–16,5 | 42,9–47,1 s | Las figuras se ordenan en el mandala dorado; las estructuras se reparan con oro. | **tr_05** |
| 16,5–18 | 47,1–51,4 s | La ballena de luz sale de la oscuridad y canta. | **demo_2** (ya grabada) |
| **Cierre** | | | |
| 18–20 | 51,4–57,1 s | Cartel: **just tap** · *free demo · play in your browser* | **00** (ya grabada) |

---

## Teaser (≈31 s, 11 compases): *el juego primero*

Poco texto y poca voz: tiene que entenderse sin sonido (Reddit y X arrancan mudos). HUD visible todo el tiempo de juego, para que se lea como un incremental (números, luz, árbol).

| Compases | Tiempo | Imagen | Voz | Texto en pantalla |
|---|---|---|---|---|
| 0–4 | 0–11,4 s | **Una sola toma de juego, sin cortes**: indicador de toque, la línea sube, dos barreras se rompen, la luz sube en el HUD; se abre el árbol, se compra Fuerza, se cierra; la siguiente barrera cae mucho más rápido (números más grandes). | **tz_01** al empezar | *tap* → *grow* (dos palabras, en el momento justo) |
| 4–7 | 11,4–20 s | Romper una barrera y **ver la pieza de ciudad dibujarse al lado**, sin cortar (la cámara se aleja un poco). El color vuelve. | **tz_02** | — |
| 7–8 | 20–22,9 s | Destello: la oscuridad, el caos blanco sobre negro, un temblor. | — | — |
| 8–9 | 22,9–25,7 s | Destello: la ballena sale de lo oscuro; se escucha su canto. Corte antes de verla entera. | — | — |
| 9–11 | 25,7–31,4 s | Cartel: **just tap** · *free demo · itch.io* | **00** (ya grabada) | — |

---

## Voces nuevas para exportar

Mismo modelo y ajustes que el resto (Eleven v3; Stability ~50 %, Similarity ~75 %, Style bajo). Guardar en `audio/voices/` con el nombre indicado. Dos o tres tomas por línea. El tono es el de siempre (acompañante, cálido, nada épico), pero acá **cuenta una historia**: un poco más lento y con más aire entre frases.

### vo_tr_01.mp3 · tráiler, apertura
```
[softly] This is a story about a grey day. [pause] Maybe... one like yours.
```
*Esta es la historia de un día gris. Tal vez… uno como el tuyo.*

### vo_tr_02.mp3 · tráiler, la primera toma
```
[warmly] It doesn't start with anything big. [short pause] Just one tap. [pause] And then... another.
```
*No empieza con nada grande. Solo un toque. Y después… otro.*

### vo_tr_03.mp3 · tráiler, el árbol y el pulso
```
[softly] Small things add up. [pause] [warmly] They always have.
```
*Las cosas chiquitas suman. Siempre sumaron.*

### vo_tr_04.mp3 · tráiler, en la oscuridad
```
[whispers] Some days fall apart. [long pause] [softly] You keep tapping anyway.
```
*Hay días que se desarman. Y vos seguís tocando igual.*

### vo_tr_05.mp3 · tráiler, el mandala
```
[softly] And slowly... [pause] [in awe] everything finds its place.
```
*Y de a poco… todo encuentra su lugar.*

### vo_tr_06.mp3 · tráiler, la barrera que ahora cae (revisión del 31/10)
```
[softly] Every time you fall short, [short pause] you learn. [pause] [warmly] And you come back... a little stronger.
```
*Cada vez que no alcanza, aprendés. Y volvés… un poco más fuerte.*

### vo_tz_01.mp3 · teaser, apertura
```
[warmly] Just tap. [short pause] [softly] That's all.
```
*Solo tocá. Nada más.*

### vo_tz_02.mp3 · teaser, la ciudad
```
[softly] Every tap... [pause] [warmly] draws a little of the world back.
```
*Cada toque… dibuja de vuelta un poco del mundo.*

Ya grabadas y reutilizadas: **00** (*If you had a bad day… just tap.*), **14** (*Look behind you. You've been building something.*), **demo_1** (*Not everything comes back so easily.*), **demo_2** (*But you're not alone in this.*).

---

## Para producirlo (después de exportar las voces)

- **Indicador de toque** en el director del tráiler: un círculo que se abre donde cae cada toque del jugador (no en los automáticos), oscuro sobre papel y blanco en la oscuridad.
- El director toca de verdad (`GameState.tap`), así cada indicador coincide con su nota y su golpe en la barrera.
- **HUD visible** en el teaser y en el acto 1 del tráiler; oculto en los actos cinemáticos.
- Las líneas nuevas entran en `VoiceLines` (id `tr_01`… `tz_02`) con su subtítulo en inglés y en español.
- `tools/trailer.gd` y un director nuevo para el teaser (en vez de recortar el tráiler, que es lo que hacía saltar los planos).
