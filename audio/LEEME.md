# just tap — sonidos

Todos los sonidos del prototipo, renderizados con el mismo motor de síntesis del juego. 44.1 kHz, OGG Vorbis (listo para Godot).

## Carpetas
- `gris/` — versión acuarela: piano, arpa, celesta, flauta, bajo, coro (fondo) y vientos.
- `neon/` — versión original: campana, kalimba, marimba, flauta, bajo, pad (fondo) y swishes.
- `comun/` — cristal (lo usan las dos).

## Instrumentos (`*/instrumentos/<instrumento>/`)
- Una nota por semitono. Nombre: `<instrumento>_<MIDI>_<nota>.ogg` (ej. `piano_060_C4.ogg` = Do central, `069_A4` = 440 Hz).
- Rango: MIDI 55–96 (bajos: 28–64).
- `con_reverb/` (estéreo): suenan exactamente como en el prototipo, con la reverb incluida. Usar tal cual.
- `seco/` (mono): sin reverb, para usar la reverb de un bus de Godot (`AudioEffectReverb`).

## Vientos / swishes (`*/viento/`)
Están afinados: hay uno por cada nota de la escala (12). Para otra octava, usar `pitch_scale` = 2 o 0.5.
- `tap/`, `auto/`: elegir según la nota que suena en el tap (MIDI 60–71).
- `romper/`, `zona/`, `semilla/`: elegir según la tónica de la zona (MIDI 43–54).

## Fondo (`*/fondo/`)
Un archivo por zona y por acorde: `coro_zona03_acorde2.ogg` (gris) / `pad_zona03_acorde2.ogg` (neón).
12 s de acorde sostenido (entra en 2 s, sale desde los 9 s) + cola. Encadenarlos con fundido cruzado de ~1.5 s cada vez que cambia el acorde (cada 2 compases).

## Volumen
Cada grupo está normalizado a −1 dBFS. Para recuperar el balance original del juego, aplicar este `volume_db`
al reproducir (y sumar el volumen relativo de cada evento indicado en el documento de diseño, sección 9):

| grupo | volume_db |
|---|---|
| `bell` | -27.7 dB |
| `bell_seco` | -31.2 dB |
| `kalimba` | -29.1 dB |
| `kalimba_seco` | -32.2 dB |
| `marimba` | -31.5 dB |
| `marimba_seco` | -33.4 dB |
| `flute_neon` | -27.7 dB |
| `flute_neon_seco` | -30.2 dB |
| `bass_neon` | -27.1 dB |
| `bass_neon_seco` | -28.6 dB |
| `glass` | -26.6 dB |
| `glass_seco` | -29.8 dB |
| `piano` | -26.3 dB |
| `piano_seco` | -30.1 dB |
| `harp` | -27.5 dB |
| `harp_seco` | -31.7 dB |
| `celesta` | -26.8 dB |
| `celesta_seco` | -29.9 dB |
| `flute_gris` | -26.5 dB |
| `flute_gris_seco` | -28.7 dB |
| `bass_gris` | -26.6 dB |
| `bass_gris_seco` | -28.2 dB |
| `neon_swish` | -28.8 dB |
| `gris_wind` | -34.6 dB |
| `neon_zone` | -32.2 dB |
| `gris_zone` | -32.6 dB |
| `neon_pad` | -11.6 dB |
| `gris_choir` | -32.8 dB |

Los volúmenes de cada evento en el juego (tap 0.05, bajo 0.07, arpegio 0.018–0.06, etc.) se grabaron con referencia 0.05:
`volume_db_final = volume_db_grupo + 20·log10(vol_evento / 0.05)`.
