# Form-Finding: Relaxation

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Position history
- Rest lengths
- Constraint corrections
- Pinned endpoints
- Iteration budgets

A mesh released settles into a shape nobody specified. Before it, particles that remember where they were and springs that know their rest length.

Read the excerpts below alongside the installed cloth, lattice and vessel. They expose parts of those constructions; they are not one complete script. The cloth keeps stepping, while the other two retain a pose after a fixed run.

Store the previous position, not the velocity.

```gdscript
var positions: PackedVector3Array = PackedVector3Array()
var prev_positions: PackedVector3Array = PackedVector3Array()
var pinned: Array = []

func add_particle(pos: Vector3, is_pinned: bool = false, mass: float = 1.0) -> int:
    positions.append(pos)
    prev_positions.append(pos)
    pinned.append(is_pinned)
    return positions.size() - 1
```

Velocity is implied by the difference. This is Verlet: integrate position straight from position, never storing a speed.

Step it forward.

```gdscript
var pos: Vector3 = positions[i]
var prev: Vector3 = prev_positions[i]
var vel: Vector3 = (pos - prev) * damping
var new_pos: Vector3 = pos + vel + gravity * dt * dt
prev_positions[i] = pos
positions[i] = new_pos
```

Gravity enters as `dt` squared because it is an acceleration and this is a position. Damping multiplies the implied velocity, bleeding energy without ever naming it.

Add a spring and let it read its own rest length.

```gdscript
func add_spring(a: int, b: int, rest_length: float = -1.0) -> void:
    if rest_length < 0.0:
        rest_length = positions[a].distance_to(positions[b])
    springs.append([a, b, rest_length])
```

You specify the initial positions and connections. The rest lengths are read from that starting lattice; the later shape follows its updates.

Nudge every constraint halfway back, several times a frame.

```gdscript
for _p in constraint_passes:
    for s in springs:
        var diff: Vector3 = positions[s[1]] - positions[s[0]]
        var cur: float = diff.length()
        var cv: Vector3 = (diff / cur) * (cur - s[2]) * 0.5 * stiffness
        if not pinned[s[0]]:
            positions[s[0]] += cv
        if not pinned[s[1]]:
            positions[s[1]] -= cv
```

No linear system is assembled here. Each free endpoint receives half the error scaled by stiffness. Correcting one spring can disturb another; repetition reduces disagreement without certifying that every constraint is satisfied.

Turn the number of passes.

```gdscript
const RELAXATION_PASSES := {
    "nudged": 1,
    "worked": 4,
    "pressed": 8,
    "held": 12,
}
```

The installed comparison offers PASSES, RESET and WIND. Each setting restarts the grid, runs sixty preliminary steps, then continues at fixed one-sixtieth-second steps. Turn WIND off and compare MEAN and WORST at the same step count for one, four, eight and twelve passes. More passes give constraints more corrections. A finite comparison does not establish equilibrium or a universal one-over-passes law.

Wire a lattice and let gravity argue with it.

```gdscript
var sim = SBShapes.make_jelly_grid(nx, ny, nz, cell, stiffness)
sim.gravity = Vector3(0.0, -4.5, 0.0)
sim.damping = 0.985
for _i in pre_steps:
    sim.step()
```

Edge springs plus face diagonals, then eighty steps. The lattice retains that pose because its loop ends. Neither a residual-error test nor a convergence test decides the stopping point.

Pin the top ring and run the clock.

```gdscript
var pin_y: float = radius * (1.0 - pin_top_fraction * 2.0)
for v in initial_verts:
    var is_pinned: bool = v.y > pin_y
    if not is_pinned:
        v = v * (1.0 + preinflate)
    sim.add_particle(v, is_pinned)
sim.simulate(sim_steps)
```

A sphere, a pinned collar, an initial expansion of the free vertices, then 200 steps. Rest lengths are set after expansion; this is not a continuing pressure calculation. Duration is a design parameter. In a source experiment, hold the initial mesh and other settings fixed, change the step budget, inspect the retained pose, then restore it. These settings are not live controls on the vessel.

Freeze the pose and keep it.

```gdscript
arrays[Mesh.ARRAY_VERTEX] = sim.positions
arrays[Mesh.ARRAY_NORMAL] = normals
arrays[Mesh.ARRAY_INDEX] = indices
var am := ArrayMesh.new()
am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
```

The vessel simulates during construction and copies the resulting positions into its mesh. It keeps the state reached by a model, including the effects of its step budget. The cloth continues to run; it has not been frozen by this operation.

Keep the distinction between a pose retained after a budget and a measured equilibrium. FormFinding_Equilibrium asks which relations have actually been solved when a shape holds still.
