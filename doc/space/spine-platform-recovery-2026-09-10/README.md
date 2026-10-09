# The platform correction across the spine

10 September 2026. Source correction applied; runtime and headset verification pending.

Audited the union of each spine sequence's authored maps and its active museum maps: **24 sequences, 202 maps, 156 active halls**. These are measured counts from the current sources, not the older 190-room plan.

**62 additional maps corrected (47 active, 15 extensions).** Restored 1,420 interior numeric `2` cells as one-metre platforms; made 186 perimeter cells explicit `w` walls. The changed maps retain all artifacts, configurations, utility tokens, dimensions and documentation. No route, primary role or book order changed. No spawn relocation or additional landing was needed in this batch.

## Distinguish the three construction cases

1. **Inherited grid converted to museum geometry:** interior `2` remains numeric, with `museum.wall_height: 3`. Existing taller structures stay taller, holes stay holes, and outer `2` becomes `w`. Recovered halls use the existing doorway gate setting.
2. **A real GridSystem staged inside the museum:** its numeric heights already produce stacks. Twenty maps in the audit use this route. Do not apply the museum wall threshold repair to their arena or convert their edge platforms using the museum rectangle. `endless_museum.gd` builds the separate shell through `em_simulation_stage.gd` and instantiates `grid_system.tscn` for the arena.
3. **A substantially rebuilt gallery:** preserve its newer partitions, as Palle explicitly requested during this audit. The historical grid does not establish what every newly placed `2` means. This records the author's choice; it does not certify runtime access.

Nine rooms remain in that third category: Point_One, Point_Lines, Point_Line_Grid, Point_Triangle_Context, Primitives_Polythedra, Point_Animatedcube, Primitives_Ignorance, Array and Change_Intro. In the first seven, current 2-cell patterns differ strongly from the old grid; Array is newer than the first museum baseline; Change_Intro was substantially rearranged. Palle answered “Preserve newer partitions (recommended).” All nine maps retain their geometry.

Boolean_Verbs has no pre-museum map, but its existing `intent.md` explicitly says its sills are steps, not walls. It therefore belongs in the corrected set: its source now matches that stated spatial argument.

## Checks and preservation

- Four focused regression tests pass: geometry preservation, real-grid/protected-gallery exclusions, narrow cached-plan patching, and rejection of incompatible cached cells.
- 1,606 source cells checked through the real Python museum deriver.
- All 62 maps retain every previously reachable interior cell and exit in before/after grid pathfinding. No new construction-rule issue appears.
- The grid pathfinder reads numeric heights directly. This check proves grid-access non-regression; it does **not** prove that the live museum gate, packing, collision or headset movement is correct. Some maps had existing access issues before the correction.
- Both plan copies receive only the affected cells, floor counts, gate settings and matching support heights. Unselected rows, existing artifact lists and curation remain unchanged.
- Existing cache differences in Change_Reconciliation, Ribbon_Change_01, Ribbon_Change_03 and VFM_02_Operations remain outside the corrected cells. Source-only artifacts in Godel_Incompleteness and QFEP_Introduction were recorded, not silently added to the cached arrangements.
- Authored sequences, active map order, roles and artifact order remain unchanged. In particular, Trans_AxisDecomposition still appears in the current source declarations despite the earlier conversation about removing it; this geometry audit did not change navigation.

Exact inputs are in `before/`; relevant old maps are in `pre-museum/` and `pre-rewrite/`. `recovery.json` records hashes, per-map classifications, cell coordinates and plan patches. Later artifact or text changes are allowed by the persistent geometry check.

```powershell
python tools/recover_spine_platforms.py --check
python -m unittest discover -s tools -p test_recover_spine_platforms.py
```

The shared physical probe accepts `--spine`. Godot PID 2780 was occupied during this work, so no second instance was launched. After the existing instance closes, run serially under the watchdog. Start with one representative room:

```powershell
python tools/godot_watchdog.py --expect=ada_run/spine_platform_Boolean_Verbs.json -- C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_sequence_platform_recovery.gd -- --spine --map=Boolean_Verbs --artifacts
```

For all 47 corrected active halls, omit `--map` and `--artifacts` and set `--expect=ada_run/spine_platform_active.json`. For images, use a rendered hidden window and append `--capture`; do not request screenshots from headless mode. Preserve the newer partitions in the nine rebuilt galleries as requested.

[Spine audit and source comparisons](http://localhost:3003/research/waves-chance-noise/spine-recovery.html)
