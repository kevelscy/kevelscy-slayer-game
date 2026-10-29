# Art style guide

Source of truth for every sprite, tile, icon, VFX and UI asset. The guide below is the
owner's brief, kept verbatim. Inspired by the look of Slayer Legend: never copy its
characters or assets.

## Pipeline

- Art: Pixelorama through the `pixelorama` MCP. Sound: SoundCraft (`soundcraft-cli mcp`).
  No AI image generators, no PhotoCraft.
- Palette: `art/palettes/paleta_juego.gpl` (35 colors; swatch sheet `paleta_juego.png`), also
  installed in Pixelorama's `Palettes/` folder.
- Sources: `art/source/*.pxo`. Exports: transparent PNG; animations as horizontal
  spritesheets in `art/sprites/`, tiles in `art/tiles/`. Audio: `.ogg` in `audio/sfx/` or
  `audio/music/`.
- Before each asset: state what it is and its size. Review it with `get_image` before
  exporting. When done: list the files created and their dimensions.
- Godot import: Nearest filter, no mipmaps.

## Owner's brief (verbatim)

```text
GUÍA DE ESTILO DEL JUEGO (inspirado en el estilo de Slayer Legend, NO copies sus personajes ni assets)

GÉNERO Y VISTA
- RPG idle / auto-batalla, vista lateral, scroll horizontal, pantalla vertical (mobile).

PALETA
- Usa SOLO la paleta "paleta_juego.gpl" (35 colores). No inventes colores fuera de ella.
- Fondos: tonos oscuros y apagados (marrones, púrpuras y grises oscuros).
- Personajes, enemigos y efectos: colores saturados (rojo, naranja, amarillo, cian, azul) para que resalten sobre el fondo.
- Contraste clave: cálidos (fuego/oro) contra fríos (cian/azul).

PERSONAJES
- Estilo chibi: cabeza grande, cuerpo de ~2.5 cabezas.
- Tamaño: héroes y enemigos comunes 32x32 a 48x48. Jefes grandes, 128px o más, con píxeles más gruesos.
- Contorno oscuro de 1px (#0f0808 o #1f1512), no negro puro en todo: aclara el contorno en zonas iluminadas.
- Sombreado con 3–4 tonos por material, luz desde arriba-izquierda.
- Armas exageradas y más grandes que el personaje.

FONDOS
- Poco detalle, formas grandes y simples, 2–3 capas de parallax.
- Más oscuros y menos saturados que los personajes para no competir con ellos.

EFECTOS (VFX)
- Pueden romper la regla del pixel: brillos, glow, partículas y estelas de movimiento.
- Colores: fuego (rojo→naranja→amarillo→blanco), hielo/energía (azul→cian→blanco).
- Destellos blancos en impactos.

UI
- Íconos de habilidad cuadrados con marco metálico plateado (#929ea6, #c0ced1).
- Ícono seleccionado o raro: borde dorado brillante (#fccf40, #fde504).
- Números de daño grandes en rojo vivo (#f4170b) con contorno oscuro.
- Barra de pestañas abajo; botones grandes, pensados para el pulgar.

ANIMACIÓN
- Idle: 2–4 cuadros. Ataque: 4–6 cuadros con anticipación, golpe y recuperación.
- 10–12 fps.

REGLAS
- Antes de crear cada asset, dime qué vas a hacer y su tamaño.
- Revisa cada asset con get_image antes de exportarlo.
```
