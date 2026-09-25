# The price of one more route

Which connection can you remove without separating anyone from the network?

<!-- @mst_visualization -->

Watch the next edge considered by the display. Before it is accepted or rejected, trace whether its two endpoints are already connected through accepted edges. An edge can look short and useful while adding no new connection between the groups that remain separate.

The default procedure is Kruskal’s algorithm. It considers edges in increasing order of weight and accepts an edge when that edge joins two different components. If the endpoints are already joined, the candidate would complete a cycle and is rejected. A small structure called union-find tracks which vertices already belong to the same component.

When an edge is rejected, trace the accepted route between its endpoints and notice how that route completes the would-be cycle. The rejection has a structural reason even if the edge’s weight is small. When an edge is accepted, identify the two previously separate groups it joins. Alternating these two checks helps you follow the algorithm’s decisions without needing to remember every edge considered earlier or interpret the final green network all at once.

Continue until the selected edges span the connected graph. A tree connects its vertices without cycles; between each pair there is one selected route. With the given edge weights, Kruskal’s rule produces a spanning tree of minimum total weight. “Minimum” refers to that sum, not to every traveller’s individual journey.

Compare a rejected edge with the route now needed between its endpoints. Removing a direct connection can lower the cost of maintaining the whole network while lengthening a particular trip. The criterion that made the tree economical does not make each path shortest.

Now imagine one selected edge failing. In a tree, removing an edge separates the structure into two components. A cycle that looked redundant under the construction budget could have supplied a second route. Redundancy changes meaning when the question changes from cheap connection to surviving a failure.

For a proposed extension, let a group spend the cost of one extra edge after the tree is complete. Which edge would it restore, and whose journey or reliability would improve? That experiment would keep the minimum tree as an understandable baseline while making room for a different objective.

<!-- @ -->

Flow adds another constraint. A route may exist and still be unable to carry everything trying to pass through it.
