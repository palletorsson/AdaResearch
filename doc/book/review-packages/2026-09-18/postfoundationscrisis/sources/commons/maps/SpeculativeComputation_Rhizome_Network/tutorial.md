# Can a network grow without naming a root?

The commons machine had many sources and one centre. Here a new node chooses several existing neighbours.

<!-- @rhizome_grower -->

Watch a new shoot and trace its links. Compare a crowded region with a sparse one. Predict which nearby nodes the next shoot could reach, then inspect what actually appears.

New nodes connect by distance. They have no designated root, but some nodes accumulate more links than others. The little graph sways as a whole; that motion is separate from the creation of edges.

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

No named root is a construction rule, not a certificate of equal power. Proximity and arrival time still shape access. A graph can contain uneven degrees, bottlenecks and dependencies without storing a hierarchy field. The desire for other relations becomes useful when we can ask which relation to change and observe the consequences. Adding a distant link or removing a busy node would make a sharper experiment than simply calling the whole network free.

<!-- @ -->

The assembly laboratory replaces nearest-neighbour growth with a catalogue and an authored target.

## Next experiment — not yet a visitor control

Expose a selectable node and removal operation, then show connected components before and after deletion. Compare nearest-only growth with one distant connection per shoot. The current exhibit has neither deletion nor automatic repair.
