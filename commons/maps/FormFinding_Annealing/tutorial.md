# Form-Finding: Annealing

Descent is greedy and gets stuck. Before this map, a landscape with more than one valley.

Wrinkle the surface so it has many rests.

```gdscript
@export var amp: float = 0.09

func _energy(x: float, z: float) -> float:
    return amp * (sin(x * 9.0) * 0.6 + cos(z * 7.0) * 0.5 + sin((x + z) * 5.0) * 0.4)
```

Three sines at different frequencies. Height is energy, so every trough is a possible rest. The annealing table uses Rastrigin for the same job — a bowl with a cosine lattice milled into it, one global minimum in a regular grid of traps.

Drop a body on it and nudge it downhill.

```gdscript
var p: Vector3 = _sim.positions[i]
var floor_h: float = _energy(p.x, p.z) + blob_size * 0.28
if p.y < floor_h:
    _sim.positions[i].y = floor_h
    var gx: float = (_energy(p.x + 0.01, p.z) - _energy(p.x - 0.01, p.z)) / 0.02
    var gz: float = (_energy(p.x, p.z + 0.01) - _energy(p.x, p.z - 0.01)) / 0.02
    _sim.positions[i].x -= gx * 0.0008
    _sim.positions[i].z -= gz * 0.0008
```

It finds the nearest valley, not the deepest. Descent is local and has no view of the map.

Propose a jump instead of taking a step.

```gdscript
var strength: float = current_temperature / initial_temperature * search_space_size * 0.3
var neighbor := Vector2(
    current_solution.x + randf_range(-strength, strength),
    current_solution.y + randf_range(-strength, strength)
)
```

The step size is the temperature. Hot proposes wildly, cold barely moves. No gradient is read at all — the candidate is guessed, then asked its energy.

Accept a worse position with a probability.

```gdscript
var delta_energy: float = neighbor_energy - current_energy
var accept: bool = false
if delta_energy < 0:
    accept = true
else:
    var probability: float = exp(-delta_energy / maxf(current_temperature, 0.0001))
    accept = randf() < probability
```

Downhill is always taken. Uphill is taken with probability `exp(-ΔE/T)`. You have to be willing to get worse to get better, and that willingness gets dearer as the system cools.

Cool.

```gdscript
match cooling_schedule:
    "exponential":
        current_temperature *= cooling_rate
    "logarithmic":
        current_temperature = initial_temperature / log(2.0 + current_iteration)
```

Anneal, do not quench. At `cooling_rate = 0.95` the shaking dies slowly enough to still leave a shallow trap; cool fast and you freeze into whichever valley you were shaken into. The adaptive schedule tunes the rate to hold acceptance near 0.44.

Hop when nothing has improved for a while.

```gdscript
if basin_hop_enabled and steps_since_improvement >= stagnation_threshold:
    if basin_hops_performed < max_hops:
        _perform_basin_hop()
```

Stagnation is information. A run that stops improving is not converged but trapped, and the cure is a deliberate throw.

Cut two wells and choose between them.

```gdscript
var depth_f: float = (sqrt(f) if narrow else (f * f))
var y: float = -depth * depth_f
```

`sqrt(f)` drops fast — a deep narrow pit, radius 0.9, depth 2.2, holding one rigid cube that will never move again. `f * f` is a soft parabola: radius 2.2, depth 0.7, holding a body that keeps re-finding a slightly different rest.

Jostle the live one so it never finishes.

```gdscript
if fmod(_t, 2.5) < delta:
    for i in _sim.positions.size():
        _sim.positions[i] += Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0.02, 0.12), _rng.randf_range(-0.08, 0.08))
_constrain_alive()
_sim.step()
```

You can now build a landscape with many rests, propose by temperature instead of gradient, accept a worse position on purpose, cool on a schedule and hop when you stall. But the deepest well is a dead-perfect crystal — finished, frozen, incapable of the next change. Max Q is the liveliest minimum, not the deepest: low enough to hold a shape, high enough to still be moved. FormFinding_Forge hands you the landscape and asks you to let something fall down it.
