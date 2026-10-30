# Voz de Just Tap — guion para ElevenLabs

Modelo **Eleven v3** (el que entiende las etiquetas entre corchetes). Se pega solo el texto del bloque. Cada archivo se guarda en `audio/voices/` con el nombre indicado, y el juego lo toma solo.

Ajustes que vienen funcionando: Stability ~50 %, Similarity ~75 %, Style bajo. Generar 2 o 3 tomas por línea y quedarse con la mejor.

Las etiquetas que ya usás y suenan bien: `[softly]`, `[warmly]`, `[whispers]`, `[sighs]`, `[exhales]`, `[breathes in]`, `[in awe]`, `[pause]`, `[short pause]`, `[long pause]`. Los `...` también dan pausa.

## Faltan grabar

### vo_03.mp3 · zona 1 completa
```
[softly] There. [pause] Something small. [short pause] [warmly] It still counts.
```

### vo_08.mp3 · primer bucle (capítulo rojo, mecánica pendiente)
```
[sighs] It keeps coming back around... [pause] doesn't it?
```

### vo_14.mp3 · barrera 44
```
[softly] Look behind you. [pause] [warmly] You've been building something.
```

### vo_19.mp3 · primera marea (capítulo azul, mecánica pendiente)
```
[breathes in] Breathe with it. [pause] [exhales] Not against it.
```

### vo_22.mp3 · barrera 75
```
[softly] It was never about... [pause] breaking walls.
```

### vo_25.mp3 · convergencia (capítulo amarillo, mecánica pendiente)
```
[in awe] All of you. [long pause] [warmly] Together again.
```

### vo_rebirth.mp3 · al renacer
```
[warmly] Again? [short pause] Of course. [pause] [softly] I'm always here.
```

### vo_idle1.mp3 · inactividad
```
[softly] I'll wait.
```

### vo_idle2.mp3 · inactividad
```
[warmly] Take your time.
```

### vo_idle3.mp3 · inactividad
```
[whispers] Still here.
```

### vo_made.mp3 · el final, mientras la cámara muestra todo lo construido
`
[softly] Look... [long pause] [in awe] You made all of this.
`

## Final de la demo (barrera 40)

### vo_demo_1.mp3 · entra la oscuridad
`
[softly] Not everything... [pause] comes back so easily.
`

### vo_demo_2.mp3 · el ave pasa, herida
`
[long pause] [warmly] But you're not alone in this.
`

### vo_demo_letter.mp3 · la carta corta de la demo
Misma voz. El texto en pantalla dice además cuántas veces tocó el jugador.
`
[softly] Thank you for playing this far.
[long pause] You kept tapping... [short pause] all the way here.
[long pause] [warmly] The rest of the way... [pause] is still waiting to be drawn.
`

## La carta del creador (cuarta pared) · vo_letter.mp3

Un solo archivo, en inglés como el resto. El texto en pantalla sigue al audio: cada línea aparece en el momento que le toca según el largo de la grabación, y la firma sale cuando la voz termina. La voz **no dice el número de taps** (no puede saberlo); en pantalla sí aparece el número real del jugador.

Con la **misma voz del narrador**, para que el locutor no cambie: la carta es el último momento de la misma presencia que acompañó todo el juego. Mismos ajustes que el resto de las líneas.

```
[softly] Hi. [pause] We've never met.
[pause] I'm the one who made this game.
[long pause] I don't know what kind of day you had... [short pause] or what you're going through.
[pause] But you kept tapping... [short pause] all the way here.
[pause] One tap at a time. [short pause] That's not nothing.
[long pause] [warmly] Whatever it is... [pause] there's a way through. [short pause] There always is.
[long pause] [softly] And I want you to know...
[pause] [warmly] You made all of this.
[long pause] I'm proud of you.
```

Ajustes: Stability más alta que el narrador (60–70 %) para que suene sereno y sin actuación, Style casi en 0.