# CA Expanding Space — Summary

CA_ExpandingSpace is the sixth map in the Cellular Automata sequence. It treats the neighbourhood radius as a parameter rather than a fixed constant. Earlier maps assumed each cell sees only its immediate neighbours; this map extends the reach to second, third, or further rings of cells and asks what changes.

The central station is a 3D tree. A local growth rule fires whenever enough cells within a chosen radius are filled. At radius one, the tree grows as a thin thread. At radius two, it thickens into a trunk. At radius three, it branches. The same rule, under larger neighbourhoods, produces qualitatively different structures — the parameter that looked like a detail turns out to shape the outcome as much as the rule does.

A second station runs a crossway automaton. Two influence zones from opposing corners of the grid overlap in the middle of the floor. Where they meet, the rules interfere: cells satisfy both conditions simultaneously and the boundary produces structure that neither zone would have produced alone.

Sliders at each station adjust the radius, the neighbourhood shape, and the activation threshold. Within the sequence, Expanding_Space is where locality itself becomes tunable. CA_SoftRules will next introduce non-determinism.
