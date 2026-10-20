# Biome ladder — implementation handover

**B22 complete, review next:** [State and readability](consistency.html), [exact Claude handoff](CLAUDE-CONSISTENCY-HANDOFF.md). START/RESUME keeps the current experiment and battle records; REST clears shots; RESET restores them. Visible warning paths, announced floor landings and finite missed shots connect Arrays to Colour. All eight check suites pass; physical headset play remains untested. Forces waits for independent review. This supersedes earlier descriptions of START resetting the floor and five-position-only flight lists.

**B20/B21 complete:** [Tiling fixes and Change](change.html), [CHANGE.md](CHANGE.md). Six stages now. All 14 controls pass the transformed-floor walk test. Matching tiles pulse together. Change adds a field and a one-time announced turn for centre-column balls; outer columns retain zigzags. Entry at Flow_Field, return to Forces. Review limits and current results are in the report; the older NOC Flow_Field cleanup errors remain separate.

**B19:** [Standing array - built](arrays.html). Arrays, Colour and Tiling now have nine persistent addressed places, row/column volleys and stored zigzag paths. Earlier stages retain three heads. Larger entrance refuge shields against the upper row. See [ARRAYS.md](ARRAYS.md) for tests, exact scope and source hashes. No Change stage added. Physical headset playtest and the earlier Tiling console-reach finding remain open.

**B18:** [Changes only](scaffold.html#route) is now the editable list. Add, remove or edit lines and click Save changes. These lists live in `SCAFFOLD.json` under each stage's `changes`; preserve Palle's edits. [Detailed review](scaffold-detail.html#route) remains background. Saving changes only the plan, not gameplay. Verified save/reload and conflict protection.

2026-10-13. Six stages built, through Change. Open `http://localhost:3003/biome-plan/index.html`. Play **Game menu → Biome Ladder**. The existing **Head Arena** still opens the mature generation-17 biome.

**B17 planning pass:** [Whole-spine reuse scaffold](scaffold.html), editable [SCAFFOLD.json](SCAFFOLD.json), full [SCAFFOLD.md](SCAFFOLD.md). All 25 sequences mapped against existing sources; only the five current route stages are playable. Next suggested group is Change through Noise, after the post-Tiling control-reach obstruction in Claude's latest route review is repaired. No runtime or book changes in B17. See ACTIVE-CODEX.md for the precise scope.

## What exists

- `commons/hazards/biome_ladder/route.gd`: stage order and exact museum boundary addresses.
- `ladder_world.tscn`, `ladder_world.gd`: shared XR/player staging, stage selection, onward route.
- `ladder_encounter.gd`: 12 × 24 m world, primitive cover, motion, pickups, disco floor, controls, three-hit player health.
- `ladder_skull.gd`, `ladder_ball.gd`: stationary/moving monochrome heads, one-hit falling defeat, small slow shots, bounded scale and colour trails.
- `museum_entry.gd`: reachable entry controls at the five final halls. Original passages remain available.
- Narrow hooks in `commons/scenes/endless_museum.gd` and `commons/scenes/main_menu/MainMenu3D.{gd,tscn}`. Existing `catalyst_counterpart/biome_arena.gd` shares its player preparation with the ladder.

All abbreviated paths above are inside `commons/hazards/biome_ladder/`. The user's working tree contains extensive other work; do not reset, stage or rewrite it wholesale.

## Evidence

- **B16 skull-hit fix.** READY and REST no longer make visible ladder skulls invulnerable. One hit defeats them and the normal physics loop drops them. Floor callbacks ignore non-static bodies before typed tile lookup. Controlled XRServer poses and trigger input → real projectile → actual fall: **106/106**, exit 0. See SKULL-HITS.md and `ada_run/biome_ladder_skull_hits/`. Requires restarting the game or rebuilding a standalone Quest installation. This does not certify physical headset feel.

- **B15 implemented: Tiling.** `TILING.md` records the source/copy rule and native captures. One catalyst tile hit repeats its ×0.8 scale, +22.5° turn and tint on the matching 18 tiles in a 2 × 2 motif. Other motif addresses stay independent. Head balls retain local paint. Fifth console stage and museum entry after Ribbon_Patterns_03 lead onward to Change_Intro. The rendered pattern probe uses real viewport clicks and projectile collisions; see `ada_run/biome_tiling_floor/report.json`. Results: 33/33 pattern, 90/90 earlier tiles, 67/67 five-stage and 54/54 desktop checks pass; all exit 0. The new museum entry passes 8/8 but the broader museum emits freed-object cleanup errors after the checks; see TILING.md. Stage buttons defer replacement until the press event finishes. Floor state survives REST, clears on RESET/new START or stage exit.

- **B14 implemented: cumulative tiles.** Arrays and Colour now retain Transformation’s ×0.8 scale and +22.5° rotation per catalyst hit. Colour recolours that same actual tile. All three stages have individual tile colliders and solid backing; gap impacts cannot affect the old footprint. `biome_transform_tiles.gd` expanded to 90/90 rendered checks, exit 0. Native Arrays/Colour captures in `ada_run/biome_transform_tiles/`. See TRANSFORMATION-TILES.md. Colour 40/40, cover 82/82 and desktop 47/47 also pass after B14, all exit 0.

- **B13 implemented.** Transformation tiles multiply scale by 0.8 and turn +22.5° around Y per catalyst hit, including repeated hits. Each collider follows its tile; a solid backing prevents holes. REST keeps the arrangement, RESET/new START restores it. `tools/probes/biome_transform_tiles.gd`: 36/36 rendered checks, exit 0. Report and native captures: `ada_run/biome_transform_tiles/`; scope: TRANSFORMATION-TILES.md. Cover 82/82, Colour 40/40 and desktop 47/47 regressions also rerun, all exit 0.

- **B12 implemented.** COLOUR.md records tile-colour persistence from real catalyst and skull projectiles. New probe: `tools/probes/biome_colour_floor.gd`, 40/40 rendered checks, exit 0. Native captures: `ada_run/biome_colour_floor/`. Stage 54/54 and desktop 47/47 regressions rerun after B12, both exit 0; logs in the same folder. Marks survive REST and clear on RESET/new START; no persistence across sessions. See TERRAIN-LINEAGE.md for Palle's agreed later floor progression (Waves → Randomness → Noise), not yet built.

- **B11 implemented.** TRANSFORMATION.md records the scope and results. Tall cover persists through all stages; fixed entrance boxes, translating spheres, rotating far boxes, uniformly growing floor-anchored cylinders. White outlined floor through Transformation. Pickups moved clear of cover. `tools/probes/biome_transformation_cover.gd`: 82/82 rendered checks, exit 0, 32 geometry phases per stage and 16 actual hostile flights. Minimum sampled centre gap 1.880 m. Claude’s unchanged probe rerun: 114 flights, exit 0, six standing shelters work in each stage. All existing 54/47/27 suites also pass, exit 0. Logs and native captures: `ada_run/biome_transformation_cover/`.

- **Independent Claude report received, B10-test.** `tools/probes/biome_ladder_cover.gd` fired 106 real hostile balls. Six tall Primitives shelters stop six standing shots; standing cover in stages 1–3 stops 0/11, 0/10, 0/10. Probe exits 1 on that missing continuation. Original baseline preserved in `ada_run/biome_transformation_cover/claude-before.json` and published as `claude-cover-before.json`. It matched the runtime at planning time. The current `claude-cover-checks.json` is the successful Codex rerun after B11. Heads are frozen, landscape moves; lowered aim simulates crouch but does not resize the player capsule. See NEXT-ITERATION.md for the next task and limits.

- **B10 cover implemented.** See COVER.md and the native before/after images on the planning page. `tools/probes/biome_primitives_cover.gd`: 27/27 rendered checks, exit 0. Real skull shots stop at cover; exposed shots reach the player. Desktop 47/47 and stage 54/54 regressions also rerun with exit 0.

- `tools/probes/desktop_biome_catalyst.gd`: **47/47** rendered input/physics assertions, exit 0. Real viewport mouse/key events fire the shared hand projectile into skulls in all four stages and the mature biome. Tests cooldown, reset/rest, button clicks, pickup/release priority, close cover, cursor/typing/death suppression, centred crosshair, and adapter cleanup. An existing ObjectDB cleanup warning remains. Evidence: `ada_run/biome_ladder_play/desktop/`; log: `desktop-input.log` in its parent. The 54-check stage regression was rerun with exit 0 (`desktop-regression.log`).
- `tools/probes/biome_ladder.gd`: **54/54** rendered runtime assertions. Real catalyst collision, falling/restored heads, shot speed, matching scale/collider, colour/particle gates, practice unlock restoration. Process exits 0; an ObjectDB cleanup warning remains.
- `tools/probes/biome_ladder_roundtrip.gd`: **22/22 gameplay assertions**, using actual menu entry, formed hand projectile, three real incoming shots, death scene, return and menu exit. The process then crashes at shutdown (3221225477). This is **not** a clean process pass. Logs: `ada_run/biome_ladder_play/roundtrip/`.
- `tools/probes/biome_ladder_entry.gd`: real isolated final halls, entry floor/height, actual button signal and onward route dispatch. This uses a staging spy for the route; it does not claim a complete museum → arena → next-museum headset traversal.
- Native stage captures: `ada_run/biome_ladder_play/stage-0.png` through `stage-3.png`. Final-hall captures/reports: `ada_run/encounter_pilot/<hall>/biome-ladder-entry/`.
- Headset/Quest performance, manual pickup feel and full museum traversal remain unverified.

## Reproduce

Desktop: **arrow keys move, mouse aims, left click fires, T starts/rests, R resets, Esc releases/recaptures cursor**. Right click retains grab/release. Both Biome Ladder and Head Arena lend the existing hand ability for practice. `commons/hazards/catalyst_counterpart/desktop_catalyst.gd` is a scene-owned adapter; `first_catalyst_ability.gd` still owns formation, cooldown and shots. It releases the adapter on exit, and the saved museum unlock is restored. VR retains tracked-hand input. No tutorial or reflection changes.

Use `res://tools/probes/desktop_biome_catalyst.gd` for the desktop checks; these require the rendered backend to exercise mouse capture. The test sends viewport input through the real handlers; it does not call `send_form` or apply skull damage directly. Target motion is held still for deterministic aim assertions; the separate stage regression checks motion.

Use the installed Godot 4.6 executable with project root as `--path`, `--xr-mode off`, and `--script res://tools/probes/biome_ladder.gd` (or the roundtrip script). Run rendered captures with `--no-window --rendering-method gl_compatibility --resolution 1440x1000`; use hidden processes on Windows.

For a museum entry:

```powershell
python -X utf8 tools/run_encounter_probe.py Primitives_Melencolia --sequence primitives --no-bridges --probe tools/probes/biome_ladder_entry.gd --output-tag biome-ladder-entry --render
```

Other map/sequence pairs: `Trans_Pit / transformation`, `Tutorial_Disco / array_tutorial`, `Color_Walls / color`, `Ribbon_Patterns_03 / tiling`. The probe runner isolates its plans and output. The combat test redirects its save to its own test folder; preserve that isolation.

Republish after a plan or evidence change: `python -X utf8 tools/publish_biome_ladder_play.py`. It writes the source page here and copies it into the sibling encyclopedia's `public/biome-plan/`. Edit PLAN.md or CLAUDE-REVIEW.md in this repository, not the generated copy.

## Next task for Claude

B06 review, B07 Tiling proposal and B10-test were received in CLAUDE-REVIEW.md on 2026-10-13. Claude used `tools/probes/biome_ladder_cover.gd`; that source was left unchanged and rerun by Codex after B11. Next requested Claude task: independently review TRANSFORMATION.md, the new `tools/probes/biome_transformation_cover.gd` evidence and the effect of timed cover in play. Record ownership before extending tests. B11 runtime scope was `ladder_encounter.gd`. B12 Colour marks are now implemented; COLOUR.md lists the additional impact signals and checks. B15 now implements the floor source/copy handoff. Next review can inspect TILING.md and its captures, especially whether the repetition is legible in play. Additional head/cover changes remain proposals.

Forum publication is blocked by automatic approval review; the rejection gave no specific reason. FORUM-OPENING.md contains the ready post. No message was sent to Claude and no forum thread was created. Do not mistake this prepared handover for a completed collaboration.
