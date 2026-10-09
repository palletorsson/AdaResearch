# CA Introduction — Summary

CA_Introduction opens the Cellular Automata sequence. A grid of discrete cells covers a wide floor. Each cell has a small, identical neighbourhood and a single rule that updates its state by looking at that neighbourhood. The grid ticks in discrete steps, and everything updates at once. Nothing in the space moves continuously.

The central feature is a Persian-rug pattern produced by a simple 1D rule running top to bottom along a wall. Each row is the successor of the row above, computed in parallel from triplets of cells. Local symmetry propagates outward and produces the woven ornament across the whole surface. The rug makes the claim of the sequence visible at the entry: complex pattern can come from a local rule applied uniformly.

Across the floor, small architectural artifacts extend the point. A short column is assembled cell by cell from a rule that adds a supporting cell whenever two neighbours are filled. A bridge spans a gap using a similar rule with different neighbour thresholds. The structures are incidental — the sequence is not about making bridges — but they show that discrete local decisions can pile up into structure.

Within the sequence, Introduction is the grammar lesson. CA_GameOfLife and CA_ElementaryRules will take these ingredients — discrete cells, discrete time, local rules — and raise the consequences.
