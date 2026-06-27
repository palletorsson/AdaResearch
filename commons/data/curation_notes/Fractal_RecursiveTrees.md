# Curation — Fractal_RecursiveTrees ("Branching Without Blueprints")

Sequence: **fractals** · tier source: `doc/fractal_concept_map.json` (group *Recursive trees*, truth: *"Split, rotate, recurse: the simplest recursion that looks alive — a trunk that is two smaller trees, forever."*)

## The argument
The map's lesson is recursion you can watch grow: *a tree is its own blueprint.* So the wall is staged as a **growth, left to right** — seed, rule, full tree, what the tree becomes, then a door out to other geometry. Curation here is the claim that the binary tree at the centre is not decoration but the whole idea made standable.

## Reading order (+X axis)
1. **Seed bay (x 0–1.2)** — `small_subdivision_cube` (touch it, it halves: *one contains many*) on a **micropod**, set forward (z 2.3); beside/behind it the `living_paper` Mandelbrot readout on a slim 1×1 plinth, set back (z 0.5) and low — a quiet "recursion makes more than trees" aside.
2. **Rule bay (x 2.5–4)** — `recursive_tree_2` (the trunk that unfurls in real time) raised on a **tall narrow 1×1 plinth** (top_height 1.3, mid-depth z 1.1) because it is 2 m tall but only 0.4 m wide — high-and-narrow = precious; its stochastic sibling `fractal_lsystem_tree` (a 0.74 m thin upright) sits one step back on a **micropod** as the "deterministic vs stochastic" pairing the map's description names. Wall **panel #1** above this bay carries the Recursive-trees truth.
3. **Centerpiece (x 6.5, z 2.5)** — `recursive_tree`, the fully-grown 16 m binary tree, on a low broad **4×4 station_stage** pushed **forward** with empty x-space either side. *Its own depth, its own light, the focal point.* Truth on its plate / on wall **panel #2**: *"a list that learned to decide — left or right, less or greater."*
4. **Counter-form (x 10.5, z 0.3)** — `inverted_tree_cloud` on a second **4×4 stage** set **deep back** and offset: roots reaching down from the sky behind the hero, so orbiting the centerpiece reveals its mirror. *"roots are where the real computation happens."*
5. **Useful-structures bay (x 13.5–15)** — the Act VI *applied* pair: `cube_desk` (branching that holds a tree up holds a shelf up) and `fractal_scene` (fractal architecture), each on a slim 1×1 plinth, staggered in depth (z 1.6 / 0.7).
6. **Bridge coda (x 17.5, z 1.8)** — `mobius_world`, an xlarge walk-in world, on a 3×3 stage: the map's own teleporter goes *Next: Cantor Set*, so the wall ends on "and here is an entirely different geometry" — a door, not a wall.

## Focal point
`recursive_tree` (the 16 m grown binary tree) — largest, lifted on its own forward stage with negative space, the only thing you must walk *up to*. Everything left of it builds the rule; everything right of it spends the rule.

## Why each prop (fit the footprint, never a default base)
- **station_micropod** ×2 — `small_subdivision_cube` (measured AABB **0.1 m**) and `fractal_lsystem_tree` (**0.74 m**, thin) are genuinely sub-1 m. A full plinth would over-claim a metre of ground for a held thing; the 0.6 m micropod post snaps to the cell without lying about its size. (Micropod shares `station_plinth.gd` + bakes `base_meters 0.6`; config = `caption_text` + `top_height`, confirmed via `tools/refit_micropods.py`.)
- **station_plinth 1×1, tall/narrow** ×4 — `recursive_tree_2` (0.4×**2.0** m), `living_paper`, `cube_desk`, `fractal_scene` are ~1-cell footprints. Per the plinth's own identity (*"size IS part of the argument… high and narrow = precious"*) they get slim high podiums, `cap_inset 0.3`, top_height 1.0–1.3.
- **station_stage 4×4** ×2 — `recursive_tree` (fp 9, capped from 256) and `inverted_tree_cloud` (fp 9, from 180) are walk-in scale; low broad stages with `name_plate` plates, capped at 4×4 per the brief's >9 rule.
- **station_stage 3×3** ×1 — `mobius_world` (size_group xlarge, a navigable world) gets a sized stage, not a podium.
- **station_panel** ×2 (wall) — tier/section headers carrying the map's *own* truth-beats, in 2D-in-3D pinned text. No floating labels: the editor hides each artifact's Label3D, so every base's plate IS the label.

## Every artifact gets a plate
All 9 artifacts carry a surface-pinned 2D-in-3D plate set to the display name: plinth/micropod via `caption_text`, the three stages via `name_plate` (NOT caption_text) — so the big walk-ins on stages are labelled without demoting them to low plinths.

## Real 3D composition (not a flat z)
Depth spans **z 0.3 → 2.5**; heights span **0.18 (stages) → 1.3 (tall plinths)**. Forward: seed micropod (2.3) and the hero stage (2.5). Deep background: the inverted-cloud counter-form (0.3) and the lsystem sibling (0.4). The two big stages sit at opposite depths (2.5 vs 0.3) so orbiting reads the tree/anti-tree pair in 3D. Deliberate negative space flanks the centerpiece. Still reads left→right from the front iso.

## Tier coverage / counts
small 4 · medium **0** · large 2 · applied 3 (9 artifacts + 2 wall panels). `dark_sphere` is excluded — it is the void/sky backdrop, not a display object, so it is not put on a base (the baseline wrongly plinthed it).

## Prop gaps flagged
- **medium tier = 0.** This map stages no medium-tier artifact; the *Recursive trees* medium (`recursive_tree_bench`) is not placed in the map. Honest gap, not a prop shortfall — if a fuller ladder is wanted, pull in `recursive_tree_bench` (fp 4 → 2×2 plinth) as a kin to complete small→medium→large→applied.
- **No dedicated lighting prop** over the centerpiece. `station_luminaire` / `station_task_light` exist in the prop vocab and would let the hero stage read as lit-from-above; not used here to keep the first pass to bases + plates per the brief, but it is the obvious next add.
- **Stale registry scene paths** (not a curation issue): `fractal_scene` and `living_paper` registry `scene` entries point at moved files (`meshfractal/fractal_scene.tscn`, `substrates/living_paper/…`); both tokens still resolve as registry-known. Worth a registry repair pass.

## What to try next
1. Add `station_luminaire` above x≈6.5 to light `recursive_tree`.
2. Pull `recursive_tree_bench` (kin, sim 0.95) into a 2×2 plinth between the rule bay and the centerpiece to fill the medium rung.
3. Capture `--mode=map --target=Fractal_RecursiveTrees` after merge to verify the forward/back stage depths read in iso + free-cam.
