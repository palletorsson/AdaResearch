# When does a body become a form? — implementation

Primary source scenes:

- `res://algorithms/softbodies/rounded_softbody_test.tscn`
- `res://commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.tscn`

The hall desk is implemented in `commons/artifacts/timing_machines/soft_workshop.gd`. It binds models inside this map, offers MEASURE, SQUEEZE, STIFFNESS, DURATION, GRAVITY, RULE, and blocks repeated activation during rebuilds. The six controls fit a 3×2 desk with a small inclined transparent readout.

The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

SQUEEZE changes the strength used by the artifact's existing squeeze interaction. STIFFNESS changes resistance in the solver. Watch the instrument as well as the silhouette. A colour scale can bring a small difference forward, or persuade us that its chosen quantity is the whole event.

The strain display compares the current geometry with reference lengths. That reference belongs to the model. Returning toward it is not a universal tendency toward an original or natural body; it is a particular constraint implemented here.

The branching study and field sculpture remain nearby, so the new capability can be compared with earlier ways of constructing an organic-looking form. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.

The glass vessel has already stopped. Its program begins with a sphere, pins an upper region and runs a custom soft-body simulation for a chosen number of steps. It then builds a surface from the resulting positions.

```gdscript
sim.gravity = Vector3(gravity_x, gravity_y, gravity_z)
sim.constraint_passes = 5
```

DURATION reconstructs the vessel using 40, 200 or 400 solver steps. GRAVITY changes the lateral component of the force. Compare duration first while the force remains fixed. These are numerical steps in a reconstruction, not seconds borrowed from the museum clock.

The object is evidence of a process, with most of that process absent. A different stop could have become the sculpture. The walkable glass surface also has limits established by its mesh and collision; resemblance to a vessel does not guarantee an opening large enough for a body.

A frozen result lets us look longer. It also makes the timing of a decision disappear into the apparent permanence of a thing. Next, we will ask what else an image of a body invites us to infer.

Floor provenance: earlier structure cells remain behind the front court. Raw zeros receive explicit covers after relocation; this does not redefine zero globally. See `doc/space/soft-sequence-2026-09-15/floor-audit.json`. Headset reach and comfort require a human pass; runtime receipts separately record tested desktop operations.
