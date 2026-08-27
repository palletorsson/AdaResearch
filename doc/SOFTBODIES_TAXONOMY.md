# Soft bodies, taught in the order the engine needs it

> Fourteenth sequence through the recipe (2026-08-27). Cheat-code: **`SoftBody3D` —
> a mesh that admits it has insides.**

Rival files once more (`softbody`, the bespoke canon of 21 real concepts, vs
`softbodies`, a 35-section June file whose "concepts" are sentences — *"A cube that
won't hold its shape"*, *"Two chemicals. One miracle."*), alias already correct. Pure
refine: four rungs at source in `tools/build_softbody_concept_map.py`, before the
phenomena.

## The four inserted rungs

1. **The vertex is a body** — a rigid body has ONE position; a soft body has a position
   per vertex. That is the whole ontological shift, and everything else in the sequence
   is a consequence of it.
2. **The constraint that remembers** — shape is not a fact, it is a MEMORY held in
   edges: each spring remembers a rest length and keeps pulling toward it. Cut the edges
   and the vertices forget what they were.
3. **The iteration budget** — `simulation_precision`: softness is a budget. More solver
   passes means stiffer and slower. Elasticity you can afford is the only elasticity you
   have. (The same shape as primitives' smoothness budget — the engine keeps charging
   for continuity.)
4. **The anchor** — an unpinned soft body falls forever. Something rigid must hold it:
   the cloth needs its rail, the jelly its plate. **Softness is always relative to
   something that refuses to move.**

Then the inherited 21 follow: mass-spring networks, Verlet, strain and pressure,
settling, jelly, cloth, bounce, viscous, the membrane, breathing and the abject
boundary, Miura folds, folding creatures, tentacles, soft morphology, and the native
SoftBody3D families. Live at **localhost:3003/softbodies-concepts** — 101 tiles, 25
sections. Truth kept: *"Form is not imposed — it emerges from the material's own
dynamics."*

## The super: the_confessing_body

An anatomy theatre for things with insides. On the slab, the confession itself: a rigid
cube marked with **one** pin at its centre, beside a soft cube pinned at **every**
vertex and webbed with its edges. Beside them the edge-memory rack — a spring at rest
and the same spring stretched, each labelled with the length it is trying to return to.
A budget row shows one jelly relaxed at 1, 3 and 8 passes, sagging to firm.

Above it all, a cloth **genuinely draped**: an 11×8 mass-spring grid, gravity applied
and rest-length constraints solved for 60 real passes, hanging from two gold anchor
pins. Around the theatre: a Verlet chain relaxed the same way, a pressure-held membrane,
a Miura fold that remembers its creases, and a tentacle that is nothing but constraint.

416 meshes, every drape computed vertex by vertex at build time. Seated at The vertex is
a body.
