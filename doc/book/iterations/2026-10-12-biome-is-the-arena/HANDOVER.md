# The biome is the arena — 12 October 2026

User correction: put the catalyst and head inside the biome, among its plants and terrain; the biome itself is the arena. Supersedes the three-patch setting with a central clearing.

## Current entry and placement

Main menu → Head Arena still opens `commons/hazards/catalyst_counterpart/biome_arena.tscn`. It now instantiates ONE unchanged generation-17 `biome_object.tscn`: seed 7, size 12, moisture .5, relief .5, wildness .6, full stage, phase 1, catalogue residents on, community seed 0, drawn foliage. State-file recording remains off. No biome generator or catalogue files were edited.

The 38 × 36 m clearing slab, dark floor inlay, border curbs, separate patches and large backdrop are removed. The player stands on the original terrain mesh collider. `terrain_arena.gd` extends the existing `test_arena.gd` round logic, replacing only its layout. Point stand at x/z (-1.3, 3.1), head home (0, -1.2), small console around (1.6, 3.4), arrival (0, 4.8). Y positions come from interpolation of the exact two mesh triangles per ground cell. A narrow stand keeps the catalyst within reach above the soil; compact controls retain START/REST/RESET/MOVE/TURN/SCALE/MAIN MENU. Labels have a light colour against the dark console.

The shared `test_arena.gd` now uses `head_home`, defaulting to its old `HEAD_HOME`. `flying_skull.gd` accepts a host-defined home, bounds, target Y range and optional ground-height callable. Original museum values are the defaults. The biome head orbits 1.65 m above local soil; its body is bounded to the interior and kept above the ground including its scaled radius. Charge destination remains locked during telegraph; actual collision ends an obstructed dash. Same pickup, resolution change, trigger projectiles and three-interruption scoring. No health damage added.

Desktop and XR spawn are both derived from the terrain. Existing XR rig, environment ownership, staging and menu return remain. Going below -3 m or beyond x/z ±6.5 m rests the head and returns to the bank. This finite patch has no invisible perimeter wall.

## Verification

`python -X utf8 tools/test_catalyst_first_abilities.py --menu --render`

43/43 runtime checks: menu dwell/staging, original biome DNA and all non-timing ecology counts, all 12 resident identities/recipes/local poses, physical terrain at arrival, sixteen exact mesh-height samples against physics, height variation, absence of stage/backdrop, six seconds of orbit/scale over soil, locked destination and actual movement, pickup/projectile interruption, three-hit round, reset, fall return, unchanged museum authoring files, return to the same menu session. Native images copied beside this file. These tests supply input; they do not establish headset ergonomics or frame-rate.

`python -X utf8 tools/test_catalyst_first_abilities.py --arena`

31/31 original museum-arena regression checks; exit 0. Shared movement defaults, pickup, scoring and reset remain intact. Report copied as `museum-regression.json`.

The biome menu test still ends with Windows access violation 3221225477 during process cleanup after the successful assertions. The prior menu-only control run already reproduced this without loading any arena. Do not report a clean menu-process exit. No APK export/deployment or headset session performed.

Evidence: `ada_run/encounter_pilot/Head_Arena_Menu/`. This report keeps the previous stage image as `before.png`; earlier iteration reports are historical.
