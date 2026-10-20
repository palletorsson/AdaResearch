# Random structures, translated from Rhino to Godot

Open `preview.tscn` in the Ada Research Godot project and run the scene with F6. Choose Columns, Spheres, Lattice or Tree. Drag empty space to orbit; the wheel zooms. The left study has zero geometric variation; the right applies the selected range to the same retained random draws. The lattice keeps the same selected connections on both sides.

These are four independently registered artifacts, available for placement as:

| Token | Scene | What randomness changes |
|---|---|---|
| `random_structure_columns` | `columns.tscn` | Cylinder height, radius, or both |
| `random_structure_spheres` | `spheres.tscn` | The Y coordinate of a 10×10 sphere grid |
| `random_structure_lattice` | `lattice.tscn` | Upper-node displacement and the presence of legal connections |
| `random_structure_tree` | `tree.tscn` | Branch endpoint offsets within a fixed three-way branching rule |

No existing hall or canonical tutorial/final is changed by this collection trial. The existing Random Space Geometry hall is a possible later home; its seeded room already provides a useful neighbour for these studies.

## Controls

- BASELINE sets geometric variation to zero; VARY returns it to one. RANGE + cycles in quarters. The preview slider allows finer changes. Neither requests new random numbers.
- SEED +1 increments a local seed, initially 435, and replaces the retained draw record. This is independent of Random Definition's shared hall seed.
- TARGET selects height, radius or both for cylinders. Height and radius use separate retained draws, matching the source's two random calls.
- LINKS + changes the lattice's connection probability in steps of 0.2. Existing direct posts remain. At zero there are 147 posts; at one there are 1,083 pipes. Node positions do not change when this probability changes.
- RESET on the sphere/tree study restores seed 435 and full range.
- KEEP writes a uniquely named JSON file into Godot's user-data folder and prints the full path in Output. REPLAY opens that kind's latest kept file. Older files remain on disk; `restore(record)` can open a selected record from code.

KEEP stores 4,096 raw 32-bit draws, the seed as a decimal string, kind, range, connection probability, cylinder target and schema/engine identifiers. The raw integers are exactly representable in JSON's numeric representation. The model derives each unit value as `float(draw) / 4294967296.0`; replay therefore recovers the same choices without calling the generator again. Changing the generation rules requires a new record schema. This is seeded reconstruction, not a physical random source.

## Translation choices

Rhino's examples use Z as height; Godot uses Y here. A Rhino `(x,y,z)` position corresponds to Godot `(x,z,y)` for these axis-aligned studies. Dimensions are normalized to a small display rather than copied as metres. The core geometry is separate from the supplied platform, controls and save interface.

**Cylinder field:** the original outer loop repeats the same row ten times because its index does not enter a position. The adaptation gives each repeat a different ground-plane row. All 100 bases remain fixed; a cylinder's mesh centre is halfway between its declared base and top. The original cylinder-cake function was not called by the supplied snippet; it is not one of this pass's four studies. Radius zero is excluded.

**Sphere field:** the horizontal addresses stay regular while height varies. Radius 0.07 m exceeds half the 0.108 m spacing, so the spheres overlap, as in the source. They are separate mesh instances, not a Boolean union or a continuous manufactured surface. Reducing the radius is a separate design change.

**Pipe lattice:** four levels of 7×7 nodes are joined by 147 direct posts. Each point may also join its eight neighbouring addresses on the next level. Bounds are checked in two dimensions before calculating a flat index; negative-index wrapping and duplicated neighbours are removed. The source's `random > 0.6` means a 0.4 selection probability, so the control uses that direct probability. Its original deviation was zero; the Godot range control lets us compare zero displacement with displaced upper nodes while holding the selected edges fixed.

**Tree:** the topology is one trunk followed by 3, 9 and 27 branches: 41 nodes, 40 segments, 27 tips. Radius depends on depth, so visiting one branch cannot accidentally make a later sibling thinner. A symmetric fan is the zero-range comparison; seeded offsets disturb it while every branch still rises. This is a generative geometry study, not botanical growth or a load-bearing simulation.

The attachment also contains a CSV-driven box-rotation script and a goal-directed pipe path. Neither is included in this first collection. The CSV script needs its `out.csv`, which was not supplied; these four studies use no invented replacement dataset.

## A small experiment to start with

Choose Columns and keep seed 435. Switch TARGET between height, radius and both; use the same range. Keep an arrangement, change the seed, then replay it. The restored structure should match every cylinder, not only its overall silhouette.

For the lattice, first change displacement while holding the edge choices fixed. Then hold the positions and change connection probability. The same dense-looking structure can result from different decisions about position and connection; the two controls let those decisions be separated.

The model lives in `structure_model.gd`. Each study returns rods, balls and, where applicable, nodes and edges. `structure_view.gd` draws these with two MultiMeshes per study. Cylinder transforms scale along their local axis before rotating, so both endpoints meet the intended nodes. There are no per-frame mesh rebuilds or per-sphere rigid bodies. The table has collision; the generated geometry is a visual model with control-based interaction.

[Native tests, provenance and images](../../../doc/book/iterations/2026-10-15-rhino-random-structures/README.md). The controls reuse Ada's rectangular push buttons and RackTemplates. The preview supplies its own camera and lighting inside the existing project; it is not a separate standalone Godot project.
