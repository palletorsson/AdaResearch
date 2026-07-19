# Bricolage sequence — artifact inventory (scoping, not a build)

> Requested 2026-07-19. The `bricolage` sequence ("Bricolage: From Parts to
> Structures" — *construction without blueprint; discover structures by
> recombining primitives until constraints are satisfied*) is a real, non-spine
> 7-map sequence whose maps reference **38 artifacts that do not exist** (zero
> scenes on disk, zero registry entries). This is the build-vs-shelve scoping.
> Source: scratchpad `bricolage_inventory.py`.

## Headline numbers

- **38 unique artifacts needed**, across 7 maps.
- **0 built** — no `.tscn`/`.gd` on disk for any of them.
- Registry fuzzy-match calls 36 of them "alias?" — but that is **suffix-string
  similarity, not semantic reuse**. On honest inspection:
  - **~3 genuine reuse** (an existing artifact really fits — just rename the map token)
  - **~33 new** — but most are *lightweight compositions of primitives that
    already exist* (a "specimen" is a primitive on a plinth with a label; an
    "affordance" is a primitive re-labelled by use)
  - **2 genuinely novel** (`geodesic_dome`, `chair_parts_inventory`)

So it is not "38 hard artifacts." It is a coherent pedagogical family, most of
it thin, resting on primitives the project already has.

## Genuine reuse (rename the map token, build nothing)

| needed | use as | existing artifact |
|---|---|---|
| `icosahedron_base` | Dome | `icosahedron` (exists; 0.81 match — likely the same solid) |
| `chair_assembled` | Chair | `chair_assembly_puzzle` (exists; used in Trans_Composition) |
| `cube_specimen` | Inventory | `cube_scene` (exists; verify it reads as a specimen) |

## New, but thin — primitives already exist to base them on

**The specimen family (Bricolage_Inventory) — 9.** Each is a primitive on a
plinth with an identity label: `point_specimen`, `line_specimen`,
`triangle_specimen`, `plane_specimen`, `cube_specimen`, `sphere_specimen`,
`cylinder_specimen`, `torus_specimen`, plus `inventory_workbench` (the rack).
Every base primitive exists (point/line/triangle/plane/cube/sphere/cylinder/
torus). One reusable "specimen plinth" wrapper + labels would cover all 8.

**The affordance family (Bricolage_Affordances) — 6.** A primitive re-labelled
by what it *does*: `cylinder_as_axle`, `cylinder_as_column`, `plane_as_seat`,
`plane_as_wall`, `sphere_as_hub`, `sphere_as_joint`. Same wrapper idea:
existing primitive + an affordance label/pose. The pedagogy (parts defined by
action, not category) is the whole point — these are deliberately the same
shapes wearing different jobs.

**The array-probe family (Bricolage_Arrays_as_Probes) — 4.**
`linear_array_demo`, `radial_array_demo`, `grid_array_demo`, `stack_array_demo`
— small layout demos (arrays as "systematic exhaustion of possibility"). Kin
exist: `sparse_array_demo`, `bar_array`, the pattern-tile family. One
parametric array-demo could cover all four (mode = linear/radial/grid/stack).

**The constraint family (Bricolage_Constraints) — 6.** Paired fail/pass
vignettes: `gravity_fail_demo`/`gravity_pass_demo`,
`balance_fail_demo`/`balance_pass_demo`,
`triangulation_fail_demo`/`triangulation_pass_demo`. Small physics tableaux
(what pushes back). Kin: `balance_puzzle`, `gravity_well`. Each pair is one
demo with a fail state and a pass state.

## New composite builders (the real content)

**Chair (Bricolage_Chair) — 3.** `chair_parts_inventory` (**BUILD** — novel),
`chair_builder` (the assembly interaction), `chair_assembled` (**reuse**
chair_assembly_puzzle). The chair as "vernacular bricolage — emerges from
inventory through constraint satisfaction."

**Sculpture (Bricolage_Sculpture) — 5.** `balanced_sculpture_1`,
`balanced_sculpture_2`, `counterweight_demo`, `sculpture_builder`,
`tension_demo`. Balance-discovery pieces (kin: the Calder `calder_mobile`,
`balance_puzzle`). A balancing-composition builder + two exemplar outputs.

**Dome (Bricolage_Dome) — 5.** `geodesic_dome` (**BUILD** — novel),
`icosahedron_base` (**reuse** icosahedron), `subdivision_demo` (kin:
`cube_subdivision`), `strut_inventory`, `dome_builder`. The geodesic dome as
"what triangulated struts want to become."

## Verdict

The sequence is coherent and its concept is strong (Lévi-Strauss bricolage as
a construction pedagogy). The cost is **one reusable "specimen/affordance
plinth" wrapper + one parametric array-demo + a few paired constraint
vignettes + three small builders (chair/sculpture/dome) + two genuinely novel
pieces (geodesic_dome, chair_parts_inventory)** — plus ~3 map-token renames to
existing artifacts. That is a focused artifact session, not a mountain: the
plinth/affordance wrappers collapse ~15 of the 38 into two reusable templates.

**Build-vs-shelve is Palle's call.** If build: start with the specimen plinth
wrapper (unblocks Inventory + Affordances = 15 artifacts at once), then the
parametric array-demo (4), then the constraint pairs (6), then the three
builders. If shelve: the maps stay as-is (they render clipboard + dark_sphere
placeholders today) and the sequence is marked WIP.
