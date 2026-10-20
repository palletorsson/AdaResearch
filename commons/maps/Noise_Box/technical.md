# Box samples from a cellular field

Cellular Noise used marching tetrahedra to interpolate the zero boundary. Here box_mesher.gd evaluates the same solid field at each box centre. A negative value occupies the whole box; a positive value leaves it empty. Only faces adjacent to empty boxes are emitted.

Default box_size is 0.65 m. The 27 × 11 × 29 m sample bounds divide each axis into whole intervals, so actual box sides are close to that size. The membrane remains thick enough for this spacing. The resulting axis-aligned triangles supply both rendering and collision. Floors remain level and entrances are cut before sampling.

box_shell_space and box_atrium_space share cellular_volume.gd. No new stochastic basis is claimed: box noise names a discrete receiving operation. Noise_Space_10 returns to the effect of a sampled surface on movement.
