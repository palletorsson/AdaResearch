# Arrays opening audit — 19 September 2026

The opening two chapters hold. Their progression is specific: a familiar cube becomes an indexed occupant; removing it exposes the difference between address and value; the third index then needs a separate bodily permission to become reachable. Neither chapter needs a broad rewrite.

## Decisions

| Hall | Current encounter | Decision |
| --- | --- | --- |
| Array | `row_3_x` and `grid_2d_4x4#notation:plate` are both primary. `column_3_z`, `xyz_coordinates`, `gridagent:copy` and `pulsar_visualizer` remain secondary in the room. | Preserve both primary encounters and all current final prose. Row label disappearance versus persistent grid plate is a productive comparison, not duplication. |
| Tutorial_3D | One primary `array_flight_lab` contains 64 pickup cubes, a selection console and the bounded Menger-style flight enclosure. | Preserve the manuscript and locomotion. Change two premature labels; correct the local address-label presentation exposed by the new capture. |

Applied to `commons/artifacts/regularity/array_flight_lab.gd` only:

```diff
- enclosure.instruction_title = "FLY INTO THE THIRD INDEX"
+ enclosure.instruction_title = "REACH AN ADDRESS"
- Kit.panel(self,"THREE INDICES",Vector3(3.5,1.2,-6.9))
+ Kit.panel(self,"SELECT AN ADDRESS",Vector3(3.5,1.2,-6.9))
```

Flight controls remain explicit. The visitor still receives usable movement instructions, while the title leaves the opening question—what changes in the address when one rises—for discovery. Map and sequence titles still name the chapter; those navigational titles are not changed in this narrow pass.

The first fresh image also showed cube addresses drawn through the opaque instruction board. The common lattice puts labels at y=0.6 inside the pickup cube and relies on `no_depth_test=true`. Merely enabling depth hides them inside their own cube. In this particular lab, after its deferred grid configuration, the 64 labels now use depth testing and stand at y=1.0. This keeps them above their cube and behind opaque panels. Shared lattice defaults elsewhere are unchanged. The final render shows clean flight instructions with addresses visible in the exposed lattice.

Both `final.md` files remain byte-for-byte unchanged in this pass.

## Fresh verification

`opening/contact_probe.gd` loads the real row, plate grid and flight-lab implementations into an isolated physics scene. It uses actual `Area3D` overlap with capsule bodies carrying the production desktop/XR body groups, rather than manually invoking removal callbacks.

**24/24 checks pass, exit 0.** Full results: `opening/contact-checks.json`.

- Contact removes row cube 2 and its child label; only table `[0][2]` visibly becomes zero.
- Contact removes grid cube `[1,2]`; the sibling plate survives. Both data and displayed cell `[1][2]` change; `[2][1]` stays one. The manuscript's first-index-as-table-row convention is supported by the display implementation.
- The flight lab builds exactly 64 cells. X/Y/Z buttons independently select `[1,2,3]`; its marker matches the spatial coordinates.
- Physical contact removes that cell and writes `values[2][3][1]`. The selected-address readout continues naming `[1,2,3]` with value zero. The visitor's capsule remaining there does not change cube occupancy.
- All 64 lab labels respect depth and stand at the new height.
- Neutral flight input yields zero velocity; a tilted basis moves forward/up; combined input is capped at 2.4 m/s. Both ground-door approaches lie outside the flight permission.
- `museum_flight_provider.gd` loads with its live dependencies.

This is not a tracked-headset test, a direct controller-input test, a complete museum-route traversal or a comfort/legibility certification. The XR collection check uses the production receiver group on a capsule; it does not impersonate a tracked XR session. The source provider uses `XRHelpers.get_left_controller`, controller `global_basis` and primary stick input, exclusively handles motion inside the enclosure, and yields outside it or when earlier exclusive providers disable it. The manuscript is consistent with that source; entry/exit with actual XR controls remains open.

The headless run retains existing unresolved-UID/certificate warnings and an exit resource-leak warning. The rendered run retained one renderer shader-cache write warning. None produced a script parse failure or failed contract check. Logs are preserved, not relabeled clean.

## Paired images

`opening/captions-before.png` and `opening/captions-after.png` use the same camera, lighting fixture, viewport and real artifact. They are **isolated artifact captures, not screenshots of the full museum**. Ordinary pickup animation continues, so the cubes need not have identical rotational phase. The original before image is retained; the final after image includes both caption and depth/height corrections.

The image `opening/captions-only-after.png` records the intermediate caption-only change. `opening/captions-depth-only-after.png` records why depth testing alone was insufficient. Those are investigation evidence, not the final pair.

## Review gaps resolved by source access

The frozen online bundle omitted mechanisms it needed, not mechanisms missing from the project:

- `commons/scenes/mapobjects/pick_up_cube.gd` implements contact collection, recognizes museum desktop `em_walker` and XR `player_body`, prevents repeated collection, and removes the cube after 0.1 seconds.
- `algorithms/arrays/binary_table/binary_table_display.gd` updates the correct displayed row/column label in `set_cell`.
- `commons/movement/museum_flight_provider.gd` supplies XR movement; `museum_flight_box.gd` builds the enclosure and installs that provider.

These dependencies should enter the next source-aware bundle. No editorial cut follows from their earlier omission.

## Remaining small debts and recovery candidates

1. Existing Array secondary `column_3_z#notation:plate` can support a future axis-orientation return. `gridagent:copy` can later contrast visitor writes with autonomous writes. Neither is necessary to promote merely to increase primary counts.
2. The dated 17 September full-museum Array report had 12 checks and one `placed gridagent` failure. Its log also says six interactables were placed, shows grid-agent instantiation warnings, and records attempts to copy into y=-1. It is not proof that the agent is absent. Fresh secondary-agent placement/operation deserves its own targeted investigation before promotion; the current manuscript does not depend on it.
3. Old source identity prose overclaims that spatial arrangement proves an abstract address is always a physical location or that 3D arrays are necessary for volumetric representation. Current final prose is more precise. Do not restore these overclaims into the book; narrow the comments in a future metadata pass.
4. The old Array role note still calls the hall a four-rung overture, including a 3D grid which now correctly has its own hall. Current roles/order and live placements are accurate; the historical note needs a dated supersession, not restoration of an unwanted duplicate.
5. Reading 64 addresses in headset and demonstrating flight entry/exit remain experience tests. The final image removes one confirmed obstruction, but does not settle all visual-density questions.

Source hashes are recorded in `opening/sources.json`; exact changed strings and source hashes in `opening/caption-change.json`. No map, role, manuscript or shared movement implementation was changed.
