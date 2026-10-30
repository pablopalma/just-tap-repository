# Tráiler de la demo (60 s)

El tráiler sale del propio juego: `tools/trailer.tscn` reproduce esta secuencia y Godot la graba con Movie Maker (60 fps fijos, con audio). Así se puede regenerar idéntico después de cada cambio.

Voz: solo líneas ya grabadas. Subtítulos en inglés (se entienden sin sonido, como se ve en redes). Sin HUD.

| Tiempo | Plano | Voz |
|---|---|---|
| 0–4 s | Papel vacío: "just tap" / "if you had a bad day…" | — |
| 4–14 s | Toca, la línea sube, las primeras barreras se rompen; al fondo el arco se dibuja con su arpegio de cristal | *Some days, everything turns grey.* |
| 14–19 s | El árbol de mejoras se abre: los nodos aparecen en cascada | — |
| 19–29 s | Barrera 20: **el color vuelve**. El mundo se vacía y el rojo entra como acuarela mojada | *Do you feel that? That's anger. It means you still care.* |
| 29–36 s | El ave gigante cruza cerca; las estructuras se dibujan | — |
| 36–42 s | Capítulo verde (avance del juego completo) | *Things grow slowly. So do you.* |
| 42–48 s | La oscuridad entra, la torre se agrieta | *Not everything comes back so easily.* |
| 48–56 s | La cámara se aleja sobre la ciudad entera, en color | *You made all of this.* |
| 56–60 s | Cartel: **just tap** · demo gratis en itch.io | — |

## Generar

```
Godot_console.exe --path . --write-movie Builds/trailer/trailer.avi --fixed-fps 60 --resolution 1920x1080 res://tools/trailer.tscn
```

Después `tools/make_trailer.ps1` lo convierte a MP4 (itch, redes) y a GIF (el momento del color que vuelve).
