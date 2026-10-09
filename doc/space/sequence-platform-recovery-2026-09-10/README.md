# Platforms across Randomness, Noise and Cellular Automata

10 September 2026. Source correction applied; physical runtime verification pending.

Inspected all 31 authored maps against both the pre-museum revision `a36f33c996004abcdc67ea2a0ac3fce72eba42fd` and the parent of the source-map rewrite, `4d8dc7c7cbea69bc189b259b5c998a44b4a13e46`.

| Sequence | Audited | Changed | Interior wall cells restored as platforms | Boundary cells made explicit |
|---|---:|---:|---:|---:|
| Randomness | 14 | 10 | 170 | 185 |
| Noise | 9 | 6 | 123 | 70 |
| Cellular Automata | 8 | 1 | 1 | 0 |
| Total | 31 | 17 | 294 | 255 |

Ten changed maps are active, seven remain extensions. Nine active halls contained the 128 active interior cells needing correction. Random_Remove changes boundary spelling only; its museum geometry is unchanged. Random_Definition was already corrected. Thirteen other maps had no numeric 2 cells, including the rebuilt Noise_Perlin_Simplex and seven CA maps.

The existing map-specific threshold supplies the correction: keep interior `2`, use `museum.wall_height: 3`, and spell boundary `2` as `w`. The boundary is the actual structure array rectangle. A previous boundary moved inside an expanded museum room is now a platform, following Palle's instruction. This is a recovery of the cell's meaning, not a claim that every original platform or historical coordinate was restored.

The relevant platform halls use `gate_depth_rows: 0` so the loading gate does not occupy their interior decks. No engine code changed. Nine active rows in both plan copies received only geometry, support-height and gate-depth updates; existing artifact coordinates/configurations and unselected rows were preserved.

## Access exceptions found during validation

Before/after pathfinding exposed three regressions that the ordinary rule-check headline did not catch. The final correction includes:

- Random_Mushrooms: move spawn (0,0) to existing floor (1,1).
- Randomness_Examples_of_Randomness: the same spawn relocation.
- Noise_Inside_Noise: add one height-2 landing at (7,11) before the unchanged teleporter (7,12). The old approach used an outer border cell.

All previously reachable interior cells and teleporters are retained after these repairs. The reduction in some total walkable counts comes from border cells becoming walls. This does not establish that every cell or artifact is accessible: several maps already had limited static reachability.

Artifact layers and placement configurations, dimensions, roles and route were preserved. Two utility spawn cells and the one additional landing are the documented exceptions to the initial goal of changing only wall interpretation.

## Evidence and follow-up

- `recovery.json`: map-by-map cell lists, history hashes, changes and access exceptions.
- `before/`: exact input maps, plans and route/role/order sources.
- `pre-museum/` and `pre-rewrite/`: original map JSON from each git revision.
- `python tools/recover_sequence_platforms.py --check`: 550 geometry cells, including the new landing; entry/exit non-regression checks; current route.
- `ada_run/sequence_platform_pathfinding.json` and `ada_run/sequence_platform_before_after_walk.json`: construction rules, token resolution and before/after reach.
- `commons/testing/probe_sequence_platform_recovery.gd`: prepared physical test of the ten changed active museum halls. Its GDScript parses, but it has not been run while Godot PID 2780 remains occupied.

Existing plan-cache drift was found in Random_Remove (cached dimensions and three artifact addresses differ from the current map) and Noise_Perlin_Simplex (cached artifact arrangement predates its pilot). Those rows were left alone: neither needs a new interior-2 correction, and stale curation should not overwrite current work.

Run Godot probes serially under the project's watchdog when the existing instance is closed. Logic-only command:

```powershell
python tools/godot_watchdog.py --expect=ada_run/sequence_platform_active.json -- C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_sequence_platform_recovery.gd
```

For one room with real artifacts, append `-- --map=Noise_Columns --artifacts`. For an image, use a rendered window (`--rendering-method gl_compatibility` in place of `--headless`) and append `--capture`; automated windows should be hidden. The output filename uses the selected map. Headset reach remains a separate observation.

[Visual source comparison](http://localhost:3003/research/waves-chance-noise/structure-recovery.html).

