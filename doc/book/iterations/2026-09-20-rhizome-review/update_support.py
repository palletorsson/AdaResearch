from pathlib import Path
import re

H=Path(__file__).resolve().parent
R=H.parents[3]
M=R/'commons/maps/SpeculativeComputation_Rhizome_Network'
old=(H/'before/commons/maps/SpeculativeComputation_Rhizome_Network/technical.md').read_text(encoding='utf-8')
code=re.search(r'```gdscript\n.*?```',old,re.S).group()
explanation=next(p for p in old.split('\n\n') if p.startswith('The neighbour search'))
technical='''# Connect — implementation and encounter

The primary artifact is `rhizome_grower`. Its [scene](../../../commons/artifacts/rhizome_grower/rhizome_grower.tscn) and [implementation](../../../commons/artifacts/rhizome_grower/rhizome_grower.gd) supply the behaviour described here. `rhizome_cave_demo` remains the secondary spatial exhibit at its existing cell.

## The same positions, another connection rule

The hall configures a full-size interactive placement, `spread=0.85`, `grow_period=0.8` and `sample_seed=47`. The default capacity is forty nodes and the initial rule chooses up to three earlier neighbours. Two initial points have no edge between them. Later points are sampled at radii `spread * 0.4 .. spread`, with height offsets of ±0.06 m. This is a fixed annulus with shallow vertical variation, not an expanding frontier. The display's circular frame is a boundary marker, not an edge in the graph.

The random generator prepares a finite sequence of positions. REPLAY retains that sequence and the current link setting, clears the graph to the two initial points and holds. STEP adds one point and holds; GROW toggles timed arrivals. Interactive growth holds at capacity. Other placements retain the passive default: smaller field, whole-graph sway and a fresh random sequence at capacity.

CODE

EXPLANATION

LINKS holds growth and reconstructs edges using either one or three nearest earlier points. Positions and insertion order remain fixed. Each node after the first two contributes one edge in the one-link case: the result is two trees. With three links, the third node joins both seeds; subsequent nodes join the existing connected graph. Neither construction asserts equal degree or social influence.

## Removal and measurement

NODE selects the next birth index, holds growth and highlights its active incident edges. Colour grades from early white to later teal. DEGREE counts undirected active neighbours. COMPONENTS traverses active adjacency and includes isolated active nodes.

CUT toggles the selected node's active state. Its stored coordinates and edges remain available for restoration; a small grey ghost marks the missing point. Edges with an inactive endpoint are omitted from drawing and measurement. Remaining nodes do not reconnect around it. Timed growth and STEP stay held while any node is cut, keeping the comparison stable. LINKS can change the underlying edge rule during that hold; returning CUT restores the node under whichever rule is selected.

Rendered edge cylinders use an oriented basis followed by scaling along their local Y axis. The runtime probe checks that both ends meet their node coordinates, including diagonal connections. Reconfiguring the artifact replaces only its own generated children and preserves children attached by the museum.

## Evidence and limits

The [dated review](../../../doc/book/iterations/2026-09-20-rhizome-review/SUMMARY.md) contains runtime measurements, button-signal checks, selected walking segments and rendered states. For the captured 24-point arrangement, one-link node 3 has degree 3: removing it changes two components into four. Under three links, the same node has degree 8; removing it leaves one component. This is a measured comparison, not a promise that any collection of cuts remains connected.

The work has no distant-link control, automatic repair, communication traffic or evolving growth boundary. Such extensions would pose different questions. Selected desktop collision and reach checks do not establish headset comfort, readability or learner understanding, nor do they establish that the cave is traversable.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Rhizome_Network/technical.md) preserves the previous proposed systems.
'''.replace('CODE',code).replace('EXPLANATION',explanation)
tutorial='''# Can a network grow without naming a root?

The commons machine had many sources and one centre. Here a new node chooses several existing neighbours.

<!-- @rhizome_grower -->

Watch a new shoot and trace its links. Press GROW to hold the arrivals, then REPLAY to return to the first two points. STEP admits one new point and waits. Compare a crowded region with a sparse one. Predict which nearby points the next shoot could reach, then inspect what appears.

Hold an arrangement and press LINKS. The positions stay while the rule switches between one and three earlier neighbours. Trace a route before and after the switch. Which points remain connected?

The source makes the operation inspectable:

CODE

EXPLANATION

[Implementation](../../../commons/artifacts/rhizome_grower/rhizome_grower.gd). This is an excerpt from the artifact, not a standalone program.

Select a busy node with NODE and predict the consequence of removing it. CUT hides its incident links and leaves a small grey ghost. Trace the surviving paths, then read COMPONENTS: it counts connected groups, including isolated active points. Restore the node with CUT, switch LINKS and repeat at the same point. Neither comparison moves the points or repairs missing relations.

No named root is a construction rule, not a certificate of equal power. Proximity and arrival time still shape access. DEGREE counts links, not authority. REPLAY can recover the same positions and forty-node growth holds for inspection; there is time to reconsider the arrangement.

<!-- @ -->

The assembly laboratory replaces nearest-neighbour growth with a catalogue and an authored target.

## Further experiment

Compare nearby links with a distant connection, or let the graph alter the region in which points can arrive. These are proposals; the current controls compare link count and temporary removal within a fixed region.
'''.replace('CODE',code).replace('EXPLANATION',explanation)
for name,value in [('technical.md',technical),('tutorial.md',tutorial)]:
 (M/name).write_text(value,encoding='utf-8')
