# Force Directed 3d

A matching pairs vertices so no vertex appears twice. Greedy approaches fail — they get stuck in local optima, unable to see that undoing one pairing enables three better ones. Jack Edmonds solved this in 1965 with a move no one expected: when an odd cycle blocks progress, contract the entire cycle into a single pseudo-vertex. The blossom shrinks. The graph simplifies. The augmenting path appears.

Here the graph floats in three dimensions, force-directed, breathing. Vertices repel; edges pull. Watch a blossom contract — five or seven nodes collapsing into one, the cycle swallowed so the algorithm can see past it. Then the blossom expands, the matching restored, every edge accounted for.

Maximum matching asks: how many pairs can coexist without conflict? The answer requires temporary dissolution — identity folded inward so structure can reorganize. Optimal pairing is not found by holding on. It is found by learning which bonds to release.