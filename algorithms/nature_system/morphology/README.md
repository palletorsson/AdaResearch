# Nature System — Morphology

Kingdom-specific mesh generators that read `CritterDNA` and produce procedural 3D geometry. All four generators follow the same architecture: static `build()` method, `RefCounted` base, returns a `Node3D` subtree under a given parent. Materials are applied via `CritterTraitMapper`.

## Generators

### CreatureMorphology

Segmented body spine with bilateral limbs. DNA genes control segment count, limb pairs, body curvature, taper, twist, and limb style (legs → tentacles → fins interpolated by `mobility` gene). Head features include eyes and antennae/horns; tail length scales with segment count.

### FlowerMorphology

Concentric petal rings with per-petal Bézier curves. Uses `MultiMeshInstance3D` for efficient petal rendering — one draw call for all petals in a bloom. Supports stamen clusters, stems, and inflorescence (multiple sub-flowers on branching stems). Per-petal color variation is encoded via `INSTANCE_COLOR`.

### TreeMorphology

L-system branching interpreted by a 3D turtle that emits tube-segment meshes. DNA maps to L-system generations (2–5), branches per fork, rotation angle, decay, leaf density, and phyllotaxis pattern. Leaves batched into a single `MultiMeshInstance3D`.

### FungusMorphology

Mushroom forms: cap + stem + gills/pores + spore clusters. Supports bracket fungi (shelf stacking via `segments`), fairy rings and colony clustering (via `sociality`/`inflorescence`), bioluminescent glow (via `iridescence`), and cap surface patterns.

## LOD Support

Each generator defines LOD constants controlling cross-section resolution, segment counts, and maximum element counts across four detail levels (0=highest, 3=lowest).

## Files

- `creature_morphology.gd` — Segmented creatures with limbs, head, and tail.
- `flower_morphology.gd` — Petal-ring flowers with Bézier geometry.
- `tree_morphology.gd` — L-system trees with turtle interpretation.
- `fungus_morphology.gd` — Mushroom caps, gills, spores, and colonies.

See the parent [Nature System README](../README.md) for architecture and DNA gene mappings.
