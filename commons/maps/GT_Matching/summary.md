# GT Matching — Summary

GT_Matching is the eighth and final map in the Graph Theory sequence, and the last map in the whole spine. The task is pairing: each node claimed by at most one edge, each pair an exclusive assignment. A perfect matching claims every node; an optimal matching minimises cost under some weighting.

The room is divided into two symmetric halves. The learner stands on a walkway between them. On each side, a set of nodes waits to be paired with a partner on the other side. A greedy algorithm runs first and fails visibly: it commits to easy pairs early and strands some nodes unmatched. A second station runs the Hungarian algorithm for the bipartite case, lifts the blockage, and produces a complete assignment.

A third station takes the problem to general graphs, where pairs can form across arbitrary edges. The blossom algorithm contracts odd cycles into pseudo-nodes, finds augmenting paths through the contracted graph, and expands the contractions back out when the matching is complete. The algorithm animates the contractions and re-expansions; the room's two halves visibly bend as blossoms form.

Within the sequence, Matching is the capstone. Within the whole spine, it is the last thing the learner encounters before the curriculum hands back to the Lab. The argument is that allocation — fair, exclusive, complete — is a graph problem, and the tools the sequence has built are enough to solve it.
