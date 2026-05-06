The floor rises as you walk outward from center. Low in the middle, stepping up to height-2, then height-3 near the walls. The room is a bowl inverted — distance made into elevation.

The Euclidean distance transform computes, for every cell in a grid, the straight-line distance to the nearest obstacle or boundary. It turns a binary image — wall or not-wall — into a gradient. The result is a field where every point knows how far it is from the edge. Navigation algorithms use this to stay centered in corridors. Erosion algorithms use it to peel shapes layer by layer.

Height is distance. The floor is not architecture — it is a computation frozen mid-execution. The terrain is the answer to a question every cell asked simultaneously: how far am I from the nearest wall?
