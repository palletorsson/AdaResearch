# A connection is not a coordinate

If the drawing moves, has the graph changed?

<!-- @force_directed_layout -->

Choose one vertex and identify two of its connected neighbours. Keep those relationships in view while the drawing settles. Notice which distances change and which connections remain. Try to describe the difference without calling every movement a new network.

The default graph has eight vertices joined in a cube’s connection pattern. Its positions are not fixed: connected vertices pull together as if on springs, every pair of vertices pushes apart, and damping wears the motion down. The final arrangement reflects the balance of these forces rather than an instruction to draw a particular cube in a particular orientation.

Choose an edge whose length changes noticeably as the drawing settles. Describe its endpoints without using left, right or above, since those descriptions may stop helping as positions move. You might identify one endpoint through its neighbours and then follow the same relation through the motion. This is a small exercise in recognising structure independently of its current projection. The drawing remains useful, but it is no longer the only way you know which connection you are seeing.

A force-directed layout is a method for choosing a graph’s visible coordinates. The graph supplies adjacency; the layout supplies positions that may make that adjacency easier to inspect. An edge can stretch without ceasing to connect the same pair. Conversely, two unconnected vertices can pass close together in the drawing without acquiring an edge.

The two travellers in the previous room followed connections. They would still need the adjacency structure even if this layout placed two unrelated vertices almost on top of one another. Visual proximity can suggest a relationship that the visiting rule does not possess.

Now find a vertex that looks central. Is it central in the arrangement, unusually well connected, or simply easy to see from where you stand? Those questions can have different answers. Count: every vertex in this graph has exactly three neighbours, so whatever looked central was the drawing’s doing. A useful drawing can also invite an unsupported story about influence or importance.

The drawing in front of you is one layout of many the same graph could be given, and walking gives you another: go round to the far side and look again. Is the vertex you called central still central from there? If a claim about the network disappears when the drawing rearranges, or when you move, ask whether the claim belonged to the graph or to its presentation.

<!-- @ -->

Pathfinding will change a connection’s availability while a traveller is already moving. This time the route really may need to change.
