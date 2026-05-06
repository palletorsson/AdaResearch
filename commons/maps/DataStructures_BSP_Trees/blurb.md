A room divided by a wall. On each side, another wall divides the space again. And again. Each partition is a binary decision — this side or that side — cutting volume into smaller and smaller regions.

Binary space partitioning selects a hyperplane and splits all geometry into two sets: in front, and behind. Recursively. The result is a tree where each leaf contains a convex region and each internal node holds a splitting plane. Doom used BSP trees to determine rendering order — walk the tree from the camera's position, and you get back-to-front or front-to-back ordering for free.

The room is its own BSP tree. Every wall is a split. Every sub-room is a leaf. The structure does not describe the space — it is the space, partitioned by recursive cuts into volumes that never need to be re-sorted. Rendering order from recursive geometry.
