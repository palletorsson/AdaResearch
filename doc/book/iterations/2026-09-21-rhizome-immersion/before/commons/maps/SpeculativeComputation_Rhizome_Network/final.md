# Growing without a named root

Can local connections build a network without first choosing its centre?

<!-- @rhizome_grower -->

Watch for a new node and follow the segments it adds. Compare a crowded part of the structure with a sparse part. Predict which existing nodes are likely to receive the next connections, then check the new shoot against your prediction.

Press GROW to hold the arrivals. REPLAY returns to the first two points; STEP admits one more and waits. You can follow the next addition without losing it in the next ten.

The exhibit starts with two unconnected nodes. Each new shoot is placed within a fixed ring-shaped region and linked to up to three of the nearest existing nodes. Repeating this rule builds a graph from local proximity. At forty nodes, the display holds. REPLAY uses the same sequence of positions, so another attempt can meet the same arrangement.

The ring does not spread with the shoots. The machine keeps finding new places inside a boundary it chose before the network began. Something is growing, but its territory has already been given.

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

No vertex is assigned a root role. There is no stored family tree telling every later node to descend from one privileged ancestor. Multiple connections permit the growing structure to contain routes that differ from a simple parent-and-child hierarchy.

The rule still has consequences worth inspecting. Earlier nodes are available to be chosen for longer, and spatially well-placed nodes can attract many nearby additions. A network without a designated root can develop busy regions and uneven degrees. “No root” describes part of the construction; it does not prove that every participant has equal influence.

Hold an arrangement and press LINKS. The points stay where they are while the rule changes between one and three earlier neighbours. What disappears without any point moving? With one link per new node, the two starting points remain in separate trees. Three links allow routes between those trees. A rule that never names a root can still grow ancestors.

Use NODE to follow the numbered arrivals. Its amber links show where the selected point connects; DEGREE counts those links. Compare an early point with a late one. A degree is something we can count here. Influence would need another question: what travels along a link, and what can a node do with it?

Find a node with several visible links. Before pressing CUT, predict whether the remaining pieces will still connect. The node becomes a small grey ghost and its links disappear. COMPONENTS counts the separate connected groups, including a point left alone. Follow the remaining paths before trusting the number. A crossing of lines is not a junction unless they meet at a node.

Press CUT again to restore it, then change LINKS and remove the same node. Does the loss divide this version too? Nothing repairs itself while you watch; the machine holds the graph so you can inspect what survived. Restoration puts back the missing point and its old links. These are different acts: surviving a loss, repairing a relation, undoing a removal. The display lets us compare the first and perform the last. Repair still needs a rule.

The peer-production tool gathered contributions at one centre. This growth rule distributes connections through space, but geometry still acts as a gatekeeper: being nearby makes a relationship available. A future variant could let a new node choose a distant connection and compare the network’s routes and dependencies afterwards.

<!-- @ -->

The assembly laboratory adds a catalogue and a target arrangement. When connections must form a recognisable body, we can ask which bodies the catalogue has already imagined.
