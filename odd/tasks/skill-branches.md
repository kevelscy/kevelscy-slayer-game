# Skill branches: cheaper characteristics, Mejoras tabs, equip up to 8, six new skills

The Mejoras page splits into Características (today's upgrades, 30% cheaper) and Habilidades
(every skill by branch, equip up to 8). Six new skills join the six current ones.

## Specs

- S1 Cheaper characteristics: "haz las mejoras un poco mas baratas, para que el usuario no se aburra tanto esperando farmear oro para subir 1 solo punto, quizas un 30% mas baratas aprox". Decision (L2): base cost x0.7 on the five characteristic tracks (Ataque, Vida, Prob. crítico, Daño crítico, Vel. ataque); skill prices do not change.
- S2 Mejoras tabs: "en la secciopn de Mejoras, vas hacer tipo pestana/tabs porque ahora vamos agregar la seccion de caracteristicas, asique vamos aclarar definiciones / todo lo que esta actualmente en mejoras realmente son caracteristicas y uno mejora caracteristicas, y las habilidades podremos ver tooodas las habilidades, las habilitidas y equipadas como las desactivadas en gris, ambas". Tabs: [Características] (today's upgrade list) and [Habilidades].
- S3 Branches: "porque ahora quiero que tengamso una seccion dnode habran un monton de habilidades incluso vayamos categorizando por rama, tipo rama de fuego, electrico, hielo, incremento (como furia), defensivo, aire / categoriza las que ya tenemos." Fuego: Meteoro, Espada Ardiente, Onda de Llamas. Eléctrico: Trueno, Tajo Relámpago. Hielo: Ventisca, Bloque de Hielo. Incremento: Furia, Espada Veloz. Defensivo: Escudo, Curación. Aire: Viento.
- S4 Equip (L2 "Barra de 8 arriba + equipar en la pestaña"): the top carousel shows only the equipped skills (up to 8), and only they cast and autocast. In Mejoras > Habilidades, tapping a bought skill equips or unequips it; a newly bought skill equips itself when a slot is free. Grey = not bought or not equipped. The equipped list is saved; a save without it equips the first 8 bought skills in catalog order.
- S5 Buying (L2 "En ambos lados"): the level button stays under each carousel card and every skill in the Habilidades tab has one too (unequipped ones included).
- S6 New skills (L2 "Usar estos valores"): "y crea 6 habilidades mas"
  - S6.1 "\"Burning Sword\" traducela al espanol, basicamente hace que la espada este en fuego e incremente un 50% los ataques con la espada" -> Espada Ardiente (Fuego), stage 25, 38.400 gold, +50% sword (basic attack) damage for 10 s, cooldown 25 s, the sword burns while active.
  - S6.2 "\"Flame wave\" traducela, es un Getsuga tipo bleach de fuego qe se dispara y avanza todo la escena haciendo dano a los enemigos" -> Onda de Llamas (Fuego), stage 28, 76.800 gold, a fire wave fired from the hero that crosses the whole scene and hits each enemy it reaches for 12x attack, cooldown 16 s.
  - S6.3 "Speed Sword, es aumentar un 40% la velocidad de atauqe" -> Espada Veloz (Incremento), stage 18, 4.800 gold, +40% attack speed for 8 s, cooldown 22 s.
  - S6.4 "Thunderbold Slash, es un trueno pero mas fuerte y greuso este lanza u na rafaga de truenos por 4 segundos de forma constante" -> Tajo Relámpago (Eléctrico), stage 32, 153.600 gold, thick bolts on every enemy for 4 s: 2x attack every 0,4 s, cooldown 24 s.
  - S6.5 "Curacion, es basicamente que el peronaje se cuire un  50% en relacion a su vida maxima a lo largo de 4 segundos" -> Curación (Defensivo), stage 22, 19.200 gold, heals 50% of max health spread over 4 s, cooldown 30 s.
  - S6.6 "Ice stone, lanza un bloque de hielo al primer enemigo que tenga de frente" -> Bloque de Hielo (Hielo), stage 20, 9.600 gold, an ice block thrown at the front enemy for 8x attack, cooldown 10 s.
- S7 Art follows `client/art/STYLE.md` (palette `paleta_juego.gpl` only, 1 px dark outline, light top-left); say what and its size before each asset; review with get_image before export; Godot Nearest, no mipmaps.

## Tasks

- [ ] T1 S1 characteristic base costs x0.7 — inline — commit:
- [ ] T2 S3 S4 skill branches, catalog-wide SkillBar with up to 8 equipped, auto-equip on buy, saved `equipped` field, Furia gratis by id — inline — commit:
- [ ] T3 S2 S4 S5 Mejoras tabs (Características / Habilidades), carousel shows equipped skills only — inline — commit:
- [ ] T4 S2 S3 S4 S5 Habilidades tab: every skill by branch, grey when not bought or not equipped, level button, tap to equip/unequip — inline — commit:
- [ ] T5 S6.3 S6.1 Espada Veloz (attack speed buff) and Espada Ardiente (sword-only damage buff, burning sword) — inline — commit:
- [ ] T6 S6.5 S6.6 Curación (heal over time) and Bloque de Hielo (ice block at the front enemy) — inline — commit:
- [ ] T7 S6.2 S6.4 Onda de Llamas (wave crossing the scene) and Tajo Relámpago (4 s bolt barrage) — inline — commit:
- [ ] T8 S7 six skill icons (silver + gold frame like the current ones) — inline — commit:
- [ ] T9 README, in-game screenshots, close — inline — commit:

## Log

- L1 (user) "vale y a revisnado aplica lo siguiente: / 1. haz las mejoras un poco mas baratas, para que el usuario no se aburra tanto esperando farmear oro para subir 1 solo punto, quizas un 30% mas baratas aprox / 2. en la secciopn de Mejoras, vas hacer tipo pestana/tabs porque ahora vamos agregar la seccion de caracteristicas, asique vamos aclarar definiciones / todo lo que esta actualmente en mejoras realmente son caracteristicas y uno mejora caracteristicas, y las habilidades podremos ver tooodas las habilidades, las habilitidas y equipadas como las desactivadas en gris, ambas / porque ahora quiero que tengamso una seccion dnode habran un monton de habilidades incluso vayamos categorizando por rama, tipo rama de fuego, electrico, hielo, incremento (como furia), defensivo, aire / categoriza las que ya tenemos. / y crea 6 habilidades mas / 1. \"Burning Sword\" traducela al espanol, basicamente hace que la espada este en fuego e incremente un 50% los ataques con la espada / 2. \"Flame wave\" traducela, es un Getsuga tipo bleach de fuego qe se dispara y avanza todo la escena haciendo dano a los enemigos / 3. Speed Sword, es aumentar un 40% la velocidad de atauqe / 4. Thunderbold Slash, es un trueno pero mas fuerte y greuso este lanza u na rafaga de truenos por 4 segundos de forma constante / 5. Curacion, es basicamente que el peronaje se cuire un  50% en relacion a su vida maxima a lo largo de 4 segundos / 6. Ice stone, lanza un bloque de hielo al primer enemigo que tenga de frente"
- L2 (user answers) equip: "Barra de 8 arriba + equipar en la pestaña (Recomendado)"; buying: "En ambos lados (Recomendado)"; new skills: "Usar estos valores (Recomendado)" (names, branches, stages, prices and numbers as in S6; characteristics base cost x0,7).
- L3 Exploration: SkillBar.SLOT_COUNT 6 holds one slot per catalog skill; save v4 stores `skills` levels by id; the server validates known fields only, so an optional `equipped` array (no version bump, no migration) is enough. FREE_FURY picks the first BUFF skill: must pick `fury` by id once Espada Veloz exists. SfxDirector plays skill.id and SfxPlayer errors on unknown sounds: new skills reuse existing sounds (thunder, meteor, blizzard, fury, shield, wind) until SoundCraft ones are made. The catalog is generated by tools/generate_ability_content.gd.
