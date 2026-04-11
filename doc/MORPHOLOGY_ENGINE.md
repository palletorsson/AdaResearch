# Universal Morphology Engine

> Form as composable process. Every shape is primitives + modifiers + time.

## Architecture

```
CritterDNA (55+ genes)
  │
  ├── body_type 0-4 ──→ Kingdom builders (unchanged)
  │     ├── TreeMorphology      (L-system → turtle → branches)
  │     ├── CreatureMorphology  (spine → segments → limbs)
  │     ├── FlowerMorphology    (Bézier → petal rings)
  │     └── FungusMorphology    (revolution → cap + gills)
  │
  └── body_type >4 or form_process genes ──→ MorphoPipeline
        │
        ├── MorphoPrimitive     (atomic form generators)
        ├── MorphoModifier      (mesh transformations)
        └── Recursive children  (sub-pipelines for branches/limbs/details)
```

The kingdom builders are **not replaced**. The pipeline is a new route for forms that don't fit the four kingdoms — math objects, crystals, abstract sculptures, or creatures whose construction process differs from their kingdom's default.

## Three Core Classes

### MorphoPrimitive (`morpho_primitive.gd`)

Atomic form generators. Pure geometry, no DNA dependency.

| Category | Functions |
|----------|-----------|
| **Tubes** | `tube()`, `multi_tube()` — extracted from duplicated code in CreatureMorphology + TreeMorphology |
| **Surfaces** | `revolution()`, `bezier_sweep()` — extracted from FungusMorphology cap + FlowerMorphology petal |
| **Godot wraps** | `sphere()`, `cylinder()`, `cone()`, `box()`, `torus()`, `capsule()`, `prism()`, `quad()`, `plane()` |
| **Fields** | `sdf_mesh()` — evaluates a signed distance function on a grid |
| **SDF combinators** | `sdf_sphere()`, `sdf_box()`, `sdf_torus()`, `sdf_union()`, `sdf_subtract()`, `sdf_intersect()`, `sdf_smooth_union()` |
| **Instancing** | `multimesh_scatter()` — wraps MultiMeshInstance3D pattern |

### MorphoModifier (`morpho_modifier.gd`)

Mesh transformations via MeshDataTool. Each takes a Mesh, returns an ArrayMesh.

| Modifier | What It Does |
|----------|--------------|
| `taper()` | Scale cross-section along an axis |
| `twist()` | Rotate vertices proportional to distance |
| `bend()` | Curve mesh around a pivot |
| `noise_displace()` | Push vertices along normals by noise |
| `inflate()` | Push all vertices outward |
| `axis_scale()` | Stretch/squash along one axis |
| `spherize()` | Pull vertices toward a sphere |
| `wave()` | Sinusoidal displacement |
| `chain()` | Apply a sequence of modifiers |

Modifiers compose: `noise_displace(twist(taper(mesh)))` — order matters.

### MorphoPipeline (`morpho_pipeline.gd`)

Composable form recipe. Chains: skeleton → surface → modifiers → instancing → children.

```
Form = Skeleton -> Surface -> Modifier* -> Instance? -> Material
     | Primitive -> Modifier* -> Material
     | Form + Form  (via children)
```

Can be generated from DNA via `build_from_dna()` or hand-authored as a Resource.

## Five New DNA Genes

| Gene | Range | What It Encodes |
|------|-------|-----------------|
| `form_process` | 0–1 | 0=grown 0.3=extruded 0.5=carved 0.7=folded 1.0=crystallized |
| `skeleton_complexity` | 0–1 | 0=no skeleton 0.5=spine 1.0=branching recursive |
| `surface_method` | 0–1 | 0=sweep 0.3=revolution 0.5=SDF 0.7=primitive 1.0=particle |
| `modularity` | 0–1 | 0=monolithic 0.5=segmented 1.0=many distinct parts |
| `recursion_depth` | 0–1 | 0=flat 1.0=deep recursive (fractals, L-systems) |

All continuous floats. 0.35 form_process = between grown and extruded. Backwards compatible: existing DNA defaults to kingdom builder behavior.

## Taxonomy of Form Processes

| Process | F (stability) | E (entropy) | Biological | Mathematical | Architectural |
|---------|--------------|-------------|------------|--------------|---------------|
| **Grown** | High | Low | Trees, coral | Fractals, L-systems | Gothic vaults |
| **Extruded** | Medium | Low | Worms, spines | Sweeps, tubes | Columns, pipes |
| **Carved** | High | Medium | Shells, caves | Boolean ops, SDFs | Arches, niches |
| **Folded** | Variable | Variable | Insects, proteins | Origami | Deployable structures |
| **Crystallized** | Very high | Very low | Minerals, diatoms | Polyhedra | Geodesic domes |
| **Dissolved** | Low | High | Slime mold, lichen | Reaction-diffusion | Erosion patterns |
| **Assembled** | Medium | Medium | Colonial organisms | Graphs | Modular buildings |
| **Instanced** | High | Medium | Forests, swarms | Arrays, scatter | Tiling, mosaics |

## QFEP Connection

- **F** = Crystallized (rigid lattice, maximum stability)
- **-lambda*E(S)** = Dissolved (reaction-diffusion, maximum entropy)
- **phi*dE** = Fold system (spring velocity, tension, misfold rate)
- **Markov blanket** = The mesh IS the boundary between internal (DNA) and external (world)

## Curriculum Progression

| Stage | Algorithm | Form Unlocked |
|-------|-----------|---------------|
| 1 | Foundations | Box, Sphere, Cylinder |
| 2 | Recursion | L-system branching |
| 3 | Graphs | Node-edge sweep |
| 4 | Cellular Automata | Voxel grids |
| 5 | Noise | Displacement, terrain |
| 6 | Physics | Fold, spring deployment |
| 7 | Optimization | Evolution of form |
| 8 | Topology | Isosurface, SDF carving |
| 9 | Emergence | Swarm instancing, Turing patterns |
| 10 | Synthesis | Full pipeline — anything |

## File Locations

```
algorithms/nature_system/
  morphology/
    morpho_primitive.gd    NEW — atomic form generators
    morpho_modifier.gd     NEW — mesh transformations
    morpho_pipeline.gd     NEW — composable form recipe
    creature_morphology.gd existing (unchanged)
    tree_morphology.gd     existing (unchanged)
    flower_morphology.gd   existing (unchanged)
    fungus_morphology.gd   existing (unchanged)
  dna/
    critter_dna.gd         EXTENDED — 5 new process genes
  systems/
    morphology_router.gd   EXTENDED — pipeline dispatch
```
