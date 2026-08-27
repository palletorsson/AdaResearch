# Boolean surfaces, taught in the order the engine needs it

> Sixteenth sequence through the recipe (2026-08-27). Cheat-code: **`CSGShape3D` — form
> by ARGUMENT.** The engine ships the whole vocabulary as an enum on one property:
> Union, Intersection, Subtraction. Three words, and the set is closed.

The leanest sequence in the corpus — 5 concepts, 5 tiles, one artifact each. The
concepts were already real; what was missing were the rungs the operations ASSUME.
Nothing owned the file, so the canon is authored in CONFIG (10 rungs) and most of them
start **starving and say so** — the forces Scaling lesson: a hungry rung is a
commission, not an embarrassment.

## The ladder
1. **Two solids, overlapping** — an operation needs contested ground. Pull the operands
   apart and every boolean returns one of them unchanged.
2. **The three verbs** — the complete vocabulary, an enum on one property.
3. **Union** — every point belonging to either: the weld with no seam left.
4. **Intersection** — only what both claim; the smallest of the three, and the only one
   that cannot grow.
5. **Difference** — the cavity, the doorway, the bite.
6. **Order matters** — A−B ≠ B−A, and subtraction is the ONLY verb that cares. A
   building minus its rooms is architecture; the rooms minus the building is nothing.
7. **The tree** — `CSGCombiner`: the result of one argument becomes an operand in the
   next, and the whole tree recomputes when any leaf moves.
8. **The seam** — where surfaces meet, edges are BORN that neither solid had. The
   boolean does not select geometry, it invents it.
9. **The debt** — CSG is recomputed, not stored. `bake_static_mesh` exists because at
   some point you must stop arguing and keep the answer.
10. **Architecture as difference** — at building scale the verb disappears into the
    result.

Live at **localhost:3003/boolean_surfaces-concepts** — 7 tiles, 10 sections.

## The super: the_argument_of_solids

A debating chamber where **nothing is modelled**: every verdict is a live
`CSGCombiner3D` and the engine itself does the arguing. Contested ground shown as two
translucent operands with their shared region lit as a real intersection; the three
verdicts in a row; **A−B beside B−A** — a bitten cube against a crescent, unmistakably
different objects from the same two solids; a nesting tree ((box + lug) − bore); a
coincident-face seam with the born edge marked in red; the baked debt, still and cheap;
and a building that is a block minus its rooms, minus its doors.

Probe note worth keeping: the probe counts `MeshInstance3D` only, so it reported 83
meshes while seeing **none of the CSG** — for a CSG artifact the capture is the only
honest verification, and it confirmed all eight verdicts rendered. Rows were then
separated after the first shot, which had collapsed them into one line.

## Also repaired: the carry-forward guard was dead

The catch-all guard added during isosurfaces referenced `cfg`, which is local to
`build()` — in `main()` it raised, and the surrounding try/except swallowed it as
"carry-forward skipped", silently disabling the WHOLE rule. Transformation's 52-token
palette was one regeneration from vanishing again. Fixed to `CONFIG[dm]`, and both
behaviours re-verified: the palette survives, the stale catch-all does not.
