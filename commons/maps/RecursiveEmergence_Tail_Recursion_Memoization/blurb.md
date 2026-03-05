# Tail Recursion Branching Halls

A function calls itself. Standard recursion stacks frames — each call waiting for the next to finish, memory piling up like unsupported floors. Tail recursion rewrites the contract. The recursive call is the last thing that happens. Nothing waits. The current frame is released before the next begins. Constant space. Infinite depth.

Memoization adds memory to the process. Results cached, redundant branches pruned. The recursive tree that would explode exponentially collapses into linear traversal. Fibonacci without the fraud — each subproblem solved once, then remembered.

Walk the branching corridors. Watch the tree grow, split, recurse. Then watch tail optimization flatten it — halls that should multiply instead extend, a structure that consumes itself as it advances. The paradox of recursion made efficient: a process that forgets its past in order to continue indefinitely.