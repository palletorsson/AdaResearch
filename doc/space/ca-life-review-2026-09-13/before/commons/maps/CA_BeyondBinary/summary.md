# CA Beyond Binary — Summary

CA_BeyondBinary is the fourth map in the Cellular Automata sequence. It relaxes two of the assumptions the earlier maps took for granted: that cells have exactly two states, and that the grid is rectangular. The space is a hexagonal tiling that reaches to the edges of the room.

The first station runs a totalistic rule. Rather than consulting the specific arrangement of neighbours, the rule counts how many neighbours are in each state and uses the totals to decide the next state. The rule table shrinks dramatically as a result, and the map shows it in full on a clipboard. Similar configurations produce similar outcomes, so the automaton reads as smoother than an elementary rule.

The second station runs Game of Life on the hexagonal grid. A hex has six neighbours instead of eight, so the thresholds change; the rule set is re-derived live on a panel. Gliders still appear, but they travel in hex-aligned directions rather than grid-aligned ones.

A VR booth at the back of the room lets the learner place seeds in a three-dimensional hex grid and watch them unfold overhead. The booth is deliberately non-rectangular — the map's broader argument is that neighbourhoods do not have to be square.

Within the sequence, Beyond_Binary loosens the substrate before CA_ExpandingSpace expands the neighbourhood.
