# graphtheory: the chapters

## GT Foundations

*GT_Foundations*

### Two travellers, one graph

Can two travellers obey the same connections and encounter the graph in different orders?


Choose a lamp several connections away from the starting lamp. Predict whether it will be reached early or late. Watch one traversal, then keep the same destination in mind as the other begins. The exhibit alternates between two visiting rules on the same branching structure.

One traveller, the hall calls it the tide, explores the nearest layer of neighbours before moving further out. The other, the diver, follows a branch deeper before returning to alternatives. The lamps and their connections remain available to both; what changes is the order in which unfinished possibilities are kept.

During the breadth-first traversal, look across an entire layer before following the traveller deeper. During the depth-first traversal, keep one unfinished side branch in mind while attention goes elsewhere. The waiting branch has not disappeared from the graph. It has changed position in the procedure’s pending work. This comparison lets you describe order without changing the structure itself, and makes the traveller’s memory as important as the connections directly in front of it.

A graph describes this arrangement with vertices and edges. A vertex is a place in the structure, and an edge records a permitted connection. Its drawing helps us see the graph, but the visiting rule acts on those connections rather than on how attractive or physically close a lamp appears.

Breadth-first search keeps a queue: newly discovered possibilities wait behind earlier ones. Depth-first search uses a stack: the most recently added possibility is taken next. Those small differences in memory produce the two larger rhythms you have watched. A queue spreads attention across a frontier; a stack carries it into a branch.

Return to your chosen lamp and count connections from the start. In this unweighted graph, breadth-first layers correspond to that number of steps. Depth-first search can reach a deep lamp while another shallow branch still waits. Neither visit order is a complete account of which destination matters most.

If the lamps stood for people awaiting attention, the ordering rule would have consequences beyond its neat animation. A procedure that eventually reaches everyone can still make some wait much longer. Pick one lamp and make it urgent. Under which traveller does it wait longer, and by how many visits?


The next room lets the drawing itself move. Keep the graph’s connections separate from the positions used to display them.

---

## GT Layout

*GT_Layout*

### A connection is not a coordinate

If the drawing moves, has the graph changed?


Choose one vertex and identify two of its connected neighbours. Keep those relationships in view while the drawing settles. Notice which distances change and which connections remain. Try to describe the difference without calling every movement a new network.

The default graph has eight vertices joined in a cube’s connection pattern. Its positions are not fixed: connected vertices pull together as if on springs, every pair of vertices pushes apart, and damping wears the motion down. The final arrangement reflects the balance of these forces rather than an instruction to draw a particular cube in a particular orientation.

Choose an edge whose length changes noticeably as the drawing settles. Describe its endpoints without using left, right or above, since those descriptions may stop helping as positions move. You might identify one endpoint through its neighbours and then follow the same relation through the motion. This is a small exercise in recognising structure independently of its current projection. The drawing remains useful, but it is no longer the only way you know which connection you are seeing.

A force-directed layout is a method for choosing a graph’s visible coordinates. The graph supplies adjacency; the layout supplies positions that may make that adjacency easier to inspect. An edge can stretch without ceasing to connect the same pair. Conversely, two unconnected vertices can pass close together in the drawing without acquiring an edge.

The two travellers in the previous room followed connections. They would still need the adjacency structure even if this layout placed two unrelated vertices almost on top of one another. Visual proximity can suggest a relationship that the visiting rule does not possess.

Now find a vertex that looks central. Is it central in the arrangement, unusually well connected, or simply easy to see from where you stand? Those questions can have different answers. Count: every vertex in this graph has exactly three neighbours, so whatever looked central was the drawing’s doing. A useful drawing can also invite an unsupported story about influence or importance.

The drawing in front of you is one layout of many the same graph could be given, and walking gives you another: go round to the far side and look again. Is the vertex you called central still central from there? If a claim about the network disappears when the drawing rearranges, or when you move, ask whether the claim belonged to the graph or to its presentation.


Pathfinding will change a connection’s availability while a traveller is already moving. This time the route really may need to change.

---

## GT Pathfinding

*GT_Pathfinding*

### The route after a stone disappears

What should a traveller do when the route it planned is no longer available?


Follow the spark’s route across the stones. Before pressing the button, choose the next connection you expect it to use. The button sinks a stone belonging to the current route. Watch where the spark goes on its next crossing, and whether it still reaches the opposite bank. The readout’s stone count is the one number that changes.

A route is a sequence through available connections. Removing a stone changes the graph the search can use; it does not merely make the old drawing look different. The exhibit marks that stone unavailable and asks for another path through the remaining graph.

After a removal, compare the crossing you remember with the one the spark now makes. Look for a stretch that remains useful to both. Replanning does not imply that every previous choice was wrong; some connections can survive a local change while another segment must be replaced. If the readout says NO ROUTE, trace the missing connection in your own proposed crossing. This keeps the observation tied to the available stones instead of treating a failed search as a mysterious refusal.

The connections here come from a spatial rule. Nearby stones are linked, and the banks receive links to nearby stones. The search therefore works with the routes that this constructed graph permits. A gap that your eyes imagine jumping is not automatically an edge, and the spark’s hops are its calculated route, not a promise that your own body can walk it.

The exhibit keeps a limited number of stones disabled. As more disappear, older ones can return. A route can consequently change because an option was removed or because an earlier option became available again. Keep both kinds of change in mind when you explain a rerouting.

Sometimes there may be no route. That outcome says something precise about the available graph. It does not prove that no crossing could exist with another bridge, another connection distance or another kind of traveller. Search cannot use an option the representation never supplies.

Try a second removal after the new route is established. Predict whether the remaining network has an alternative before asking the algorithm. The search is over before the spark sets off; what you watch is the route it found, not the finding. Which stones do you think it had to consider and pass over before it settled on these?


Network analysis asks what the arrangement as a whole makes possible: which vertices connect many others, and which only look important in the drawing?

---

## GT Network Analysis

*GT_Network_Analysis*

### Important by which measure?

What evidence would justify calling one vertex central?


Find a large, conspicuous vertex and count its incident edges. Compare it with a smaller one. The large red vertices orbit slowly and pulse harder; the small green ones circle faster and glow less. Ask which of those differences, size, colour, orbit, glow, you could independently check by following the connections.

Degree is one answer to a narrow question: how many edges meet this vertex? Other questions require other measures. A vertex might connect two regions without having the largest number of neighbours, or it might have many neighbours that are already richly connected to one another. “Important” hides these differences until we name the relation we want to measure.

Use two descriptions for the same vertex: one about how it is drawn, another about a connection you have checked. “Large and high” belongs to the first description; “joined to these neighbours” belongs to the second. You can then ask whether the presentation is helping you discover a relation or asking you to accept one. This distinction is especially useful when a size or a glow appears authoritative before you know what events or paths it summarises.

This display arranges vertices in authored layers with different sizes and colours. Its centrality values are assigned from ranges, and the two summary numbers it computes follow a clock rather than the edges, and are never shown. Nothing here is calculated from the displayed connections. The room currently offers a diagram of a network hierarchy; its two meters, a ball on a bar at either side, do not move, and cannot certify that hierarchy through graph analysis.

Your edge count is therefore a useful small piece of evidence. It can be compared with a visual claim without pretending that counting degree settles every possible meaning of centrality. If a large vertex looks authoritative, separate the role of its size, its placement and its actual connections.

The pathfinding room showed how losing an option can alter a route. Extend that thought here: imagine removing your chosen vertex. Which neighbours would still reach one another? Which connection would you need to check before answering? This is a prediction for a future removal experiment, not a claim that the present display performs one.

Beyond these moving vertices, another drawing gives us a named measure and the records it counts. Follow one connection into the next part of the room.


<!-- study-spine:evidence_network -->


A fine curve joins the Studio to the Builder. It seems easy to follow. Select RECORD. A date and a payment appear beneath it. The arrow says which way the payment went; it says nothing about whether the work was done.

Move the arrangement. The Archive travels towards the centre without receiving another report. Its incoming count stays the same. Choose only PAYMENTS and several connections disappear. The people have not ceased to know one another. We have narrowed the question.

Lombardi's drawings make the labour behind a connection matter. This small archive is openly fictional. Each line can be traced to one authored record; none can stand as evidence about an actual person. A convincing network can still be a poor account.


Connectivity next gives us one exact question to test: where can a directed traveller go and still return?

---

## GT Connectivity

*GT_Connectivity*

### A way back

If you can travel from one vertex to another, can you necessarily return?


Choose two vertices joined by a directed path. Trace the arrow directions from the first to the second, then search for a return route. Keep your proposed group in mind while the traversal assigns colours to completed components.

A strongly connected component is a maximal group in which every vertex can reach every other by directed paths. A one-way bridge can connect two groups visually while leaving them separate in this sense. Proximity, shared colour before the search, or a line with the wrong direction cannot substitute for a return path.

Test your proposed component from more than one starting point. A return route for one pair is necessary but does not settle whether every member of a larger group can reach every other. You can make the check manageable by looking for the paths that join a candidate member to the already considered group in both directions. An incoming connection alone may make the drawing feel joined while still leaving the traveller unable to return.

The exhibit runs a depth-first traversal. Each newly visited vertex receives a discovery number and remains on a stack while its group is unresolved. Another value records how far back the current exploration can connect through the relevant routes. This is the low-link information used to recognise when a component can be completed. A vertex turns yellow when visited and orange when finished but still waiting on the stack; an edge that closes back onto a waiting vertex turns red, and that is the moment the low-link is lowered.

Watch the moment several vertices receive one component colour. They are being discharged together from the unresolved stack. The procedure has found a boundary in reachability, not simply collected the next fixed number of vertices. The stack you met with the two travellers now carries information about a question that remains open during the walk.

Try finding an edge between two completed colours. Follow its direction and ask what would need to be added to make the components mutually reachable. One additional return connection can change the component structure much more than its modest length in the drawing suggests.

Strong connectivity is still a limited promise. It establishes the existence of directed routes, not that those routes have equal cost, sufficient capacity or equal accessibility. A long and fragile return journey counts as a return journey under this definition.


Spanning trees will ask how many connections can be removed while everyone remains connected. The useful return route you just found may look like an expendable cycle under a different objective.

---

## GT Spanning Trees

*GT_Spanning_Trees*

### The price of one more route

Which connection can you remove without separating anyone from the network?


Watch the next edge considered by the display: it turns yellow. Before anything else happens to it, trace whether its two endpoints are already connected through accepted edges. If they are not, a green line is laid along it. If they are, nothing more happens: the yellow stays, and the display moves on. A rejection is never marked here, so the tracing is yours to do.[^GT_Spanning_Trees--red] An edge can look short and useful while adding no new connection between the groups that remain separate.

The default procedure is Kruskal’s algorithm. It considers edges in increasing order of weight and accepts an edge when that edge joins two different components. If the endpoints are already joined, the candidate would complete a cycle and is rejected. A small structure called union-find tracks which vertices already belong to the same component.

When an edge is left yellow, trace the accepted route between its endpoints and notice how that route completes the would-be cycle. The rejection has a structural reason even if the edge’s weight is small. When an edge is accepted, identify the two previously separate groups it joins. Alternating these two checks helps you follow the algorithm’s decisions without needing to remember every edge considered earlier or interpret the final green network all at once.

Continue until the selected edges span the connected graph. A tree connects its vertices without cycles; between each pair there is one selected route. With the given edge weights, Kruskal’s rule produces a spanning tree of minimum total weight. “Minimum” refers to that sum, not to every traveller’s individual journey.

Compare a yellow edge with the green route now needed between its endpoints. Removing a direct connection can lower the cost of maintaining the whole network while lengthening a particular trip. The criterion that made the tree economical does not make each path shortest.

Now imagine one selected edge failing. In a tree, removing an edge separates the structure into two components. A cycle that looked redundant under the construction budget could have supplied a second route. Redundancy changes meaning when the question changes from cheap connection to surviving a failure.

Suppose you had the cost of one extra edge to spend once the tree is complete. Which of the yellow edges would you restore, and whose journey or reliability would improve? The minimum tree is the baseline in front of you; the objective that would spend on it is yours to name.


Flow adds another constraint. A route may exist and still be unable to carry everything trying to pass through it.

[^GT_Spanning_Trees--red]: The artifact’s registry entry promises that rejected cycle-forming edges glow red (`commons/artifacts/registry/algorithms_misc.json`, line 5357). The scene never does it: the call that would colour them is commented out and the export for that colour is unused. What you see is what the code does, not what its description says.

---

## GT Flow

*GT_Flow*

### What a junction cannot pass on

Where does the excess go when a junction receives more than it can send onwards?


Follow the initial flow leaving the source. Choose a junction that accumulates excess and compare its readout with the available outgoing edges. Watch for a PUSH or RELABEL step. Predict whether the next action can send material towards a neighbour or must first change the junction’s label.

Capacity limits how much an edge can carry. Flow is the amount currently assigned to it. Excess records a temporary imbalance at a vertex: more has arrived than has yet left. The source shows a negative excess: it is the total it has sent out and will not receive back. The height label gives the local procedure a direction in which to attempt a push; it is an algorithmic value, not the physical altitude of the drawn vertex.

Separate an edge that is full from a vertex that has excess. The first describes a limit on one connection; the second describes a temporary balance at a junction. A vertex can have more than one outgoing option, and those options can have different amounts of room left. Following that distinction makes a local PUSH easier to interpret: it transfers an available amount through a particular edge, rather than declaring that the entire junction is solved.

The exhibit begins by filling outgoing source edges. It then tries to move excess through remaining outgoing capacity towards lower labelled neighbours, changing labels when a push is unavailable. Those local changes help make congestion and temporary storage visible.

A junction can run out of forward capacity while still holding excess. If the display stops at BLOCKED, find that junction. Its neighbours have not vanished; the remaining space on its outgoing edges has run out. The readout keeps the excess visible and reports how much reached the sink. It leaves us with a question: could some of what was sent earlier be taken back?

A complete maximum-flow method also needs a way to revise earlier allocations. Residual reverse capacity represents that possibility: some previously sent flow can be undone so that a better arrangement becomes available. The display is labelled a forward-only study because it has no such reverse adjustments. What reached the sink records this run; it does not settle how much could reach it under another allocation.

Keep the observation smaller and exact: which vertex held excess, which original edge still had room, and what local operation followed? Those are relationships you can inspect without treating every accepted push as an irrevocable good decision.

The next useful experiment would expose a case that requires rerouting and make the reverse adjustment visible. The comparison would show why revision is part of the algorithm’s power. It would also prevent a blocked intermediate allocation being mistaken for a physical impossibility.


Matching will impose a different limit: each vertex may have only one selected partner. Once again, an early acceptable choice may need to be undone.

---

## GT Matching

*GT_Matching*

### A pair that blocks two pairs

Can every chosen pair be valid while the collection still leaves avoidable gaps?


Five points make a ring; each has another point waiting outside it, joined by a single spoke. Choose one of those outer points. In CYCLE FIRST, press STEP and watch the edges considered by the matching display. Predict whether the next edge can be selected: has either endpoint already been paired? RUN / PAUSE lets the scan continue. Keep your chosen point in view as its neighbour finds company.

A matching is a set of edges with no shared endpoints. Each vertex participates in at most one selected pair. This condition tells us whether a collection is allowed, but it does not tell us that the collection contains as many pairs as possible.

Follow an occupied endpoint into the next few decisions. Several rejected edges can share that same endpoint, so one accepted pair can shape the fate of many later candidates. The rule prevents double booking correctly, but that correctness is only one part of the task. Keeping an unmatched vertex in view makes the consequence visible from the waiting vertex’s side, instead of assessing the procedure solely by how confidently it marks each new pair.

The present exhibit scans edges and accepts a pair whenever both endpoints are free. It keeps those choices. That greedy procedure can reach a maximal matching: no extra edge can simply be added without breaking the rule. A maximum matching answers a stronger question by containing the greatest possible number of pairs.

Try a small example in your head or with four people standing in a line, A, B, C, D. If B pairs with C first, neither outer edge can be added. The matching is maximal with one pair. Choosing A with B and C with D instead gives two pairs. Improving the first result requires undoing an accepted edge, not just looking harder for another unused edge.

When the cycle-first scan ends, count the pairs and the points left waiting. There are three pairs, with four outer points unpaired. Follow each unused spoke inwards. The connection is still there. Its inner endpoint was taken by an earlier choice.

Press ORDER for SPOKES FIRST. The points stay where they were; every connection remains. The earlier pairings clear. Before running again, predict what will happen to the point you chose. This time five pairs form, one along each spoke. Nobody has gained a new connection. We changed which possibility was considered first.

![Cycle first: the ring’s edges scanned before the spokes; three pairs, four outer points waiting.](/book-review/doc/book/figures/graphtheory/matching-cycle-first.png)

![Spokes first: the same ten points and ten connections; five pairs, one along each spoke.](/book-review/doc/book/figures/graphtheory/matching-spokes-first.png)

*Same ten points, same ten connections. Cycle first: three pairs, four waiting. Spokes first: five pairs. Two end states of one graph, from the same museum camera.*

RESET repeats the selected order. Switching back to CYCLE FIRST brings the gaps back too. Both scans obey the same rule about free endpoints. Their different results give us a reason to ask for a procedure that can reconsider its own choices. The display runs greedy matching; Edmonds’ augmenting paths and blossom handling remain a further construction.[^GT_Matching--name] Our order switch starts another scan. It does not teach the first scan how to undo a pair.

Matching also leaves the meaning of a good partnership outside its endpoint rule. Maximising a count cannot establish consent, suitability or fairness. Those questions require further conditions and a way for participants’ preferences to matter.


The next hall keeps five sentences on a plaque and colours one of them gold before you have read it. Ask there, as here, whether a rule that is followed has been proved: a procedure meeting its local rule is not automatically a proof of its strongest advertised conclusion.

[^GT_Matching--name]: The caption on the display reads GREEDY MATCHING. The artifact keeps the name of the procedure it was built to become, edmonds_algorithm, in its files, and nowhere a visitor can see.

---
