# Bottom tab bar

Portrait (mobile) gets a bottom tab bar so the panels stop overflowing the screen.
Landscape (PC) keeps its three-column layout.

## Specs

- S1 STYLE.md rule (verbatim): "Barra de pestañas abajo; botones grandes, pensados para el pulgar."
- S2 STYLE.md frame rule for UI: silver frame, gold when selected.
- S3 Plan approved by the user ("si! play!"): portrait keeps HUD, battle and the skill bar (skills + auto-cast) always visible; below them a scrollable page area and a bottom tab bar with Upgrades (default), Spirits and Ascension. Ascension opens the existing overlay; the HUD Ascension button hides in portrait. Landscape stays three columns with no tab bar.
- S4 Nothing is cut off in portrait 720x1280: every upgrade row is reachable (scroll).

## Tasks

- T1 [S3] Split SpiritPanel out of AbilityPanel (same behavior, tests move) — inline — commit: e39422b
- T2 [S1, S2] BottomTabBar component (thumb-sized toggle buttons, one selected, silver/gold) — inline — commit: de06d8c
- T3 [S3, S4] Main portrait wiring: page scroll, tab bar, Ascension tab, HUD button; landscape unchanged; docs — inline — commit: c942732
- T4 [S1-S4] Verify: suite, screenshots 720x1280 and 1600x900, close and push — inline — commit: this docs commit

## Log

- L1 (user, verbatim): "si! play!" — answer to "¿Arranco con la planificación del tab bar?"
- L2 Finding: in portrait 720x1280 the UpgradePanel overflows (Attack Speed row cut off below Crit Damage).
- L3 Decisions (auto mode, reversible): skills stay out of the tabs (combat controls); Ascension stays an overlay opened from its tab; landscape unchanged.
- L4 T1 evidence: RED (SpiritPanel missing), GREEN 426/426, layout test pins spirits under the skills in landscape; screenshots 720x1280 and 1600x900 unchanged. Commit e39422b.
- L5 T2 evidence: RED (BottomTabBar, GameTheme.TAB_BUTTON missing), GREEN 433/433. Simulated mouse taps never reach buttons under the GUT runner (parse_input_event and push_input both failed), so "a tab never unselects itself" is pinned through the ButtonGroup contract (shared group, allow_unpress false). Silver band uses palette Plata #c0ced1 / Acero #929ea6. Commit de06d8c.
- L6 T3 evidence: RED (Main.TAB_* missing), GREEN 439/439. Main portrait: Hud, BattleView, AbilityPanel, Pages (ScrollContainer, vertical auto) > PageStack [UpgradePanel, SpiritPanel], TabBar. Ascension tab opens the overlay and silently reselects the page; HUD Ascension button visible only in landscape; landscape shows both panels and returns to the picked page. README layout lines updated (the old "panel sits under the upgrades" line was already stale). Commit c942732.
- L7 T4 verify: suite 439/439. Screenshots 720x1280: Upgrades tab (HUD no longer clipped, Attack Speed reachable by scroll, S4), Spirits tab, Ascension overlay over the whole screen; 1600x900 landscape unchanged. Scratch shots typed `as Main` failed to compile in a `-s` script (GameState autoload not yet registered); use untyped get/call there. Assess (base 96e10ed, committedOnly): medium, no verifier, no review due (native unassessable: untracked .vscode/ and client/.mcp.json). S1-S4 covered. Feature closed.
