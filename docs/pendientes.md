# Just Tap — pendientes

Notas de lo que queda por hacer, con fecha. Al hacerlo, se borra de acá y se documenta donde corresponda (`JUST_TAP_GODOT.md`, `docs/`).

## Para el juego completo (anotado el 3/11/2026)

Sale del video de Scansylabs: al ver la ballena dijo "¡guau, qué hermoso!", y con la historia de papá se emocionó.

### Animales gigantes, cada uno con su momento
- **Pocos y en momentos clave:** uno por capítulo, como premio después de un tramo difícil, para que cada aparición sorprenda.
- **Cada uno con su cinemática de despertar:** se enciende de a poco, sus ojos empiezan a parpadear y recién después se mueve. Es su momento: la cámara y la música le dan lugar.
- **Lo que dicen juntos:** que todo está conectado y somos parte del todo (`JUST_TAP_GODOT.md`, "El norte"). Cada uno puede decir algo propio. Ideas: tortuga gigante (la paciencia), ciervo de luz (la calma), banco de medusas (soltar), búho (mirar hacia adentro), fénix (volver a empezar).
- **Cada uno con su canto**, en la tonalidad del tema que suena, como la ballena.
- La ballena actual (`scripts/world/celestial_whale.gd`) también puede ganar su despertar: encenderse, abrir los ojos y recién ahí nadar.

### Una historia real por capítulo
Como la de esperar a papá en la vereda: momentos reales, chicos, que el juego ofrece contar y el jugador elige escuchar. Pocos y verdaderos.

### La espiral hacia abajo (nivel aparte, fuera de la demo)
Una espiral que se hunde, como una escalera caracol o un remolino, vista desde arriba y de frente. La pelotita da vueltas y en cada vuelta baja un poco más: con la perspectiva, lo que está más abajo se ve más chico, más cerca del centro y más tenue, como mirar el fondo de un pozo. Las barreras son marcas sobre la espiral, cada vez más hondas. Es la idea de "hacia adentro" hecha imagen: descender dentro de uno mismo.
- **Dónde:** la noche (la tinta, el quiebre) del juego completo, o el camino de vuelta al todo del final, cayendo hacia la luz del centro.
- **Cómo:** sin pasar a 3D. Cada punto de la espiral tiene una profundidad, y según ella se dibuja más chico, más al centro y más tenue (un túnel en 2D). Se mantiene la tinta y el papel, la música, el pulso y el árbol.
- **Para que se sienta:** una vuelta por compás, así el giro va con la música; la luz del fondo crece con cada barrera; la cámara gira suave con la pelotita.
- **Prototipos (3/11/2026):**
  - `tools/spiral_down.tscn`: el pozo con escalera caracol, la pelotita baja rompiendo barreras con toques, y el final (rayos desde el fondo, la bajada sola, el brillo amarillo y el paso al escenario siguiente).
  - `tools/spiral_rhythm.tscn` (**el elegido**): un tramo de ritmo, sin árbol ni barreras que romper. La pelotita baja sola con la música y llega a cada línea en un pulso; si tocás al llegar, la línea se abre en dorado y suena la nota siguiente de una melodía. Fallar no castiga (la nota no suena). Lo acertado llena la luz del fondo. Detrás se forma **un ave gigante de estrellas**: cada nota traza una línea a su estrella siguiente, y en el desenlace queda entera, abre el ojo y bate las alas. Pensado como uno de los niveles desenlace del juego.
  - Para ajustar: el ave más grande, abrazando el pozo; elegir la criatura y la melodía según la historia del capítulo.

### El monumento que se parte (estilo Gris)
Una estatua gigante de piedra: una mujer arrodillada, con la cabeza inclinada, las manos juntas en el pecho y el pelo largo cayéndole por la espalda. La línea sube por su contorno, desde la rodilla hasta la coronilla, con la cámara cerca, así que solo se ve la piedra que se está escalando. Cada barrera que rompés agrieta la piedra a su alrededor.
- **El desenlace:** en la cima, la cámara se aleja y la estatua se ve entera. El oro corre por todas las grietas mientras retumba, y la estatua estalla en pedazos que flotan, con la luz de su corazón a la vista. Después la pelotita baja sola entre los pedazos, una nota de una melodía descendente por pulso, y cada pedazo que pasa brilla. Abajo la espera un resplandor dorado, que es el paso al nivel siguiente.
- **Es la Madre Divina, Kundalini (v5):** los pedazos no vuelven a ser la estatua arrodillada. Se rearman en la Madre de pie, con vestido y velo. Las grietas brillan en oro, se borran y la piedra cobra vida: el velo y el ruedo del vestido se mueven con el viento y respira. Abre los ojos, se agacha, toma la lucecita, se incorpora con la palma abierta y le habla como una madre a su hijo: *"Mi pequeña luz… a veces crees que estás rota. / Pero si sigues, todo vuelve a su lugar. / Y las grietas que tanto dolieron son las que ahora brillan."* Después la luz se eleva de su palma y sigue su camino.
- **Romperse y volver a armarse (v3, reemplazado por la Madre):** durante la bajada, cada pedazo vuelve a su lugar cuando pasa la pelotita, y la estatua queda entera con las grietas en oro, como el kintsugi. Después levanta la cabeza, se incorpora y se va caminando hacia la niebla. El narrador dice: *"A veces creemos que estamos rotos. Pero si sigues, todo vuelve a su lugar… y las grietas se llenan de oro."*
- **Profundidad y cámara:** contraluz con una luna enorme, ruinas en planos con niebla al pie, escombros en primer plano y escamas en el aire. La cámara arranca abierta desde los pies de la estatua, se va acercando hasta quedar cerca en la cara, y se abre en el estallido y al final. Hay variante roja (`-- rojo`).
- **Prototipo (3/11/2026):** `tools/monument.tscn` (`-- auto end` para verlo desde cerca de la cima).
- **Para ajustar:** un sonido propio para el estallido, más grave y con golpe de piedra; dibujar la estatua a mano y partirla igual; que las grietas crezcan con cada toque.

### Variante de la mecánica: avanzar con el pulso
Salió del monumento y le encantó a Pablo: la pelotita **no avanza sola**, cada toque en el pulso la empuja hasta la barrera siguiente. Si no tocás, no se mueve. Así el jugador siente que sube él, a ritmo. Sirve para otros tramos: escaladas, subidas, cualquier lugar donde avanzar tenga que costar y sentirse.

### El final
El puntito es un ser que vuelve a su padre, el todo, el absoluto, que es el narrador.

La orquesta de luces se hizo el 3/11/2026 (`JUST_TAP_GODOT.md` §1, "Tocar con la música").
