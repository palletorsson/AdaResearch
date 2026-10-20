# B22 — Keep the work. Read the next shot.

13 October 2026. Six playable stages, Primitives through Change. Forces waits for independent review.

## State

START/RESUME preserves floor transforms and paint, defeated skulls, damage and consumed pickups. REST stops attacks and removes shots and warnings while retaining those records. The next addressed group receives a fresh warning on resume; an interrupted windup is not resumed halfway through. Landscape motion and the unpainted disco floor continue during REST. RESET restores heads, pickups, health and floor edits. A cleared encounter requires RESET before playing again. The console labels this distinction and shows RESUME after resting.

Exact floor edits still reset when changing stage. This pass preserves within-stage experimentation, not a cross-stage save system.

## Readability and the receiving floor

Upcoming paths are 4 cm wide tubes with bright centres and dark edges. They fade near the viewer, disappearing within 0.7 m, because their target can be the eye itself. Flight guides are thinner and dimmer (1.8 cm); they disappear with their shot. The array's explanation is larger and a short instruction is placed on the refuge. The same cue rendering also serves Change's one-time turn warning.

The original five-position zigzag is preserved. For targets inside the central floor bounds, one additional, previewed position leads to a floor-cell centre after passing the sampled target. Actual collision still decides whether the ball paints a tile, meets cover, hits a player or lands in a gap. A shot cannot paint through cover. Change's centre column keeps its field/warning/straight-commit sequence; its outer columns inherit the landing list.

Stored paths end at their final position. All ladder skull shots are removed after leaving the arena's local bounds (|x| > 6.5, |z| > 12.5 or y < -1), taking their guide with them. The 14-second lifetime remains a fallback. Health, speed, volley interval and stage order are unchanged.

## Verification

| Check | Passed |
|---|---|
| State, warnings, landings and clutter | [104/104](consistency-checks-0.json) |
| Six-stage behaviour | [80/80](consistency-checks-1.json) |
| Arrays | [141/141](consistency-checks-2.json) |
| Change | [36/36](consistency-checks-3.json) |
| Colour | [40/40](consistency-checks-4.json) |
| Desktop input | [61/61](consistency-checks-5.json) |
| Controlled XR and skull hits | [127/127](consistency-checks-6.json) |
| Tiling access and feedback | [25/25](consistency-checks-7.json) |

The new probe prepares floors with actual desktop mouse shots, exercises the real control relays, and checks START, REST, RESUME, CLEAR and RESET in all six stages. For state assertions it invokes the existing damage handler and pickup signal; separate regressions exercise real collisions and controlled XR input. Nine real swept skull flights to a missed arrival target each hit a tile and leave colour. The normal 32-second volley loop sends 21 balls, with at most six balls and six guides alive. Claude's earlier, separate dodging experiment reached nine balls and twelve guides; the methods differ and Claude should rerun its own probe.

All listed processes exit 0 without script errors or failed assertions. Existing ObjectDB shutdown warnings remain. Physical headset readability, comfort and performance have not been tested. The known Flow_Field museum cleanup issue is outside this pass. The console and hand glow still occupy part of the entrance view; their layout has not been redesigned.

## Exact runtime changes

- `commons/hazards/biome_ladder/ladder_encounter.gd`
- `commons/hazards/biome_ladder/ladder_skull.gd`
- `commons/hazards/biome_ladder/ladder_ball.gd`
- `commons/hazards/biome_ladder/array_path.gd`
- `commons/hazards/biome_ladder/path_cue.gdshader`
- `commons/hazards/biome_ladder/path_cue.gdshader.uid`
- `commons/hazards/biome_ladder/change_ball.gd`

[Review the runtime diff](consistency-runtime.patch). [Source hashes and run results](consistency-evidence.json).

## Probe changes

- `tools/probes/biome_consistency.gd`
- `tools/probes/biome_ladder_arrays.gd`
- `tools/probes/biome_change.gd`
- `tools/probes/biome_colour_floor.gd`

biome_consistency is new. The existing Arrays probe now explicitly asserts that RESUME keeps a vacancy; Change expects the added landing entry for outer-column shots; Colour expects START to retain paint and checks the new announced landing tile. Claude's review/probe files are untouched. No tutorial.md, final.md, canonical route or user-authored SCAFFOLD changes.

Publishing: new `tools/publish_biome_consistency.py`; report and images under `doc/plans/biome-ladder`, mirrored to `ada_encyclopedia/public/biome-plan`. PLAN.md, HANDOVER.md and ACTIVE-CODEX.md link this result. `tools/publish_biome_change.py` and the existing change.html gain a navigation link to this update; historical B20/B21 evidence is retained. The new shader's Godot resource UID is included in the runtime list and diff.
