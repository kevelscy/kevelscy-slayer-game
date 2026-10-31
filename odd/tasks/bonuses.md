# Bonuses: chests, buyable skill levels, waves, wind skill, gold coin

Break the post-stage-30 gold wall with Megabonk-style chest drops and a reward roulette, let skills be
bought and leveled with gold, add random enemy waves and a wind dash skill, and give gold a coin icon.

## Specs

- S1 Chests: "quiero que aplquemos algunas ideas del megabonk, como cofres que el personaje va recogiendo y que sea como una ruleta donde va cambiado rapido los iconos de las recompensas que te pueden tocar". Approved proposal: "Cofre: 4% por enemigo, 100% por jefe" / "El héroe lo recoge al pasar → ruleta ~2 s" / "Offline no hay cofres."
- S2 Multipliers: "te puede tocar aumentadores de XP x 2  o x4 o x6 o x8 o x10". Decision (L2): "Ambos: oro ahora, XP después" — chests multiply gold now; hero XP is a later feature, out of scope here. Approved rule: "Un multiplicador nuevo reemplaza al activo si es mayor; si es igual, suma tiempo."
- S3 Rarities: "podemos tener recompensas categorizadas, tipo Comun, Raro, Epico, Legendario, Super o algo asi" / "estas recompensas salen de los enemigos de forma random, y tiene X probabilidades por cada tipo de categfotia de recompensa, asi como megabonk". Approved table, verbatim:

  ```
  Rareza      Prob.  Recompensas posibles
  Común       55%    oro x2 60s | bolsa de oro
  Raro        27%    oro x4 60s | Furia gratis
  Épico       12%    oro x6 90s | recarga habilidades
  Legendario   5%    oro x8 120s | bolsa grande
  Super        1%    oro x10 180s | +1 nivel habilidad
  ```

- S4 Coin: "tambien haz la illustracion de una moneda para el oro y tambin lo reusas al lado de los costos de habilidades, para que se entienda que subir una habilidad cuesta X de Oro". Every gold amount (HUD counter, stat upgrade costs, skill buy and level costs) shows the coin.
- S5 Skill card: "las ilustraciones de las habilidades no quiero que sean asi com oestan actualmente: [imagen] [titulo] [segundos de couldown]" / "quiero que el cuadro completo este integrado la imagen de fondo  y encima en la parte inferior de la imagen el titulo y el coldown no lo reflejes con segundos reflejalo con un tipo de mascara encima de la imagen que sea tipo reloj, es decir cuando la habildiad se use se pone todo en gris y de inmediato hay una mascara encima que va quitando ese gris como un reloj"
- S6 Waves: "haz que de forma aleatorea pueda haber mas enemigos en pantalla, es decir una oleada de 6 de una y pegados o no, que sea random, pero aplicales un poquito mas". Decision (L2): "Un poco más de vida y de oro" — wave enemies get about +25% health and +25% gold.
- S7 Skill unlock and purchase: "permite que se desbloqueen habilidades en ciertas etapas y que se puedan comprar y se guarden". Decision (L2): "Oro, y se conservan al ascender" — reaching the stage makes a skill buyable, gold buys it, purchases and levels are permanent and saved. Existing saves keep working.
- S8 Wind skill: "hay una que quiero que agregues que es de tipo viento y esta lo que hace es que cuando se activo, el personaje se lanza al enemigo mas cercano como una estocada con la espada y le hace dano, el coldown es mas rapido, pero hace un poco menos de dano que el trueno"
- S9 Skill levels: "lo otro que quiero es que las habilidades se puedan subir de nivel poco a poco, para que las mejoras no sol osean de puntops de ataque y eso, sino tambien las habilidades"
- S10 Art follows `client/art/STYLE.md` (palette `paleta_juego.gpl` only, 1 px dark outline, light top-left, UI silver frames, gold for rare); before each asset say what and its size; review with get_image before export; report files and dimensions; Godot Nearest, no mipmaps.

Out of scope (L1/L2): map change every 10 stages ("luego haremos"), hero XP, iPhone build.

## Tasks

- [ ] T1 S4 S10 gold coin icon (art/icons/coin.png) shown in the HUD gold counter and stat upgrade costs — inline — commit:
- [ ] T2 S5 skill card: icon fills the card, title over the bottom, radial clock cooldown mask instead of seconds — inline — commit:
- [ ] T3 S6 random waves of up to 6 enemies, tight or spread, +25% health and gold — inline — commit:
- [ ] T4 S7 S9 S4 skills bought and leveled with gold, kept on ascension, saved (backward-compatible save) — inline — commit:
- [ ] T5 S8 S10 wind skill: dash-stab to the nearest enemy, icon, catalog entry — inline — commit:
- [ ] T6 S1 S2 S3 chest core: drop roll, rarity table, rewards, gold multiplier rule, tests — inline — commit:
- [ ] T7 S1 S3 S10 chest pickup in the lane, roulette overlay, chest and reward icons — inline — commit:

## Log

- L1 (user) "vale, hay que pensar en bonificaciones, ya me quedeje jugando un buen rato y llega un punto donde te quedas estancado porque las habilidades ahora cuesta mas subirlas con oro ya despues de la etapa 30 y dejando el juego por 1 hora llega hasta 48 aprox y ya luego es dificl conseguir mas oro para solo subir un 1 punto de habilidad / asi que en base aa esto hay que pensar en bonificadores... / quiero que aplquemos algunas ideas del megabonk, como cofres que el personaje va recogiendo y que sea como una ruleta donde va cambiado rapido los iconos de las recompensas que te pueden tocar / te puede tocar aumentadores de XP x 2  o x4 o x6 o x8 o x10 / podemos tener recompensas categorizadas, tipo Comun, Raro, Epico, Legendario, Super o algo asi / estas recompensas salen de los enemigos de forma random, y tiene X probabilidades por cada tipo de categfotia de recompensa, asi como megabonk / --- / tambien haz la illustracion de una moneda para el oro y tambin lo reusas al lado de los costos de habilidades, para que se entienda que subir una habilidad cuesta X de Oro / --- / otra cosa, las ilustraciones de las habilidades no quiero que sean asi com oestan actualmente: [imagen] [titulo] [segundos de couldown] quiero que el cuadro completo este integrado la imagen de fondo  y encima en la parte inferior de la imagen el titulo y el coldown no lo reflejes con segundos reflejalo con un tipo de mascara encima de la imagen que sea tipo reloj, es decir cuando la habildiad se use se pone todo en gris y de inmediato hay una mascara encima que va quitando ese gris como un reloj / --- / otra cosa haz que de forma aleatorea pueda haber mas enemigos en pantalla, es decir una oleada de 6 de una y pegados o no, que sea random, pero aplicales un poquito mas / --- / otra cosa, permite que se desbloqueen habilidades en ciertas etapas y que se puedan comprar y se guarden, hay una que quiero que agregues que es de tipo viento y esta lo que hace es que cuando se activo, el personaje se lanza al enemigo mas cercano como una estocada con la espada y le hace dano, el coldown es mas rapido, pero hace un poco menos de dano que el trueno / --- / lo otro que quiero es que las habilidades se puedan subir de nivel poco a poco, para que las mejoras no sol osean de puntops de ataque y eso, sino tambien las habilidades / luego haremos que despues de cada 10 etapas cambie el mapa"
- L2 (user answers) XP: "Ambos: oro ahora, XP después"; chests: "Sí, usá la propuesta"; skills: "Oro, y se conservan al ascender"; waves: "Un poco más de vida y de oro".
- L3 Plan: T2 and T3 run as parallel background workers (disjoint surfaces: skill card UI vs spawning/world); T1 coin art inline meanwhile. T4 waits for T2 (same panel), T6 for T3 (both touch GameSession gold).
- L4 Both background workers (T2 mvvpc725-1-i3ak, T3 mvvpc72c-2-pxnh) failed at start with "assistant reported an error" (0 tool calls, nothing written). Not retried: T2 and T3 move inline, done sequentially after T1.
