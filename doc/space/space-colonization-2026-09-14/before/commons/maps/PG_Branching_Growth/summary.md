# PG Branching Growth — Summary

PG_Branching_Growth is the fourth map in the Procedural Generation sequence. It places two branching strategies side by side in one room so the learner can compare them: explicit rule-based branching on one side, noise-driven organic growth on the other.

On the rule side, a seed grows upward through deterministic forking. At each step, the current tip splits into two shorter segments at a fixed angle, and the process recurses until the branches reach a minimum length. The result is legible and repeatable: given the same parameters, the tree grows the same way every time. A bench exposes the branching angle, the length scaling, and the recursion depth.

On the noise side, a field of 3D Perlin noise fills the space, and growth follows the field lines — each step moves in the direction of the steepest gradient within a tight radius, then samples again. The resulting branch pattern looks organic: bends, widenings, unexpected merges. A separate bench adjusts the noise frequency and the step size.

A panel between the two sides draws attention to the convergence. Different algorithms arrive at similar-looking structure, which suggests that branching is less a design choice than an attractor in the space of growth rules.

Within the sequence, Branching_Growth is the comparison map. PG_Caves_Mazes will next pivot from additive to subtractive generation.
