# A pair that blocks two pairs

Can every chosen pair be valid while the collection still leaves avoidable gaps?

<!-- @edmonds_algorithm -->

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

RESET repeats the selected order. Switching back to CYCLE FIRST brings the gaps back too. Both scans obey the same rule about free endpoints. Their different results give us a reason to ask for a procedure that can reconsider its own choices. The display runs greedy matching; Edmonds’ augmenting paths and blossom handling remain a further construction.[^name] Our order switch starts another scan. It does not teach the first scan how to undo a pair.

Matching also leaves the meaning of a good partnership outside its endpoint rule. Maximising a count cannot establish consent, suitability or fairness. Those questions require further conditions and a way for participants’ preferences to matter.

<!-- @ -->

The next hall keeps five sentences on a plaque and colours one of them gold before you have read it. Ask there, as here, whether a rule that is followed has been proved: a procedure meeting its local rule is not automatically a proof of its strongest advertised conclusion.

[^name]: The caption on the display reads GREEDY MATCHING. The artifact keeps the name of the procedure it was built to become, edmonds_algorithm, in its files, and nowhere a visitor can see.
