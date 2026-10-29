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

- [x] T1 S1-S3 translate texts + decimal comma, tests RED then GREEN — inline — commit: f3ea07c
- [x] T2 S4 portrait + landscape screenshots, fix overflows — inline — commit: f3ea07c

## Log

- L1 (user, verbatim): "hagamos 2 cosas\n\n1. traduce todo a espanol, el publico objetivo es espanoil\n2. yo ya tengo soundcraft descargado, necesitas un mcp activo dentro del programa? dime como hacerlo para avisarte"
- L2 Decisions (auto mode, reversible): direct translation, no `tr()`/CSV localization layer (single Spanish audience; migrate later if English is wanted); neutral "tú" Spanish; decimal comma; dev report/log prints stay English.
- L3 T1: tests changed to the Spanish strings first (27 RED), new tests/unit/main/test_spanish_texts.gd (HUD, JEFE timer with decimal comma, offline toast, section titles, catalog names) and dialog tests in test_ascension_panel.gd; then the code: NumberFormat comma + NumberFormat.decimal, panels, HUD (.gd/.tscn), Main tab titles and toast, catalog .tres hand-edited with their generators kept in sync. Bug caught by the dialog test: `"a" + "b" % x` formats only "b"; fixed with parentheses order. Saves and cloud use ids, never display names, so the save format is unchanged. Suite 455/455.
- L4 T2 screenshots (scratch save, --no-cloud): 720x1280 Mejoras and Espíritus tabs, ascension overlay, 1600x900 landscape: every text fits, accents and ¿¡ render. The confirmation dialog (client/.tmp/dialog_shot.gd) ran off screen with the longer Spanish text, hiding the "Ascender" button: now dialog_autowrap + popup_centered(640, 0) and a deferred reset_size so it hugs its 3 lines; test RED (no autowrap) then GREEN. Landscape "Prob. crítico  Nv 0" reaches the buy button edge but is not clipped. Assess (base ac1fc08, committedOnly): medium, no verifier, no review due. S1-S4 covered. Feature closed.
