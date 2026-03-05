# PG: MC Flat Landscape

Marching cubes reads a scalar field and decides where surface meets void. Each cube in a 3D grid checks its eight corners — above threshold or below — and selects from 256 possible triangle configurations. The algorithm doesn't model terrain. It extracts it.

Here the field is flat. A 13×14 grid, maximum height of one. The simplest possible case: a heightmap with almost nothing to say. Every cube resolves the same way. The mesh emerges uniform, predictable, boring on purpose. This is the baseline — the silence before variation.

Flatness is not absence of structure. It is structure at minimum entropy. The entire apparatus of marching cubes mobilized to produce a plane. All that machinery, one output. Complexity waits in the field values, not the algorithm.