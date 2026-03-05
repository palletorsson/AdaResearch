# Segment Tree Bisection

A segment tree splits an array in half, then splits each half again, until every leaf holds a single element. Each internal node stores an aggregate — sum, minimum, maximum — over its children's range. Query any contiguous interval in O(log n). Update any element and propagate the change upward in O(log n). The structure is the question asked efficiently: *what is true about this slice?*

The room bisects. Halves of halves. Walk through a space that recursively divides itself — raised terrain, random profiles, cubes placed and removed along ranges. Every partition is a decision about what to remember and what to recompute. The tree doesn't store answers. It stores the *capacity to answer*.

Binary decomposition as spatial memory. The segment tree proves that division is not destruction — it's how structure learns to speak about its own parts.