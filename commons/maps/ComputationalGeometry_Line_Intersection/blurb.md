Two corridors cross. Height-5 walls form a cruciform — one arm running north-south, the other east-west. You enter from the top and walk toward the center, where the corridors meet in a single open cell.

Line intersection is the foundational question of computational geometry: do these two segments share a point? The cross product gives the answer — the sign tells you which side of one line the other's endpoints fall on. If the signs differ, the lines cross. The room makes this spatial. Two paths, one crossing point. You cannot reach the far arms without passing through the intersection.

The sweep line algorithm processes many intersections at once, advancing across the plane like a horizon. But each individual test comes down to this: two directions, one shared coordinate. Where paths cross, something must be resolved.
