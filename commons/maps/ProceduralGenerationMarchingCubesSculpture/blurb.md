The gyroid is a minimal surface with zero mean curvature everywhere — no inside, no outside, just continuous membrane folding through space. Discovered by Alan Schoen in 1970, found in butterfly wings and block copolymers decades later. Nature arrived first.

Marching cubes extracts the surface from an implicit function. The equation is simple: sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0. Every point in space either satisfies it or doesn't. The algorithm walks a grid, cube by cube, testing corners, triangulating the boundary between inside and outside — except here, there is no inside or outside. The surface divides space into two equal, interlocking labyrinths. Neither contains the other.

A structure that separates everything it touches and connects everything it divides.