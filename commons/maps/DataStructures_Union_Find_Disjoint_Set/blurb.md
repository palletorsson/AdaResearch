Distinct platform groups, separated by voids. Each group is an island — internally connected, externally isolated. For now.

Union-Find tracks which elements belong to the same set. Two operations: find (which set is this element in?) and union (merge two sets into one). The merging is irreversible. Once two sets join, they cannot be split apart again. Path compression flattens the tree so future finds are nearly instant. Union by rank keeps the structure balanced.

The platforms start separate. Each union bridges a void, and once bridged, the connection is permanent. The data structure remembers every merger but cannot undo any of them. Irreversible merging — the structure only grows, only consolidates, only forgets the boundaries it once maintained. Some connections, once made, change the topology forever.
