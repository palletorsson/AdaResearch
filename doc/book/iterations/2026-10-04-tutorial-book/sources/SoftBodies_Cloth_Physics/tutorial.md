# Which points must stay?

<!-- @cloth_straps -->

Walk along the hanging strips. Each begins as an open surface. Unlike the pressurized cube, it has no enclosed interior for pressure to inflate. The upper edge holds while the rest hangs below it.

Press PINS to keep only the upper corners. Look for the difference before naming it. The material settings have not changed. The allowed motion has: points that were fixed can now participate in the sag. PINS alternates those two arrangements; RELEASE removes the pins, and REBUILD makes fresh strips with their upper rows fixed again.

```gdscript
sb.set_point_pinned(i, keep)
```

For each strip, the desk finds the top row in its mesh coordinates and chooses which indices to pin. This is a boundary condition written into an array. The frame makes that condition visible, but the frame and the pinning rule are distinct constructions. A convincing support does not prove how the simulation is attached to it.

Try STIFFNESS after choosing a support. We now have two ways to change the silhouette: change the material response, or change which points may move. When we describe an object as compliant, how much of that description belongs to the object, and how much to the arrangement holding it?



<!-- @softstopscene -->

The four falling bodies provide a second encounter. They are soft spheres, retained from the earlier collection, not pieces of woven cloth. LANDING changes the support below them between a floor, a narrow pan, a rail and a cone. Rebuilding that comparison also starts a new fall.

Their timers disable processing and raise damping and stiffness at scheduled moments. This stopping method is not an explicit snapshot of all vertex positions. The apparent crumple depends on the solver as well as the timer; it is not a shape the material was destined to have. Two shipped stop times are equal; four specimens do not automatically mean four different moments.

This prepares two questions we will return to: what makes the body deform, and what makes us stop looking? Carry the fixed edge into the next hall. There, the support itself moves.


<!-- study-spine:tension_membrane -->

## Return: A little give

Change the added load while preserving the four anchors and material compliance. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses soft, constraint, force. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`tension`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-nengudi-a-little-give/index.html). Release the pink handle before RESET or the preset pull. The four supports stay fixed throughout.

<!-- study-edit:tension_membrane -->

### One source change: A little give

In tension_score.gd, change the last entry of LOAD_KG from 3.0 to 2.0. Predict and compare the settled centre height after the same pull and release. Keep the pins and compliance fixed. The constraint solver and mesh renderer are supplied; no new foundational capability is required.

```gdscript
const LOAD_KG := [0.0, 1.0, 2.0]
```

Source: `commons/artifacts/spine_studies/tension_score.gd`. Use the prepared scene to run and compare.

<!-- tension-reference -->

### Pull, wait, release

This return follows the hanging strips: those changed the fixed points. Here the four corner points stay pinned. The pink bead is one additional prescribed point only while you hold it. Desktop: right-click the bead, move your view, then right-click to release. XR uses the ordinary pickup grip. HOLD A PULL supplies the same target each time; RELEASE lets it move again. Release a hand-held bead before using the preset or RESET.

Start unloaded, use HOLD A PULL, then RELEASE. Watch the bead and the centre height. LOAD selects the next downward load: 0, 1, 3, then 0 kg. Compare one load at a time. MORE / LESS GIVE changes the links' compliance independently of that load. RESET restores the unloaded, settled starting configuration and the firmer setting.

The bead and black load marker are representations. The solver distributes the additional downward force over nine central nodes; there is no separate falling rigid weight. The remaining mesh is visual, not a barrier to the player. The four supports and the museum floor are solid. A bounded grip target and floor limit keep the small study in its space.

### The next close reading

Begin with the single array edit above. The supplied solver keeps three arrays: current positions, previous positions and rest positions. Gravity changes the free points. Distance links share the displacement between their ends; four indices are excluded from movement. A held bead temporarily adds another exclusion. Releasing it removes that exclusion without replacing its current position with its rest position.

`compliance` controls the distance links' response; `damping` removes motion over time. They do different jobs. A softer response may settle lower, while greater damping makes the journey quieter. Neither creates wear or a remembered injury. The rest lengths remain unchanged.


### Reference

Whitney identifies nylon hosiery and places the work in the RSVP series. Nengudi discusses bodily and psychological elasticity and the energy associated with previously worn material. Ada makes an original four-anchor membrane encounter, not a reconstruction or a measurement of her sculpture. Its knit-like opaque surface is procedural. It models reversible distance constraints, damping and a distributed downward load, with a floor limit; it does not simulate nylon, damage, self-collision, skin or a human body.

[Senga Nengudi: Internal I (1977, refabricated 2014)](https://whitney.org/collection/works/46609).
