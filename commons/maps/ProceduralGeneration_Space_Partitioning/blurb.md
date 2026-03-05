# PG: Binary Space Partitioning

Start with a rectangle. Cut it in two. Cut each half again. Keep cutting — vertical, horizontal, vertical — until the pieces are small enough to hold a room. Then place rooms inside the leaves. Connect them back up the tree. A dungeon assembles itself through division.

BSP is architecture by subtraction. No designer draws the floor plan. The algorithm splits space recursively, building a binary tree where every node is a cut and every leaf is a potential room. The tree remembers how space was carved — parent knows both children, so corridors follow the hierarchy back up.

The whole emerges from the partition. Structure from fracture. Every room exists because a wall was placed first. Identity defined not by what fills the space, but by where the cuts fell.