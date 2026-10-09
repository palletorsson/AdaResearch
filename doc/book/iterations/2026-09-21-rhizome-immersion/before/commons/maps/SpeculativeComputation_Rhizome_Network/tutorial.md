# Can a network grow without naming a root?

The commons machine had many sources and one centre. Here a new node chooses several existing neighbours.

<!-- @rhizome_grower -->

Watch a new shoot and trace its links. Press GROW to hold the arrivals, then REPLAY to return to the first two points. STEP admits one new point and waits. Compare a crowded region with a sparse one. Predict which nearby points the next shoot could reach, then inspect what appears.

Hold an arrangement and press LINKS. The positions stay while the rule switches between one and three earlier neighbours. Trace a route before and after the switch. Which points remain connected?

The source makes the operation inspectable:

```gdscript
var targets: Array = _nearest_indices(pos, links_per_node)
var new_idx: int = _add_node(pos)
if new_idx < 0:
    return
var t: int = 0
while t < targets.size():
    _add_edge(new_idx, int(targets[t]))
    t += 1
```

The neighbour search runs before the new node is inserted, so the shoot cannot select itself. It can only select nodes already present. Up to three nearest neighbours receive a link. The rule creates a graph without declaring a family tree; it also gives earlier and nearby nodes opportunities that later or distant nodes do not have.

[Implementation](../../../commons/artifacts/rhizome_grower/rhizome_grower.gd). This is an excerpt from the artifact, not a standalone program.

Select a busy node with NODE and predict the consequence of removing it. CUT hides its incident links and leaves a small grey ghost. Trace the surviving paths, then read COMPONENTS: it counts connected groups, including isolated active points. Restore the node with CUT, switch LINKS and repeat at the same point. Neither comparison moves the points or repairs missing relations.

No named root is a construction rule, not a certificate of equal power. Proximity and arrival time still shape access. DEGREE counts links, not authority. REPLAY can recover the same positions and forty-node growth holds for inspection; there is time to reconsider the arrangement.

<!-- @ -->

The assembly laboratory replaces nearest-neighbour growth with a catalogue and an authored target.

## Further experiment

Compare nearby links with a distant connection, or let the graph alter the region in which points can arrive. These are proposals; the current controls compare link count and temporary removal within a fixed region.
