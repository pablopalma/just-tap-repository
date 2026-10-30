# Just Tap — port a Godot 4.7

Port del prototipo web "just tap · gris". El diseño completo está en `JUST_TAP_GODOT.md` (copia del documento de diseño). Esta primera pasada cubre los pasos 1–4 del §17.

## Qué hay

- **Núcleo** (`autoload/game_state.gd`): fórmulas del §4, tap → daño → romper → luz, combo, eco, pulso, crítico, regeneración, renacer. Emite señales; no sabe nada de gráficos ni de audio.
- **Guardado** (`autoload/save_system.gd`): `user://save.json` cada 3 s, al romper, al comprar y al pausar.
- **Mundo** (`scripts/world/`): vía determinística con ramas, punta, barreras con hueco, cámara con suavizado manual, auras de acuarela (blend multiply), anillos, gotas y números flotantes.
- **Árbol** (`scripts/ui/tree_panel.gd`): 7 mejoras con estados oculto/asomado/abierto y aparición en cascada (escala, rotación, mancha, línea que se dibuja, nota de celesta).
- **Música** (`autoload/music.gd`): reloj por zona, progresiones de 4 acordes, taps cuantizados (sextillos, máx. 2 por slot), capas (bajo, arpegio, brillo, contramelodía), coro con fundido cruzado y filtro según la tensión, sonidos de eventos. Samples secos de `audio/` + una reverb de bus.
- **Pantallas**: intro, título de zona / "el color vuelve", final con renacer.

## Qué falta (§17 pasos 5–11)

Formas musicales, figuras abstractas por barrera, mandalas, semillas y red, lavados de capítulo persistentes, voz grabada, mecánicas por capítulo (§19), cinemáticas jugables (§22).

## Audio

`audio/` sale de `just_tap_sonidos.zip` (versión gris, `seco/` + vientos + coro). Volúmenes según la tabla del `audio/LEEME.md`.

## Voz

- El guion completo (§20.3) está en `data/voice_lines.gd`, en inglés y español. La voz es siempre en inglés; los subtítulos salen en el idioma elegido (botón `es`/`en` del HUD, guardado en la partida).
- Cada grabación va en `audio/voices/vo_<id>.mp3` (también `.ogg` o `.wav`), con el id de la línea: `vo_00.mp3`, `vo_00b.mp3`, `vo_01.mp3`… `vo_32.mp3`, `vo_rebirth.mp3`, `vo_idle1.mp3`. Una línea sin grabación muestra solo el subtítulo.
- `autoload/narrator.gd` hace la cola (7 s entre líneas), los disparadores, el ducking de la música (−3 dB) y guarda qué se dijo.

## Herramientas

- `tools/smoke_test.tscn`: juega en headless y escribe un resumen. `Godot_console.exe --headless --path . res://tools/smoke_test.tscn`
- `tools/screenshots.tscn`: juega una sesión con guion y guarda capturas en `user://shots/`.

Las dos sobrescriben `user://save.json`.
