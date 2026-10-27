# Graph Theory → Void transfer: HANDOFF

## Coordinator acceptance — current state

Codex independently reviewed Claude's delivery and ran the native scenes on 21 October 2026.
All 3 original placements are transferred and independently editable. Source audit 39/39,
native checks 51/51, editor checks 6/6. Desktop and synthetic XR passed; no physical
headset session. Curation and chapter texts remain pending. Original maps/text hashes match.

Corrections made after the delivery below:

- Added a trial-local inherited `bridge.tscn` / `bridge.gd` adapter, registered as
  `void_gt_bridge`. THEOREM and DEGREES call the original working functions from spatial
  buttons in desktop and VR. The original 2D analysis is shown in a spatial readout.
  D no longer toggles labels while the player strafes.
- The source E/B handlers call **empty functions**, so path attempts and bridge removal
  are not working gameplay. The original handoff below overstated them. No replacement
  gameplay has been invented for this transfer.
- Raised the bridge 0.12 m so the river is visible above the deck, retaining its source
  0.1 scale. Measured all three objects between the six-metre slabs; shafts remain clear.
- Removed the five provenance captions from the floor; retained provenance in the inventory.
- The optional pre-ready catalog flag was not needed: seed 41 and the cube graph apply
  correctly, and reset reproduces the starting coordinates.

Native checks exercised complete BFS/DFS traversal and alternation, bridge topology,
actual desktop/XR buttons, move/turn control retention, fixed layout adjacency while
coordinates move, seeded reset, camera ownership, descent, sleep/resume and checkpoint retry.
The editor checks load each real exported model, copy/move/turn every object, save/reload
to the native layout and Desktop mirror, and reject stale writes. Test edits were restored.

Open curation issues: the source-scale bridge is small; the layout is overhead. The
learner-built small study described in GT_Layout remains outside the original placement
inventory. Decide its role when composing the encounter. Web models are arrangement
snapshots; the game runs the original simulations.

## Original Claude delivery — retained for review history

The following records the state before coordinator corrections above.

Owner: Claude Opus. Written 2026-10-21. Batch: `doc/void-transfer/2026-10-21-batch-05/`.
Stage: **placed**. Native-tested: no. Headset-tested: no. Curated: no. No Godot run.
`python tools/audit_void_transfer.py graphtheory` passes 39 / 39.

All three placements are placed. `graph:cube` and `layout_seed:41` are kept. **No adapter
and no catalog override is required**; one optional pre-ready flag is proposed.

## Files (all in `commons/void/trials/graphtheory/`)

| file | what |
|---|---|
| `rooms.json` | 2 + 1 placements, 5 provenance captions |
| `layout.json` | text only (status, roles, note); frame, six-metre storeys and pads unchanged |
| `source-inventory.json` | each placement `placed` with its `void` record; `transfer` block |
| `catalog-additions.json` | none required; optional `configure_before_ready` for the layout |
| `transfer-status.json`, `HANDOFF.md` | this package |

## Placement

Each floor is its source grid turned 180°, 1 cell = 1 m: `void_x = cx - cell_x`,
`void_z = cz - cell_z`, `facing = token_rotation + 180`. Height and scale are the token's
y offset and scale, which match the museum plan rows. GT_Foundations uses cx 6, cz 12;
GT_Layout uses cx 7, cz 12. The entrance lands beside the shared spawn (0, 12).

| rooms id | source cell, token | void x, z | facing | height | scale |
|---|---|---|---|---|---|
| `f1_two_travelers_9_7` | (9,7) `two_travelers:180:0:1#plinth:0#pin:1` | -3, 5 | 0 | 0 | 1 |
| `f1_KonigsbergBridge_3_8` | (3,8) `KonigsbergBridge:180:0:0.10#plinth:0#pin:1` | 3, 4 | 0 | 0 | 0.1 |
| `f2_force_directed_layout_10_7` | (10,7) `force_directed_layout:180:2.4:0.3#plinth:0#pin:1#graph:cube#layout_seed:41` | -3, 5 | 0 | 2.4 | 0.3 |

Both small halls stand between x -6 and 6 and z 2 and 7. They are well clear of both
shafts, the columns and the A landings.

## Not transferred

- Perimeter walls, spawn and teleporter utilities, lighting, sky and `nature_layer`.
- **The "small study" in GT_Layout's `final.md`** ("your hand can pull the black point").
  This is the tutorial's learner reconstruction (`study.gd`, built by the reader in the
  hall's left learner bay; source under
  `doc/book/studies/graphs-through-the-hands/GT_Layout/`). It is not a map placement and
  not one of the three originals. The text refers to an object this transfer does not
  contain. Curation should decide whether a reference build belongs here.

## Controls to test

- **two_travelers.** No controls. A 15-lamp tree (lamps 0.64 to 2.5 m up) is walked by
  BFS, the blue tide, then DFS, the orange diver, at 0.45 s per visit with a 1.6 s rest.
  Two readout plates stand at local (±1.7, 0.24, 0.8), toward the visitor. Check both
  orders run and repeat.
- **KonigsbergBridge.** Keyboard only, as in the museum. E attempts an Eulerian path,
  H toggles the theorem, D toggles the degree labels, and B demonstrates bridge removal.
  **Conflict:** the Void walks with WASD, so every D press while strafing right also
  toggles the degree labels. E, H and B are free in the Void. There is no VR control.
  Its scene carries a DirectionalLight, a WorldEnvironment and a Camera; the Void's import
  handling should neutralise all three. Verify the sky and the visitor camera are unchanged.
- **force_directed_layout.** No controls. A seeded cube graph (8 vertices, 12 springs)
  settles under spring, repulsion and damping. Check `graph == "cube"` and
  `layout_seed == 41`, and whether the layout is reproducible across retry.

## Fit risks

- **Königsberg at scale 0.1.** Its 50 x 32 m model becomes 5 x 3.2 m, and its water level
  at -1 lands about 0.1 m under the deck. That is the source scale; I did not raise it.
  Measure whether the river reads.
- **The layout at 2.4 m.** Its drawing is about 5.1 m wide and spans roughly 1.3 to 3.5 m
  above the floor, from the registry AABB scaled by 0.3. That is the museum's height, and
  it is mostly overhead. Measure natively.
- **two_travelers extent** is estimated from its code at about 3.8 x 2.6 x 1.2 m; the
  registry has no measurement.

## Commands

```bash
python tools/audit_void_transfer.py graphtheory
```
```bash
python tools/export_void_trial.py graphtheory
```

Editor: `http://localhost:3003/lab-editor?mode=void&trial=graphtheory&floor=1`. Each of
the three is its own entry.

**Test scope.** This package was checked statically: the schema, transforms against the
inventory, the source audit, and clearance by inspection. Loading, behaviour, input,
residency and editor saves are untested and are yours to run.
