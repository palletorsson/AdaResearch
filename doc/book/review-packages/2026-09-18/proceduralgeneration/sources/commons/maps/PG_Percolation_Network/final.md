# Touching is not enough

<!-- @percolationnetwork_ca -->

Two cubes stand near the floor of a much larger possible lattice. One is pink, the source. The other is white. Look at their contact before pressing STEP. Where could something pass between them?

At a face contact the white site becomes flowing. Press CONTACT to start again with a different arrangement. The cubes now meet at a corner. STEP leaves the white one waiting. Their visual contact has not disappeared. The program simply does not consult that relation.

Its neighbourhood consists of six positions: one step in either direction along x, y and z. It does not include the diagonal positions. This is an explicit local definition, not a universal meaning of nearness.

```gdscript
Vector3i(x+1, y, z), Vector3i(x-1, y, z),
Vector3i(x, y+1, z), Vector3i(x, y-1, z),
Vector3i(x, y, z+1), Vector3i(x, y, z-1)
```

The update reads the old grid while writing another. An occupied site becomes flowing when a permitted neighbour carries flow. One press advances one generation; it does not instantly colour every reachable site. The source remains supplied. Flow values and state transitions have their own rules beyond the simpler question of whether a path exists.

Press LATTICE. The comparison expands into an 18 by 18 by 18 field, supplied from one z face. STEP lets you follow its spread. DENSITY restarts from the same seeded sequence of occupation draws at a different cutoff: 0.2, 0.4 or 0.6. A larger cutoff admits more sites. The readout counts sites reached and those reached on the opposite face. The desk permits 64 generations before another reset.

One such field cannot establish a universal critical threshold. Its seed, dimensions, boundary source and neighbourhood are part of the experiment. We can learn from a failed crossing without claiming that a whole kind of space has become impossible. Keep changing one condition at a time, and name the condition when you describe the result.

There is another distinction already under your hands. White occupied sites have collision. Pink source and flowing sites do not. The signal travels through the occupied network; as it arrives, that particular obstacle to your body is removed. The same event is connection for one system and a change of resistance for another.

The museum floor supplies an independent way around the field. That support is authored separately from the lattice. We should not call the pink route walkable just because a sequence of neighbour tests succeeded. A body needs dimensions, headroom and somewhere to stand.

The dark sphere and its stand remain in the room as supporting works. They are not hidden steps in this flow calculation. Our next comparison is Caves / Mazes: how can a rule construct the interior that our signal did not need?

<!-- @ -->
