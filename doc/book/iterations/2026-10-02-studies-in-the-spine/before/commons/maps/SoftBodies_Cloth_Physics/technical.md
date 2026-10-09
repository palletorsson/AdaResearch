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

The lesson token builds eight strips with 112 vertices each, at stiffness 0.34, damping 0.05 and simulation precision 5. The initial top row has eight pins per strip; PINS keeps the two corners, and RELEASE removes all pins. SUPPORT cycles gantry → none → hoop → mast → wall without changing those indices. The wall and other solid frame pieces can still collide; independence from the pin rule is not independence from the physics world. Godot Physics adds bending links as well as triangle-edge links.

The map begins with the rail landing, whose bar is 0.14 m wide. The first LANDING press selects the pan. Rebuilding starts new bodies and timers; the stop raises damping and stiffness rather than preserving a vertex snapshot.

Floor provenance: earlier structure cells remain behind the front court. Raw zeros receive explicit covers after relocation; this does not redefine zero globally. See `doc/space/soft-sequence-2026-09-15/floor-audit.json`. Headset reach and comfort require a human pass; runtime receipts separately record tested desktop operations.
