Tiered platforms ascend from the floor. The lowest level is wide — many cells. The next is narrower. The top is a single elevated point. The room is a pyramid you climb, and the pyramid is the heap.

A heap is a partially ordered tree stored in an array. Every parent must be greater (or less) than its children. Not fully sorted — just dominated. The maximum lives at the root, always. Insert at the bottom, bubble up. Extract the max, trickle down. Each operation touches one path from root to leaf: log-n steps.

Partial order is weaker than total order but cheaper to maintain. The heap does not care about the relationship between siblings — only between parent and child. Dominance without exhaustive comparison. The insight is that you rarely need everything sorted. You just need the extreme, right now.
