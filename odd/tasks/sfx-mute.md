# Sound effects mute button

A speaker button in the HUD mutes and unmutes the sound effects (the `SFX` bus). The choice is
kept in a local settings file next to the save, never synced to the cloud.

## Specs

- S1 The user chose (verbatim option): "Botón altavoz en el HUD (Recomendado)" — "Un ícono pixel-art de altavoz en una esquina del HUD; un toque silencia/activa. Se guarda localmente (user://settings.cfg), no en la nube."
- S2 Art rule (client/art/STYLE.md, verbatim): "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S3 The settings file sits next to the save (`settings.cfg` in the save's folder, so scratch saves get their own); a missing or unreadable file means sound on.
- S4 One tap on the button toggles the `SFX` bus mute, the icon shows the current state (speaker with waves = on, speaker with a cross = off), and the choice survives a restart.

## Tasks

- [x] T1 S1,S3,S4 `SettingsStore` (ConfigFile) + `GameState.settings` + `SfxPlayer.set_muted`, tests RED then GREEN — inline — commit: 4033a01
- [x] T2 S2 icons `sound_on.png` and `sound_off.png` 24x24 in Pixelorama (`.pxo` sources) — inline — commit: ab38b13
- [x] T3 S1,S4 HUD speaker button wired from `Main`, tests, screenshot, docs — inline — commit: dc2a20c

## Log

- L1 (user, verbatim): "a todos bajale un poco, especialmente Fury, meteor, asscension / sigue con los pendientes" — volumes lowered 3 dB (6 dB for fury, meteor, ascension) in de4b176 before this feature.
- L2 (user) chose "Botón altavoz en el HUD (Recomendado)" for the mute control and "Ignorar ambos (Recomendado)" for the untracked `.vscode/` and `client/.mcp.json` (ignored in the commit after de4b176).
- L3 T1 (4033a01): `SettingsStore` (ConfigFile `[audio] sfx_muted`; missing, unreadable or non-boolean = sound on; loading never creates the file), `GameState.settings` at `settings_path(save_path)` = `settings.cfg` next to the save, applied with `SfxPlayer.set_muted` at boot; `GameState.set_sfx_muted` saves and applies. Tests RED then GREEN; suite 482/482.
- L4 T2 (ab38b13): announced "sound_on.png 24x24 speaker with two waves, sound_off.png 24x24 speaker with a red cross". Generator client/.tmp/sound_icons.py (first preview: waves merged with the cone, cross too thin; respaced the waves, 2 px cross). Drawn in Pixelorama, reviewed with get_image, `.pxo` saved, PNG exported: 206/192 painted px as the generator, palette-only, no semi-transparent px; import settings equal to the tab icons.
- L5 T3 (dc2a20c): `Hud.sound_button` (toggle, pressed = muted, 64x56, no focus, icon at 2x, tooltip "Silenciar efectos"/"Activar efectos"), `Hud.show_sfx_muted` (silent) and `sfx_muted_toggled` -> `GameState.set_sfx_muted` from `Main`. Tests through Main RED then GREEN; suite 486/486. Screenshots (scratch save, --no-cloud): 720x1280 speaker at the HUD top-right, tap shows the cross and writes `sfx_muted=true`; 1600x900 next to Ascensión. README, STYLE.md (audio is .wav) and ASSETS.md updated. S1-S4 covered. Feature CLOSED.
