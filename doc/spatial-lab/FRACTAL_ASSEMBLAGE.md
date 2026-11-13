# Fractal assemblage — four prefab roles

Open `/spatial-lab?recipe=lab_fractal_assembly&sequence=fractals`.

The experiment repeats a small construction: branch, joint and platform. A fourth
prefab marks each terminal. Choose each role separately from the same prefab
catalogue used elsewhere in the lab. Geometry and materials come from those actual
Godot sources; each is fitted to its role's dimensions. This is not an original-scale
museum transfer.

The procedure is related to the existing recursive trees, recursive furniture and
braced towers in the Fractal sequence:

- `algorithms/fractals/recursive_tree/recursive_tree.gd`: inherited branching and a stopping depth.
- `algorithms/fractals/cubesubdivision/recursive_chair.gd`: assign different roles to parts of a construction.
- `commons/artifacts/fractal_truss_tower/fractal_truss_tower.gd`: repeat a structural assembly at smaller scales.

These are conceptual precedents; their original scenes are unchanged.

## The rule

At a branch tip, create N children. Each child starts at that tip, inherits the
parent's local frame, turns around local Y and leans around local Z. Multiply all
its dimensions by the child/parent ratio. Repeat until the chosen depth.

`child_frame = parent_frame × turn_Y(twist + i × 360/N) × lean_Z(angle)`

For N=3 and depth=3 there are 40 branch assemblies and 27 terminals:
`3 × (1 + 3 + 9 + 27) + 27 = 147` editable parts. Depth zero is still a useful
four-piece model. One child makes a single recursive chain. Growth is deliberately
bounded at three generations and three children per branch.

## Starting forms

| Preset | Parts | Rule |
|---|---|---|
| Branching canopy | Timber planks, building cubes, timber panels, traffic pyramids | 42° lean, 35° local twist, 0.66 ratio |
| Spiral tower | Building cubes, trace balls, timber panels, bipyramids | 18° lean, 75° local twist, 0.78 ratio |
| Wide coral | Timber planks, trace balls, wedges, tetrahedra | 68° lean, −55° local twist, 0.62 ratio |

The prefabs are roles rather than fixed ingredients: try barriers instead of
branches, balls instead of terminals, or wedges instead of platforms. Changing a
prefab leaves the recursive attachment positions intact.

Shared grammar example:

```json
{
  "t": "lab_fractal_assembly",
  "with": {
    "source": "timber_plank_2m",
    "joint_source": "construction_cube",
    "deck_source": "timber_panel_1x1",
    "tip_source": "traffic_pyramid_5",
    "depth": 3,
    "branches": 3,
    "size": 0.85,
    "ratio": 0.66,
    "angle": 42,
    "twist": 35
  }
}
```

## Save and refine

**Save variation + native check** creates a separate trial. **Arrange this variation
in the lab editor** opens actual exported models, with stable names such as
`Root_1_2_Deck`. Move, rotate or copy any member independently; those edits are
stored in the trial's shared desktop/VR layout. Reusing recipe settings makes a
new variation, leaving the earlier arrangement saved. Nothing is placed on a main
Void floor by this workflow.

## Evidence and limits

Godot and Three.js use the same explicit numerical rule. The browser's generated
members explicitly request YXZ rotation order to match Godot when multiple axes
are involved. Tests compare positions, orientations, source identities, all exported
GLBs, independent copy/move/rotate and the editor save/reload contract.

This is a static composition study. Each part uses a fitted box collider, including
non-box prefabs. Intersections are reported, not silently resolved. There is no
load-bearing, joint, balance, walkability or physical-headset acceptance. Recursion
creates a finite approximation, not an infinite fractal.

Receipts: `ada_run/spatial-studies-2026-11-13/references.json` and
`editor-checks.json`. Each trial also has native screenshots and checks under
`ada_run/spatial-lab-2026-10-27/<trial>/`.
