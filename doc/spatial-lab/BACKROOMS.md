# Backrooms / repeated rooms in Transformation

The installed timber version is on **Transformation / Scale, floor 18** at
`[-1.2, 0.01, -0.7]`. It adds three rooms and two short corridors, with alternating
door positions. Existing floor objects and routes remain in place.

- Lab: http://localhost:3003/spatial-lab?recipe=lab_backrooms
- Main installation: http://localhost:3003/lab-editor?mode=void&floor=18
- Timber reference: http://localhost:3003/lab-editor?mode=void&trial=spatial_lab_bacc000000&floor=1
- Cube variation: http://localhost:3003/lab-editor?mode=void&trial=spatial_lab_a9fe732672&floor=1

Change the prefab, room count, room scale, opening width, corridor length and
roof state in the lab. **Save variation + native check** creates a separate trial;
it does not replace the main installation. Open that variation in the lab editor
to move, rotate, copy or delete individual walls, lintels, floors and roofs.
The default enclosed version has **38 independent parts**. Opening its roofs
produces 33 parts. Stable names preserve each member's editor pose.

```json
{"t":"lab_backrooms","with":{
  "source":"timber_panel_2x2","count":3,"size":1,
  "opening":1.4,"corridor":1.2,"roof":1
}}
```

This is a bounded deterministic room grammar, not WFC or an endless generator.
The construction input is explicit: real prefab meshes and materials are fitted
to each structural envelope. Thin sheets are turned upright for walls; the
original prefab scenes are unchanged. Static collision matches each fitted panel.
Floors finish 2 mm above the insertion plane to avoid slab z-fighting without
creating a step that blocks the desktop capsule.

The default occupies 3.78 × 12.18 m and is 2.79 m high. Clear door width is 1.4 m;
headroom above the timber floor is about 2.248 m. Increasing the count or scale can
exceed a standard floor: the native receipt reports overflow instead of shrinking
the design. No claim that every parameter combination fits the main tower.

## Verification — 2026-11-13

- Reference native run: 86 checks, 41 exported model files, including all 38 members.
- Installed floor-18 run: 90 checks, including a scripted production desktop walker
  through all rooms and corridors, wall collision, unobstructed openings, and at
  least 0.8 m separation from the other floor artifacts. The sorter required a
  1.2 m sideways placement adjustment. Separate 3D worlds inside film monitors
  are excluded from physical floor bounds.
- Cube-input variation: 52 native checks, two rooms, wider openings, scale 1.1,
  open roofs; saved from the actual web controls.
- Three.js/Godot member transform parity; 54 parameter combinations; real GLBs;
  independent member move/rotate/copy; production save validation; isolated
  save/reload and desktop mirror; stale-save protection.
- Browser controls and input swap inspected. Physical Quest/headset testing and
  unrestricted player exploration are not claimed.

Receipts and native photographs are in `ada_run/backrooms-2026-11-13` and
`ada_run/spatial-lab-2026-10-27/spatial_lab_bacc000000`. Cutaway photographs hide
roofs for inspection only; the installed version retains them.

Implementation: shared term `lab_backrooms`, `room_chain.gd` and the numeric
counterpart `room-chain.ts`, existing `recipe_area` adapter, and explicit
`fit_box` support in `lab_input`. Preserve the Colour/Portal/Review lab families.
