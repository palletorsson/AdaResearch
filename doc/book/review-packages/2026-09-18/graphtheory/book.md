# graphtheory: the chapters

## GT Foundations

*GT_Foundations*

# Two travellers, one graph

Can two travellers obey the same connections and encounter the graph in different orders?


Choose a lamp several connections away from the starting lamp. Predict whether it will be reached early or late. Watch one traversal, then keep the same destination in mind as the other begins. The exhibit alternates between two visiting rules on the same branching structure.

One traveller explores the nearest layer of neighbours before moving further out. The other follows a branch deeper before returning to alternatives. The lamps and their connections remain available to both; what changes is the order in which unfinished possibilities are kept.

During the breadth-first traversal, look across an entire layer before following the traveller deeper. During the depth-first traversal, keep one unfinished side branch in mind while attention goes elsewhere. The waiting branch has not disappeared from the graph. It has changed position in the procedure’s pending work. This comparison lets you describe order without changing the structure itself, and makes the traveller’s memory as important as the connections directly in front of it.

A graph describes this arrangement with vertices and edges. A vertex is a place in the structure, and an edge records a permitted connection. Its drawing helps us see the graph, but the visiting rule acts on those connections rather than on how attractive or physically close a lamp appears.

Breadth-first search keeps a queue: newly discovered possibilities wait behind earlier ones. Depth-first search uses a stack: the most recently added possibility is taken next. Those small differences in memory produce the two larger rhythms you have watched. A queue spreads attention across a frontier; a stack carries it into a branch.

Return to your chosen lamp and count connections from the start. In this unweighted graph, breadth-first layers correspond to that number of steps. Depth-first search can reach a deep lamp while another shallow branch still waits. Neither visit order is a complete account of which destination matters most.

If the lamps stood for people awaiting attention, the ordering rule would have consequences beyond its neat animation. A procedure that eventually reaches everyone can still make some wait much longer. A proposed extension could let the group choose one urgent destination and compare the waiting time under each rule.


The next room lets the drawing itself move. Keep the graph’s connections separate from the positions used to display them.

---

## GT Layout

*GT_Layout*

# A connection is not a coordinate

If the drawing moves, has the graph changed?


Choose one vertex and identify two of its connected neighbours. Keep those relationships in view while the drawing settles. Notice which distances change and which connections remain. Try to describe the difference without calling every movement a new network.

The default graph has eight vertices joined in a cube’s connection pattern. Its positions are adjustable. Connected vertices exert a spring-like attraction, while pairs of vertices also repel one another. Damping reduces continuing motion. The final arrangement reflects the balance of these forces rather than an instruction to draw a particular cube in a particular orientation.

Choose an edge whose length changes noticeably as the drawing settles. Describe its endpoints without using left, right or above, since those descriptions may stop helping as positions move. You might identify one endpoint through its neighbours and then follow the same relation through the motion. This is a small exercise in recognising structure independently of its current projection. The drawing remains useful, but it is no longer the only way you know which connection you are seeing.

A force-directed layout is a method for choosing a graph’s visible coordinates. The graph supplies adjacency; the layout supplies positions that may make that adjacency easier to inspect. An edge can stretch without ceasing to connect the same pair. Conversely, two unconnected vertices can pass close together in the drawing without acquiring an edge.

The two travellers in the previous room followed connections. They would still need the adjacency structure even if this layout placed two unrelated vertices almost on top of one another. Visual proximity can suggest a relationship that the visiting rule does not possess.

Now find a vertex that looks central. Is it central in the arrangement, unusually well connected, or simply easy to see from where you stand? Those questions can have different answers. A useful drawing can also invite an unsupported story about influence or importance.

For a future comparison, hold the graph fixed and show several layouts side by side. If a claim about the network disappears when the drawing rotates or rearranges, ask whether the claim belonged to the graph or to its presentation. The present moving layout gives you the beginning of that distinction.


Pathfinding will change a connection’s availability while a traveller is already moving. This time the route really may need to change.

---

## GT Pathfinding

*GT_Pathfinding*

# The route after a stone disappears

What should a traveller do when the route it planned is no longer available?


Follow the spark’s route across the stones. Before pressing the button, choose the next connection you expect it to use. The button sinks a stone belonging to the current route. Watch the displayed route change and see whether the spark can still reach the opposite bank.

A route is a sequence through available connections. Removing a stone changes the graph the search can use; it does not merely make the old drawing look different. The exhibit marks that stone unavailable and asks for another path through the remaining graph.

After a removal, compare the old route you remember with the newly highlighted one. Look for a stretch that remains useful to both. Replanning does not imply that every previous choice was wrong; some connections can survive a local change while another segment must be replaced. If no route appears, trace the missing connection in your own proposed crossing. This keeps the observation tied to the available stones instead of treating a failed search as a mysterious refusal.

The connections here come from a spatial rule. Nearby stones are linked, and the banks receive links to nearby stones. The search therefore works with the routes that this constructed graph permits. A gap that your eyes imagine jumping is not automatically an edge, and a bright route is the spark’s calculated route rather than a promise that your own body can walk it.

The exhibit keeps a limited number of stones disabled. As more disappear, older ones can return. A route can consequently change because an option was removed or because an earlier option became available again. Keep both kinds of change in mind when you explain a rerouting.

Sometimes there may be no route. That outcome says something precise about the available graph. It does not prove that no crossing could exist with another bridge, another connection distance or another kind of traveller. Search cannot use an option the representation never supplies.

Try a second removal after the new route is established. Predict whether the remaining network has an alternative before asking the algorithm. A future extension could expose the search frontier, separating the work of finding a route from the spark’s later traversal of it.


Network analysis asks what the arrangement as a whole makes possible: which vertices connect many others, and which only look important in the drawing?

---

## GT Network Analysis

*GT_Network_Analysis*

# Important by which measure?

What evidence would justify calling one vertex central?


Find a large, conspicuous vertex and count its incident edges. Compare it with a smaller vertex. Then look at the displayed network measures. Ask which of those quantities you could independently check by following the connections.

Degree is one answer to a narrow question: how many edges meet this vertex? Other questions require other measures. A vertex might connect two regions without having the largest number of neighbours, or it might have many neighbours that are already richly connected to one another. “Important” hides these differences until we name the relation we want to measure.

Use two descriptions for the same vertex: one about how it is drawn, another about a connection you have checked. “Large and high” belongs to the first description; “joined to these neighbours” belongs to the second. You can then ask whether the presentation is helping you discover a relation or asking you to accept one. This distinction is especially useful when an animated number appears authoritative before you know what events or paths it summarises.

This display arranges vertices in authored layers with different sizes and colours. Its centrality values are assigned from ranges, and some summary measures follow an animation over time. They are not all calculated from the displayed edges. The room currently offers a diagram of a network hierarchy; its readouts cannot yet certify that hierarchy through graph analysis.

Your edge count is therefore a useful small piece of evidence. It can be compared with a visual claim without pretending that counting degree settles every possible meaning of centrality. If a large vertex looks authoritative, separate the role of its size, its placement and its actual connections.

The pathfinding room showed how losing an option can alter a route. Extend that thought here: imagine removing your chosen vertex. Which neighbours would still reach one another? Which connection would you need to check before answering? This is a prediction for a future removal experiment, not a claim that the present display performs one.

A stronger version of the room would calculate a named measure and let you inspect its supporting paths. It should also let another measure disagree, so a single visual ranking does not become the definition of value.


Connectivity next gives us one exact question to test: where can a directed traveller go and still return?

---

## GT Connectivity

*GT_Connectivity*

# A way back

If you can travel from one vertex to another, can you necessarily return?


Choose two vertices joined by a directed path. Trace the arrow directions from the first to the second, then search for a return route. Keep your proposed group in mind while the traversal assigns colours to completed components.

A strongly connected component is a maximal group in which every vertex can reach every other by directed paths. A one-way bridge can connect two groups visually while leaving them separate in this sense. Proximity, shared colour before the search, or a line with the wrong direction cannot substitute for a return path.

Test your proposed component from more than one starting point. A return route for one pair is necessary but does not settle whether every member of a larger group can reach every other. You can make the check manageable by looking for the paths that join a candidate member to the already considered group in both directions. An incoming connection alone may make the drawing feel joined while still leaving the traveller unable to return.

The exhibit runs a depth-first traversal. Each newly visited vertex receives a discovery number and remains on a stack while its group is unresolved. Another value records how far back the current exploration can connect through the relevant routes. This is the low-link information used to recognise when a component can be completed.

Watch the moment several vertices receive one component colour. They are being discharged together from the unresolved stack. The procedure has found a boundary in reachability, not simply collected the next fixed number of vertices. The stack you met with the two travellers now carries information about a question that remains open during the walk.

Try finding an edge between two completed colours. Follow its direction and ask what would need to be added to make the components mutually reachable. One additional return connection can change the component structure much more than its modest length in the drawing suggests.

Strong connectivity is still a limited promise. It establishes the existence of directed routes, not that those routes have equal cost, sufficient capacity or equal accessibility. A long and fragile return journey counts as a return journey under this definition.


Spanning trees will ask how many connections can be removed while everyone remains connected. The useful return route you just found may look like an expendable cycle under a different objective.

---

## GT Spanning Trees

*GT_Spanning_Trees*

# The price of one more route

Which connection can you remove without separating anyone from the network?


Watch the next edge considered by the display. Before it is accepted or rejected, trace whether its two endpoints are already connected through accepted edges. An edge can look short and useful while adding no new connection between the groups that remain separate.

The default procedure is Kruskal’s algorithm. It considers edges in increasing order of weight and accepts an edge when that edge joins two different components. If the endpoints are already joined, the candidate would complete a cycle and is rejected. A small structure called union-find tracks which vertices already belong to the same component.

When an edge is rejected, trace the accepted route between its endpoints and notice how that route completes the would-be cycle. The rejection has a structural reason even if the edge’s weight is small. When an edge is accepted, identify the two previously separate groups it joins. Alternating these two checks helps you follow the algorithm’s decisions without needing to remember every edge considered earlier or interpret the final green network all at once.

Continue until the selected edges span the connected graph. A tree connects its vertices without cycles; between each pair there is one selected route. With the given edge weights, Kruskal’s rule produces a spanning tree of minimum total weight. “Minimum” refers to that sum, not to every traveller’s individual journey.

Compare a rejected edge with the route now needed between its endpoints. Removing a direct connection can lower the cost of maintaining the whole network while lengthening a particular trip. The criterion that made the tree economical does not make each path shortest.

Now imagine one selected edge failing. In a tree, removing an edge separates the structure into two components. A cycle that looked redundant under the construction budget could have supplied a second route. Redundancy changes meaning when the question changes from cheap connection to surviving a failure.

For a proposed extension, let a group spend the cost of one extra edge after the tree is complete. Which edge would it restore, and whose journey or reliability would improve? That experiment would keep the minimum tree as an understandable baseline while making room for a different objective.


Flow adds another constraint. A route may exist and still be unable to carry everything trying to pass through it.

---

## GT Flow

*GT_Flow*

# What a junction cannot pass on

Where does the excess go when a junction receives more than it can send onwards?


Follow the initial flow leaving the source. Choose a junction that accumulates excess and compare its readout with the available outgoing edges. Watch for a PUSH or RELABEL step. Predict whether the next action can send material towards a neighbour or must first change the junction’s label.

Capacity limits how much an edge can carry. Flow is the amount currently assigned to it. Excess records a temporary imbalance at a vertex: more has arrived than has yet left. The height label gives the local procedure a direction in which to attempt a push; it is an algorithmic value, not the physical altitude of the drawn vertex.

Separate an edge that is full from a vertex that has excess. The first describes a limit on one connection; the second describes a temporary balance at a junction. A vertex can have more than one outgoing option, and those options can have different amounts of room left. Following that distinction makes a local PUSH easier to interpret: it transfers an available amount through a particular edge, rather than declaring that the entire junction is solved.

The exhibit begins by filling outgoing source edges. It then tries to move excess through remaining outgoing capacity towards lower labelled neighbours, changing labels when a push is unavailable. Those local changes help make congestion and temporary storage visible.

A complete maximum-flow method also needs a way to revise earlier allocations. Residual reverse capacity represents that possibility: some previously sent flow can be undone so that a better arrangement becomes available. This exhibit does not yet implement those reverse adjustments, so its current run cannot establish the general maximum-flow claim suggested by its title and readout.

Keep the observation smaller and exact: which vertex held excess, which original edge still had room, and what local operation followed? Those are relationships you can inspect without treating every accepted push as an irrevocable good decision.

The next useful experiment would expose a case that requires rerouting and make the reverse adjustment visible. The comparison would show why revision is part of the algorithm’s power. It would also prevent a blocked intermediate allocation being mistaken for a physical impossibility.


Matching will impose a different limit: each vertex may have only one selected partner. Once again, an early acceptable choice may need to be undone.

---

## GT Matching

*GT_Matching*

# A pair that blocks two pairs

Can every chosen pair be valid while the collection still leaves avoidable gaps?


Watch the edges considered by the matching display. Predict whether the next edge can be selected by checking its endpoints: has either already been paired? Follow one unmatched vertex to see whether its remaining neighbours are all occupied.

A matching is a set of edges with no shared endpoints. Each vertex participates in at most one selected pair. This condition tells us whether a collection is allowed, but it does not tell us that the collection contains as many pairs as possible.

Follow an occupied endpoint into the next few decisions. Several rejected edges can share that same endpoint, so one accepted pair can shape the fate of many later candidates. The rule prevents double booking correctly, but that correctness is only one part of the task. Keeping an unmatched vertex in view makes the consequence visible from the waiting vertex’s side, instead of assessing the procedure solely by how confidently it marks each new pair.

The present exhibit scans edges and accepts a pair whenever both endpoints are free. It keeps those choices. That greedy procedure can reach a maximal matching: no extra edge can simply be added without breaking the rule. A maximum matching answers a stronger question by containing the greatest possible number of pairs.

Try a small example in your head or with four people standing in a line, A, B, C, D. If B pairs with C first, neither outer edge can be added. The matching is maximal with one pair. Choosing A with B and C with D instead gives two pairs. Improving the first result requires undoing an accepted edge, not just looking harder for another unused edge.

The exhibit’s name refers to Edmonds’ algorithm, but its current procedure does not implement that algorithm’s augmenting and blossom-handling steps. Treat the visible greedy process as a starting case; the next development needs to make revision possible and show the example in which it matters.

Matching also leaves the meaning of a good partnership outside its endpoint rule. Maximising a count cannot establish consent, suitability or fairness. Those questions require further conditions and a way for participants’ preferences to matter.


The foundations sequence will question what a formal system can establish. Carry one distinction forward: a procedure meeting its local rule is not automatically a proof of its strongest advertised conclusion.

---
