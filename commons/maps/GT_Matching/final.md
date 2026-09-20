# A pair that blocks two pairs

Can every chosen pair be valid while the collection still leaves avoidable gaps?

<!-- @edmonds_algorithm -->

Watch the edges considered by the matching display. Predict whether the next edge can be selected by checking its endpoints: has either already been paired? Follow one unmatched vertex to see whether its remaining neighbours are all occupied.

A matching is a set of edges with no shared endpoints. Each vertex participates in at most one selected pair. This condition tells us whether a collection is allowed, but it does not tell us that the collection contains as many pairs as possible.

Follow an occupied endpoint into the next few decisions. Several rejected edges can share that same endpoint, so one accepted pair can shape the fate of many later candidates. The rule prevents double booking correctly, but that correctness is only one part of the task. Keeping an unmatched vertex in view makes the consequence visible from the waiting vertex’s side, instead of assessing the procedure solely by how confidently it marks each new pair.

The present exhibit scans edges and accepts a pair whenever both endpoints are free. It keeps those choices. That greedy procedure can reach a maximal matching: no extra edge can simply be added without breaking the rule. A maximum matching answers a stronger question by containing the greatest possible number of pairs.

Try a small example in your head or with four people standing in a line, A, B, C, D. If B pairs with C first, neither outer edge can be added. The matching is maximal with one pair. Choosing A with B and C with D instead gives two pairs. Improving the first result requires undoing an accepted edge, not just looking harder for another unused edge.

The exhibit’s name refers to Edmonds’ algorithm, but its current procedure does not implement that algorithm’s augmenting and blossom-handling steps. Treat the visible greedy process as a starting case; the next development needs to make revision possible and show the example in which it matters.

Matching also leaves the meaning of a good partnership outside its endpoint rule. Maximising a count cannot establish consent, suitability or fairness. Those questions require further conditions and a way for participants’ preferences to matter.

<!-- @ -->

The foundations sequence will question what a formal system can establish. Carry one distinction forward: a procedure meeting its local rule is not automatically a proof of its strongest advertised conclusion.
