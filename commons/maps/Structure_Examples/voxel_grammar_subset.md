# Voxel Grammar Subset

This folder now includes `voxel_grammar_subset.json`, a reusable module catalog for the next combinatorial layer in voxel grammar design.

## Assumptions Used
- Grid: 1m cubic cells
- Verticality: multi-level maps are allowed
- Tables/plinths: treated as walkable platforms (`height=2`)
- Structure encoding: same as map `structure` layer (`0` void, `1` floor, `2` platform, `3+` wall/pillar)

## Scope
- `between`: joints, apertures, corridor transitions, threshold buffers
- `beyond`: courts, rhythm fields, symmetry errors, negative-space modules, topology hooks
- 20 high-yield modules are included in `priority_batch`

## Piece Format
Each piece defines:
- `size` in local module coordinates (`x`, `z`, `y`)
- `heightmap` (2D structural footprint)
- Optional `void_ops` for carved openings (door/window/anti-column)
- Optional `logic_hooks` for topology modules (for example portal wrap)
- `flow_ports` for module stitching
- `variants` for rotation and mirror operations

## Naming
Pattern:
`[Role]_[Primitive]_[Operator]_[Size]_[Variant]`

Example:
`THRESH_GATE_PILLARPAIR_3x1_A`

## Integration Notes
- For static map work, copy/compose `heightmap` into `structure`.
- For authored apertures, apply `void_ops` in your geometry pass.
- For non-Euclid modules, map `logic_hooks` to your portal/trigger system in `utilities` or artifact scripts.
