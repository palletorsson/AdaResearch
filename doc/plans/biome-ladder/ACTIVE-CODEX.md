# Current Codex work

## B22 - state and readability complete; independent review next

START/RESUME preserves floor edits, vacancies, health and consumed pickups. REST clears shots/warnings; RESET restores the encounter; CLEAR requires explicit RESET. Upcoming paths are bright 4 cm tubes with near-eye fade; flight guides are dimmer. The original zigzag adds an announced floor landing; exact collision paints the receiver. Finite paths and local arena bounds retire missed balls and their drawings. Change's centre-column motion is unchanged; outer columns inherit landings. Six stages, no Forces expansion.

New native consistency checks 104/104; stage 80/80, Arrays 141/141, Change 36/36, Colour 40/40, desktop 61/61, controlled XR/skull 127/127, Tiling access 25/25. All exit 0 without script errors; existing ObjectDB warnings remain. Final Colour probe was updated for START retention, the announced landing cell, and enough time for the longer flight. Fresh standing before/after captures plus an elevated landing view: consistency.html. Exact diff, source hashes and task: CONSISTENCY.md / CLAUDE-CONSISTENCY-HANDOFF.md. Claude-owned files untouched. Forces waits for Claude's review; headset acceptance, entrance console/glow composition and older Flow_Field cleanup remain open.


## B20/B21 - Tiling and Change completed

Tiling now flashes all 18 matching copies for 1.15 seconds. Desktop and XR bodies walk the continuous backing; shots still hit exact transformed tile colliders. Collision exceptions are removed before stage disposal. The probe reproduces the old obstruction, then walks to all 14 controls with the fix.

Six stages now: Change's centre-column balls follow tile arrows for 1.4 seconds, sample one player position, signal for 0.9 seconds, then commit to a straight line. Outer columns keep the stored zigzag. Flow_Field has the biome entry; MUSEUM leads into Forces / Vectors_Act1_WhatAVectorIs. Existing tile abilities return. Acceleration is reserved for Forces. No book text edits.

Evidence: Tiling feedback 25/25; Change 36/36; six-stage 80/80; Arrays 140/140; Tiling impacts 33/33; desktop 61/61; controlled XR 127/127. Standalone processes exit 0 with existing shutdown warnings. Museum entry/dispatch 8/8 passes, but the older NOC Flow_Field artifact reports freed-object errors during cleanup. Physical headset and full updated route acceptance remain open. See change.html, CHANGE.md and change-evidence.json.

Claude's probe/review files and Palle's authored changes arrays remain untouched. Claude can update its old three-head/five-stage assumptions and independently assess readability and route safety. Forces is the next unbuilt stage.

## B19 - Arrays implemented and checked

Palle's standing 3 x 3 array is built: persistent row/column addresses, falling vacancies, row then column volleys, a shared stored zigzag list for warning and flight. Colour and Tiling inherit it. Taller, wider entry refuge preserves protection from all nine slots. See [Arrays report and captures](arrays.html), [ARRAYS.md](ARRAYS.md) and arrays-evidence.json for the tested source hashes.

Native checks: 140/140 array/path/cover, 54/54 desktop, 33/33 Tiling and 106/106 controlled XR input/fall; base five-stage checks 67/67 headless. All exit 0. Existing shutdown cleanup warnings remain. Physical headset acceptance and Claude's Tiling console-reach issue remain open. No new stage unlocked; book texts unchanged. Claude-owned probes/review and Palle's SCAFFOLD.json changes remain untouched.

## B18 — changes only, editable by Palle

`/biome-plan/scaffold.html#route` now shows a concise list per sequence with add, edit, remove, save and Markdown download. `/api/biome-plan` in ada_encyclopedia saves only the `changes` arrays in this repository's `SCAFFOLD.json`, with revision conflict protection and backups in `history/scaffold-*.json`. User edits are the working change list; preserve them when regenerating or expanding the background proposal. The publisher now retains the detailed review at `scaffold-detail.html`. The live editor reads the current JSON on load; detailed reports are publication snapshots.

Verified browser add/save/reload/remove, stale-revision rejection (409), unknown-sequence rejection (400), and preservation of the clean plan. No runtime changes. ESLint could not run because the site has no ESLint configuration; the API compiled and the live persistence checks passed.

2026-10-13. Claude is independently reviewing the five-stage ladder. Keep CLAUDE-REVIEW.md and Claude's probes under Claude's ownership.

Palle reports: shots visibly hit a ladder skull, but it does not break or fall. Codex is investigating the actual tracked-trigger → projectile → skull → falling-body path, including READY, PLAY and REST. Owned fix files: `commons/hazards/biome_ladder/ladder_skull.gd`, the three floor-hit type guards in `ladder_encounter.gd`, a new `tools/probes/biome_ladder_skull_hits.gd`, and the fix report. Do not overlap those edits.

Change remains the next sequence. Its implementation has not started; resolve this play-blocking feedback first. Existing stage code and source evidence will be identified in the fix report so Claude can distinguish the reviewed version from the corrected version.

## Result

B16 is complete: 106/106 controlled XR input/physics checks, 54/54 desktop and 33/33 Tiling regressions, all exit 0. See SKULL-HITS.md and the planning page #skull. Ready for Palle to retest in the headset after restart. Change remains queued; it has no runtime edits yet.

## B17 — whole-spine reuse scaffold

Palle asked to look back at the existing biome ladder and scaffold a larger share of the sequence. Source review and planning only: `SCAFFOLD.json` is the editable 25-sequence record; `SCAFFOLD.md` and `scaffold.html` are generated by `tools/publish_biome_scaffold.py`. No runtime, tutorial or final.md edits in this task. All 25 canonical sequences are represented; all 56 referenced source files exist and are hashed in `scaffold-audit.json`. This is structural evidence, not new gameplay validation.

The older BiomeGrammar/vocabulary, BiomeObject generation 17, retained panels in biome_inheritance, and walkgrid surfaces are the main reuse seams. Some older layers are only displays; numeric legacy gates differ from current spine order, and Shaders lacks a vocabulary entry. Do not wire the old accrual stack wholesale into the arena.

Next implementation priority from Claude's latest route review: Tiling's transformed slab obstructs desktop access to three controls. Then a small surface/state adapter; then Change through Noise, one stage at a time. Change uses prescribed velocity, while Forces introduces carried velocity, acceleration and mass. The plan proposes carrying player floor edits on NEXT STAGE; that persistence is not built or implicitly approved by publishing the plan. Keep Claude's review/probes untouched.
