# Cápsulas de tienda (Steam e itch)

**Desde el 31/10/2026 el arte de las cápsulas es una ilustración propia, no una captura del juego.** Una cápsula hecha con el juego se ve como una captura de pantalla; la cápsula tiene que vender el tono, la calidez y la promesa (*if you had a bad day…*) antes que la mecánica.

`tools/key_art.py` la dibuja: alguien chiquito, sentado en un día gris con las rodillas abrazadas y una bufanda roja; desde la punta de un dedo levantado (un toque, con su anillo) sube una línea de tinta que se vuelve dorada hasta una ballena de luz que nada sobre su cabeza. Tinta y papel como el juego, con aguadas de acuarela: gris y lluvia abajo, la luz cálida de la ballena arriba y en el suelo alrededor de la persona.

`tools/make_capsules.py` recorta ese arte para cada tamaño y le pone el logo (Cormorant Garamond, tinta `#3b3835`) con un halo de papel (`#ebe6de`) para que se lea sobre el dibujo.

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
| `itch/cover.png` | 630 × 500 | Portada de itch: se sube en *Edit game → Cover image* (`tools/make_itch_images.ps1` la copia a `Builds/itch/`) |
| `itch/banner.png` | 960 × 300 | Banner de la página de itch: se sube en *Edit theme → Images → Banner* (también se copia a `Builds/itch/`) |

Y `presskit/`, para prensa y streamers:

- `key_art_landscape.png` (3840 × 2160) y `key_art_portrait.png` (1800 × 2700): el arte limpio, sin texto.
- `logo.png`: el logo sobre transparente.
- `main_capsule.psd`, `library_capsule.psd`, `cover.psd`: con capas separadas (`art`, `glow`, `title`, `tagline`), para poder mover o sacar el logo y usar el arte en miniaturas propias.

## Composición

Tres encuadres, cada uno dibujado aparte (`LAYOUTS` en `tools/key_art.py`):

- **Horizontal** (`art_land.png`, 3840 × 2160): la ballena arriba a la derecha, la persona abajo, el logo en el papel vacío de la izquierda.
- **Vertical** (`art_port.png`, 1800 × 2700): el logo arriba, la ballena cruzando el medio, la persona abajo.
- **Portada de itch** (`art_cover.png`, 2520 × 2000): igual que la vertical pero más ancha.
- **Banner de itch** (`art_banner.png`, 1920 × 600): el logo a la izquierda, la ballena y la persona a la derecha.
- La cápsula chica no lleva subtítulo: a ese tamaño no se lee.

## Regenerar

1. El arte: `python tools/key_art.py` (necesita `pillow` y `numpy`; tarda un par de minutos). Con `--fast` lo hace a un cuarto del tamaño (`art_*_fast.png`) para probar cambios.
2. Las cápsulas: `python tools/make_capsules.py` (necesita `pillow` y `psd-tools`). Los recortes y el lugar del logo de cada tamaño están en `main()`.

`tools/capsule_art.tscn`, que renderiza la ciudad terminada desde el juego, sigue disponible para capturas de prensa o fondos, pero ya no es el arte de las cápsulas.

## Notas

- Steam pide que el logo se lea en la cápsula chica y que el héroe de biblioteca no tenga texto. Revisar las reglas vigentes de Steamworks antes de subir.
- Es una ilustración generada por código, en el estilo del juego. Para Steam a largo plazo, una ilustración pintada a mano por un ilustrador sobre esta misma composición sería el paso siguiente.
