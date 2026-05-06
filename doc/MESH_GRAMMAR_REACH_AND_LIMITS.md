# Mesh-Grammar: Reach, Limits, and the Critter Question

*Written 2026-04-26 after the gen02 flower-top render.*

## TL;DR

- **The face-and-tag substrate is the right shape.** `tag_by_grammar` +
  `paint_by_tag` + `extrude_by_role` + `bulge_by_role` + `hide_by_rule`
  already give us a recognisable flower-from-above and a 3D solid with
  per-role morphology. We do not need to rearrange.
- **What we hit a wall on is *part-individuation*.** Petals as a contiguous
  annular band can be coloured and extruded *together*, but cannot splay as
  *separate pieces* until we add ops that promote each tagged region to its
  own sub-mesh.
- **For critters: do not unify the runtime systems.** Use mesh-grammar as
  the *design-time* substrate that exports to the existing runtime
  (CritterDNA, MiuraCrawler, fold_system, hazard creatures, pokemon_studio).
  One research surface, many consumers.

## Where we stand

| Op | Status | What it gives |
|----|--------|---------------|
| `tag_by_grammar` | shipped | role tags from anatomical bands |
| `paint_by_tag` | shipped | per-face color from role |
| `hide_by_rule` | shipped | substrate visibility carved into faces |
| `extrude_by_role` | shipped | per-role distance + scale push |
| `bulge_by_role` | shipped | per-role rounded displacement |
| `subdivide_by_attention` | scoped | not yet — glyph as morphology |
| `mark_specimen` | scoped | not yet — labels and pickup hooks |
| `protect_path` | scoped | not yet — PATH_GUARANTEE in face graph |
| `compose_edges` | scoped | not yet — 13 edges as recipes |

The five shipped ops produced `gen02_unified_flower_top` (a readable flower
from above) and `gen02_unified_flower_top_morph` (a domed citadel, not yet
a recognisable 3D flower).

## Where the wall is

When the flower stamen is a concentric **ring of faces**, extruding all of
them upward produces a **cylinder wall**, not 24 separate stamen stalks.
Same for petals: a band of faces extruded outward becomes a frill, not
12 individual petals splaying off the receptacle.

The face-tag-op vocabulary handles **regions** beautifully. It does not yet
handle **part-individuation** — the step where a region of N faces becomes
N independent objects, each with its own coordinate frame to grow from.

This is solvable with two more ops, both of which fit the existing pattern
without rearranging anything:

- `cluster_by_role` — partition the faces of a role into K clusters by
  position. "Petal ring of 24 faces, K=12 clusters" → 12 petal centroids,
  each tagged `flower_petal_0` … `flower_petal_11`.
- `lsystem_branch_by_role` — for each tagged face (or cluster), grow an
  L-system stalk along its normal. Stamen as 12 stalks instead of 1 wall.
- `replace_with_mesh_by_role` — swap each tagged region for a stamped
  primitive (lily petal mesh, fern leaf, beetle elytra). Bridges to the
  primitive library and to artifact scenes.

With those three, the morphology vocabulary is expressive enough for
flowers, simple insects, and bird silhouettes. We do not need to rethink
the substrate; we extend it.

## The critter question

The repo already contains many creature systems. They serve different
masters and **should not be unified at runtime**:

| System | Purpose | Runtime |
|--------|---------|---------|
| `algorithms/nature_system/` (CritterDNA, evolution, breeding) | living ecosystems, ecology progression | per-frame on every map |
| `algorithms/nature_system/studio/` (pokemon_studio) | breeding/growth/ecosystem lab | scenario-driven |
| `commons/folding/` (MiuraCrawler etc.) | folding-as-language demo | generative + animated |
| `commons/hazards/` (DangerZone, transformation) | threat creatures | event-driven |
| Hand-modeled critter scenes | bespoke set pieces | scripted |

These have different APIs because they have different jobs. Forcing them
through one base class would either dumb them all down or bloat the base.

**What CAN be unified is the design-time layer.** The mesh-grammar should
become the place where you author critter morphology — tag → paint →
extrude → branch → fold — and then **export** to whichever runtime needs it:

- Export to a `.tres` MeshData → consumed by NatureRenderer as a
  CritterDNA phenotype seed.
- Export to a Node3D scene → loaded by MiuraCrawler / hazard creatures.
- Export to a CritterDNA dictionary → fed to pokemon_studio breeding.

The shape is: **one research substrate, several runtime consumers**.
That is exactly the shape we already settled on for substrate vs.
mesh-grammar (substrate stays in maps, mesh-grammar absorbs the
research-time vocabulary). We apply the same answer one floor up: the
mesh-grammar absorbs the design-time critter vocabulary, runtime systems
keep their own bodies.

## Next moves (concrete, ordered)

1. **`cluster_by_role`** — partition role faces by k-means on centroid.
   Two days of work, zero architectural risk. Unblocks part-individuation.
2. **`lsystem_branch_by_role`** — wire LSystemBranchOp to per-cluster
   tagged faces. We already have LSystemBranchOp; this is a per-role
   wrapper, mirroring the bulge_by_role / extrude_by_role pattern.
3. **`replace_with_mesh_by_role`** — load primitive scene per role,
   place at each tagged face's centroid + normal. Bridges to the
   primitive library and unlocks "use the lily-petal artifact as the
   petal piece" without writing geometry by hand.
4. **Critter export adapter** — `MeshGrammarExporter.to_critter_dna(grammar)`
   that reads role tags + final mesh and emits a CritterDNA dictionary.
   No runtime changes anywhere else.
5. **First critter target**: a tagged-and-folded beetle. Insect grammar
   already exists in `tag_by_grammar`; with cluster + lsystem we can grow
   six legs instead of one thoracic ring.

## Honest summary

The mesh-grammar **has the substrate** to reach flowers and critters.
What it does not yet have is the **part-individuation step**. Three
small ops (`cluster_by_role`, `lsystem_branch_by_role`,
`replace_with_mesh_by_role`) close that gap without rearranging
anything. Critters stay distributed at runtime; the mesh-grammar
becomes the single place we *design* them.

The vision is intact. The plan is additive.
