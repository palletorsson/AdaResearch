# Colour recovery — 9 September 2026

The colour sequence is recovered from commit `a36f33c996004abcdc67ea2a0ac3fce72eba42fd`, the parent of the first endless-museum commit `62e08730f` (31 July 2026). Historical source JSON is in `historical/`; the state encountered at the start of this work, including manuscripts and museum plans, is in `before/`.

## Active rooms

Colour: `Color_Context_Placed`, `Color_Nails`, `Color_Grid_Pallet`, `Color_Rainbow`, `Color_Pillar`, `Chamber_Color`, `Color_Paint`, `Color_Walls`, `Color_Flashlight`.

Pattern: the existing `tiling` sequence owns `Pattern_Foundry`, `Tutorial_Pattern`, `Array_Patterns`, `Symmetry_Seventeen`. Its current developed configurations were retained and enclosed. No competing pattern sequence was created.

Each source footprint is translated by (4,4), preserving every original structure and utility cell, with perimeter walls and three-cell entrances/exits. The larger pillar and office installations occupy additional floor. Embedded GridSystem instances preserve grid-dependent interactions at full scale; there is no staged glass arena or fire. Seven obsolete Ribbon_Color entries were removed from the active plans; their source files and plan backups remain.

## Changed encounters

- `ball_painting_demo#automated:true`: an automatic, hue-changing brush draws on its own existing wet-paint canvas; manual pigment balls remain.
- `pillarcolorcollection#layout:spatial_gradient`: 35 pillars, 4.6 m tall, spaced 3.2 m apart, sample the same HSV field shown continuously on the floor.
- `color_sets_overview#mount:wall`: twelve existing grabbable palette collections in a framed 6.4 m wall.
- `color_constellation_office#layout:cubicles`: eight furnished cubicles, forty tinted glass panels, 2.6 m wall height, 1.2 m entrances and a 3.2 m central aisle; all walls are orthogonal.

The historical Color_Flashlight map was empty; its existing namesake demonstration was installed as an explicit exception. `serial_principle` at (5,30) in Color_Context_Placed appeared in the working copy during final checks and was retained as an additional current-workspace placement.

## Shared correction

`GridSystem.gd` now forwards `settings.color_overrides` to the structure component. The material code already supported these settings, but they never arrived. Recovered rooms use quiet, neutral surfaces; Color_Rainbow retains its historical authored finish. Saved modifier cells and brush coordinates move with their original grid.

## Text and navigation

Primary roles, colour/tiling book navigation, sequence membership, both museum plans and the spine manifest were synchronized. Four draft final chapters and three room summaries/tutorials describe the revised encounters. Existing material is archived before replacement. Color_Grid_Pallet, Color_Rainbow, Chamber_Color and Color_Flashlight still need final manuscripts. No learner verification is claimed.

## Verification

Final results: **234 runtime checks, 109 recovery invariants and 27 content tests passed; zero failures.**

- `python doc/space/color-recovery-2026-09-09/audit.py`: historical structure, utility and artifact preservation, authored exceptions, paint offsets, rectangular grids, entrances, chapter/book/plan membership.
- `commons/testing/probe_color_recovery.gd`: actual museum loading and artifact placement in all thirteen rooms, runtime material settings, plus standalone interaction/geometry checks. Office capsule sweeps test the aisle and every entrance.
- `python -m unittest tools.test_artifact_roles_book_inventory tools.test_build_spine_artifact_order tools.test_museum_progress`: 27 tests passed.
- Godot graphical captures were inspected for the pillar field, palette wall, painting, office and full Color_Walls room.
- Headset performance, colour appearance and a complete learner walkthrough remain unverified.

Runtime reports and captures: `ada_run/color_recovery_*.json`, `ada_run/color_recovery_*.png`. Detailed source dimensions and placement exceptions: `recovery.json`. The archived compilation scripts document the migration; do not rerun them over later authored edits without reviewing their sources.
