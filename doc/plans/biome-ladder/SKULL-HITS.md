# Skull hits — visible targets respond

B16 · 2026-10-13 · Codex. Palle reported that a projectile visibly hits the skull but it does not fall or die.

## Reproduced cause and correction

The ladder skull discarded a hit whenever `active` was false. READY and REST both set that flag false. The projectile still collided and produced its impact effect, so the player saw contact without a response. The earlier tests always pressed START before shooting and missed this case.

`ladder_skull.gd` now ignores only an already destroyed skull. A visible skull takes one hit, stops attacking, clears its balls, falls and stays down until RESET/new START. START/REST control hostile behaviour rather than granting invulnerability. This is limited to the ladder; the older mature biome retains its three-hit rule.

A separate issue appeared on those same collisions: the floor callbacks tried to find a CharacterBody3D in an Array[StaticBody3D]. Godot emitted typed-array errors. The three floor callbacks in `ladder_encounter.gd` now reject non-static bodies before looking up a tile. Skull impacts cannot trigger tile changes; actual tile impacts keep their existing behaviour.

## Actual tracked-input test

`tools/probes/biome_ladder_skull_hits.gd` drives XRServer controller poses and the real `trigger_click` input. It uses the shared hand-form ability, real projectile flight and the skull's normal physics loop. No damage handler is called directly and skull movement/falling is not frozen.

**106/106 checks pass, exit 0.** Desktop regression also passes **54/54**, and Tiling passes **33/33**, both exit 0. Across Primitives, Transformation, Arrays, Colour and Tiling, the probe checks READY, PLAY and REST: hand discovery and formation, one real projectile, contact with the skull, one-hit defeat, an actual downward fall onto the floor, inability to shoot after defeat, and RESET restoring the skull and collider. It also verifies that the temporary practice ability does not overwrite earned progression.

The initial report reproduced ignored collisions in all ten READY/REST cases. Its moving-head tests also exposed stale test aim; the final probe re-aims at the moving head before firing without changing the game's aim or freezing the head. The preserved baseline is diagnostic evidence, not a strict unchanged-test before/after score.

Evidence: `ada_run/biome_ladder_skull_hits/report.json`, `before-report.json`, `before.log`, `after.log`. Native screenshots `before.png` and `after.png` show the same first skull on its pole and then on the floor. `ignored-hit.png` preserves the failing behaviour before the fix.

The controlled XR path is stronger evidence than desktop input alone. It is still not a physical headset playtest. Existing ObjectDB exit warnings remain; the corrected tracked-input run reports no script errors.

## Retest in the headset

Restart the running project, enter **Game menu → Biome Ladder**, and shoot a skull before START. It should fall immediately. RESET restores it. START then lets the same skull attack; a hit should still defeat it. A standalone Quest install needs a new export/install to receive code changes.

## Handoff to Claude

Fix ownership: Codex changed `ladder_skull.gd` and only the three non-static-body guards in `ladder_encounter.gd`; added this probe and report. Please review against the updated files. The independent review and Claude-owned probes were not edited. Change remains the next biome; no new stage was implemented during this bug fix.
