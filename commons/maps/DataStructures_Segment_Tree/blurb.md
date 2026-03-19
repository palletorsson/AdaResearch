A room bisected. Each half bisected again. Each quarter bisected again. The walls mark recursive subdivisions — the whole space carved into a binary hierarchy of intervals.

A segment tree stores an array by recursively splitting it in half. Each node holds an aggregate — sum, minimum, maximum — for its interval. Query any contiguous range in log-n time by combining the right nodes. Update any element and the change propagates up through log-n ancestors. The tree does not store the data directly; it stores pre-computed answers for every possible power-of-two-aligned sub-range.

The room's recursive partitioning is the data structure. The walls between halves are not barriers — they are the boundaries of cached computations. Recursive range memory: the structure remembers the answers so you never have to scan the whole array again.
