# What a junction cannot pass on

Where does the excess go when a junction receives more than it can send onwards?

<!-- @push_relabel_algorithm -->

Follow the initial flow leaving the source. Choose a junction that accumulates excess and compare its readout with the available outgoing edges. Watch for a PUSH or RELABEL step. Predict whether the next action can send material towards a neighbour or must first change the junction’s label.

Capacity limits how much an edge can carry. Flow is the amount currently assigned to it. Excess records a temporary imbalance at a vertex: more has arrived than has yet left. The height label gives the local procedure a direction in which to attempt a push; it is an algorithmic value, not the physical altitude of the drawn vertex.

Separate an edge that is full from a vertex that has excess. The first describes a limit on one connection; the second describes a temporary balance at a junction. A vertex can have more than one outgoing option, and those options can have different amounts of room left. Following that distinction makes a local PUSH easier to interpret: it transfers an available amount through a particular edge, rather than declaring that the entire junction is solved.

The exhibit begins by filling outgoing source edges. It then tries to move excess through remaining outgoing capacity towards lower labelled neighbours, changing labels when a push is unavailable. Those local changes help make congestion and temporary storage visible.

A complete maximum-flow method also needs a way to revise earlier allocations. Residual reverse capacity represents that possibility: some previously sent flow can be undone so that a better arrangement becomes available. This exhibit does not yet implement those reverse adjustments, so its current run cannot establish the general maximum-flow claim suggested by its title and readout.

Keep the observation smaller and exact: which vertex held excess, which original edge still had room, and what local operation followed? Those are relationships you can inspect without treating every accepted push as an irrevocable good decision.

The next useful experiment would expose a case that requires rerouting and make the reverse adjustment visible. The comparison would show why revision is part of the algorithm’s power. It would also prevent a blocked intermediate allocation being mistaken for a physical impossibility.

<!-- @ -->

Matching will impose a different limit: each vertex may have only one selected partner. Once again, an early acceptable choice may need to be undone.
