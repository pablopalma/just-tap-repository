# JUST TAP — Documento de diseño y port a Godot 4

> *"If you had a bad day… just tap."*
> Un clicker incremental relajante: una sola línea de luz/tinta que sube rompiendo barreras, mientras el mundo se construye, se pinta y suena como una única pieza musical.

Este documento describe el prototipo web (versión **"gris"**) con todo el detalle necesario para reconstruirlo en **Godot 4.x** con rendimiento fluido en móvil (60 fps estables, audio sin cortes). Los números de balance y las fórmulas están probados en el prototipo; las decisiones técnicas están adaptadas a lo que Godot hace bien.

---

## 0. Índice

1. Visión y pilares
2. Loop de juego
3. Progresión: barreras, zonas, capítulos de color
4. Economía y fórmulas
5. Árbol de mejoras
6. Mundo: la vía, las ramas, la cámara
7. Lo que se construye: mandalas, figuras, semillas y red
8. Dirección de arte (estilo Gris)
9. Música y sonido (sistema armónico)
10. Voz en off y textos
11. Cinemáticas y pacing
12. UI / HUD
13. Arquitectura en Godot (escenas, scripts, señales, datos)
14. Rendimiento en móvil
15. Guardado
16. Parámetros de ajuste (tabla de "perillas")
17. Orden de implementación sugerido
18. Diferencias con el prototipo y mejoras pendientes
19. **Estructura para 2½–3 horas: una mecánica nueva por capítulo**
20. **Historia y guion de voz**
21. **Pack de sonidos**
22. **Cinemáticas jugables y estrellas**

---

## 1. Visión y pilares

**El norte (2/11/2026).** Just Tap es más una experiencia que un juego de números: todo lo que el jugador hace forma una gran obra de arte que representa sus pensamientos y su mundo interior. La línea no es una torre que se sube: es un recorrido hacia adentro. Cada decisión se mide contra esa idea.
- **La historia:** el puntito es el alma de una niña (la de la portada) y la voz es su padre, o Dios, enseñándole la vida: emociones, momentos, que no está sola, que todo lo que tenemos es este momento.
- **Hacia adentro:** entre zona y zona la cámara cae en la punta y sale en la zona siguiente, que es la línea dentro de la línea (el efecto Droste, `scripts/world/droste.gd`). Cada zona va hacia su propio lado: la línea no siempre sube (`Main.ZONE_ANGLE`, detrás de `BuildFlags.DROSTE`).

  | Zona | Dirección | Zona | Dirección |
  |---|---|---|---|
  | 1 | Sube | 6 | Baja |
  | 2 | Derecha | 7 | Diagonal, arriba a la izquierda |
  | 3 | **El espiral** (abajo) | 8 | Derecha |
  | 4 | Izquierda | 9 | Diagonal, abajo |
  | 5 | La oscuridad: sube | 10 | Sube, para el final |

  Se gira toda la vista, y el paisaje, las capas del fondo y la ola de color giran con ella (`View.angle`); los textos del mundo se enderezan. A la oscuridad no se entra por la zambullida: el mundo gira despacio mientras cae. El tráiler mantiene la vista derecha (`Main.turn_zones`).
- **El espiral (zona 3, `PathData.SPIRAL_ZONE`).** La línea de la zona es un doble espiral: entra enroscándose hasta el centro y sale por el brazo intercalado, sin cruzarse, y termina donde habría terminado la zona, así que el resto del mundo no se mueve.
  - La punta crece a medida que se acerca al centro, hasta 4 veces su tamaño, y vuelve a su tamaño al salir (`PathData.grow_at`).
  - La cámara la sigue de lleno y se aleja un poco para que se vea la forma.
  - Las barreras se reparten a lo largo del espiral y quedan atravesadas sobre la curva (`PathData.gate_dir`).
  - En esta zona no hay estrella: la figura es la línea misma.
- **Pendiente (Pablo hará un documento por nivel con lo que pasa en cada uno):** más formas de camino y más juego con la escala, la forma y la dirección de la línea en cada zona.
- **El árbol es parte del dibujo:** brota de la línea en ramas, no se abre en un menú (§5).

| Pilar | Qué significa en la práctica |
|---|---|
| **Just tap** | La única interacción del juego principal es tocar la pantalla. Todo lo demás (árbol) es secundario y se abre aparte. |
| **Relajación** | Nada castiga. No hay derrota, solo "todavía no alcanza". El ritmo es lento, los textos son amables, la música nunca estresa. |
| **Todo es armonía** | Cada sonido, incluso los "ruidos" (viento/swish), está afinado en el acorde que suena y cae en el tiempo de la música. No existe un sonido fuera de la pieza. |
| **Algo se construye** | Cada tap deja huella: figuras que se dibujan, se pintan, viajan y se conectan formando una gran estructura. Al final, la cámara se aleja y se ve la obra completa. |
| **El color vuelve** | (Estilo Gris) El mundo empieza en grises; el color se recupera por capítulos: rojo, verde, azul, amarillo. |

Referencias: **Linelight** (línea y conectores minimalistas), **Gris** (acuarela, color que regresa, piano + coro, cinemática pausada).

---

## 2. Loop de juego

1. El jugador toca → la punta de la línea golpea la **barrera** actual → daño.
2. La barrera tiene **vida (HP)**. Desde la barrera 8, **se regenera** con el tiempo.
3. Si HP ≤ 0 → la barrera se rompe, la línea avanza hasta la siguiente, el jugador gana **luz (◆)**.
4. La luz se gasta en el **árbol** para subir daño, taps automáticos, combo, etc.
5. Al principio cada barrera cae en 1, 2, 3… taps (mucha recompensa). Hacia la barrera ~15–20 la regeneración supera lo que el dedo puede hacer → hay que mejorar el árbol.
6. 100 barreras = fin. Final cinemático + opción **Renacer** (reinicio con multiplicador permanente ×2 por renacimiento).

Taps también dan luz de a poco, así que estar "trabado" igual avanza (nunca hay un muro absoluto).

---

## 3. Progresión

- **100 barreras** (`FINAL = 100`), separadas `GAP = 150` unidades verticales.
- **10 zonas** de 10 barreras. Nombre de cada zona (lo que se construye):
  `semilla, raíz, tallo, hoja, flor, fruto, bosque, cielo, estrella, luz`
- **5 capítulos de color** (estilo Gris):

| Capítulo | Zonas | Color | Hex |
|---|---|---|---|
| gris | 1–2 | grises | `#b3ada6`, `#c2bcb4`, `#a29c95` |
| rojo | 3–4 | rojo coral | `#c95a4f` |
| verde | 5–6 | verde salvia | `#6c9c72` |
| azul | 7–8 | azul acuarela | `#4d84b3` |
| amarillo | 9–10 | ocre dorado | `#d9a948` (zona 10 mezcla todos) |

Tinta: `#3b3835`. Papel: `#ebe6de`.

Al completar la zona 2, 4, 6 y 8 se dispara el **evento "el color vuelve"** (ver §11).

---

## 4. Economía y fórmulas

Todas las fórmulas son del prototipo y fueron simuladas (jugador perfecto, 6 taps/s, compra golosa): llega a la barrera 100 en ~13 min. Un humano real tarda 3–4× más. **El muro aparece gradualmente** — no hay runaway.

```gdscript
# n = número de barrera (1..100), l = nivel de una mejora
func max_hp(n: int) -> float:
    if n <= 12: return n
    return round(12.0 * pow(1.15, n - 12) + (n - 12) * 3)

func regen_frac(n: int) -> float:          # fracción de la vida máxima por segundo
    if n < 8: return 0.0
    return min(0.5, 0.025 * (n - 7))

func regen(n) -> float:
    return max_hp(n) * regen_frac(n) * pow(0.9, lv("corrosion"))

func reward(n: int) -> float:              # luz por romper la barrera n
    return ceil(pow(1.14, n)) * gain()

func light_per_tap(n) -> float:            # luz por cada tap (auto = ×0.5)
    return n * 0.04 * gain()

func rebirth_mult() -> float: return pow(2, rebirths)
func power() -> float:   var l = lv("fuerza");   return (1 + l) * pow(1.075, l) * rebirth_mult()
func gain() -> float:    return pow(1.15, lv("ganancia")) * rebirth_mult()
func cost(k) -> int:     return ceil(UP[k].base * pow(UP[k].growth, lv(k)))
```

**Daño de un golpe**
```
d = power()
if auto:  d *= 0.6
d *= 1 + combo * 0.015 * lv("resonancia")        # combo 0..30
if randf() < 0.03 * lv("destello"): d *= 4       # crítico
```

**Combo:** cada tap manual suma 1 (máx 30) y reinicia un timer de 0.45 s; al vencer, el combo decae a 25/s.
**Eco:** cada tap manual tiene `0.06 * lv("eco")` de chance de repetirse 120 ms después.
**Pulso:** taps automáticos a `0.6 * lv("pulso")` por segundo.

> ⚠️ Lección del prototipo: si la recompensa crece al mismo ritmo que la vida (`reward ∝ max_hp`), la economía se dispara. La recompensa **debe** crecer más lento (1.14ⁿ vs 1.15ⁿ).

---

## 5. Árbol de mejoras

Forma de árbol que crece hacia arriba (como la línea). Posiciones en % del panel.

**Desde el 2/11/2026 el árbol no es un panel: son ramas que brotan de la misma línea** (`scripts/world/inline_tree.gd`, `BuildFlags.TREE_INLINE`; F1 vuelve al panel para comparar). Abrir un menú para mejorar cortaba el ritmo; ahora se compra tocando los nodos mientras se juega, sin pausar.
- Cada mejora es un nodo en la punta de su rama. La rama nace de la línea, o de la rama de la mejora que necesita, y brota dibujándose con una nota cuando la mejora se abre. Las que todavía no se abren se ven como un boceto punteado.
- Las raíces salen del punto real de la línea a su altura (`PathData.pos_at`), así que siguen sus curvas y quiebres. Las ramas son cortas, para no tapar el fondo.
- Cada nodo cuelga de un resorte: al subir la punta las ramas se quedan un poco atrás, se estiran y vuelven. Además se mecen con el viento, más en las puntas y más cuanto más rápido sube la línea.
- Un toque sobre un nodo compra y nunca cuenta como golpe a la barrera. El margen es chico, para no comprar sin querer.
- Dónde va cada rama está en `LAYOUT` dentro de `inline_tree.gd`. Las posiciones en % de la tabla de abajo quedan para el panel.
- En celular el subtítulo sube cerca del borde superior, para no taparse con las ramas.

| id | Nombre | Descripción | Requiere | base | growth | máx | Efecto (nivel l) | pos (x,y) |
|---|---|---|---|---|---|---|---|---|
| fuerza | Fuerza | Cuánto empuja cada tap | — | 10 | 1.33 | 400 | `(1+l)·1.075^l` daño | 50, 88 |
| ganancia | Ganancia | Más luz por barrera y por tap | fuerza 2 | 30 | 1.9 | 40 | `×1.15^l` luz | 18, 60 |
| pulso | Pulso | La línea late sola | fuerza 3 | 50 | 1.65 | 40 | `0.6·l` taps/s | 50, 56 |
| resonancia | Resonancia | Taps seguidos cargan combo | fuerza 5 | 80 | 1.8 | 20 | `+1.5·l %` por combo | 82, 60 |
| corrosion | Corrosión | Las barreras se regeneran más lento | ganancia 3 | 200 | 1.9 | 20 | regen `×0.9^l` | 18, 24 |
| eco | Eco | Cada tap puede repetirse | pulso 3 | 300 | 2.0 | 10 | `6·l %` | 50, 18 |
| destello | Destello | Crítico ×4 | resonancia 2 | 250 | 1.9 | 12 | `3·l %` | 82, 24 |

**Estados visuales de un nodo**
- `oculto` (0): no se ve, ni su conexión.
- `asomado` (1): el padre tiene ≥1 nivel → aparece punteado, sin número.
- `abierto` (2): cumple el requisito → sólido, muestra nivel.
- `comprable`: borde del color del capítulo. `máximo`: relleno del color.

**Animación de aparición (cada nodo la suya, nunca de golpe)**
- Al cambiar de estado (0→1 o 1→2), en cascada con **220 ms** de retraso entre nodos:
  - escala 0.2 → 1.12 → 1.0, rotación −50° → +4° → 0°, blur 6 px → 0, opacidad 0 → 1, en **1.5 s** con curva `ease-out` suave (cubic-bezier .2,.8,.2,1).
  - detrás, una **mancha de acuarela** del color del capítulo que se expande (escala 0.2 → 1.6) y se desvanece en 1.8 s.
  - la línea que lo une a su padre **se dibuja** de padre a hijo en 1.3 s (en Godot: `Line2D` con puntos interpolados por Tween, o shader con `progress`).
  - suena una **nota de celesta** del acorde actual por cada nodo (en la misma cascada).
- Al comprar: "pop" (escala 1 → 1.22 → 1) en 0.7 s + arpegio de 3 notas.
- El estado visto se guarda (`seen`) para que la animación no se repita al reabrir.

---

## 6. Mundo

### 6.1 La vía (path)
Generada proceduralmente con un RNG determinístico por índice (`rnd(i, salt) = fract(sin(i*127.1 + salt*311.7) * 43758.5453)`), así siempre es la misma.

Para cada barrera `i` desde la anterior `g=(gx, gy)`:
1. punto `(gx, gy+30)`
2. con prob. 70 % se desvía en diagonal 45°: `dx ∈ {±45, ±75}`, clamp a x ∈ [−95, 95]; punto `(nx, gy+30+|dx|)`
3. punto `(nx, gy+150)` → ahí está la barrera `i`.

Se guarda la longitud acumulada `L` de cada vértice para poder ubicar la punta con "distancia a lo largo del camino".

**Ramas decorativas** (estilo Linelight): 70 % de las barreras tienen una rama lateral horizontal de 40–130 u, a veces con un quiebre diagonal, terminada en un anillo pequeño. 35 % tienen una rama "flotante" desconectada a x=±160.

### 6.2 La punta y la línea
- `lit` = longitud encendida. Objetivo = `L(barrera actual) − 16`. Avanza con `max(min(diff, dt*120), diff*min(1, dt*5))` (rápido al principio, se frena al llegar).
- **Jolt** al golpear: la punta avanza 12 u y vuelve (decae a 9/s).
- La línea recorrida toma el color del capítulo de cada tramo.

### 6.3 Barreras
- Barra horizontal de 72 u de ancho con extremos redondeados.
- El daño abre un **hueco central**: `gap = 3 + (1 − hp/max) * 26`.
- Anillo de vida (r=12) alrededor de la punta.
- Las barreras futuras aparecen **dibujándose desde el centro** hacia afuera (1.5 s) la primera vez que entran en escena.
- Las rotas quedan como dos muñones y un anillo pequeño.

### 6.4 Cámara (Camera2D)
- Sigue a la punta: `target = (tip.x*0.5, tip.y+70)`, suavizado exponencial `k = 2.2`.
- **Evento de zona completa** (6 s): centra el mandala y hace zoom para que entre entero: `zoom = min(W*0.92, H*0.75) / (2*R*1.1)`, `k = 1.1`.
- **Final**: zoom out hasta ver la torre completa (100 barreras + mandalas), `k = 1`.
- Sacudida mínima (2 px) al romper. En Gris la cámara casi no tiembla.

> En Godot usar `Camera2D` con `position_smoothing` desactivado y hacer el suavizado manual en `_process` (más control), o Tweens para los eventos.

---

## 7. Lo que se construye

### 7.1 Mandalas (uno por zona)
- Centro: `(0, (10*z + 5.5) * GAP)`, radio `R = 560`.
- 10 vértices en el círculo exterior; rotación base `z * 0.31`.
- Parámetros por zona (`ko` salto de cuerda exterior, `ki` interior, `ri` radio interior relativo):

```
z: ko ki ri
0: 4 3 .50   1: 3 4 .42   2: 4 2 .60   3: 3 3 .48   4: 4 4 .55
5: 3 2 .62   6: 4 3 .45   7: 3 4 .50   8: 4 3 .40   9: 4 4 .58
```

- **Cada barrera rota agrega una pieza** (j = índice dentro de la zona):
  - cuerda exterior `V(j) → V(j+ko)`, cuerda interior `U(j) → U(j+ki)`, arco del círculo exterior `j → j+1`.
  - se dibujan en tinta con animación de trazo (2.4 s, ease-out cúbico) y brillo inicial que se apaga en 3.5 s.
  - **acuarela**: el sector anular `[ri, 1]` entre los ángulos de `j` y `j+1` se pinta del centro hacia afuera (clip circular creciente, 3.6 s, empieza 0.4 s después).
- **Zona completa**: se pinta el disco interior con un barrido circular (4.5 s), aparece un círculo exterior en tinta y dos pilares verticales que la unen con el mandala de abajo. Desde ese momento el mandala gira muy lento (0.01 rad/s).

### 7.2 Figura abstracta de cada barrera
- Cada barrera tiene una figura determinística (seed = n) de geometría sagrada, de 17 familias que se alternan (n % 17): semilla, germen, flor, huevo y fruto de la vida, estrella {p/q}, espiral áurea, merkaba, toro, cubo de Metatrón, loto, vector equilibrio, vesica piscis, cuadrados anidados, tetraedro estrella de 64, Sri Yantra y árbol de la vida. Son trazos normalizados a radio 1 que se dibujan en orden, del centro hacia afuera, a medida que se rompe la barrera (`scripts/world/barrier_figure.gd`).
- Centrada detrás de la barrera, radio 150 u.
- **Se dibuja mientras le pegás**: cantidad de puntos visibles = `figProg * N`, con `figProg → (1 − hp/max)` suavizado (dt·6). **Si la barrera se regenera, la figura se deshace.**
- Relleno acuarela que se intensifica: `alpha = 0.04 + 0.14 * figProg²`.
- Respira con el pulso de la música (+2 % en cada negra).

### 7.3 Semillas y red ("la gran figura")
Al romper la barrera:
1. La figura **florece** (escala ×1.4 en el primer 30 %).
2. **Viaja** (2.8 s, smoothstep) hasta su vértice del mandala, encogiéndose a ×0.16.
3. Queda ahí como **semilla** girando lentamente.
4. Desde la semilla **crecen hilos** (1.8 s) hacia la semilla anterior (`n−1`) y hacia la de la misma posición en la zona de abajo (`n−10`). Así se teje una red que sube por toda la torre.
5. Por cada hilo viaja permanentemente un puntito de color (período 3.4 s).

Sonidos: llegada → cascada de 4 notas de celesta; hilo conectado → 2 notas de piano graves (ver §9).

### 7.4 Formas musicales
Cada nota del acompañamiento (arpegio, brillos) hace nacer una forma a los costados: triángulo/cuadrado/pentágono/hexágono según la nota (círculo para los brillos agudos). Crece ×1.8, gira, se desvanece en 3.2–4.4 s. **Lo que suena se ve.**

### 7.5 Aura al pasar una barrera
Mancha de acuarela que se expande (30 → 260 px, 3 s) + 2 anillos de tinta concéntricos escalonados 0.25 s. Gotitas de tinta/color (12) con gravedad.

---

## 8. Dirección de arte (estilo Gris)

- **Fondo**: papel `#ebe6de` con grano (ruido ±6), manchas tonales grandes muy suaves y fibras. → En Godot: una textura de papel (1024² tileable) + `TextureRect` fijo a pantalla.
- **Viñeta** cálida `rgba(110,100,90,.3)` en los bordes.
- **Tinta** `#3b3835` para líneas: 0.8–1.2 px de grosor en figuras, 2.2 px en la línea principal.
- **Acuarela**: técnica de "polígono deformado en capas":
  1. polígono base → deformación recursiva por punto medio (desplazamiento gaussiano proporcional a la longitud del lado, profundidad 2).
  2. de esa base, 6–8 capas con deformación extra (profundidad 3).
  3. cada capa se dibuja con alpha 0.05–0.08 y **blend multiply**.
  → En Godot: generar las capas una vez (al cargar o al romper) como `Polygon2D` hijos con un `CanvasItemMaterial` en `BLEND_MODE_MUL`. Son estáticos, así que cuestan casi nada. Para la animación de "pintado", usar un **shader de máscara radial** con uniform `progress` en lugar de clip.
- **Color recuperado**: cada capítulo desbloqueado agrega un **lavado** grande y lento (gradiente radial, alpha 0.13, multiply) que deriva por la pantalla. Al desbloquearlo, una mancha gigante se abre desde el centro en 6 s.
- **Tipografía**: Cormorant Garamond (300, itálica para subtítulos), espaciado de letras amplio.

---

## 9. Música y sonido — el sistema armónico

### 9.1 Principio
Hay un **reloj musical** (tempo de la zona, en semicorcheas) y una **progresión de 4 acordes** (2 compases = 32 semicorcheas cada uno). **Todos** los sonidos:
- usan notas del **acorde actual** (o la tónica para los swish), y
- se **cuantizan** al siguiente pulso de la grilla.

Así es imposible que algo suene "mal".

### 9.2 Recomendación clave para Godot (fluidez)
El prototipo **sintetiza** todo en tiempo real (osciladores + reverb por convolución) → en celulares produce cortes y caídas de fps. En Godot:

- **Usar samples pre-grabados** (OGG) por instrumento, una nota por cada semitono necesario (o cada 3 semitonos y transponer con `pitch_scale`). Instrumentos: **piano, arpa, celesta, cristal, flauta suave, bajo cálido**.
- **Coro / pad**: stems pre-renderizados por acorde (o un loop por zona) con crossfade al cambiar de acorde.
- **Pool de `AudioStreamPlayer`** (16–24 voces) con robo de voz (la más vieja).
- **Bus de reverb** (`AudioEffectReverb`, room 0.8, damping 0.5, wet 0.35) compartido; nada de reverb por voz.
- **Reloj**: usar `AudioServer.get_time_since_last_mix()` + `AudioServer.get_output_latency()` para programar notas con precisión, o un `AudioStreamGenerator` sólo para el clic interno. Alternativa simple y robusta: un `Timer` de alta frecuencia en `_process` que avance la grilla por tiempo de audio acumulado.
- **Cuantización de taps**: al tocar, la nota se programa en el siguiente slot de la grilla (semicorchea; si la semicorchea dura > 150 ms, usar sextillos). Máximo 2 notas por slot (la segunda sube un grado del acorde → arma acordes). **El feedback visual es inmediato; sólo el sonido se cuantiza.**

### 9.3 Música por zona

Semitonos relativos a la tónica de la zona. Tónicas (Hz): `130.81, 146.83, 123.47, 110, 138.59, 116.54, 130.81, 98, 146.83, 164.81`.

| Zona | BPM | Progresión | Instrumento de taps | Capas |
|---|---|---|---|---|
| 1 | 64 | vi – IV – I – V `[9,12,16] [5,9,12] [0,4,7] [7,11,14]` | piano | 0 |
| 2 | 66 | vi – iii – IV – I `[9,12,16] [4,7,11] [5,9,12] [0,4,7]` | piano | 1 |
| 3 | 68 | i – VII – III – iv `[0,3,7] [-2,2,5] [3,7,10] [5,9,12]` | piano | 1 |
| 4 | 70 | i7 – VI – iv – v `[0,3,7,10] [8,12,15] [5,8,12] [7,10,14]` | arpa | 2 |
| 5 | 72 | Imaj7 – vi – IVmaj7 – V | piano | 2 |
| 6 | 74 | I – ii – IV – V | arpa | 3 |
| 7 | 72 | i – iv – VII – III7 | celesta | 3 |
| 8 | 76 | vi7 – IVmaj7 – Imaj7 – V7 | piano | 4 |
| 9 | 80 | Imaj7 – II (lidio) ×2 | celesta | 4 |
| 10 | 84 | Imaj7 – iii7 – IVmaj7 – V7 | piano | 5 |

**Arco emocional**: grises = menor, lento, melancólico → con cada color, más brillo, más capas, más tempo → final luminoso y esperanzador. A mitad de cada zona (barrera 6 de 10) entra **una capa más**.

### 9.4 Capas de acompañamiento (por número de capas activas L)

| Capa | Desde L | Qué toca |
|---|---|---|
| Coro (pad) | siempre | acorde completo, ataque 6 s, vibrato 4.6 Hz, se abre (más brillo) con la tensión |
| Bajo | 1 | fundamental −1 octava en el tiempo 1 de cada compás; desde L3 también la quinta en el tiempo 3 y ½ |
| Arpegio | 2 (o antes si hay tensión) | corcheas sobre `[0,1,2,3,4,3,2,1]` del acorde en 2 octavas; volumen `0.018 + T*0.04`; con L5 y T>0.55 pasa a semicorcheas |
| Brillo | 4 | nota aguda cada medio compás, cristal, muy suave |
| Contramelodía | 5 | flauta, una nota por compás, patrón `[2,1,3,2,4,3,1,2]` |

### 9.5 Tensión (T)
`T` (0..1) = cuánto le falta a la barrera actual × actividad reciente (`exp(-Δt_desde_último_golpe / 1.4 s)`), suavizada (dt·2.5).
- Sube el volumen y la velocidad del arpegio → **la música crece cuando estás por romper**.
- Abre el filtro del coro.
- Hace más visible la figura abstracta.

### 9.6 Catálogo de sonidos

| Evento | Sonido |
|---|---|
| Tap | nota del acorde según progreso de la barrera (más alta cuanto más rota) + viento suave afinado (banda en 2× la nota) |
| Pulso automático | sólo viento muy suave |
| Crítico | 2 notas agudas (grados 4–5) |
| Romper barrera | viento largo ascendente + arpegio de 5 notas en corcheas |
| Zona completa | arpegio de 8 notas lento + viento largo + voz en off |
| Capítulo de color | lo anterior + **crecida del coro** (×2 volumen, 5 s, vuelve en 2.5 s) |
| Semilla llega | cascada de 4 notas de celesta (agudas) |
| Hilo conectado | 2 notas de piano (fundamental y quinta) separadas un pulso |
| Comprar mejora | arpegio de 3 notas |
| Nodo del árbol aparece | 1 nota de celesta por nodo, en cascada |

---

## 10. Voz en off y textos

La voz es un personaje con historia propia: ver **§20 Historia y guion de voz** (guion completo, disparadores y subtítulos).
Grabar las líneas con voz grave, cálida, lenta, casi susurrada; procesadas con la reverb del bus. Cada línea aparece también escrita: inglés (la voz) + subtítulo en español, centrada a 30 % de la altura, fade de 3 s, ~5.6 s en pantalla, con una cola de líneas separadas al menos 7 s.

---

## 11. Cinemáticas y pacing

- **Intro**: papel vacío → "just tap" aparece (fade 3 s, retraso 0.5 s) → "if you had a bad day…" (retraso 2 s) → "tocá para empezar" pulsando. Al tocar: la intro se desvanece en 3 s, el HUD aparece en 2 s, la línea sube desde abajo de la pantalla hasta la primera barrera, y se escucha la voz.
- **Romper barrera**: aura + gotas + figura viaja (2.8 s) + hilos (1.8 s). El jugador puede seguir tocando mientras tanto: **nunca se bloquea el input**.
- **Zona completa** (6 s): cámara se aleja y centra el mandala, pulso de anillo, título "zona ii completa · raíz", voz.
- **Capítulo de color**: igual que zona completa pero el título es "el color vuelve · rojo", mancha gigante del color nuevo y crecida del coro.
- **Final**: zona 10 completa → (6.4 s) → la cámara se aleja hasta ver la **torre entera** de 10 mandalas con las 100 semillas conectadas → (5 s) → aparece "you made colour" + botón renacer, abajo, con gradiente de papel.

---

## 12. UI / HUD

- Arriba izquierda: número de barrera grande (`021 / 100`), debajo "zona iii · tallo".
- Arriba derecha: luz `◆ 57` (color del capítulo) y daño por tap.
- Abajo izquierda: botones **♪** (música) y **voz**.
- Abajo derecha: botón **árbol** con punto de color si hay algo comprable.
- Pista contextual abajo al centro: "tap" en los primeros toques; "mejorá el árbol" si pasaron > 12 s, > 25 taps y la barrera sigue > 75 % de vida.
- Junto a la barrera: HP actual y regeneración (`+9.8/s`) en itálica tenue.
- Números flotantes de daño (itálica, tinta) y de luz ganada (color).

Formato de números: `<1000` entero (o 1 decimal si < 10), después `K, M, B, T, Qa, Qi, Sx` con 2/1/0 decimales.

---

## 13. Arquitectura en Godot 4

### 13.1 Árbol de escenas
```
Main (Node2D)                      main.gd — orquesta, input
├── Paper (CanvasLayer -10)        textura de papel + viñeta
├── WashLayer (Node2D)             lavados de color, blooms (multiply)
├── World (Node2D)
│   ├── Mandalas (Node2D)          Mandala.tscn × 10 (instanciadas al llegar)
│   ├── SeedNetwork (Node2D)       semillas + hilos (draw custom o Line2D)
│   ├── Figures (Node2D)           figura actual + figuras viajando
│   ├── MusicShapes (Node2D)       pool de formas
│   ├── Path (Node2D)              Line2D vía apagada + Line2D encendida por capítulo
│   ├── Branches (Node2D)
│   ├── Gates (Node2D)             Gate.tscn (pool de ~14)
│   ├── Tip (Node2D)               punta + halo
│   └── FX (Node2D)                auras, gotas (GPUParticles2D), números flotantes
├── Camera2D                       camera.gd
├── UI (CanvasLayer 10)
│   ├── HUD
│   ├── TreePanel                  tree_panel.gd, TreeNode.tscn × 7
│   ├── Narration (Label)
│   ├── ZoneTitle
│   ├── Intro
│   └── EndScreen
└── Audio (Node)                   music.gd (reloj, capas), sfx pool, buses
```

### 13.2 Autoloads (singletons)
| Script | Responsabilidad |
|---|---|
| `GameState.gd` | stage, hp, light, upgrades, rebirths, seen; fórmulas de §4; señales |
| `Music.gd` | reloj, acordes, capas, cuantización, API `play_note(degree, instrument, vol)`, `tension` |
| `SaveSystem.gd` | guardar/cargar JSON en `user://save.json` |
| `Palette.gd` | capítulos, `paint_col(z, j)`, `line_col(n)` |

### 13.3 Señales principales
```gdscript
signal hit(damage: float, is_crit: bool, source: String)   # "tap" | "auto" | "echo"
signal gate_broken(n: int)
signal zone_completed(z: int)
signal chapter_unlocked(idx: int)
signal upgrade_bought(id: String, level: int)
signal light_changed(value: float)
signal game_finished
```
Visual y audio **escuchan** señales; `GameState` no sabe nada de gráficos.

### 13.4 Datos como Resources
- `ZoneData.tres` × 10: bpm, progresión, instrumento, capas, nombre, parámetros de mandala (ko, ki, ri).
- `UpgradeData.tres` × 7: id, nombre, desc, base, growth, max, requisito, posición, fórmula del efecto.
- `ChapterData.tres` × 5: nombre, color, zona de inicio, línea de voz.

### 13.5 Input
- `_unhandled_input`: `InputEventScreenTouch` (pressed) y `InputEventMouseButton` → `GameState.tap()`. Multitouch: cada dedo cuenta.
- Activar `input_devices/pointing/emulate_mouse_from_touch = false` para no duplicar.

---

## 14. Rendimiento en móvil

Objetivo: **60 fps estables** (plataforma principal: **PC**; móvil secundario), cero cortes de audio.

1. **Nada se recalcula por frame si es estático**: polígonos de acuarela, puntos de figuras, la vía → se generan una vez (o al romper) y quedan como nodos.
2. **Figura que se dibuja**: `Line2D` con todos los puntos + shader que corta por `progress` (usar UV.x a lo largo de la línea), en vez de reconstruir puntos.
3. **Semillas**: misma figura a escala 0.16 → usar ~1/3 de los puntos.
4. **Pools** para gates, formas musicales, auras, números flotantes. Nunca `queue_free` en caliente.
5. **Partículas**: `GPUParticles2D` (o CPUParticles2D en GL Compatibility).
6. **Renderer**: *Mobile* o *Compatibility* (este último para Android viejo). Probar MSAA 2D 2× para las líneas finas.
7. **Culling**: sólo procesar mandalas/semillas dentro de la pantalla + margen (en el final, que se ve todo, bajar puntos a 1/6).
8. **Audio**: samples OGG, pool de voces, una sola reverb en bus, nada de síntesis en tiempo real. Precargar todo al inicio.
9. `Engine.max_fps = 60`, `physics` desactivada (no se usa).

---

## 15. Guardado

```json
{ "stage": 21, "hp": 37.2, "light": 1234.5, "up": {"fuerza": 12, "pulso": 3},
  "reb": 0, "seen": {"fuerza": 2, "ganancia": 2, "pulso": 1},
  "music_on": true, "voice_on": true }
```
- Guardar cada 3 s, al romper una barrera, al comprar, y en `NOTIFICATION_APPLICATION_PAUSED`.
- Al cargar a mitad de partida: las piezas ya construidas aparecen **sin animación**; la línea sube rápido desde abajo hasta la barrera actual (es una mini-cinemática de "volver").

---

## 16. Parámetros de ajuste

| Parámetro | Valor | Efecto |
|---|---|---|
| `GAP` | 150 | distancia entre barreras |
| `R` | 560 | radio de mandala |
| Crecimiento HP | 1.15 | dificultad |
| Crecimiento recompensa | 1.14 | debe ser < crecimiento HP |
| Regen | `0.025*(n−7)`, máx 0.5 | presión desde la barrera 8 |
| Combo máx / por nivel | 30 / 1.5 % | |
| `FLY` | 2.8 s | viaje de figura a semilla |
| `LINK` | 1.8 s | crecimiento de hilos |
| Evento de zona | 6 s | duración cinemática |
| Cámara `k` | 2.2 (normal), 1.1 (evento), 1.0 (final) | suavidad |
| Tensión: decaimiento | 1.4 s | cuánto dura la "carga" musical |
| Cuantización | semicorchea (o sextillo si > 150 ms) | latencia vs musicalidad |

---

## 17. Orden de implementación sugerido

1. **Núcleo**: `GameState` + fórmulas + tap → daño → romper → luz. HUD mínimo. Guardado.
2. **Vía + punta + barreras + cámara** (Line2D, sin acuarela todavía).
3. **Árbol** con datos en Resources y animaciones de aparición.
4. **Música**: reloj + acordes + taps cuantizados con samples de piano. Probar en celular real **antes de seguir**.
5. **Capas, tensión, coro**, sonidos de eventos.
6. **Figuras abstractas** (dibujo por progreso), aura.
7. **Mandalas** en tinta → luego acuarela con Polygon2D multiply.
8. **Semillas y red**.
9. **Capítulos de color**, lavados, blooms.
10. **Intro, eventos, final, voz grabada**.
11. Pulido: balance con jugadores reales, accesibilidad (vibración opcional, tamaño de texto), menú.

---

## 18. Diferencias con el prototipo y mejoras pendientes

- **Audio sintetizado → samples** (causa principal de los cortes en móvil).
- **Voz del sistema → voz grabada.**
- El prototipo dibuja todo en un `<canvas>` cada frame; en Godot, todo lo estático debe ser nodos persistentes.
- Ideas no implementadas aún:
  - progreso offline (pulso sigue funcionando con la app cerrada, con tope).
  - más ramas del árbol en capítulos avanzados (desbloqueadas por color).
  - háptica sutil sincronizada con el pulso al romper.
  - modo "sólo escuchar": sin HUD, la línea late sola.
  - logros silenciosos (ej. "completaste una zona sin comprar nada").
- Balance: la simulación asume 6 taps/s sostenidos; validar con jugadores reales y ajustar los crecimientos de §16.

---

*Prototipo de referencia: "just tap · gris" (HTML). Toda la lógica, fórmulas y parámetros de este documento salen de ese código.*

---

## 19. Estructura para 2½–3 horas: una mecánica nueva por capítulo

**Objetivo de duración:** 150–180 min para la primera partida completa (jugador real, ~3–4 taps/s con pausas), sin que se sienta relleno. La regla: **cada capítulo de color trae una forma nueva de tocar**, siempre con un solo dedo y siempre "just tap". El color nuevo, la mecánica nueva y la emoción de la historia llegan juntos.

### 19.1 Mapa general

| Capítulo | Emoción | Mecánica nueva | Barreras | Duración objetivo | Acumulado |
|---|---|---|---|---|---|
| Prólogo + **Gris** | entumecimiento | **La línea** (lo actual): una punta, línea recta, árbol básico | 1–20 | 20–25 min | 25 min |
| **Rojo** | enojo | **El bucle**: la línea entra en un círculo y hay que romperlo | 21–40 | 30–35 min | 60 min |
| **Verde** | respirar / crecer | **La bifurcación**: la punta se divide en 2 y después en 3 | 41–60 | 35 min | 95 min |
| **Azul** | tristeza / soltar | **La marea**: tocar en armonía con la respiración y el pulso | 61–80 | 35 min | 130 min |
| **Amarillo** | calidez / esperanza | **La convergencia**: todo junto, las 3 puntas vuelven a ser una | 81–100 | 30–35 min | 165 min |
| Epílogo | — | "Mañana": renacer con variaciones | — | opcional | — |

Cada capítulo cierra con una **barrera guardiana** (barreras 20, 40, 60, 80, 100) más grande, que pide usar la mecánica del capítulo, y cuya rotura dispara el evento de color.

### 19.2 Gris — La línea (1–20)
Lo que ya existe. Enseña tocar, que la barrera se regenera, y el árbol. Aquí se aprende el loop básico; no agregar nada más.

### 19.3 Rojo — El bucle (21–40)
**Fantasía:** el enojo da vueltas sobre sí mismo. Hay que romper el círculo.
- A partir de la barrera 21 la vía entra en un **anillo** (radio ~180 u). En el anillo hay **6–10 segmentos-barrera** repartidos.
- Cada tap hace que la punta **avance por el anillo** hasta el siguiente segmento y le pegue. La punta da vueltas sola: tocar rápido = girar rápido.
- Los segmentos rotos **se curan** si la punta tarda demasiado en volver a pasar (p. ej. 4 s): hay que mantener el ritmo de vueltas sin desesperarse.
- Cuando todos los segmentos están rotos a la vez, **el anillo se abre**, la línea sale por una tangente y sigue subiendo. Hay un bucle cada 4–5 barreras normales; los últimos son **espirales** (anillos concéntricos que se van cerrando).
- **Árbol (rama roja):** *Inercia* (la punta sigue girando sola un rato tras cada tap), *Temple* (los segmentos tardan más en curarse), *Chispa* (cada vuelta completa hace un golpe extra a todos los segmentos).
- **Música:** cada segmento roto agrega una nota a un ostinato que gira con el anillo; romper el bucle completo resuelve el acorde.
- **Visual:** el anillo se dibuja en tinta; al romperlo, los fragmentos se convierten en pétalos rojos que caen.

### 19.4 Verde — La bifurcación (41–60)
**Fantasía:** crecer es abrirse en ramas.
- En la barrera 41 la punta **se divide en 2**; en la 51, **en 3**. Cada rama tiene su propia barrera y su propia figura abstracta.
- **Un solo toque mueve a todas:** cada clic / barra espaciadora golpea **todas las ramas a la vez** con el daño completo. No hay que apuntar (pensado para PC).
- Cada rama tiene vida ligeramente distinta (`max_hp(fila) · (1 + 0.18·sin(i·2.3 + fila·1.7))`), así avanzan desfasadas y se siente el "trío" moviéndose a destiempo.
- Las ramas **se vuelven a unir** en un nodo cada 3–5 barreras: para pasar, **todas** las ramas tienen que haber llegado. Así se aprende a repartir la atención.
- Si una rama queda muy atrás, la música lo marca (su voz instrumental se apaga) y la voz da una pista amable.
- **Árbol (rama verde):** *Raíces* (pulso automático para cada rama), *Savia* (un % del daño de una rama pasa a las otras), *Injerto* (cuando una rama rompe, las otras reciben un golpe).
- **Música:** cada rama es un instrumento (piano, arpa, celesta). Tres ramas avanzando = un trío.
- **Visual:** las ramas dibujan tallos; en los nodos de unión florece una flor de acuarela.

### 19.5 Azul — La marea (61–80)
**Fantasía:** la tristeza viene en olas. No se pelea: se respira con ella.
- El mundo **respira**: un ciclo lento (8 s) visible como una marea que sube y baja (el papel se tiñe de azul y se aclara).
- En la **exhalación** (mitad del ciclo) las barreras están **blandas**: cada golpe hace ×3. En la inhalación, ×0.5. Tocar sin parar funciona, pero tocar con la marea es mucho mejor.
- **Tocar en el pulso:** si el tap cae en la grilla musical (±60 ms), cuenta como **"en armonía"**: suma un combo especial, la nota suena más brillante y aparece un anillo azul. Es la mecánica que conecta el juego con el sistema armónico.
- Algunas barreras azules **no se rompen pegando**: se **disuelven** si las dejás en paz durante una exhalación completa (enseña a soltar).
- **Árbol (rama azul):** *Marea* (ventana de exhalación más larga), *Calma* (más margen para tocar en el pulso), *Llanto* (cada combo en armonía de 8 suelta una lluvia que daña todo).
- **Música:** la marea controla el filtro y el volumen del coro; los taps en armonía dejan ecos que se suman al arpegio.

### 19.6 Amarillo — La convergencia (81–100)
**Fantasía:** todo lo aprendido vuelve a ser uno.
- Las 3 puntas del Verde reaparecen y **convergen** en una sola, más grande, que usa todo: anillos (Rojo), bifurcaciones cortas (Verde), marea (Azul).
- Mezcla de las mecánicas en secuencias cortas y variadas (nunca más de 3 barreras seguidas de un mismo tipo).
- **Árbol (rama amarilla):** *Constelación* (cada semilla de la red gigante suma un % permanente de daño, así lo construido ayuda), *Sol* (toda la luz ×2).
- **Barrera 100 — el coloso:** ocupa toda la pantalla; es un mandala vivo con anillos, ramas y marea a la vez. Al romperla empieza la cinemática final.

### 19.7 Variedad dentro de cada capítulo (anti-monotonía)
Cada capítulo alterna **barreras normales**, **barreras de la mecánica**, **una barrera de respiro** (muy fácil, con recompensa grande y un momento visual) y la **guardiana**. Patrón sugerido por bloque de 10:
`N N M N R M N M M G` (N normal, M mecánica, R respiro, G guardiana o fin de zona).

### 19.8 Ritmo de tiempo por barrera (para balancear a 3 h)
Tiempo medio objetivo por barrera (jugador real):

| Barreras | Tiempo medio | Notas |
|---|---|---|
| 1–10 | 5–20 s | recompensa constante, se aprende |
| 11–20 | 30–60 s | primer muro (regeneración), primer uso del árbol |
| 21–40 | 60–90 s | bucles; guardianas ~3 min |
| 41–60 | 90–120 s | dividir la atención |
| 61–80 | 90–120 s | marea y armonía |
| 81–100 | 90–150 s | coloso ~5 min |

Suma ≈ 160–175 min. **Para lograrlo:** volver a simular la economía (§4) con un modelo de jugador "humano" (3.5 taps/s, 15 % del tiempo en el árbol, pausas) y ajustar `crecimiento HP`, `crecimiento recompensa` y `growth` de costos hasta que cada tramo caiga en su ventana. Las mecánicas nuevas suman multiplicadores propios, así que **cada capítulo debe tener su propia curva** (HP base y crecimiento por capítulo) en lugar de una sola fórmula global.

### 19.9 Sesiones y progreso fuera del juego
- Pensado para sesiones de 10–20 min: cada zona (10 barreras) es una sesión natural que cierra con una cinemática.
- **Progreso fuera del juego** (opcional): el Pulso sigue funcionando con la app cerrada a 25 % de eficiencia, con un tope de 2 h. Al volver, la voz dice *"Welcome back"* y la línea muestra lo que avanzó sola.

### 19.10 Epílogo — "Mañana" (renacer)
Al renacer, el mundo vuelve a gris pero **la torre anterior queda dibujada muy tenue al fondo**. Las mecánicas aparecen en otro orden y las figuras cambian de semilla. Voz: *"Again? Of course. I'm always here."*

---

## 20. Historia y guion de voz

### 20.1 La premisa
Alguien tuvo un mal día. Abre el juego y una voz le dice: *"If you had a bad day… just tap."*
La línea que sube es lo que esa persona hace con su día: cada tap es un pequeño acto de seguir. El viaje por los colores recorre, sin nombrarlo, cómo se atraviesa un mal día: **entumecimiento → enojo → respirar → tristeza → calidez**.

**¿Quién habla?** Durante todo el juego la voz parece un acompañante externo, cálido, que sabe lo que pasa. Al final se revela: **es la parte de vos que sigue adelante**. La voz es la línea.

### 20.2 Tono
- Frases cortas, en segunda persona, nunca más de 12 palabras.
- Nunca da órdenes duras ni juzga. Valida ("está bien") y acompaña.
- Silencios largos: la voz aparece poco (≈ 30 líneas en 3 horas). Que cada aparición se espere.
- Voz en inglés (el *tagline* es en inglés) con subtítulo en español. Se puede doblar al español para el mercado local.

### 20.3 Guion completo

| # | Disparador | Inglés (voz) | Español (subtítulo) |
|---|---|---|---|
| 0 | Inicio (primer toque) | If you had a bad day… just tap. | Si tuviste un mal día… simplemente tocá. |
| 0b | Volver con partida guardada | Welcome back. Where were we? | Volviste. ¿Dónde estábamos? |
| **Gris** | | | |
| 1 | Llegar a barrera 3 | Some days, everything turns grey. | Hay días en que todo se vuelve gris. |
| 2 | Barrera 8 (empieza la regeneración) | It pushes back. That's alright. | Empuja de vuelta. Está bien. |
| 3 | Zona 1 completa | There. Something small. It still counts. | Ahí está. Algo chiquito. Igual cuenta. |
| 4 | Barrera 14 | You don't have to fix the whole day. Just the next tap. | No tenés que arreglar el día entero. Sólo el próximo toque. |
| 5 | Trabado por primera vez | It's heavy, isn't it? Grow a little. Then try again. | Pesa, ¿no? Crecé un poco. Después volvé a intentar. |
| 6 | Zona 2 completa → **vuelve el rojo** | Do you feel that? That's anger. It means you still care. | ¿Lo sentís? Es enojo. Quiere decir que todavía te importa. |
| **Rojo** | | | |
| 7 | Barrera 24 | Go on. Hit it. It can take it. | Dale. Pegale. Lo aguanta. |
| 8 | Primer bucle | It keeps coming back around, doesn't it? | Vuelve y vuelve, ¿no? |
| 9 | Zona 3 completa | Anger is just energy that hasn't found its way yet. | El enojo es energía que todavía no encontró su camino. |
| 10 | Barrera 35 | Give it somewhere to go. Up. | Dale un lugar a dónde ir. Arriba. |
| 11 | Trabado en Rojo | Pushing harder isn't always stronger. | Empujar más fuerte no siempre es ser más fuerte. |
| 12 | Zona 4 completa → **vuelve el verde** | Breathe in… and let it go. | Respirá… y soltalo. |
| **Verde** | | | |
| 13 | Primera bifurcación | You can be more than one thing at once. | Podés ser más de una cosa a la vez. |
| 14 | Barrera 44 | Look behind you. You've been building something. | Mirá atrás. Estuviste construyendo algo. |
| 15 | Zona 5 completa | Things grow slowly. So do you. | Las cosas crecen despacio. Vos también. |
| 16 | Barrera 55 | Resting is part of it too. | Descansar también es parte. |
| 17 | Trabado en Verde | Roots grow when nothing seems to happen. | Las raíces crecen cuando parece que no pasa nada. |
| 18 | Zona 6 completa → **vuelve el azul** | And now it hurts a little. That's how you know it's leaving. | Y ahora duele un poco. Así sabés que se está yendo. |
| **Azul** | | | |
| 19 | Primera marea | Breathe with it. Not against it. | Respirá con eso. No contra eso. |
| 20 | Barrera 64 | You've been carrying this all day. | Estuviste cargando esto todo el día. |
| 21 | Zona 7 completa | You can put it down here. I'll hold it for a while. | Podés dejarlo acá. Yo lo sostengo un rato. |
| 22 | Barrera 75 | It was never about breaking walls. | Nunca se trató de romper paredes. |
| 23 | Trabado en Azul | It's okay to be sad and keep going at the same time. | Está bien estar triste y seguir al mismo tiempo. |
| 24 | Zona 8 completa → **vuelve el amarillo** | It was about not stopping. | Se trataba de no detenerse. |
| **Amarillo** | | | |
| 25 | Convergencia | All of you. Together again. | Todo vos. Juntos otra vez. |
| 26 | Barrera 84 | Do you remember this morning? Before all of it? | ¿Te acordás de esta mañana? ¿Antes de todo? |
| 27 | Zona 9 completa | It's still there. It always was. | Sigue ahí. Siempre estuvo. |
| 28 | Barrera 95 | Almost. Don't rush the ending. | Casi. No apures el final. |
| 29 | Trabado en Amarillo | Slowly. The light isn't going anywhere. | Despacio. La luz no se va a ningún lado. |
| **Final** | | | |
| 30 | Barrera 100 rota | I'm the part of you that keeps going. | Soy la parte de vos que sigue adelante. |
| 31 | +7 s | You found me again. | Me volviste a encontrar. |
| 32 | +7 s (torre completa) | Tomorrow, if it's grey again… you know what to do. | Mañana, si vuelve a estar gris… ya sabés qué hacer. |
| — | Renacer | Again? Of course. I'm always here. | ¿Otra vez? Claro. Siempre estoy acá. |
| — | Sin tocar 25 s (máx. cada 3 min, rotan) | I'll wait. / Take your time. / Still here. | Te espero. / Tomate tu tiempo. / Sigo acá. |

Las líneas 8, 13, 19 y 25 dependen de las mecánicas nuevas de §19 (todavía no están en el prototipo); el resto ya funciona en el prototipo web.

### 20.4 Reglas de disparo
- Cada línea suena **una sola vez por partida** (se guarda en `said`), salvo las de inactividad, regreso y renacer.
- Cola de líneas con **7 s mínimo** entre una y otra; nunca dos a la vez.
- Al renacer se borra `said`: la historia se vuelve a contar (con la torre anterior de fondo).
- Al hablar la voz, la música baja 3 dB (*ducking*) durante la línea.

---

## 21. Pack de sonidos

El archivo `just_tap_sonidos.zip` trae **todos los sonidos del prototipo** renderizados con el mismo motor (1092 archivos OGG, 44.1 kHz):
- **Instrumentos** (gris: piano, arpa, celesta, flauta, bajo · neón: campana, kalimba, marimba, flauta, bajo · común: cristal): una nota por semitono, en versión **con reverb** (tal cual el juego) y **seca** (para usar la reverb de Godot).
- **Vientos/swishes afinados** (12 notas por tipo; para otras octavas, `pitch_scale` ×2 o ×0.5).
- **Fondos**: coro (gris) y pad (neón), un archivo por zona y acorde (40 + 40), para encadenar con fundido cruzado.
- `LEEME.md` con nombres, rangos y la tabla de `volume_db` para recuperar el balance original.

El prototipo web ya usa este mismo sistema (samples MP3 cada 3 semitonos, transpuestos), lo que eliminó la síntesis en tiempo real.

---

## 22. Cinemáticas jugables y estrellas

### 22.1 Cinemáticas "la pelotita sigue sola"
En los momentos de historia (líneas de §20 ligadas a una barrera) el juego entra en **modo cine**:
- Franjas de cine (12 % arriba y abajo, color papel oscuro) entran en 1.6 s; el HUD se desvanece; los subtítulos bajan a la franja inferior.
- La cámara se acerca (zoom 1.18) y se suaviza.
- **El input se pausa** y la punta toca sola **en cada negra del tempo**, con daño suficiente para romper la barrera en ~6–8 golpes. Cada golpe suena (nota del acorde) y deja un aura pequeña: la pelotita "toca una melodía" mientras la voz habla. Deja una **estela** (22 posiciones que se desvanecen).
- Termina 2.6 s después de romper la barrera (máx. 16 s) y devuelve el control.
- Zonas completas también usan las franjas durante su evento de 6 s.

### 22.2 Estallido de bifurcación
Al llegar al inicio de una bifurcación (§19.4) — si coincide con un evento de zona, espera a que termine:
1. **Carga (2.2 s):** cámara a zoom 1.55 sobre el punto de división. La punta brilla; 3–4 anillos dorados se cierran hacia ella; 16 rayos dorados giran y se alargan; halo radial creciente. Las ramas quedan retenidas en el punto.
2. **Estallido:** destello de pantalla (crema, 0.9 → 0 en 1.3 s), tres auras escalonadas (oro / color del capítulo / oro), 46 partículas, crecida del coro, arpegio de cada instrumento de rama + bajo, viento largo ascendente. Voz: *"You can be more than one thing at once."*
3. **Salida:** las puntas salen disparadas por sus ramas (velocidad ×3.2 que decae), 24 rayos y un anillo se abren y desvanecen (2.4 s). Cámara vuelve a 0.95.
- **Convergencia:** al unirse las ramas, cinemática corta (3.4 s): destello suave, tres anillos dorados expandiéndose, acorde con los instrumentos de las ramas. Voz: *"And all of it is still you."*

Color oro de estos momentos: `#e2b65a`.

### 22.3 Estrellas-circuito (molinete)
En barreras puntuales la punta se convierte en **N luces que recorren a la vez un circuito geométrico** — un gran momento que pide haber invertido en el árbol:

| Barrera | Figura | n | salto k |
|---|---|---|---|
| 16 | tetragrama | 4 | 2 |
| 27 | pentagrama | 5 | 2 |
| 37 | hexagrama | 6 | 2 |
| 67 | heptagrama | 7 | 3 |
| 77 | pentagrama | 5 | 2 |
| 87 | hexagrama | 6 | 2 |
| 96 | heptagrama | 7 | 2 |

- **Circuito de cada luz i** (radio 150 u, todo gira): **(A)** cuerda oblicua del vértice `i` al `i+k` (las líneas cruzadas de la estrella) → **(B)** arco del círculo de `i+k` a `i+k+1` → **(C)** rayo recto de `i+k+1` al **centro**. Entre todas trazan la estrella completa, el círculo completo y todos los rayos.
- **Barreras:** 2 por tramo (al 40 % y 85 %) = 6 por luz. Vida `max_hp(barrera)·1.6·(1 ± 0.15)`, regeneración propia (`regen_frac·1.6`). **Un toque golpea a todas las luces a la vez.**
- **Molinete:** la figura gira (`0.12 + 0.35·progreso` rad/s); lo recorrido se traza en oro con un lavado de color debajo, y la estrella se va pintando por dentro según el progreso total.
- **Entrada (cinemática):** carga dorada en el centro con el circuito dibujándose en miniatura → estallido → las luces viajan a sus vértices (1.3 s).
- **Clímax al completar:** las N luces llegan al centro; la figura gira cada vez más rápido (2.8 s) → estallido grande (destello 2 s, 80 partículas, 4 auras, 32 rayos, 3 anillos, coro, arpegio de 8 notas, bajo) → **el personaje vuelve a ser uno**: una sola luz en el centro que sigue subiendo. Voz: *"See? It was whole all along."* La figura queda en el fondo, pintada, girando lenta.
- Recompensa: 15 % de `reward` por cada barrera de luz rota + `reward·n·0.5` al completar.
