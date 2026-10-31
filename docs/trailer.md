# Tráiler de la demo (57 s)

El tráiler sale del propio juego: `tools/trailer.tscn` reproduce esta secuencia y Godot la graba con Movie Maker (60 fps fijos, con audio). Así se puede regenerar idéntico después de cada cambio.

- **Una sola pieza musical:** la música queda fija en la tonalidad y el tempo de la zona 10 (84 BPM) y el director suma o quita capas. No hay saltos de tempo entre planos.
- **Cortes al compás:** cada corte cae justo en un compás (2,86 s), con un fundido rápido a papel.
- Voz: solo líneas ya grabadas. Subtítulos en inglés. Sin HUD ni números de daño.

| Compases | Tiempo | Plano | Capas | Voz |
|---|---|---|---|---|
| 0–2 | 0–5,7 s | Papel: "just tap" | 0 | *If you had a bad day… just tap.* |
| 2–4 | 5,7–11,4 s | Primeros toques, la línea sube, el arco se dibuja | 1 | *Some days, everything turns grey.* |
| 4 | 11,4–14,3 s | El árbol se abre en cascada | 2 | — |
| 5–7 | 14,3–20 s | **El color vuelve** (rojo) | 3 | *Do you feel that? That's anger…* |
| 7 | 20–22,9 s | **Montaje:** la ciudad se arma a lo lejos | 5 | — |
| 8 | 22,9–25,7 s | Montaje: una estrella-circuito gira | 5 | — |
| 9 | 25,7–28,6 s | Montaje: el ave pasa cerca | 5 | — |
| 10 | 28,6–30 s | Montaje: la línea en tres ramas | 5 | — |
| 10,5 | 30–31,4 s | Montaje: el árbol, medio compás | 5 | — |
| 11–13 | 31,4–37,1 s | **La oscuridad:** blanco sobre negro, figuras que chocan, la torre se desmorona | 1 | *Not everything comes back so easily.* |
| 13–14,5 | 37,1–41,4 s | Barreras 42, 43 y 44 rompiéndose a tempo, cada una con su sacudón | 1 | — |
| 14,5–16 | 41,4–45,7 s | La 45: el caos se ordena en un mandala dorado, las grietas se llenan de oro | 3 | — |
| 16–18 | 45,7–51,4 s | **Algo despierta:** la ballena celestial, apenas vista (aparece a los ~48 s) | 5 | *But you're not alone in this.* (compás 17) |
| 18–20 | 51,4–57,1 s | Cartel: **just tap** · free demo · itch.io | — | — |

- **Ritmo:** los primeros planos cortan con un fundido a papel; el montaje (compases 7–11) corta con un parpadeo, un plano por compás o por medio compás. En la oscuridad los cortes funden a negro.
- **Sin mostrar todo:** la oscuridad y la ballena son destellos. La ballena entra ya avanzada en su travesía y el tráiler corta al cartel antes de que cruce.
## Generar

```
powershell -File tools/make_trailer.ps1
```

Graba a 1080p (unos 9 minutos) y deja en `Builds/trailer/` el MP4 (H.264, −14 LUFS), GIFs del color que vuelve, la ciudad armándose, la oscuridad y la ballena (cada uno de menos de 3 MB). Para cambiar planos, tiempos o capas: `_plan()` en `tools/trailer.gd`, en compases.
