# Cápsulas de tienda (Steam e itch)

El arte de las cápsulas sale del propio juego: `tools/capsule_art.tscn` renderiza la ciudad terminada, en color, con la línea de tinta y el ave, sin interfaz ni texto y a cualquier resolución. `tools/make_capsules.py` recorta ese arte para cada tamaño y le pone el logo (Cormorant Garamond, tinta `#3b3835`) con un halo de papel (`#ebe6de`) para que se lea sobre el dibujo.

## Qué sale

En `Builds/capsule/`:

| Archivo | Tamaño | Uso |
|---|---|---|
| `steam/header_capsule.png` | 920 × 430 | Cápsula de cabecera (arriba de la página de Steam, listas) |
| `steam/small_capsule.png` | 462 × 174 | Cápsula chica (búsquedas, listas). Solo el título, bien grande |
| `steam/main_capsule.png` | 1232 × 706 | Cápsula principal (portada de la tienda, destacados) |
| `steam/vertical_capsule.png` | 748 × 896 | Cápsula vertical (ofertas de temporada) |
| `steam/library_capsule.png` | 600 × 900 | Biblioteca: portada |
| `steam/library_header.png` | 920 × 430 | Biblioteca: cabecera |
| `steam/library_hero.png` | 3840 × 1240 | Biblioteca: héroe. Sin texto (Steam pone el logo encima) |
| `steam/library_logo.png` | 1280 × 720 | Biblioteca: logo transparente |
| `steam/page_background.png` | 1438 × 810 | Fondo de la página de la tienda: el arte fundido con el papel |
| `itch/cover.png` | 630 × 500 | Portada de itch (`tools/make_itch_images.ps1` la copia a `Builds/itch/`) |

Y `presskit/`, para prensa y streamers:

- `key_art_landscape.png` (3840 × 2160) y `key_art_portrait.png` (1800 × 2700): el arte limpio, sin texto.
- `logo.png`: el logo sobre transparente.
- `main_capsule.psd`, `library_capsule.psd`, `cover.psd`: con capas separadas (`art`, `glow`, `title`, `tagline`), para poder mover o sacar el logo y usar el arte en miniaturas propias.

## Composición

- **Horizontales:** la columna de estructuras de colores a la derecha, el ave volando hacia la izquierda arriba y el logo centrado en el papel vacío de la izquierda.
- **Verticales y portada de itch:** cielo arriba con el logo, el ave debajo y la ciudad abajo.
- La cápsula chica no lleva subtítulo: a ese tamaño no se lee.

## Regenerar

1. El arte, con la versión de Godot sin C# (`Godot_v4.7.2-stable_win64`), con ventana: renderiza fuera de pantalla y se cierra solo a los 11 s.

   ```
   godot --path . --resolution 640x360 res://tools/capsule_art.tscn -- --size=3840x2160 --zoom=0.045 --cy=-5650 --x=-5200 --bird=0.22 --dir=-1 --out=Builds/capsule/art_land.png
   godot --path . --resolution 640x360 res://tools/capsule_art.tscn -- --size=1800x2700 --zoom=0.028 --cy=-10900 --bird=0.3 --dir=1 --bscale=0.5 --bx=0.64 --by=0.29 --out=Builds/capsule/art_port.png
   ```

   Parámetros: `zoom` (respecto del zoom base; `0` deja la cámara del final), `cy` y `x` (adónde mira la cámara, en unidades del mundo), `bird` (momento del vuelo, 0–1; `-1` lo oculta), `dir` (1 a la derecha, −1 a la izquierda), `bscale`, `bx`, `by` (tamaño del ave y su lugar como fracción del cuadro).

2. Las cápsulas: `python tools/make_capsules.py` (necesita `pillow` y `psd-tools`). Los recortes y el lugar del logo de cada tamaño están en `main()`.

## Notas

- Steam pide que el logo se lea en la cápsula chica y que el héroe de biblioteca no tenga texto. Revisar las reglas vigentes de Steamworks antes de subir.
- Si el juego cambia de aspecto (paleta, estructuras, ave), volver a renderizar el arte: así las cápsulas siempre muestran el juego como es.
