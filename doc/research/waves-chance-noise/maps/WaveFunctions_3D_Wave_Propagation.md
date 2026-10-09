# WaveFunctions_3D_Wave_Propagation

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Does a crest travel, or do neighbours make it again?

Body/layer: A connected array of oscillating bodies.

Proposed primary encounter: `coupled_oscillator_lattice`.

## Starting evidence

Outside the current museum route. The lattice computes neighbour coupling and exposes apply_displacement. It has nodes/bonds/sheet/boundary views. Random excitation currently uses a probability per rendered frame; integration order and step stability need inspection before quantitative claims. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 16, 'depth': 22, 'max_height': 5}. Current final: 411 words.

Current primaries: coupled_oscillator_lattice. Book anchors: coupled_oscillator_lattice.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Build a reachable excitation point that produces one local pulse; compare coupling zero with a nonzero value from the same initial state.
2. Use the existing node/bond views to reveal the relation between cells. Show a selected cell's displacement beside the local pair; let the visitor locate the delayed response.
3. Use a stable simulation step and separate old/new state if needed so array iteration order does not supply an unacknowledged preferred direction. Bound the energy/input range and expose the finite boundary.

## Revise final.md

1. Follow one marked sphere while the disturbance spreads elsewhere.
2. Repeat with the neighbours disconnected, then ask what carried the change.
3. Read the restoring, damping and neighbour terms from the implemented update.
4. Let the edge interrupt the idea of an unlimited medium; keep wave motion distinct from a transported object.

**Code to trace and quote after implementation:** coupled_oscillator_lattice.gd: _apply_excitation, _update_oscillators, _get_neighbors, apply_displacement. Cite whichever time-stepping scheme actually ships.

## Evidence to return

- From the same initial state, compare zero/nonzero coupling at selected cell times.
- Check bounded behaviour at the maximum offered setting.
- Verify boundary handling and that any pulse control triggers only the intended lattice.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Could be linked pearls, a fabric or architectural joints. Keep a way to see individual motion under the larger pattern.

**Reusable method:** R3 explicit time; R6 local state/seed; R8 bounded simulation.

## Open and inspect

- Map: `commons/maps/WaveFunctions_3D_Wave_Propagation/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_3D_Wave_Propagation/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_3D_Wave_Propagation&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_3D_Wave_Propagation)
- `res://algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.tscn`
- `algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
