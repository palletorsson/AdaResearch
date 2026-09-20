# Growing without a named root

Can local connections build a network without first choosing its centre?

<!-- @rhizome_grower -->

Watch for a new node and follow the segments it adds. Compare a crowded part of the structure with a sparse part. Predict which existing nodes are likely to receive the next connections, then check the new shoot against your prediction.

The exhibit starts with two nodes. A new shoot is placed within a bounded region and linked to up to three of the nearest existing nodes. Repeating this rule builds a graph from local proximity. The node and edge counts record its growth until the forty-node capacity is reached and the display starts again.

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

Find a node with several visible links. Imagine removing it and predict whether the remaining pieces would still connect. Graph theory gave us the tools to ask this precisely. The present exhibit does not offer deletion, so treat the prediction as a proposed test rather than evidence that every rhizome repairs itself.

The peer-production tool gathered contributions at one centre. This growth rule distributes connections through space, but geometry still acts as a gatekeeper: being nearby makes a relationship available. A future variant could let a new node choose a distant connection and compare the network’s routes and dependencies afterwards.

<!-- @ -->

The assembly laboratory adds a catalogue and a target arrangement. When connections must form a recognisable body, we can ask which bodies the catalogue has already imagined.
