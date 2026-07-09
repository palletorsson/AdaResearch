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
1. ~~**Real footprints at furnish time** — furnish_gallery.py matches the cast to
   slots by MEASURED artifact_sizes.json grid_cells; giants (koch_curve 41c,
   radiolaria 13c) flagged for their own room.~~ (Empty-slot measure still uses
   the per-KIND table, which is correct — slots are sized by kind, not by an
   artifact that isn't there yet.)
2. **Wire walk_evaluator directly.** It already scores detour / encounter-order
   / backtrack with footprints — call it on the compiled gallery instead of the
   local BFS, so empty-gallery walkability uses the same instrument as placed maps.
3. ~~**Encounter order term** — order_score = 1 - backtrack fraction of the
   nearest-neighbour walk; rewards progressive spawn→exit routes. Drama shifted
   to the axis form for its clean progression.~~
4. **Clearance-aware placement.** When two slots' clearances overlap, nudge or
   drop one — currently only checked, not repaired.
5. **Door-width pathing.** Verify the player capsule fits every doorway on the
   actual walk (the jamb bug class); fold into reach_frac.

## Architecture / form
6. **Wall-wash light strips** as a gene (grazing light down a hanging wall).
7. **Floor-material zones** — the red-carpet street, a plinth apron.
8. **Coat-check / bench entry sequence** — an arrival room before the collection.
9. ~~**Niche-embedded vitrines** — a tall vitrine set into each 2m niche recess;
   the alcoves are now real display spaces.~~
10. **Mezzanine / upper gallery** (the balustrade rail already exists in the shell).
11. **Rotunda oculus** — top-light the round form's centre.

## The loop / integration
12. ~~**Curator compiles into a champion genome** — tools/curate_gallery.py:
    brief + taste + cast -> evolve a fitting champion -> furnish by footprint
    -> Curated_<id> map + curation.json decision record. THE LOOP IS CLOSED.~~
13. ~~**Fill the slots with a cast** — tools/furnish_gallery.py: empty champion +
    cast -> footprint-matched furnished map (Furnished_CAP_1 done).~~ NEXT: hand
    the oversized/unplaced to place.py for their own generated rooms.
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
