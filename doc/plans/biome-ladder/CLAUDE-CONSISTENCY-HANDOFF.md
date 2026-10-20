# Claude — independently review B22

Start at http://localhost:3003/biome-plan/consistency.html . Read CONSISTENCY.md and consistency-evidence.json in this folder. Forces is deliberately not built; review the first six stages before expansion.

## Changed runtime files

- `commons/hazards/biome_ladder/ladder_encounter.gd`
- `commons/hazards/biome_ladder/ladder_skull.gd`
- `commons/hazards/biome_ladder/ladder_ball.gd`
- `commons/hazards/biome_ladder/array_path.gd`
- `commons/hazards/biome_ladder/path_cue.gdshader`
- `commons/hazards/biome_ladder/path_cue.gdshader.uid`
- `commons/hazards/biome_ladder/change_ball.gd`

`consistency-runtime.patch` is the exact runtime diff from the pre-B22 snapshots. Verify source hashes before comparing with a later checkout.

## Fresh Godot captures

- consistency-before-row-warning.png / consistency-after-row-warning.png — same standing camera and announced row.
- consistency-before-column-warning.png / consistency-after-column-warning.png — same standing camera and announced column.
- consistency-after-prepared-and-running.png — Tiling floor edits kept when combat starts.
- consistency-after-landing-path.png — the additional floor landing shown in the announced list, elevated view.
- consistency-after-skull-floor-landing.png — actual coloured receiver after missed shots.
- consistency-before-stage-0.png through consistency-before-stage-5.png and matching after-stage files — six-stage arrival comparison.

## Your independent checks

1. Rerun state continuity through START, REST, RESUME, CLEAR and RESET. Floor edits, vacancies, damage and consumed pickups should survive starting/resuming; only RESET restores them. Windups restart safely; the next row/column is selected.
2. Rerun your missed-shot, floor-paint and clutter cases. The runtime now includes an announced sixth landing entry and local-bound retirement. Do not remove a meaningful failing expectation just to get a pass; distinguish stale assumptions from regressions.
3. Inspect bright upcoming paths versus dimmer flight paths from a standing viewpoint. Does the near-eye fade stay comfortable? Does the end-on column warning read? Does the added landing create an unfair second contact while sidestepping?
4. Verify cover still matters and Change still samples one target with no continuous homing. Check both outer zigzags and centre field shots.
5. Report one most useful improvement per stage: what returns, what is new, what the player can perceive and use. Keep code correctness, screenshot evidence and headset questions separate.

Codex's results are in CONSISTENCY.md. Your review and probes remain yours; do not change the runtime, book or stage order. Append your findings to CLAUDE-REVIEW.md. Console placement, hand-glow dominance, physical headset play and the older Flow_Field cleanup errors remain open. This file is the shared handoff, not a claim that Claude has already reviewed or received a forum message.
