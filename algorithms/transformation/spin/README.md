# Spin

A three-phase copy-and-transform sequence that takes a single source mesh and replicates it along the X-axis: first with pure translation, then with combined translation and rotation, then with translation again. The result is a ribbon of copies that bends through space. The artifact teaches how **composed translation and rotation** create arcs and spirals from straight-line copies, using a `MultiMesh` for efficient rendering.

## Concept Taught

**Transformation composition** -- specifically the interplay between translation and local rotation -- is central to computer graphics and robotics. Phase 1 produces a straight line (translation only). Phase 2 introduces per-copy Z-axis rotation on top of continued translation, curving the line into an arc. Phase 3 resumes pure translation in the new orientation. This three-phase approach makes it visually clear how rotation changes the frame of reference for subsequent translations.

## How It Works

1. The script runs in `@tool` mode for editor preview.
2. A `MultiMesh` is created with `1 + copy_count_phase1 + rotation_count + copy_count_phase3` total instances.
3. The script reads the mesh from either the `source_mesh` export or the first `MeshInstance3D` child named `copyandrotate`.
4. **Phase 1 -- Translation**: starting from the source transform, each copy adds `translation_step` to the X origin.
5. **Phase 2 -- Translation + Rotation**: each copy adds the same X step and also applies `z_rotation_degrees` of local Z-axis rotation via `rotated_local`.
6. **Phase 3 -- Translation**: continues stepping in X with the accumulated rotation from Phase 2.
7. If `alternating_colors` is enabled, per-instance colors alternate between `color_a` and `color_b`.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `copy_count_phase1` | int | `10` | Copies in the straight translation phase |
| `translation_step` | float | `0.14` | X-axis distance between consecutive copies |
| `rotation_count` | int | `12` | Copies in the rotation phase |
| `z_rotation_degrees` | float | `15.0` | Degrees of Z-rotation per copy in Phase 2 |
| `copy_count_phase3` | int | `10` | Copies in the final straight phase |
| `source_mesh` | Mesh | `null` | Optional mesh override (falls back to child node) |
| `alternating_colors` | bool | `true` | Alternate between two colors |
| `color_a` | Color | Black | Color for even-indexed copies |
| `color_b` | Color | White | Color for odd-indexed copies |
| `regenerate` | bool | `false` | Editor button to rebuild |

## Features

- `@tool` script: full editor preview of the generated ribbon.
- Three distinct transformation phases (translate, translate+rotate, translate).
- MultiMesh instancing for efficient rendering of many copies.
- Per-instance color support for visual alternation.
- Source mesh auto-detected from child node or set via export.

## Files

- `spin.gd` -- Main script: three-phase MultiMesh generation with translation and rotation composition.
- `spin.tscn` -- Scene file (contains the `copyandrotate` source mesh node).
