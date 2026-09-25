# Two travellers, one graph

Can two travellers obey the same connections and encounter the graph in different orders?

<!-- @two_travelers -->

Choose a lamp several connections away from the starting lamp. Predict whether it will be reached early or late. Watch one traversal, then keep the same destination in mind as the other begins. The exhibit alternates between two visiting rules on the same branching structure.

One traveller explores the nearest layer of neighbours before moving further out. The other follows a branch deeper before returning to alternatives. The lamps and their connections remain available to both; what changes is the order in which unfinished possibilities are kept.

During the breadth-first traversal, look across an entire layer before following the traveller deeper. During the depth-first traversal, keep one unfinished side branch in mind while attention goes elsewhere. The waiting branch has not disappeared from the graph. It has changed position in the procedure’s pending work. This comparison lets you describe order without changing the structure itself, and makes the traveller’s memory as important as the connections directly in front of it.

A graph describes this arrangement with vertices and edges. A vertex is a place in the structure, and an edge records a permitted connection. Its drawing helps us see the graph, but the visiting rule acts on those connections rather than on how attractive or physically close a lamp appears.

Breadth-first search keeps a queue: newly discovered possibilities wait behind earlier ones. Depth-first search uses a stack: the most recently added possibility is taken next. Those small differences in memory produce the two larger rhythms you have watched. A queue spreads attention across a frontier; a stack carries it into a branch.

Return to your chosen lamp and count connections from the start. In this unweighted graph, breadth-first layers correspond to that number of steps. Depth-first search can reach a deep lamp while another shallow branch still waits. Neither visit order is a complete account of which destination matters most.

If the lamps stood for people awaiting attention, the ordering rule would have consequences beyond its neat animation. A procedure that eventually reaches everyone can still make some wait much longer. A proposed extension could let the group choose one urgent destination and compare the waiting time under each rule.

<!-- @ -->

The next room lets the drawing itself move. Keep the graph’s connections separate from the positions used to display them.
