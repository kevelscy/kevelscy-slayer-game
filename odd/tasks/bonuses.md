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

- [x] T1 S4 S10 gold coin icon (art/icons/coin.png) shown in the HUD gold counter and stat upgrade costs — inline — commit: c91770d
- [x] T2 S5 skill card: icon fills the card, title over the bottom, radial clock cooldown mask instead of seconds — inline — commit: 39a7a5f
- [x] T3 S6 random waves of up to 6 enemies, tight or spread, +25% health and gold — inline — commit: c3f4325
- [x] T4 S7 S9 S4 skills bought and leveled with gold, kept on ascension, saved (backward-compatible save) — inline — commit: 78f4d4f, 52517c9
- [ ] T5 S8 S10 wind skill: dash-stab to the nearest enemy, icon, catalog entry — inline — commit:
- [ ] T6 S1 S2 S3 chest core: drop roll, rarity table, rewards, gold multiplier rule, tests — inline — commit:
- [ ] T7 S1 S3 S10 chest pickup in the lane, roulette overlay, chest and reward icons — inline — commit:

## Log

- L1 (user) "vale, hay que pensar en bonificaciones, ya me quedeje jugando un buen rato y llega un punto donde te quedas estancado porque las habilidades ahora cuesta mas subirlas con oro ya despues de la etapa 30 y dejando el juego por 1 hora llega hasta 48 aprox y ya luego es dificl conseguir mas oro para solo subir un 1 punto de habilidad / asi que en base aa esto hay que pensar en bonificadores... / quiero que aplquemos algunas ideas del megabonk, como cofres que el personaje va recogiendo y que sea como una ruleta donde va cambiado rapido los iconos de las recompensas que te pueden tocar / te puede tocar aumentadores de XP x 2  o x4 o x6 o x8 o x10 / podemos tener recompensas categorizadas, tipo Comun, Raro, Epico, Legendario, Super o algo asi / estas recompensas salen de los enemigos de forma random, y tiene X probabilidades por cada tipo de categfotia de recompensa, asi como megabonk / --- / tambien haz la illustracion de una moneda para el oro y tambin lo reusas al lado de los costos de habilidades, para que se entienda que subir una habilidad cuesta X de Oro / --- / otra cosa, las ilustraciones de las habilidades no quiero que sean asi com oestan actualmente: [imagen] [titulo] [segundos de couldown] quiero que el cuadro completo este integrado la imagen de fondo  y encima en la parte inferior de la imagen el titulo y el coldown no lo reflejes con segundos reflejalo con un tipo de mascara encima de la imagen que sea tipo reloj, es decir cuando la habildiad se use se pone todo en gris y de inmediato hay una mascara encima que va quitando ese gris como un reloj / --- / otra cosa haz que de forma aleatorea pueda haber mas enemigos en pantalla, es decir una oleada de 6 de una y pegados o no, que sea random, pero aplicales un poquito mas / --- / otra cosa, permite que se desbloqueen habilidades en ciertas etapas y que se puedan comprar y se guarden, hay una que quiero que agregues que es de tipo viento y esta lo que hace es que cuando se activo, el personaje se lanza al enemigo mas cercano como una estocada con la espada y le hace dano, el coldown es mas rapido, pero hace un poco menos de dano que el trueno / --- / lo otro que quiero es que las habilidades se puedan subir de nivel poco a poco, para que las mejoras no sol osean de puntops de ataque y eso, sino tambien las habilidades / luego haremos que despues de cada 10 etapas cambie el mapa"
- L2 (user answers) XP: "Ambos: oro ahora, XP después"; chests: "Sí, usá la propuesta"; skills: "Oro, y se conservan al ascender"; waves: "Un poco más de vida y de oro".
- L3 Plan: T2 and T3 run as parallel background workers (disjoint surfaces: skill card UI vs spawning/world); T1 coin art inline meanwhile. T4 waits for T2 (same panel), T6 for T3 (both touch GameSession gold).
- L4 Both background workers (T2 mvvpc725-1-i3ak, T3 mvvpc72c-2-pxnh) failed at start with "assistant reported an error" (0 tool calls, nothing written). Not retried: T2 and T3 move inline, done sequentially after T1.
- L5 T1 coin.png 16x16 (164 px, palette-only, no semi-transparent px), coin.pxo; GameTheme.coin_texture(32) nearest 2x; HUD GoldIcon + amount without "Oro"; upgrade buttons coin on the right, none on Máx. RED (parse error, missing API) → GREEN 490/490. Screenshot .tmp/shot/coin_240.png.
- L6 (user) "para, se acaba la ventana de contexto, guarda todo en engram status actual y pendientes, retomamos en la siguiente sesion". T2 state: code done, UNCOMMITTED (client/ui/panels/skill_card.gd new, ability_panel.gd, tests/unit/ui/test_ability_panel.gd); RED (SkillCard missing) → GREEN 489/489; screenshots .tmp/shot/card_240.png, card_400.png (+ _crop) taken but NOT reviewed yet.
- L7 Resume (2026-10-30): card_400_crop.png reviewed (icon fills the 96x96 card, title band over the bottom, no seconds); suite 489/489; T2 committed 39a7a5f.
- L8 T3: SpawnScheduler Order.WAVE (WAVE_SIZE 6, wave_roll < wave_chance on a due regular spawn, not at cap or with a boss alive); GameSession WAVE_CHANCE 0.08, WAVE_HEALTH/GOLD_MULTIPLIER 1.25, on_enemy_killed(was_boss, gold_multiplier = 1.0); BattleWorld._spawn_wave tight (20 px) or spread (36-80 px) at random; Enemy.gold_multiplier. Offline gold unchanged (waves are online only). RED (missing API) → GREEN 499/499.
- L9 T4 core: 78f4d4f (save format + server contract, own commit). SkillSlot.level (0 = not bought), can_buy(stage) (first level needs unlock_stage, later levels any stage), cost() = base_cost * cost_growth^level, is_ready() = owned and cooled; SkillBar.try_cast(slot, has_target) (stage param dropped), try_buy, levels/set_levels/level_of, grant_reached, signal leveled_up; SkillDefinition LEVEL_POWER_STEP 0.15, power_at(level), base_cost (thunder 30, meteor 150, blizzard 300, fury 600, shield 1200), cost_growth 1.35; GameSession.try_buy_skill, skill power by level, levels kept on ascend; SaveCodec VERSION 4 with `skills` object, SaveData.has_skill_levels false for v1-3 → apply_save grants level 1 to skills the saved stage reached. Server migration 20261030120000_save_skill_levels.sql (accepts v3 and v4, v4 requires skills, save_version = pushed version), applied locally with `supabase migration up`; pgTAP 45/45; client 516/516. gentle_review assess: native medium, reviewDue false (no review, no verifier).
- L10 T4 UI (UNCOMMITTED, GREEN 521/521): ability_panel.gd buy_buttons (BuyButton, coin 20 px right, cost text, disabled without gold or before stage), column card + buy; skill_card.gd level_label "Nv N" top-left, show_unowned(title). Screenshot NOT taken yet. Note: coin 16 px resized to 20 px is a non-integer nearest scale (uneven pixels) — consider 16 or 32.
- L11 (user) "para, se acaba la ventana de contexto, guarda todo en engram status actual y pendientes, retomamos en la siguiente sesion".
- L12 Resume (2026-10-30): buy coin set to 16 px (native, integer scale) instead of 20; suite 521/521; screenshot .tmp/shot/t4_400.png (save v4, stage 12, thunder 3, meteor 1) reviewed: level badge, clock mask, greyed unowned cards with titles, buy buttons with cost + coin (thunder 73 = 30*1.35^3).
