# Higher Dimensional

4D and 5D geometry visualization — tesseracts, penteracts, and dimensional projections.

## QFEP Connection

Higher dimensions are **structure beyond perception**. We can't see 4D directly, but we can project it to 3D (F, constraint of our space meeting E, full geometry). Rotation in higher dimensions reveals hidden structure — what looks like deformation is actually rigid motion in a larger space.

## Features

- **Penteract**: 5D hypercube
- **Tesseract**: 4D hypercube
- Double projection: 5D → 4D → 3D
- Interactive rotation in W and V axes

## Parameters

| Control | Description |
|---------|-------------|
| `projection_type` | Perspective/orthographic |
| `dist_5d/4d` | Projection distances |
| `rot_5d_vw` | 5D rotation in VW plane |
| `rot_4d_xw/yw/zw` | 4D rotations involving W |
| `animation` | Auto-rotate through dimensions |

## Files

| File | Purpose |
|------|---------|
| `penteract_demo.gd` | 5D visualization |
| `PenteractDoubleProjection` | Projection math |
| `*.tscn` | Scenes |

## See Also

- `alternativegeometries/` — Non-Euclidean spaces
- `transformation/` — Lower-dimensional rotations
