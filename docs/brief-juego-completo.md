# Just Tap — brief del juego completo

Versión 1.1, 3/11/2026. Parte del *Brief Document Design v1.0.0* de Pablo (PDF del 3/11/2026), lo cruza con lo que el juego ya tiene y suma las decisiones tomadas ese mismo día (§9). Sirve para pasar de la demo al juego completo: qué hay hoy, cómo se arman los capítulos y sus niveles, y qué falta decidir.

En este documento, **nivel = barrera** y **capítulo = zona** (10 barreras): el juego ya está armado así.

Leyenda de estado: ✅ hecho · 🧪 prototipo · 📝 diseñado, sin hacer · 💡 idea nueva

---

## 1. Qué es Just Tap

Una experiencia, un viaje con dos protagonistas: **el narrador, el Padre**, y **el jugador, el Hijo**. El Hijo no tiene género: es masculino y femenino a la vez. "Hijo" se usa en el sentido de hijo del Padre. La niña de la portada es una imagen, no el género del puntito.

El juego busca transmitir paz e invitar a la reflexión: el Padre alienta a seguir y a superar los obstáculos de la vida, y cuenta historias de su vida que dejan un mensaje profundo.

- **La voz es el Padre:** el todo, el absoluto. No hace falta una revelación de otra identidad.
- **El final:** el puntito vuelve a su Padre, al todo.
- **Todo está conectado:** los animales gigantes que despiertan en el camino muestran que somos parte del todo.
- **Duración:** **120 niveles**, siempre que cada capítulo traiga una experiencia propia (sin relleno); si alguno no la tiene, se vuelve a 100. Entre **2:30 y 3 horas**.

---

## 2. La mecánica

Se atraviesan barreras que se rompen haciendo el daño suficiente, y el daño crece si el toque **coincide con el pulso de la música** (al estilo Guitar Hero, pero sin castigo). Todo lo que hace el jugador forma una melodía de la que es parte.

| Pieza | Estado |
|---|---|
| Tocar, mantener, el árbol de mejoras | ✅ |
| Tocar con la música: ×2 a ×5 con la racha, notas de luz que marcan el pulso (en la punta, las estrellas y las ramas), la lección con su voz | ✅ |
| Logros de racha (4, 8, 12…): cascada de notas y aros dorados | ✅ |
| Cada sonido en la escala y armonía del tema que suena | ✅ |
| Joystick, con íconos dibujados en tinta | ✅ |
| Una curva de dificultad por capítulo (hoy hay una sola, con un muro en 99–100) | 📝 `juego-completo.md` §6 |

---

## 3. Lo que ya existe (la demo y más)

| Pieza | Dónde | Estado |
|---|---|---|
| Capítulos 1–4 (barreras 1–40) + la oscuridad (41–45) | la demo | ✅ |
| Temas grabados: título, zonas 1–4, la oscuridad, la historia, la carta | `docs/banda-sonora.md` | ✅ 8 temas |
| Historia 1: esperando a papá en la vereda | al final del cap. 4, antes de la oscuridad | ✅ |
| El ave (rodea la torre, canta en la tonalidad) | todo el juego | ✅ |
| La ballena celeste (despierta al salir de la oscuridad) | fin de la oscuridad | ✅ |
| Estrellas: la luz se divide y recorre una estrella, como una orquesta | barreras 16, 27, 37 y más | ✅ |
| Bifurcaciones trenzadas que cantan como un coro | barreras 46–60 | ✅ |
| Geometría sagrada y mandala ("el ahora") | barreras 43–45 | ✅ |
| Direcciones por zona: sube, derecha, diagonal, baja | `Main.ZONE_ANGLE` | ✅ |
| La espiral plana | capítulo 3 | ✅ |
| Caída "hacia adentro" entre zonas (efecto Droste) | entre capítulos | ✅ |
| La espiral hacia abajo, como tramo de ritmo, con el ave de estrellas | `tools/spiral_rhythm.tscn` | 🧪 |
| La carta del creador | final | ✅ |

---

## 4. Cómo se arma cada capítulo

**Cada capítulo (10 niveles) tiene su propio arco** y termina con un **acontecimiento** que le deja al jugador la sensación de haber aprendido algo:

| Niveles | Parte | Qué pasa |
|---|---|---|
| 1–3 | **Inicio** | Entra el color, el tema y la forma nueva de la línea. Fácil, se aprende. La voz presenta. |
| 4–6 | **Conflicto** | La mecánica se complica: más vida, más regeneración, variantes de la forma. |
| 7–9 | **Desenlace** | Algo se prepara: un nivel de respiro, una historia, un tramo de ritmo o una criatura que empieza a formarse. |
| 10 | **Final** | La barrera guardiana y **el acontecimiento**: un color que vuelve, una criatura que despierta, una revelación. |

Dentro de cada capítulo sigue valiendo el patrón anti-monotonía de `JUST_TAP_GODOT.md` §19.7, en el que nunca hay más de 3 niveles iguales seguidos: `N N M N R M N M M G` (N normal, M mecánica, R respiro, G guardiana).

**El juego entero también tiene un arco**, que va de la luz a lo más oscuro, vuelve a bajar hacia la luz y sube:

| Parte | Capítulos | Emoción |
|---|---|---|
| **Inicio** | 1–2 | entumecimiento, algo chico que cuenta |
| **Conflicto** | 3–9 | enojo, el asombro de la noche, el caos, crecer, soltar, el miedo; lo más hondo en el 9 (la tinta) |
| **Desenlace** | 10–11 | bajar hacia la luz (la espiral) y subir al amanecer (los saltos) |
| **Final** | 12 | volver al Padre, al todo |

---

## 5. Los 12 capítulos (120 niveles)

Colores: gris (1–2), rojo (3–4), verde (5–6), azul (7–8), **tinta** (9), noche estrellada que se vuelve dorada (10), amarillo (11–12). El brief suma los **niveles oscuros**: unos para trabajar lo interno y otros oscuros pero lindos, iluminados por estrellas que acompañan.

| # | Capítulo | Barreras | Color · tipo | Emoción | La forma de la línea | Tema | El acontecimiento final | Qué aprende |
|---|---|---|---|---|---|---|---|---|
| 1 | **Semilla** | 1–10 | gris · luz | entumecimiento | línea recta que sube ✅ | *After the Hard Day* ✅ | la lección del ritmo: *"That's you."* ✅ | tocar con la música |
| 2 | **Raíz** | 11–20 | gris · luz | algo chico que cuenta | línea hacia la derecha ✅ | *Rooted Light* ✅ | **el color vuelve** (rojo) ✅ | lo chico también cuenta |
| 3 | **Tallo** | 21–30 | rojo · luz | enojo | la espiral ✅ + **el bucle**, un anillo que hay que romper 📝 | *Reach Toward Light* (vals) ✅ | el anillo se abre en pétalos 📝 | el enojo da vueltas; se suelta |
| 4 | **Hoja** | 31–40 | rojo → noche estrellada · **oscuro lindo** | asombro | estrellas que se recorren como orquesta ✅ | *Starlit Drift* ✅ | **historia 1** (papá) ✅ y la noche se cierra: entra la oscuridad ✅ | no todo vuelve fácil |
| 5 | **Flor** | 41–50 | **oscuro** → verde | caos, el ahora | la oscuridad y "el ahora" (41–45) ✅; nace la bifurcación (46–50) ✅ | *Light After the Dark* ✅ → tema verde 💡 | **la ballena despierta** ✅ | no estás solo; solo existe este momento |
| 6 | **Fruto** | 51–60 | verde · luz | crecer | **tres ramas trenzadas que cantan como un coro** ✅ | tema verde 💡 | las ramas se funden en una flor 📝 + **historia 2** 💡 | puedes ser más de una cosa a la vez |
| 7 | **Bosque** | 61–70 | azul · luz | tristeza | **la marea**: líneas que ondulan y respiran 📝 | tema azul 💡 | la marea baja y deja ver algo enterrado 💡 | la tristeza viene en olas |
| 8 | **Cielo** | 71–80 | azul · luz | soltar | barreras que se disuelven si las dejas 📝; **la malla del espacio-tiempo** que se hunde bajo el peso de la luz 💡 | tema azul (reutilizado) | **soltar**: la barrera que solo cae si no la tocas 📝 | no todo se pelea; se respira |
| 9 | **Noche** | 81–90 | **tinta · oscuro** | miedo, quiebre | grietas, apagón, la sombra 📝 | *Light After the Dark* (variación) | **el ave sanada** vuelve a volar en dorado 📝 + **historia 3** 💡 | caerse está permitido; lo roto también guarda luz |
| 10 | **Estrella** | 91–100 | noche estrellada → oro · **oscuro lindo** | rendirse a la luz | **la espiral hacia abajo**, tramo de ritmo 🧪 | *Starlit Drift* (reutilizado) | **el ave de estrellas despierta** 🧪 | dejarse llevar |
| 11 | **Alba** | 101–110 | amarillo · luz | renacer | **los saltos**: subir de barrera en barrera tocando en el pulso 💡; líneas espejadas, al revés 💡 | tema final (primera parte) | el sol sale 💡 + **historia 4** 💡 | levantarse otra vez |
| 12 | **Luz** | 111–120 | amarillo · luz | calidez, volver a casa | **la convergencia**: todas las formas juntas 💡; el coloso (120) 📝 | tema final 💡 + la carta ✅ | **el puntito vuelve al Padre**, al todo 💡 | estás en casa |

---

## 6. Los saltos y la espiral: dónde van

Los dos son la misma familia de experiencia: la luz se mueve sola con la música y tú la acompañas tocando en el pulso, sin árbol ni barreras que romper. Por eso los pongo **seguidos, en el desenlace, y uno como espejo del otro**:

- **Capítulo 10, Estrella: la espiral hacia abajo.** Después de la noche más dura (cap. 9), bajar hacia adentro, hacia la luz del fondo. Es entregarse. Cada nota acertada dibuja el ave de estrellas, que despierta al final. 🧪
- **Capítulo 11, Alba: los saltos hacia arriba.** Del fondo de la espiral, la luz sale y sube: un toque a tiempo la impulsa a la barrera siguiente; si no, se frena ahí hasta acertar. De costado, de abajo hacia arriba, en zigzag. Es levantarse. 💡

**Bajar para después subir:** el punto más hondo del viaje queda en el medio, y los dos tramos se responden. Además, como se tocan en el pulso, son de lo más **distinto** del juego: rompen la rutina justo antes del final, cuando más hace falta.

Para que no sean capítulos enteros de lo mismo, cada uno usa la forma especial en su parte de **Desenlace** (niveles 7–9) y la combina con niveles normales del color en el resto.

---

## 7. Catálogo de formas de nivel

El brief pide que cada capítulo se sienta como un **"flash" visual y sonoro**: la línea se deforma según lo que el nivel busca transmitir.

| Forma | Qué es | Estado | Capítulo |
|---|---|---|---|
| Línea recta, con dirección | sube, derecha, diagonal, baja | ✅ | todos |
| Espiral plana | la línea se enrolla | ✅ | 3 |
| Estrella | la luz se divide y recorre una estrella | ✅ | 2–4 y más |
| Bifurcación trenzada | varias luces a la vez que se funden y separan | ✅ | 5–6 |
| Geometría sagrada | figuras que se dibujan barrera a barrera | ✅ | 5 (el ahora) |
| Bucle | un anillo de segmentos que hay que romper | 📝 | 3 |
| Líneas que ondulan | la línea fluye como agua, con la marea | 📝 | 7 |
| **Malla del espacio-tiempo** | una malla se hunde bajo el "peso" de la luz al pasar (solo visual) | 💡 | 8 |
| Grietas, apagón, la sombra | partes oscuras para trabajar lo interno | 📝 | 9 |
| Espiral hacia abajo | un pozo con escalera caracol hacia la luz | 🧪 | 10 |
| **Saltos (subida)** | un toque a tiempo impulsa la luz a la barrera siguiente | 💡 | 11 |
| **Espejada, al revés, en reversa, oblicua** | la línea se refleja, se invierte o baja | 💡 (en parte, las direcciones ✅) | 11–12 |
| Caída hacia adentro | entre capítulos | ✅ | entre todos |

---

## 8. Música: pocos temas, reutilizados

La idea es no tener muchas canciones: **unos 10 temas**, varios usados en más de un capítulo. Todo suena en la escala y la armonía del tema que suena. ✅

| Tema | Estado | Dónde suena |
|---|---|---|
| *Watercolor Recovery* (título) | ✅ | el menú y la pantalla final |
| *After the Hard Day* | ✅ | cap. 1 |
| *Rooted Light* | ✅ | cap. 2 |
| *Reach Toward Light* (vals) | ✅ | cap. 3 |
| *Starlit Drift* | ✅ | cap. 4 y **cap. 10** (la espiral, de noche) |
| *Light After the Dark* | ✅ | cap. 5 (41–45) y **cap. 9** (una variación, o la misma más grave) |
| *Sun Through the Leaves* | ✅ | las historias |
| *Letter to the Player* | ✅ | la carta |
| **Tema verde** | falta | caps. 5 (46–50) y 6 |
| **Tema azul** | falta | caps. 7 y 8 |
| **Tema final** | falta | caps. 11 y 12 |

En total son **11 temas**, con **3 nuevos**. Para quedar en 10: que el tema final sea un arreglo del tema del título, así el juego termina donde empezó.

---

## 9. Decisiones (3/11/2026)

1. **El Hijo no tiene género**: es masculino y femenino. "Hijo" en el sentido de hijo del Padre.
2. **La voz es el Padre**, el todo. Se descarta la revelación de "la parte de ti que sigue adelante".
3. **120 niveles**, si cada capítulo trae una experiencia propia y no hay relleno. Si no, 100.
4. **Pocos temas, reutilizados** (§8).
5. **La oscuridad de la demo (41–45) queda igual en el juego completo**: hoy solo existe en la demo (`BuildFlags.is_dark`), así que hay que activarla también en el juego completo.
6. **Los saltos y la espiral van en una etapa avanzada**: propuesta en §6 (caps. 10 y 11).
7. **La duración sale de la cantidad de experiencias, no solo de la dificultad** (§10).

---

## 10. La duración, por experiencias

Las 2:30–3 h tienen que salir de **cosas distintas para vivir**, no de barreras más duras. Cada capítulo, unos **12–15 minutos**, con este presupuesto:

| Ingrediente | Por capítulo | Ejemplo |
|---|---|---|
| Una forma nueva de la línea | 1 | el bucle, la marea, la malla |
| Niveles normales con esa forma, variando | 5–6 | `N N M N … M M` |
| Un nivel de respiro | 1 | fácil, con un momento visual |
| Una historia o una criatura | 1 | la historia de papá, la ballena |
| Un acontecimiento final | 1 | el color que vuelve, el ave que despierta |
| Un tema (propio o reutilizado) | 1 | §8 |

12 capítulos × 12–15 min ≈ **2:25 a 3:00 h**. La dificultad sigue ahí (las barreras piden más daño y el árbol importa), pero acompaña a las experiencias en lugar de estirarlas. Un capítulo que no llegue a tener su experiencia propia es la señal para volver a 100 niveles.

---

## 11. Precio, público y lanzamiento (3/11/2026)

### El público
- **Quien compra Just Tap juega en Steam a GRIS, To the Moon, A Short Hike, Before Your Eyes, Florence o A Dark Room:** juegos cortos, emotivos, relajantes y personales. El incremental es el gancho original ("un clicker que se juega con la música y te cuenta una historia"), no el público principal.
- **itch.io es el laboratorio, no la tienda:** público indie que juega muchísimo gratis en el navegador y casi no paga. La demo de la 0.17 lo muestra: 369 jugaron en el navegador y 6 descargaron. Sirve para medir retención, recibir comentarios y probar portadas.
- **Los fans de los clickers** (r/incremental_games) buscan números y progresión larga: van a probar la demo, pero no son el núcleo comprador.

### El precio
- **El juego: USD 7,99**, con un **10–15 % de descuento de lanzamiento**.
  - Comparables en Steam: A Dark Room USD 6,99 · A Short Hike USD 7,99 · To the Moon USD 9,99 · Before Your Eyes USD 9,99 (~2 h, con quejas de "caro para lo que dura") · GRIS USD 14,99.
  - Para 2:30–3 h es la zona sin quejas: los juegos cortos se perdonan, los cortos y caros (USD 13–25) no.
  - Menos de USD 10 convierte mejor las wishlists (mediana 0,15 ventas por wishlist en la primera semana; 0,10 por encima de USD 10, según GameDiscoverCo).
  - Más barato (USD 2,99) da la impresión de juego chico.
- **La banda sonora como DLC: USD 3,99** (*Just Tap — Soundtrack*), y un **bundle juego + banda sonora con 10–15 % de descuento**. Detalle en `docs/banda-sonora.md`.
- En itch, el juego completo al mismo precio y la demo gratis.

### Cuánta gente hace falta (estimación gruesa)
A USD 7,99 quedan unos **USD 4,50–5 por copia** después del 30 % de Steam, impuestos y precios regionales.

| Objetivo | Copias | Wishlists al lanzar |
|---|---|---|
| USD 20.000 | ~4.200 | ~7.000–10.000 |
| USD 100.000 | ~21.000 | ~35.000–50.000, o un éxito que viaje solo |

Como referencia del embudo: impresión → visita ≈ 2–5 % (la página de itch: 2,19 %); visita → compra ≈ 3 %; wishlist → venta en la primera semana ≈ 10–20 %.

### Referencias de How To Market A Game (Chris Zukowski)
Sus benchmarks (howtomarketagame.com/benchmarks) por nivel de ingresos de por vida: **Bronce** USD 0–10.000 · **Plata** USD 10.000–249.000 · **Oro** USD 250.000–999.000. El objetivo de Just Tap (USD 20–100.000) es **Plata**.

| Para Plata | Mediana |
|---|---|
| Wishlists al lanzar | **~8.000** (Bronce ~5.000, Oro ~50.000) |
| Wishlists el día que abre la página "próximamente" | 79–441 |
| Wishlists por semana normal | 15–120 |
| Wishlists en Steam Next Fest | 1.000–6.999 |
| Conversión wishlist → venta, primera semana | ~20 % (15 % con menos de 5.000 wishlists) |
| Tiempo de juego de la demo | ~18 min (Oro ~38 min) |
| Ventas por reseña | ~31 |

- **La demo de Just Tap ya está en zona Plata:** la mediana hasta el final de la demo es de ~15 min (0.17), y quien la termina juega más. Alargar la experiencia de la demo acerca al nivel Oro.
- **El DLC de la banda sonora suma poco dinero:** la tasa de compra de DLC suele ser baja (1,5–3 % en Bronce y Oro). Vale como gesto para los fans y como vidriera de la música, no como fuente de ingresos.
- **Su advertencia más importante:** *"Players don't typically buy indie games that are linear with a single on rails narrative"*, salvo con un arte excepcional (cita GRIS como excepción). Lo que se vende en Steam son juegos con sistemas que se combinan y se pueden rejugar; el terror y las novelas visuales son las excepciones narrativas.
  - **Qué significa para Just Tap:** comunicar el **sistema**, no solo la historia. El gancho es *"un incremental que se toca con la música"*: el árbol, la racha, las luces que se dividen como orquesta, la Madre que se rompe. La historia va como lo que lo vuelve especial, no como el género.
  - Cuidar que el arte esté a la altura (por eso la luz, la niebla y los rayos del monumento).
- **De dónde salen los picos de wishlists** (su encuesta a desarrolladores, de más a menos): **festivales de Steam → TikTok → streamers → Reddit → prensa → Twitter**. Twitter se lleva mucho tiempo y rinde poco. TikTok, Reddit y Twitter funcionan si el juego es muy llamativo a la vista; si no, lo que más pesa es **tener una demo gratis y llevarla a festivales y a streamers**.
  - **Para Just Tap:** la demo ya existe. Prioridades: festivales (Next Fest y los festivales temáticos cozy o relajantes), streamers (como el del "guau" con la ballena), y clips cortos verticales para TikTok de los momentos más visuales (la ballena que despierta, la orquesta de luces, la Madre que se rompe y se rearma). Twitter, lo mínimo.
- **Next Fest:** lanzar la demo **más de un mes antes** del festival rinde más, y cuenta el impulso de wishlists de las dos semanas previas. Las wishlists del festival convierten menos (calcular la mitad).

Fuentes: [Benchmarks](https://howtomarketagame.com/benchmarks/) · [El plan de 10 pasos](https://howtomarketagame.com/2021/07/12/how-to-market-your-indie-game-a-10-step-plan/) · [Por qué no consigo wishlists](https://howtomarketagame.com/2023/12/05/why-am-i-not-getting-wishlists-a-step-by-step-solution/) · [Next Fest de febrero 2026](https://howtomarketagame.com/2026/04/13/making-sense-of-the-february-2026-steam-next-fest/) · [Impulso antes del Next Fest](https://howtomarketagame.com/2026/07/14/games-that-used-momentum-for-steam-next-fest-success/) · [La mayoría juega la demo y no agrega a la wishlist](https://howtomarketagame.com/2026/06/30/nobody-plays-demos-and-that-is-ok/)

### Lo que sigue
1. **Abrir la página de Steam cuanto antes**, aunque el juego no esté terminado, para empezar a juntar wishlists.
2. **Steam Next Fest** con la demo.
3. Buscar al público emotivo y relajado: r/CozyGamers, Wholesome Direct, streamers de juegos cozy y emotivos. Etiquetas: *Relaxing, Emotional, Story Rich, Atmospheric, Rhythm, Incremental, Hand-drawn*.
4. Material de venta: la ballena que despierta, la Madre que se rompe y se rearma, la portada estilo Journey.

---

## 12. Próximos pasos sugeridos

1. Diseñar la forma de cada capítulo que falta (bucle, marea, malla, grietas, saltos, convergencia) y prototipar las nuevas como se hizo con la espiral.
2. Activar la oscuridad 41–45 en el juego completo.
3. Pedir los 3 temas nuevos (verde, azul, final) con prompts como los de la demo.
4. Escribir las historias 2, 3 y 4 (recuerdos reales).
5. Rehacer la curva de dificultad por capítulo y simularla junto con el tiempo de cada experiencia.
