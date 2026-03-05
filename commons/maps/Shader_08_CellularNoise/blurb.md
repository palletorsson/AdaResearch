# Cellular Noise

Scatter points across a plane. Now ask every pixel: which point is closest? The answer is a Voronoi diagram — space partitioned by proximity, each cell belonging to its nearest seed. Worley noise is the distance to that nearest point (F1): smooth hills rising from each center, ridges where territories collide.

Subtract F1 from F2 — the second-nearest distance — and the ridges isolate into crackle patterns. Cell walls without cells. Structure defined entirely by boundaries.

Voronoi appears everywhere biology does: giraffe skin, dragonfly wings, dried mud, bone marrow. Not because nature copies the algorithm, but because the algorithm describes what happens when competing centers claim space. Every cell is a territory. Every edge is a negotiation. Identity defined not from the center outward, but from the contested borders between.