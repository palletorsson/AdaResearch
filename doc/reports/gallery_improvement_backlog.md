# Gallery / Space-Automation — improvement backlog

Standing list of what can still improve, roughly ordered by leverage. Struck
items are done. This is the steering surface for the auto-research loop.

## Done this session
- ~~Wedges walkable both ways (wp on terrace steps)~~
- ~~Grand stairs (3-wide), Marly flank (furniture at stair heads)~~
- ~~Return-path measured (reverse BFS over climb rules)~~
- ~~Full furniture vocabulary (floating wall, plinths s/m/l, hollow, platform, 2m table, tall vitrine, cabinet, infoboard, exit/fire signs)~~
- ~~Hospitality genes (signage/infoboard) — won in every taste~~
- ~~2m niches (NICHE_LEN=2)~~
- ~~Per-prop isolation scenes (tools/prop_isolation.py, 18 Prop_* maps)~~
- ~~Wedge y-sink fixed (prism base seats on floor)~~
- ~~Wedge rotation corrected to wp:-90 (walked-verified)~~
- ~~PATHFINDING + FOOTPRINT in fitness (reach_frac, approach_frac, detour)~~

## Pathfinding & footprints (deepen what just landed)
1. **Real footprints, not proxies.** FOOTPRINT{} is a hand table; read the
   measured `artifact_sizes.json` grid_cells + registry spatial_needs.clearance
   per slot so a 2m table reserves its true AABB and clearance, and place.py's
   sync_footprints feeds the same numbers.
2. **Wire walk_evaluator directly.** It already scores detour / encounter-order
   / backtrack with footprints — call it on the compiled gallery instead of the
   local BFS, so empty-gallery walkability uses the same instrument as placed maps.
3. **Encounter order term.** Reward galleries whose nearest-neighbour walk visits
   slots in a sensible spawn→...→exit order (no criss-cross), not just low detour.
4. **Clearance-aware placement.** When two slots' clearances overlap, nudge or
   drop one — currently only checked, not repaired.
5. **Door-width pathing.** Verify the player capsule fits every doorway on the
   actual walk (the jamb bug class); fold into reach_frac.

## Architecture / form
6. **Wall-wash light strips** as a gene (grazing light down a hanging wall).
7. **Floor-material zones** — the red-carpet street, a plinth apron.
8. **Coat-check / bench entry sequence** — an arrival room before the collection.
9. **Niche-embedded vitrines** (a case *inside* a 2m niche).
10. **Mezzanine / upper gallery** (the balustrade rail already exists in the shell).
11. **Rotunda oculus** — top-light the round form's centre.

## The loop / integration
12. **Curator compiles into a champion genome** — exhibition.json → pick a
    taste-profile → evolve the room → hang the argument into its slots.
13. **place.py fills the slots** — feed a champion gallery + a cast to the real
    placement engines (humanoid_walker / hybrid / sim_annealing).
14. **Walk-verdict re-weighting** — Palle's spoken reactions → fitness weights →
    next generation (the human-in-the-loop step, still manual).
15. **/gallery-dna interactivity** — click a champion → walk it in the live
    Godot bridge (map-simulator pattern), tune genes with sliders.

## Correctness / hygiene
16. **Physics walkability probe** — a headless test that actually spawns the
    player and confirms they can climb each wedge (rotation is invisible to the
    pathfinder; only a body or the eye catches it — cost us two wrong guesses).
17. **Overlap guard** — no two furniture pieces on adjacent cells whose meshes
    intersect (the tall cabinet vs a neighbouring plinth).
18. **Capture eye-level** — a first-person capture per champion for judging rooms
    from the body, not the iso bird's-eye.
