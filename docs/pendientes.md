# Just Tap — pendientes

Notas de lo que queda por hacer, con fecha. Al hacerlo, se borra de acá y se documenta donde corresponda (`JUST_TAP_GODOT.md`, `docs/`).

## Para el 3/11/2026

### Tocar con la música en las bifurcaciones: una orquesta
En las partes bifurcadas (la línea se divide y avanzan varias luces a la vez, `forks` y `star_circuit` en `scripts/world/`), sumar la mecánica de tocar con el pulso (§1, "Tocar con la música") de forma que **cada luz sea un instrumento** y entre todas suenen como una pequeña orquesta.

Ideas para arrancar:
- Cada luz con su voz y su registro, tomados del color de toque del tema que suena (`Songs.TRACKS[...].taps`): por ejemplo, una grave en el primer tiempo, otra media y otra aguda tipo campana.
- Un toque a tiempo hace sonar a las luces en orden, como un arpegio o un acorde repartido entre ellas, o en pregunta y respuesta; cada una se ilumina cuando suena su nota.
- Las notas, como siempre, de la pentatónica del compás del tema, así todo queda en armonía.
- Con la racha, se suman más luces o voces: a más racha, más orquesta.
- Revisar cómo se ven y suenan hoy los toques en una bifurcación (`tools/star_fork_test.tscn`) antes de diseñar.
