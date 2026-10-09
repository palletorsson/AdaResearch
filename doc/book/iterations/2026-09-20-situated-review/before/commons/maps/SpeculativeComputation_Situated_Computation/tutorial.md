# Which part of a judgement tells you where it came from?

The conflict room asked for sources. Here the source travels visibly with the verdict.

<!-- @situated_readout -->

Read all four panels. Keep SUBJECT #4729 fixed in your comparison and record each verdict, confidence and footer. Return to the first panel and identify which fields changed between panels.

Four authored verdicts share one identifier. Your movement changes which panel you read. It does not make a panel recalculate an assessment of you.

The source makes the operation inspectable:

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

[Implementation](../../../commons/artifacts/situated_readout/situated_readout.gd). This is an excerpt from the artifact, not a standalone program.

A visible address makes a claim easier to question, but cannot make it correct. ORDERLY and CREATIVE are not logical negations; they could both describe someone under different criteria. DANGEROUS demands an account of danger to whom and in what circumstances. Even an agreeable label needs evidence. The room's productive limit is the gap between displaying a standpoint and exposing the method that produced its judgement.

<!-- @ -->

Keeping viewpoints visible is different from combining their contributions into a common object.

## Next experiment — not yet a visitor control

Give each panel an inspectable criterion and the evidence used. Compare disagreement caused by different criteria with disagreement caused by different observations. First verify that all four small panels can be read without losing their footers.
