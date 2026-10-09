# How much space does a distinction need?

Transformation gave us interpolation; arrays gave each word an address. Those operations now distribute room between labels.

<!-- @bias_from_inside -->

Choose two pink labels. Move the Perspective slider partway, compare their separation, then repeat with two grey labels. Hold the slider at one value while moving your own viewpoint.

The slider changes the positions of the labels themselves. Moving your head changes the view of that arrangement. Keep these two transformations separate.

The source makes the operation inspectable:

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The script calls this perspective, but it changes the represented geometry. It is not a camera command.

[Implementation](../../../commons/artifacts/bias_from_inside/bias_from_inside.gd). This is an excerpt from the artifact, not a standalone program.

The two groups and both arrangements were chosen by the maker. This is a spatial argument about compression, not a measurement of a trained language model. Its pink category can itself flatten the people it asks us to distinguish. Name one difference within that category that matters to you. The queer opening is a demand to revise the representation, not a promise that expanding every distance will produce justice.

<!-- @ -->

A representation allocates distinctions. A room allocates opportunities to address one another.

## Next experiment — not yet a visitor control

Compare a named pair at three slider positions from the same viewing distance, then ask whether the labels remain distinguishable from the intended approach. Record the pair and viewpoint before generalising this to other dense displays.
