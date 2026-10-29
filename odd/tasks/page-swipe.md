# Page swipe (portrait)

Swipe left/right over the portrait pages to move between Upgrades and Spirits,
kept in sync with the bottom tab bar.

## Specs

- S1 Swipe between the portrait pages (Upgrades <-> Spirits) in main/main.gd's Pages ScrollContainer/PageStack, synced with BottomTabBar.select (approved next step: "si pero en una proxima sesion").
- S2 Swipe left goes to the next page, swipe right to the previous one; no wrap and never into Ascension (an overlay, not a page).
- S3 Only a clear horizontal swipe counts (long enough, mostly horizontal) that starts on the pages; vertical drags keep scrolling the page; landscape and an open Ascension overlay ignore swipes.
- S4 A swipe never presses the button it ends on (the release is consumed).

## Tasks

- [x] T1 S1-S4 Main swipe handling + tests in tests/unit/main/test_main_layout.gd, README line, screenshot — inline — commit: 3a1843c

## Log

- L1 (user, verbatim): "retoma la anterior sesión" — resumed after tab-icons (closed, pushed at 2e8d4d4); its approved next step was swiping between the portrait pages.
- L2 Decision (auto mode, reversible): threshold 120 px in the 720 px wide canvas, horizontal distance at least twice the vertical one, measured from press to release of the left mouse button (touch reaches it through the default mouse emulation). Tested by feeding events to Main._input, since simulated input does not reach controls under GUT.
- L3 T1: Main.handle_swipe (run by _input, which marks the release handled) + static Main.swipe_target; 6 tests in test_main_layout.gd RED (missing API, then missing handler) then GREEN; suite 448/448. Viewport.is_input_handled() stays true outside input processing, so the tests read handle_swipe's return instead.
- L4 In-game check (client/.tmp/swipe_shot.gd, real events through Input.parse_input_event, scratch save, --no-cloud) found a bug the unit tests could not see: the swipe changed the page AND bought Attack. Hiding the page makes Viewport drop the mouse focus with a synthetic release, which presses the held button even though the real release was consumed. Fix: before switching, Main._cancel_page_presses toggles disabled on every page button (clears its pending press). After the fix: tap buys (level 0->1), left swipe that starts and ends on the buy button shows Spirits and buys nothing, right swipe returns to Upgrades, a later tap buys again (1->2). Screenshot 720x1280: Spirits page, Spirits tab gold. Assess (base 2e8d4d4, committedOnly): medium, no verifier, no review due (native unassessable: untracked .vscode/ and client/.mcp.json). S1-S4 covered. Feature closed. Not checked: a real touch device.
