# Which points must stay? — implementation

Primary source scenes:

- `res://algorithms/softbodies/cloth_straps/cloth_straps.tscn`
- `res://algorithms/physicssimulation/softbodies/softbodystop/fourstopsoftbody.tscn`

The hall desk is implemented in `commons/artifacts/timing_machines/soft_workshop.gd`. It binds models inside this map, offers PINS, SUPPORT, STIFFNESS, RELEASE, REBUILD, LANDING, RULE, and blocks repeated activation during rebuilds. The seven controls occupy a four-column, two-row desk with a small inclined transparent readout.

Walk along the hanging strips. Each begins as an open surface. Unlike the pressurized cube, it has no enclosed interior for pressure to inflate. The upper edge holds while the rest hangs below it.

Press PINS to keep only the upper corners. Look for the difference before naming it. The material settings have not changed. The allowed motion has: points that were fixed can now participate in the sag. PINS alternates those two arrangements; RELEASE removes the pins, and REBUILD makes fresh strips with their upper rows fixed again.

```gdscript
sb.set_point_pinned(i, keep)
```

For each strip, the desk finds the top row in its mesh coordinates and chooses which indices to pin. This is a boundary condition written into an array. The frame makes that condition visible, but the frame and the pinning rule are distinct constructions. A convincing support does not prove how the simulation is attached to it.

For a comparison that changes one condition at a time, follow PINS with RELEASE, then REBUILD before trying STIFFNESS. We now have two ways to change the silhouette: change the material response, or change which points may move. When we describe an object as compliant, how much of that description belongs to the object, and how much to the arrangement holding it?

The four falling bodies provide a second encounter. They are soft spheres, retained from the earlier collection, not pieces of woven cloth. LANDING changes the support below them between a floor, a narrow pan, a rail and a cone. Rebuilding that comparison also starts a new fall.

Their timers disable processing and raise damping and stiffness at scheduled moments. This stopping method is not an explicit snapshot of all vertex positions. The apparent crumple depends on the solver as well as the timer; it is not a shape the material was destined to have. Two shipped stop times are equal; four specimens do not automatically mean four different moments.

This prepares two questions we will return to: what makes the body deform, and what makes us stop looking? Carry the fixed edge into the next hall. There, the support itself moves.

The lesson token builds eight strips with 112 vertices each, at stiffness 0.34, damping 0.05 and simulation precision 5. The initial top row has eight pins per strip; PINS keeps the two corners, and RELEASE removes all pins. SUPPORT cycles gantry → none → hoop → mast → wall without changing those indices. The wall and other solid frame pieces can still collide; independence from the pin rule is not independence from the physics world. The current project uses Jolt Physics. Earlier GodotPhysics3D constraint descriptions are historical and are not a description of this solver.

The map begins with the rail landing, whose bar is 0.14 m wide. The first LANDING press selects the pan. Rebuilding starts new bodies and timers; the stop raises damping and stiffness rather than preserving a vertex snapshot.

Floor provenance: earlier structure cells remain behind the front court. Raw zeros receive explicit covers after relocation; this does not redefine zero globally. See `doc/space/soft-sequence-2026-09-15/floor-audit.json`. Headset reach and comfort require a human pass; runtime receipts separately record tested desktop operations.


<!-- study-spine:tension_membrane -->

## Installed application: A little give

`tension_membrane` occupies a new adjoining bay, after the existing encounters. Cell [15, 57], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/tension.tscn`. Original response to Senga Nengudi; no claim of exact reconstruction.

Change the added load while preserving the four anchors and material compliance. Reuses soft, constraint, force; adds no prerequisite node. The display and main-player controls are supplied.

<!-- tension-reference -->

### Implementation and limits

`tension_score.gd` contains a 25 by 9 network (225 nodes), four pinned corners, horizontal/vertical/diagonal distance links and eight compliant-constraint iterations per step. The fixed step is 1/120 second, with at most eight steps per physics update; under sustained overload simulation time slows instead of integrating an unstable large step. The initial five simulated seconds are settled before the handle is exposed. `tension_membrane.gd` fabricates the supports, rebuilds the displayed triangle surface and routes controls. `tension_handle.gd` uses the project's XRToolsPickable and desktop grab callbacks.

The model has units but no calibration against nylon. It has no self-collision, tearing, plasticity or contact against the visitor. The shader suggests a weave on an opaque surface. The added load is force distributed over a central patch, not added inertial mass. Pin positions and the original rest lengths survive every comparison. No claim of physical headset testing or Quest performance is made.


### Reference

Whitney identifies nylon hosiery and places the work in the RSVP series. Nengudi discusses bodily and psychological elasticity and the energy associated with previously worn material. Ada makes an original four-anchor membrane encounter, not a reconstruction or a measurement of her sculpture. Its knit-like opaque surface is procedural. It models reversible distance constraints, damping and a distributed downward load, with a floor limit; it does not simulate nylon, damage, self-collision, skin or a human body.

[Senga Nengudi: Internal I (1977, refabricated 2014)](https://whitney.org/collection/works/46609).

## Runnable boundary reconstruction · 9 October 2026

The tutorial prints a complete 1.2 × 1.4 m PlaneMesh study, with the installed subdivision counts (6/12), stiffness .34, damping .05 and precision 5. Reference coordinates choose a top row, upper corners or no pins. Mesh construction precedes world entry. The black PointBody is copied unchanged from the preceding lesson; the contact mask includes its layer. The visual bar has no collision, unlike some installed support variants. The learner releases the row to two corners; returning to the full row explicitly rebuilds the body. A native test found that changing pin flags on already moving vertices did not guarantee stationary positions. REBUILD avoids promising a rewind through pin selection. The optional tension membrane application and its supplied solver remain separate. See the dated review for executable tests, actual museum images and remaining limits.
