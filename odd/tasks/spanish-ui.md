# Spanish UI

Translate every player-facing text of the game to Spanish; code, docs and dev logs stay English.

## Specs

- S1 "traduce todo a espanol, el publico objetivo es espanoil"
- S2 Every on-screen text is Spanish: HUD, tab bar, skills, spirits, upgrades, ascension panel and its confirmation dialog, offline-reward toast, skill/spirit/talent names (catalog `.tres` and their generators).
- S3 Spanish for Spain-friendly neutral reading: "tú", no voseo; decimal comma (`1,23K`, `1,50/s`, `5,5%`).
- S4 Texts fit their controls at 720x1280 portrait and 1600x900 landscape (screenshots).

## Glossary

| English | Español |
|---|---|
| Upgrades / Spirits / Ascension / Skills | Mejoras / Espíritus / Ascensión / Habilidades |
| Attack / Health / Crit Chance / Crit Damage / Attack Speed | Ataque / Vida / Prob. crítico / Daño crítico / Vel. ataque |
| Lv / Max / Up | Nv / Máx / Mejorar |
| Stage / Gold / BOSS | Etapa / Oro / JEFE |
| Auto-cast | Automático |
| Shards / Ascensions / Ascend / Needs / Close | Fragmentos / Ascensiones / Ascender / Requiere / Cerrar |
| Thunder, Meteor, Blizzard, Fury, Shield | Trueno, Meteoro, Ventisca, Furia, Escudo |
| Wisp, Ember Fox, Frost Owl | Fuego fatuo, Zorro ígneo, Búho de escarcha |
| Might, Vitality, Greed, Precision, Ferocity, Haste | Poder, Vitalidad, Codicia, Precisión, Ferocidad, Celeridad |

## Tasks

- [ ] T1 S1-S3 translate texts + decimal comma, tests RED then GREEN — inline — commit:
- [ ] T2 S4 portrait + landscape screenshots, fix overflows — inline — commit:

## Log

- L1 (user, verbatim): "hagamos 2 cosas\n\n1. traduce todo a espanol, el publico objetivo es espanoil\n2. yo ya tengo soundcraft descargado, necesitas un mcp activo dentro del programa? dime como hacerlo para avisarte"
- L2 Decisions (auto mode, reversible): direct translation, no `tr()`/CSV localization layer (single Spanish audience; migrate later if English is wanted); neutral "tú" Spanish; decimal comma; dev report/log prints stay English.
