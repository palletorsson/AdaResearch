# Four structures from retained randomness

15 October 2026. Palle supplied Rhino scripts and asked for Godot versions. The attachment is preserved in [rhino-source.txt](rhino-source.txt), with [provenance](source.json). Two inline examples additionally describe repeated cylinders and a sphere grid with random height.

Implemented as four separate collection artifacts: cylinder field, raised sphere grid, layered pipe lattice and branching tree. The [implementation guide](../../../../commons/artifacts/random_structure_studies/README.md) states dimensions, source corrections, controls and limits. The collection has not been placed in an existing hall and does not alter the Entropy experiment, adopted room/final order, or the 48-value pilot.

## Observed and checked

[58 native checks pass](verification.json). The rendered Godot preview compares zero geometric range with full range using the same retained draw record. The lattice's selected connections are held constant across that comparison. Tests cover actual push-button callbacks, slider changes without resampling, independent cylinder targets, saved records, fresh scene reconstruction, rejection of malformed records, every rendered pipe's endpoints, legal grid neighbours and tree topology.

The source's repeated cylinder rows now occupy ten separate rows. The lattice has 196 nodes and 147 mandatory posts; all 936 legal diagonal candidates can be enabled, yielding 1,083 pipes. Seed 435 at probability 0.4 retains 534 pipes in the tested implementation. The tree has 40 segments and 27 tips. Both the point coordinates and the topology survive saved reconstruction.

The initial tests exposed two implementation faults, subsequently repaired: scaling a rotated pipe in world axes missed its endpoints; and floating serialization did not preserve every retained random value under exact comparison. Rods now scale locally before rotation. Records save raw uint32 draws instead of decimal random fractions, then reconstruct the normalized values. An additional type check accepts integral JSON numbers for the target selector. The final receipt covers the corrected implementation.

## Reproduce and inspect

Run from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-15-rhino-random-structures/run.py --render
python -X utf8 doc/book/iterations/2026-10-15-rhino-random-structures/publish.py
```

For interaction, open `commons/artifacts/random_structure_studies/preview.tscn` in Godot and press F6. The four registered `.tscn` files can also be placed independently. Existing project dependencies provide the button interaction components.

The runner uses a real renderer with a hidden window. Godot's headless dummy renderer does not retain the MultiMesh transforms needed for endpoint readback; that mode cannot establish the rendered-geometry checks. The suite explicitly requires the renderer rather than treating dummy readback as a geometry result.

These are native geometry/controller tests and rendered comparisons. Physical headset comfort, performance on Quest, structural engineering, mesh unions, map placement and learner response remain untested. The inherited Jolt solver-bias warning is retained in the log. No runtime frame-rate claim follows from batching the geometry.

## A question for the next encounter

A regular address grid remains underneath the cylinder and sphere forms. The lattice admits only neighbours before it makes a random choice. The tree fixes three children before deciding where they arrive. Changing the seed varies outcomes inside these rules; changing which connections or properties are admissible is another kind of intervention. The next trial can test which of these differences is perceptible and worth developing into a room.

API reference used for record handling: [Godot JSON documentation](https://docs.godotengine.org/en/stable/classes/class_json.html). Algorithm choices and repairs are grounded in the supplied scripts and the native checks, not in an external architectural example.
