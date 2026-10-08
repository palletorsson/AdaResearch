# Fold, print, sort

`cube_sorting_line.tscn` occupies cell `(16,7)` in `Point_Animatedcube`, facing
west. The restored cube shelf at `(11,8)` faces east across the shared aisle,
with a 0.2 m westward offset. Closer column spacing makes the rack 7.44 m long, clear of the sliding door.
Its 24 original pickable copies retain their previous sizes;
the worktable sits at the south end so the aisle and exit stay clear. The builders, independent cube
net, stencilled crates and supply pile remain in the hall. Both baskets sit behind the belt,
with raised labels facing the visitor. The 0.48 m belt leaves the operator's
side clear to stand close and reach across; the control stand stays alongside.

The feeder folds six faces and releases a 0.32 m pickable onto a 5.2 m physical
conveyor. The printer assigns one of two original carton designs, AGAIN or YET.
Both words and colours distinguish the designs. Release a printed cube in its
matching basket: its visual and individual box collider shrink together before
it joins the basket's miniature collection. An incorrect or still-held cube is
never consumed. Pause and reset use the project's existing touch buttons.

The game keeps every delivery in its ledger:

    produced = active + stored + sorting + sorted

Missed cubes tumble onto the museum floor and stay unorganized. Settled stock
keeps each cube's actual position and rotation in two instanced meshes, with
matching individual box shapes on a shared static body. Batching never moves a
cube into a storage slot or separates the two designs. Nearby exposed cubes
become pickable again in exactly the same pose. Grabbing one restores that
delivery to active physics and wakes nearby boxes above it so they can fall.
The floor scan estimates a bounded room capacity; it does not arrange the stock.
Filling a whole hall is a prolonged consequence. The belt can also clog naturally;
`active_limit` holds production when the moving-body budget is exhausted instead
of deleting or tidying older cubes. Only the player's matching basket sorts them.

Desktop pickup uses the production pointer's grab/drop hooks. XR pickup uses
`XRToolsPickable`, including the existing surface-grip fallback. A held delivery
is released through its owner before reset removes it. Physics bodies are never
scaled at their root; only mesh and private shape sizes change.

## Source boundaries

- `cube_sorting_line.gd`: feeder, printing, basket decisions, receipts and ledger.
- `sorting_cube.gd`: desktop/XR ownership and fitted collider size.
- `cube_sorter_stage.gd`: fixed geometry, original net and carton samples.
- `carton_skins.gd`: shared six-face atlases from the prefab carton's original
  palette, stripes and lettering; no downloaded packaging texture.
- `cube_sorter_backlog.gd`: unchanged settled poses, matching collisions and reclaimable cubes.

The feeder reuses `polyhedron_nets_cube`, but does not reuse its independent
exhibit's capped drop collection. The baskets display the original
`edition_carton` scene as their reference samples.

## Verification

Run `python tools/run_cube_sorting_line.py`; add `--capture` for native viewport
images. The runner uses an isolated normal-scene project with the same runtime
assets, physics settings and XR classes. It avoids changing live museum state
and bypasses the checkout's pre-existing stale audio-bus UID by using its path.
Reports and images go to the encyclopedia's shared captures directory.

Before exporting Android, refresh Godot's filesystem scan. For command-line
builds, finish `godot --headless --path . --editor --import`, then start a fresh
export process. An already-open editor must rescan the new files before exporting.
The Android preset includes JSON separately, so a stale editor export can contain
the current map and registry while omitting the new scene and scripts.

Check the finished APK before installing it:

```sh
python tools/verify_cube_sorter_apk.py path/to/game.apk --report ada_run/cube-sorter-apk-report.json
```

This checks both registry entries, all 22 hall placements, and the sorter/library
resource dependencies, including exported remap targets.

Physical headset comfort and Quest performance require a hardware visit.
