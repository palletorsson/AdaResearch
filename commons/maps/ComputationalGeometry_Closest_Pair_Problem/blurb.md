Platforms scattered across a wide floor like stones in a dry riverbed. Height-3 islands, each a few cells across, separated by flat ground. Some close together, some far apart. Fibonacci spirals turn slowly on one of them.

The closest pair problem: given n points, find the two nearest. Brute force checks every combination — n-squared comparisons. The trick is divide and conquer. Split the set down the middle. Solve each half. The answer is either within one half or it straddles the divide. That straddling case is where the cleverness lives.

Growth remembers its last two steps and spirals. The closest pair algorithm remembers its recursive subproblems. Among many scattered things, nearness is not obvious — it must be computed, and the fastest path to it runs through division.
