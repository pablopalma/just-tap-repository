# Datos de juego de la beta

La beta manda eventos anónimos a una hoja de Google Sheets para balancear con jugadores reales, no solo con `tools/sim_time`. No se guarda nada personal: un id al azar por jugador, la versión, la plataforma, el idioma y lo que pasa en el juego. El jugador lo puede apagar en la pantalla de título (abajo a la derecha: *beta · anonymous play data: on*).

Si `BuildFlags.TELEMETRY_URL` está vacío, el juego no registra nada y el interruptor no aparece. Tampoco registra mientras el guardado está apagado (pruebas, tráiler) ni después de usar el menú de desarrollo.

## Poner en marcha la hoja (una vez)

1. Crear una hoja nueva en Google Sheets, por ejemplo *Just Tap beta*.
2. **Extensiones → Apps Script.** Borrar lo que haya y pegar `tools/beta_sheet.gs`. Guardar.
3. **Implementar → Nueva implementación →** tipo **Aplicación web**.
   - Ejecutar como: **Yo**.
   - Quién tiene acceso: **Cualquier usuario**.
4. Autorizar (Google avisa que la app no está verificada: *Configuración avanzada → Ir a…*). Copiar la **URL de la aplicación web**, la que termina en `/exec`.
5. Abrir esa URL en el navegador: tiene que decir *Just Tap beta data endpoint: ok*.
6. Pegar la URL en `scripts/build_flags.gd`, en `TELEMETRY_URL`, y exportar web y Windows.

Si se cambia el script, hay que publicar una **nueva versión** de la misma implementación (*Implementar → Gestionar implementaciones → editar*) para que la URL no cambie.

## Qué se registra

Cada fila de la hoja `events` es un evento: `received, uid, session, version, platform, lang, t, event, barrier, data, time`.
- `t`: los segundos desde que se abrió el juego en esa sesión.
- `data`: un JSON corto.
- `received`: cuándo llegó la tanda de eventos. El juego manda una tanda cada 30 s, así que varios eventos comparten esa hora.
- `time` (desde el 2/11/2026): el momento exacto de cada evento, hasta el segundo, según el reloj del jugador. Las builds anteriores no lo mandan, y en ese caso se usa la hora de llegada.

Para ver los segundos: seleccioná la columna y elegí *Formato → Número → Fecha y hora*.

| Evento | Cuándo | `data` |
|---|---|---|
| `open` | Al abrir el juego | `returning` (había partida), `w` (ancho de ventana) |
| `start` | Al empezar a jugar | `light` |
| `gate` | Cada barrera rota | `s` segundos en esa barrera, `taps`, `light`, `lv` niveles comprados en total, `tree` veces que abrió el árbol en esa barrera, `cine` si la rompió una cinemática |
| `buy` | Cada compra | `id`, `lv`, `cost`, `light` que le queda |
| `tree` | Al cerrar el árbol | `s` segundos adentro, `light` |
| `tick` | Cada minuto jugando | `p` progreso de la barrera (0–1), `s` segundos en ella, `light`, `taps` |
| `star` | Estrella completada | — |
| `leave` | Al cerrar o pausar (escritorio) | `p`, `s` |
| `new_game` | Empezar de nuevo | — |
| `demo_end` | Final de la demo | `taps`, `clock` |
| `opt_out` / `opt_in` | El jugador apaga o prende los datos | — |

En web, la página guarda los eventos y los manda con `navigator.sendBeacon` cada 30 s y al ocultar o cerrar la pestaña. En escritorio los manda el juego por HTTP cada 30 s. En la consola del navegador aparece un error `ERR_BLOCKED_BY_RESPONSE` por cada envío: es la respuesta de Google, que la página descarta por el aislamiento de hilos; el dato ya se escribió.

## Leer los datos

Descargar la hoja como CSV (*Archivo → Descargar → .csv*) y:

```
python tools/beta_report.py "Just Tap beta - events.csv" --version 0.9.0-beta --out Builds/beta_report.md
```

El reporte da tiempo por barrera (mediana, 75 %, máximo, toques, si abrieron el árbol), dónde deja la gente, qué compran en el árbol y en qué barrera, y cuánto tardan en terminar la demo. Las barreras con mediana de más de 90 s quedan marcadas.

## Probar sin la hoja

`tools/telemetry_sink.py` hace de hoja en local y escribe un CSV con las mismas columnas:

```
python tools/telemetry_sink.py 8770 Builds/telemetry_test.csv
godot --headless --path . res://tools/telemetry_test.tscn -- --telemetry-url=http://127.0.0.1:8770/
```

Usar `127.0.0.1` y no `localhost` (Godot puede resolverlo a IPv6 y el servidor escucha en IPv4).

## Texto para la página de itch

> **About the beta.** This is a beta: to balance it, the game sends anonymous play data — how long each barrier takes and what you buy in the tree, with a random id and no personal information. You can turn it off on the title screen.

> **Sobre la beta.** Esto es una beta: para balancearla, el juego manda datos anónimos de juego (cuánto tardás en cada barrera y qué comprás en el árbol), con un id al azar y sin datos personales. Lo podés apagar en la pantalla de título.
