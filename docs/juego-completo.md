# Just Tap — del prototipo al juego completo

Notas de diseño para lo que falta: qué es la demo, qué tiene que tener el juego completo (incluidas las partes oscuras y difíciles) y cómo dejar a quien juegue la demo con ganas de más. Complementa `JUST_TAP_GODOT.md` (§19 tiene las mecánicas por capítulo).

---

## 1. Dónde estamos (medido el 30/10/2026)

Simulación con un jugador "humano" usando las fórmulas del juego (`tools/sim_time.tscn`): 3,5 taps/s, abre el árbol cada 25 s y compra lo más barato, una pausa corta por minuto.

| Tramo | Tiempo | Lectura |
|---|---|---|
| Zona 1 | ~20 s | Demasiado rápido: el documento pide 1–3 min |
| Zonas 2–9 | ~25 min en total | Ritmo razonable, sin muro claro |
| Barreras 91–98 | 1–3 min cada una | Empieza a pesar |
| Barreras 99 y 100 | 15–20 min cada una, a veces mucho más | **Muro**: la regeneración (50 %/s) le gana al daño y las mejoras ya están casi al máximo |

Total del build actual: entre **1 y 3 horas**, casi todo trabado al final. La curva única de §4 no sirve para 100 barreras; hay que tener una curva por capítulo (§19.8 ya lo pedía).

---

## 2. La demo

**Recomendación: la demo son los capítulos gris y rojo (barreras 1–40), unos 25–35 minutos.**

- Es lo que un jugador de itch termina en una sentada, y le alcanza para entender el juego (tap, árbol, regeneración, el color que vuelve, el paisaje que se dibuja, el ave).
- Muestra el primer "el color vuelve" (rojo, en la barrera 20): el momento más fuerte del juego para un GIF.
- Deja guardadas las revelaciones grandes para el juego completo: quién es la voz ("I'm the part of you that keeps going"), la ciudad completa y la carta.

Ajustes para que dure eso: zona 1 más lenta (que la primera barrera pida 5–8 taps), y las barreras 21–40 calibradas para 45–75 s cada una.

### Cómo termina la demo (barreras 40–45, decidido el 31/10/2026)

La oscuridad se juega. Antes la demo se cortaba justo cuando aparecía lo más intrigante; ahora se atraviesa y algo despierta, que es lo que deja con ganas de más.

1. Se rompe la barrera 40 y vuelve el verde… pero solo un instante. Voz: *"Not everything comes back so easily."* (*"No todo vuelve tan fácil."*)
2. **El mundo se vuelve blanco sobre negro** (el negativo de la página, como en Gris): el papel se apaga, la tinta brilla. La torre se agrieta y las estructuras que el jugador dibujó **se rompen**: sus trazos se parten en fragmentos que se separan, giran y caen. El ave pasa, herida, con su canto en menor.
3. **Barreras 41–45, en la oscuridad.** El fondo es caos: figuras blancas que se multiplican, flotan y chocan entre sí; cada choque es una nota suave y grave del acorde (el caos interior, intentando calmarse). La torre se desmorona: astillas de tinta que se desprenden con cada toque, polvo, y temblores cada pocos segundos que sacuden la cámara y rompen un poco más las estructuras. La música se reduce a bajo y coro. Cada barrera rota calma un poco el caos. No hay voz: el caos habla solo. Dura unos 2,5–4 minutos (`tools/sim_time`).
4. **Se rompe la 45: todo se acomoda.** Las figuras se deslizan a su lugar y forman un mandala que gira, con hilos dorados; cada una suena al llegar, en un arpegio que sube. Acorde mayor amplio, coro, cascada de cristal. Las grietas se cierran bajo la luz y los fragmentos de las estructuras vuelven a su sitio con costuras de oro (kintsugi).
5. **Algo despierta: la ballena celeste.** Una ballena de luz, mucho más grande que el ave, cruza el cielo despacio, con constelaciones adentro y una estela de motas; canta tres veces (un canto largo y grave afinado en la tonalidad, con brillo de celesta y cristal). Voz: *"But you're not alone in this."* (*"Pero no estás solo en esto."*). Mientras pasa, el negativo se deshace y vuelve el papel.6. Pantalla de papel. La silueta de la ciudad completa en punteado: las 2 estructuras construidas en color y las otras 8 apenas dibujadas, esperando.
7. Una carta corta del creador:
   > Gracias por jugar hasta acá. Tocaste {taps} veces.
   > El resto del camino todavía está por dibujarse.
   > — Pablo
8. Botones: **Wishlist en Steam** · Seguir tocando (modo libre en la zona 4).

**Por qué funciona como gancho:** la demo termina en una pregunta (¿qué es lo oscuro?, ¿quién me habla?) y con algo visible que falta (la ciudad punteada). La carta corta con el número de taps conserva el momento de "esto me habla a mí", sin gastar el "estoy orgulloso de vos", que queda para el final del juego completo.

### Otros ganchos posibles

- **La voz se quiebra.** En la última línea de la demo la voz duda y no termina una frase: *"I'm…"* — silencio. La identidad de la voz queda abierta.
- **Una estructura que no es tuya.** Al fondo aparece, ya construida, una estructura que el jugador no dibujó (de otra persona, de "otro día"). Pregunta: ¿quién más pasó por acá?
- **El ave herida.** El ave aparece con un ala quebrada en tinta negra; en el juego completo hay un capítulo para sanarla.
- **"Mañana".** La demo termina diciendo que el juego completo es el resto del día: tarde, noche y la mañana siguiente.

---

## 3. El juego completo: arco y partes oscuras

El juego completo recorre un mal día entero. Para que el color pese, tiene que haber oscuridad: tramos donde el mundo se apaga, se complica y el jugador tiene que sostenerse.

| Acto | Capítulos | Emoción | Mecánica nueva | Barreras |
|---|---|---|---|---|
| I · Mañana | Gris, Rojo | entumecimiento, enojo | la línea, el bucle | 1–40 (la demo) |
| II · Tarde | Verde, Azul | crecer, soltar | bifurcación, marea | 41–80 |
| **III · Noche** | **Tinta** (nuevo) | **miedo, quiebre** | **grietas, apagón, la sombra** | **81–100** |
| IV · Amanecer | Amarillo | calidez, esperanza | convergencia | 101–120 |
| Epílogo | — | — | renacer, "mañana" | — |

El acto III es el nuevo: después del azul, en lugar de pasar directo al amarillo, **todo se pone negro**. La tinta, que hasta ahora dibujaba, empieza a romper. Es el tramo más difícil del juego y el que hace que el amanecer valga.

---

## 4. Mecánica: las grietas (acto III)

La idea: **las líneas se resquebrajan y hay que pasar antes de que se partan. Si se parten, volvés un punto atrás y lo intentás de nuevo con más fuerza.**

### Reglas

- En las zonas de grietas, cada barrera tiene un **tiempo de quiebre**: desde que la punta llega, la línea entre la barrera anterior y la actual empieza a agrietarse.
- La grieta avanza a la vista: fisuras de tinta que se ramifican desde la punta hacia atrás, y el papel se oscurece a su alrededor.
- **Si rompés la barrera antes de que la grieta llegue al final:** pasás; la grieta se cierra y deja una cicatriz dorada (kintsugi) en la línea.
- **Si la grieta se completa:** la línea se parte. La punta cae a la barrera anterior (un punto atrás), que hay que volver a romper. Esa barrera vuelve con la vida a medias, para que el retroceso duela pero no castigue.
- **Cada quiebre suma "temple"**: +15 % de daño acumulable mientras estés en esa zona (como en un roguelike). Nunca hay un muro absoluto: si te trabás, cada intento te hace más fuerte hasta que pasás.
- Las barreras guardianas de grietas (90 y 100) se agrietan desde los dos lados a la vez.

### Números de partida (a balancear con la simulación)

| Parámetro | Valor inicial |
|---|---|
| Tiempo de quiebre | 12 s (barrera 81) → 7 s (barrera 99) |
| Vida de la barrera anterior al caer | 50 % |
| Temple por quiebre | +15 % de daño, acumulable, se pierde al salir de la zona |
| Objetivo | 1–2 quiebres por barrera en el primer intento de un jugador medio |

### Cómo se siente

- **Visual:** el mundo en negro y blanco duro; el papel se vuelve gris oscuro y la tinta brilla apenas. Las grietas son la única forma que se mueve rápido en todo el juego. Al pasar, la cicatriz dorada queda en la torre para siempre (se ve en la ciudad final).
- **Sonido:** la música se reduce a coro grave y bajo. La grieta suena como cristal tensándose, afinado en el acorde y subiendo de semitono en semitono a medida que avanza. Al pasar, el cristal se resuelve en un acorde mayor. Al quebrarse, un golpe seco y silencio de un compás.
- **Voz (líneas nuevas):**
  - Primera grieta: *"It's cracking. Hurry… but don't panic."*
  - Primer quiebre: *"You fell back. That's allowed."*
  - Tercer quiebre seguido: *"Every time you fall, you come back stronger. Look."*
  - Al pasar la zona: *"Broken things can hold light too."* (anticipa el kintsugi)

### Árbol (rama negra)

- **Raíz firme:** las grietas avanzan un 10 % más lento por nivel.
- **Oro:** cada cicatriz dorada en la torre suma un 2 % de daño permanente.
- **Segunda oportunidad:** una vez por zona, la línea aguanta un quiebre sin caer.

---

## 5. Otras partes oscuras del acto III

Para que el acto no sea una sola mecánica, alternar (bloques de 10 como en §19.7):

- **Apagón.** La pantalla se queda a oscuras salvo un círculo alrededor de la punta. No se ve la vida de la barrera; hay que guiarse por la música, que sube de tensión a medida que la barrera se rompe (la tensión de §9.5 se vuelve la única información). Muy corto: 3–5 barreras.
- **La sombra.** Una línea negra sube detrás de la punta, a la velocidad de la regeneración. Si la alcanza, borra la última barrera rota. Es el "trabado" hecho personaje: no se pelea, se le gana subiendo.
- **El peso.** Cada tap cuesta un poco más (el daño baja mientras tocás muy rápido), y tocar con el pulso de la música lo alivia. Enseña a no desesperarse.
- **El ave en la noche.** El ave aparece herida, en tinta negra. Las notas de cristal de las estructuras la van curando; al final del acto vuelve a volar en dorado y abre el amanecer.

---

## 6. Para que funcione (pendientes técnicos)

1. **Curva por capítulo.** Reemplazar la fórmula única (`max_hp`, `regen_frac`) por una tabla por capítulo con HP base, crecimiento y regeneración propios. Simular cada tramo con `tools/sim_time.tscn` hasta caer en las ventanas de tiempo.
2. **Arreglar el muro de 99–100** en el build actual (o recortar la demo antes de llegar ahí).
3. **Más mejoras para el final.** Hoy eco y destello se maximizan alrededor de la barrera 60 y después solo crece fuerza: hace falta una rama nueva por capítulo (§19 ya las propone).
4. **Guardar los quiebres** (temple por zona, cicatrices doradas) en el save.
5. **Demo como build aparte:** una constante `DEMO_LAST := 40` y su final propio, con el botón de wishlist.
