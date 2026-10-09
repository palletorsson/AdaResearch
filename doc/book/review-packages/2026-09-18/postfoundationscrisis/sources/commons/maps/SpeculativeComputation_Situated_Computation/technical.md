# Locate the claim — implementation and encounter

The primary artifact is `situated_readout`. Its [scene](../../../commons/artifacts/situated_readout/situated_readout.tscn) and [implementation](../../../commons/artifacts/situated_readout/situated_readout.gd) supply the behaviour described here.

There are four placements of the same primary token with #verdict:NW, NE, SW and SE. _resolve_quadrant_key() returns a valid explicit override first; only unconfigured instances use a position hash. The default address=footnote shows provenance on the panel. There is no classifier, player sensor or probability calibration behind QUADRANT_VERDICTS. These placements had been absent from the museum declaration even though they existed in the sequence and grid map.

## Operation to read after the encounter

```gdscript
var pos := global_position
var key := _resolve_quadrant_key(pos)
var verdict: Dictionary = QUADRANT_VERDICTS.get(key, QUADRANT_VERDICTS["NW"])

_verdict_label.text = verdict.label
_verdict_label.modulate = verdict.color
_confidence_label.text = "confidence %d%%" % int(verdict.confidence * 100.0)
_footer_label.text = "view from %s (%.1f, %.1f)" % [key, pos.x, pos.z]
```

The dictionary supplies a verdict and a confidence; the footer supplies a location. There is a revealing extra decision: this hall explicitly assigns NW, NE, SW and SE through its map tokens. That override takes precedence over the position-based fallback. The four-way disagreement has been composed for us. The percentages have not been earned by measuring the subject.

## What to compare

Read all four panels. Keep SUBJECT #4729 fixed in your comparison and record each verdict, confidence and footer. Return to the first panel and identify which fields changed between panels.

Four authored verdicts share one identifier. Your movement changes which panel you read. It does not make a panel recalculate an assessment of you.

## Limits and next test

Give each panel an inspectable criterion and the evidence used. Compare disagreement caused by different criteria with disagreement caused by different observations. First verify that all four small panels can be read without losing their footers.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Situated_Computation/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
