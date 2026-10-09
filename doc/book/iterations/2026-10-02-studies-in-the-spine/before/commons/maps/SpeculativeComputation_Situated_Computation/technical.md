# Locate the claim — implementation and encounter

The primary artifact is `situated_readout`. Its [scene](../../../commons/artifacts/situated_readout/situated_readout.tscn) and [implementation](../../../commons/artifacts/situated_readout/situated_readout.gd) supply the behaviour described here.

This follows the merge encounter's question about preserving sources. Four placements retain their explicit `#verdict:NW`, NE, SW and SE keys and cells. They face inward and use full scale, `#interactive:true` and `#address:footnote`. The primary comparison is still between four authored entries, not four sensor measurements.

The ADDRESS panel exposes FOOTNOTE, COVER (`erasure`) and WITNESS. Only the address presentation changes: the subject, verdict, supplied confidence and station transform remain fixed. The explicit key takes precedence over the position hash. Moving a configured panel and repopulating it updates the numeric footer without changing its verdict. Walking the player around does not update a classification.

Interactive panels put their centre at 1.25 m and draw four readable text quads from the existing Label3D values. The erasure strip remains physically in front of the footer. WITNESS retains the existing symbolic eye, station plate and height marks; it measures nothing. Controls sit to the side of the reading. Stage geometry rebuilds independently of the console and children added by the museum. Unconfigured placements retain the passive 0.85 m panel centre and original labels. Parallax and survey remain author-configurable variants; they are not added to this hall's controls.


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

Controlled runtime checks cover the four assigned claims, presentation changes, selected reach and walking routes. Headset readability, comfort, Quest performance and learner understanding remain open. The supporting spider is paused only in the private geometry probe; its live behaviour is unchanged. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Situated_Computation/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.

The grid exit at (4,9) previously had a zero floor cell beneath its teleporter; it now has continuous floor. An arrival marker and local decoration exclusions reserve approach and reading space. The creature remains at its original cell with detection 14.
