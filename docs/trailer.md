# Tráiler de la demo (69 s)

El tráiler sale del propio juego: `tools/trailer.tscn` reproduce esta secuencia y Godot la graba con Movie Maker (60 fps fijos, con audio). Así se puede regenerar idéntico después de cada cambio.

- **Una sola pieza musical:** la música queda fija en la tonalidad y el tempo de la zona 10 (84 BPM) y el director suma o quita capas. No hay saltos de tempo entre planos.
- **Cortes al compás:** cada corte cae justo en un compás (2,86 s), con un fundido rápido a papel.
- Voz: solo líneas ya grabadas. Subtítulos en inglés. Sin HUD ni números de daño.

| Compases | Tiempo | Plano | Capas | Voz |
|---|---|---|---|---|
| 0–2 | 0–5,7 s | Papel: "just tap" | 0 | *If you had a bad day… just tap.* |
| 2–4 | 5,7–11,4 s | Primeros toques, la línea sube, el arco se dibuja | 1 | *Some days, everything turns grey.* |
| 4 | 11,4–14,3 s | El árbol se abre en cascada | 2 | — |
| 5–8 | 14,3–22,9 s | **El color vuelve** (rojo) | 3 | *Do you feel that? That's anger…* |
| 8–10 | 22,9–28,6 s | **La ciudad se arma a lo lejos:** cámara alejada, piezas que suben flotando con chispas, aire y arpa | 3 | — |
| 10 | 28,6–31,4 s | Estrella de 4 luces | 4 | *Small lights. One shape. That's you, too.* |
| 11–13 | 31,4–37,1 s | Estrella de 5 luces: se completa, gira y estalla | 4 | *See? It was whole all along.* |
| 13–15 | 37,1–42,9 s | **El ave pasa cerca:** aleteos, su grito y la ráfaga con Doppler | 2 | — |
| 15 | 42,9–45,7 s | La línea se divide en 2 (estallido dorado) | 5 | *You can be more than one thing at once.* |
| 16 | 45,7–48,6 s | Tres ramas, trío de instrumentos | 5 | — |
| 17–19 | 48,6–54,3 s | La oscuridad, la torre se agrieta | 1 | *Not everything comes back so easily.* |
| 19–22 | 54,3–62,9 s | La cámara se aleja sobre la ciudad entera | 5 | *You made all of this.* |
| 22–24 | 62,9–68,6 s | Cartel: **just tap** · free demo · itch.io | — | — |
## Generar

```
powershell -File tools/make_trailer.ps1
```

Graba a 1080p (unos 9 minutos) y deja en `Builds/trailer/` el MP4 (H.264, −14 LUFS), un GIF del color que vuelve y otro de la ciudad armándose. Para cambiar planos, tiempos o capas: `_plan()` en `tools/trailer.gd`, en compases.
