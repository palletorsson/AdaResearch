# Connect — implementation and encounter

The primary artifact is `rhizome_grower`. Its [scene](../../../commons/artifacts/rhizome_grower/rhizome_grower.tscn) and [implementation](../../../commons/artifacts/rhizome_grower/rhizome_grower.gd) supply the behaviour described here.

The default has max_nodes=40, links_per_node=3, grow_period=0.4 and spread=0.36. Two initial nodes seed the display. _nearest_indices() sorts Euclidean distances; _grow_shoot() inserts a node and its edges. Capacity triggers a fresh small graph. Growth is bounded in a shallow volume. rhizome_cave_demo remains a secondary spatial exhibit; a rootless graph does not prove that the visitor can traverse every part of the room.

## Operation to read after the encounter

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

## What to compare

Watch a new shoot and trace its links. Compare a crowded region with a sparse one. Predict which nearby nodes the next shoot could reach, then inspect what actually appears.

New nodes connect by distance. They have no designated root, but some nodes accumulate more links than others. The little graph sways as a whole; that motion is separate from the creation of edges.

## Limits and next test

Expose a selectable node and removal operation, then show connected components before and after deletion. Compare nearest-only growth with one distant connection per shoot. The current exhibit has neither deletion nor automatic repair.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Rhizome_Network/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
