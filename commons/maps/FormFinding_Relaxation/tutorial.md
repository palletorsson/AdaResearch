# Form-Finding: Relaxation

A mesh released settles into a shape nobody specified. Before it, particles that remember where they were and springs that know their rest length.

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

You specify the connections. The rest lengths are read off the lattice you built. Nobody types in a shape.

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

No linear system is ever assembled. Each spring corrects its ends by half the error, and the network agrees by repetition.

Turn the number of passes.

```gdscript
const RELAXATION_PASSES := {
    "nudged": 1,
    "worked": 4,
    "pressed": 8,
    "held": 12,
}
```

One pass sags, twelve is taut. At equilibrium the cloth hangs at 0.6406 m against 0.5988 m and mean spring stretch falls from 0.701% to 0.051% — a one-over-passes law. Four resting shapes, not four stages of one.

Wire a lattice and let gravity argue with it.

```gdscript
var sim = SBShapes.make_jelly_grid(nx, ny, nz, cell, stiffness)
sim.gravity = Vector3(0.0, -4.5, 0.0)
sim.damping = 0.985
for _i in pre_steps:
    sim.step()
```

Edge springs plus face diagonals, eighty steps, and the argument is over. The bulge is where the disagreement ended, not where anyone put it.

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

A sphere, a pinned collar, a pressure pulse, 200 steps of gravity. Duration is a design parameter — a short run is a bowl, a long one a neck. The clock is part of the genome.

Freeze the pose and keep it.

```gdscript
arrays[Mesh.ARRAY_VERTEX] = sim.positions
arrays[Mesh.ARRAY_NORMAL] = normals
arrays[Mesh.ARRAY_INDEX] = indices
var am := ArrayMesh.new()
am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
```

The simulation runs once, at `_ready`. What stands in the room is not a model of the forces but a recording of them. A form is a fossil of what made it.

You can now integrate positions from positions, hold constraints by correcting rather than solving them, tune insistence with a pass count, and freeze a settled pose. FormFinding_Equilibrium asks what holds a shape still once the settling stops.
