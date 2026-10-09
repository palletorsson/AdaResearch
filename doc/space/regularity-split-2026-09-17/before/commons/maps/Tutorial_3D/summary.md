# Tutorial 3D — Summary

Tutorial_3D is the fifth map in the Array Tutorial sequence. It completes the dimensional ladder begun in Tutorial_Single and extended through Tutorial_Row and Tutorial_2D_Build. The map is built around a four-by-four-by-four volume — sixty-four cells addressed by three indices — and the learner has to move through all three axes to read it.

Stepped platforms rise along the north and west sides of the arena, providing physical access to the upper layers of the cube. Lifts at two corners give a more direct vertical shortcut. The volume itself is partially transparent, so the learner can see layers above and below their current height while standing on any given platform.

A small helper at the entrance walks the learner through the addressing convention. Three sliders set row, column, and layer independently; adjusting any one of them moves a highlight cube to the corresponding cell inside the volume. The learner can see that the same indexing logic scales: one index gave a row, two gave a grid, three give a volume.

A side wall shows the code `cell = grid[x][y][z]` alongside the live sliders, so each numerical change highlights the corresponding bracket. Within the sequence, Tutorial_3D is the payoff of the dimensional progression. Tutorial_Pattern will next shift the grid from a data container to a pattern generator.
