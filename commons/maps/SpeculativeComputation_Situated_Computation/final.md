# Four verdicts about the same subject

What changes when the subject stays the same but the source of the judgement changes?

<!-- @situated_readout -->

Read the subject identifier on all four panels. Keep it fixed in your comparison, then note the verdict, the confidence and the footer on each. Look back at the first panel after reading the others: it has not become a different subject because another description is available.

SUBJECT #4729 appears as ORDERLY, CREATIVE, DANGEROUS or IRRELEVANT across the four positions. The associated percentages differ too. The room makes a judgement’s location visible instead of presenting one description as if it came from nowhere.

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

These are four authored readouts. Each panel retains the verdict assigned to it; your movement changes which panel you read. The percentages are supplied examples, not calibrated probabilities calculated from evidence about a real person. A high number in this room therefore cannot establish that its description is more trustworthy than a lower number.

Separate four parts of a claim: the subject, what is asserted, how certain the speaker appears, and the conditions under which the assertion was produced. Keeping the subject constant helps expose changes in the other parts. It does not imply that all four predicates have the same meaning or answer the same question.

Choose DANGEROUS and ask what evidence would make that judgement accountable. Dangerous to whom, under which circumstances, and according to what consequence? Then apply an equally precise question to CREATIVE. A favourable word also needs criteria; situatedness is not a licence to stop checking an appealing claim.

For the room’s next experiment, each panel could reveal a distinct criterion and the observation it used. A visitor could then compare disagreement caused by different evidence with disagreement caused by different definitions. The current four views supply the scaffold for that comparison.

A small spider moves among the readouts. It can notice and follow you; its controller can bite. The panels do not direct this creature, and their confidence numbers do not describe its behaviour. For now, keep the two encounters distinguishable: an assigned judgement on a screen, and a rule that acts on a body. What would we need to observe before calling either one dangerous?

<!-- @ -->

Collective knowledge asks how contributions from different positions can become a common object without losing the evidence and disagreement that make it revisable.
