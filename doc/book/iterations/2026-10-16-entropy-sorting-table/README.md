# Four cubes / How many ways?

User request: tube and sorting table in Entropy Workshop; same four cubes, compartments added one at a time, pause for sorting, WAYS with every possible arrangement pictured.

Installed artifact: `commons/artifacts/entropy_sorting_table/entropy_sorting_table.tscn`, registry ID `entropy_sorting_table`, source cell (13,9), yaw 180. Registered in the web editor and writing wall before the sixteen-site bench. Existing exhibits retained.

## Procedure

1. DROP FOUR releases the kept batch to four spots, filling the far end first. It stops indefinitely. This is an authored balanced batch, not independent random draws.
2. Pick up a cube; drop over a spot to exchange occupants. Release outside the tray to return it. Counts are withheld while a cube is held. A held target cannot be displaced.
3. ADD DIVIDER retains identities and positions; it changes partition from `[0000]` to `[0011]`, `[0012]`, `[0123]`. Each press returns to the sorting pause.
4. WAYS enumerates binary four-site patterns with two pink sites, retaining only those matching the pink counts in each compartment. Same-colour identities, rotations and continuous positions do not create new ways.
5. ONE BOX removes all dividers and retains the sorted arrangement. No new cube is produced.

Alternating colours yield 6 → 4 → 2 → 1. Separated halves yield 6 → 1 → 1 → 1. These are examples, not a universal prescribed progression. Whole-board Shannon colour entropy for a uniformly selected site remains one bit. The displayed count concerns a conditional description of this finite arrangement; no thermal dynamics or unpredictable generator is claimed.

## Reconstruction

The small `sorting_model.gd` owns site identities, colours, partition, exchange and enumeration. The host builds the tube, tray, four XRTools pickables, rectangular pointer/poke button, and possibility pictures. Desktop and XR release events route to the same placement operation. Reproduce six two-pink patterns on paper, draw the same dividers, and eliminate those with different compartment counts. Preserve the row and partition in a notebook to reconstruct a comparison; this first apparatus has no persistent session save. The existing two-gauge bench retains its separate KEEP and REPLAY functions.

## Verification

- `verify.gd` checks every two-pink pattern under every partition against independent binomial counts; invariants, real button signal, enabled pickable collisions, a rotated-host desktop swap, XR release route, out-of-bounds return and indefinite pause.
- `museum_probe.gd` loads an isolated copy of the actual museum, checks authored placement, supported approach and clear button reach, exercises ray-pointer events and sorting, and captures the installed states. Probe outputs are copied here; live museum output paths are not replaced.
- `python tools/map_pathfinder.py check Random_Entropy` checks the map route.
- The web writing-wall API exposes the new scene at (13.5,9.5), with tutorial/final notes and tags.

Native checks are evidence of behavior, not evidence that a learner understands the count. Next trial: ask for a prediction before adding the middle divider; ask the visitor to make WAYS one while keeping two boxes and the same four cubes. Observe confusion and null results. The first 48-value seed-bench pilot remains unchanged.

Run installed probe:

```powershell
python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag entropy-sorting-table --probe doc/book/iterations/2026-10-16-entropy-sorting-table/museum_probe.gd
```
