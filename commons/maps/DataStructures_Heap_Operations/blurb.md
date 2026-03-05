# Heap Pyramid

A heap is a almost-sorted tree. Not fully ordered — just enough. Every parent dominates its children. The maximum floats to the top. Insert at the bottom, bubble up. Extract from the top, sift down. Two operations, both logarithmic, both vertical.

Tiered platforms rise across the grid. Each level enforces a single constraint: be greater than what's beneath. Not sorted left to right — the heap doesn't care about siblings. Only the parent-child relationship matters. This is partial order. Minimum structure for maximum access.

Priority queues run on this. Emergency rooms, operating systems, packet routers — anything that needs the most urgent element *now* without sorting everything else. The heap's secret: total order is expensive, and usually unnecessary. Dominance is cheaper than discipline.