# Distinguish — implementation and encounter

The primary artifact is `bias_from_inside`. Its [scene](../../../commons/artifacts/bias_from_inside/bias_from_inside.tscn) and [implementation](../../../commons/artifacts/bias_from_inside/bias_from_inside.gd) supply the behaviour described here.

The seeded position generator uses seed 42 and two arrays of twelve terms. A horizontal slider calls _on_perspective_changed(), clamps its input and updates MultiMesh instance transforms and label positions. The map places the default blend; perspective_blend is also configurable for authors. The exhibit does not train, query or evaluate an embedding model. Inspect the expanding grey group's clearance at both endpoints; its configured offset and spread exceed the initial compact cloud.

## Operation to read after the encounter

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The script calls this perspective, but it changes the represented geometry. It is not a camera command.

## What to compare

Choose two pink labels. Move the Perspective slider partway, compare their separation, then repeat with two grey labels. Hold the slider at one value while moving your own viewpoint.

The slider changes the positions of the labels themselves. Moving your head changes the view of that arrangement. Keep these two transformations separate.

## Limits and next test

Compare a named pair at three slider positions from the same viewing distance, then ask whether the labels remain distinguishable from the intended approach. Record the pair and viewpoint before generalising this to other dense displays.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
