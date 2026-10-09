# What a form leaves room for

19 September 2026. First bridge from the early encounter prototype into the
existing later BiomeObject (generation 17).

Review: http://127.0.0.1:3003/biome-primitives/inheritance.html

Follow-up: [Doors become banners](biome-inheritance-banners.md) adds an automatic
lift and patterned surfaces. The width study documented here is retained below
the new study on the review page, and remains available with `banners = false`.

The artistic aim is a continuing lineage of forms whose roles change as the
world gains capabilities. An abstract panel can remain a sculpture and become
a boundary another process must acknowledge. The early form need not be a
disguised tree awaiting its final appearance.

## What now works

`commons/artifacts/biome_inheritance/biome_inheritance.gd` composes the actual
BiomeObject with a `Trans_Scale` encounter. A caller can assign an existing live
encounter to `sculpture` before adding the bridge to the scene. That node is
reparented, retaining its model, existing collision bodies, form IDs, trace and
clock. Its ground-local coordinate frame becomes the later ground's frame.
Without a supplied encounter, the review scene creates the shared seed-7 fixture.

The habitat inherits the source seed. It supplies the ground, while the early
ground is retired. The five x/z hinge positions persist. Small foundations adapt
the panels to terrain height, sampling the maximum panel width at the selected
angle once. Heights are recorded and do not move during width comparison.
The renderer and dimensional model are the same ones used in the early study.

The later biome generates its normal terrain, residents and cover candidate
plan. We cache that CPU plan and read each cover mesh's transformed bounds.
A shared spatial rule in `commons/biome_layers/inherited_form_clearance.gd`
measures distance to the oriented panel footprint. The chosen clearance is
0.35 m plus a conservative circular envelope around the plant mesh's AABB.
This reserves ground around the panel regardless of its elevated base.

Only cover membership changes. No random draws are repeated, no excluded
member is replaced, and the original species, positions and colours remain.
Each exclusion records the responsible form ID. Width changes from 0.66 to
1.375 m at a fixed 45-degree pose. Returning the width restores exactly the
same candidates. This is an instantaneous occupancy rule, not plant growth,
death or ecological adaptation. The 12-second automatic film separates it from
the earlier hinge-cycle demonstration.

The host's `habitat.counts.cover` remains its original candidate count. The
bridge's authoritative visible count is `standing_cover`; `excluded_cover`
contains the omitted members and their causes. This keeps the production
BiomeObject and its RSI record unchanged.

## Evidence and limits

- 572 candidates from the existing seed-7 habitat; 469 stand with narrow
  panels, 422 with wide panels. Returning width restores the same 469 IDs.
- 1,020 headless checks cover the live handoff, retained body identity and
  archive, fixed terrain/layout, monotonic exclusion, cause IDs, shape
  clearance and rendered MultiMesh counts.
- Native Godot captures agree with the headless accepted/excluded records.
  The five stills and twelve-second movie use the real composed scene.
- `Primitives_Melencolia` and `full` illustrate the later generator's own
  early and mature stages. They do not establish chronological growth.
- Larger catalogue residents do not yet read this clearance rule and may
  intersect the panels. Shade, resources, soft interaction, whole-spine
  persistence and headset walking remain unimplemented here.

## A direction for emergence

This bridge makes an earlier form causally relevant. It is a starting condition
for stronger emergence, not proof of it. Next experiments can introduce:

1. Orientation affects a measured light field, and a later placement rule
   reads that field. Compare against today's geometry-only rule.
2. A retained trace becomes input to branching, with a fixed-prescription
   comparison to reveal what the visitor's detour changes.
3. A membrane keeps a recognizable identity while forces and softness alter
   which bodies it supports or shelters.
4. At later agent/QFEP stages, compare and revise the objective itself: who
   receives room, resources and a place in the record?

The scaffold for each step is: inherited form → new operation → consequence
for another body → inspectable limit. Artist references can guide the forms;
the implemented relation has to carry the argument.
