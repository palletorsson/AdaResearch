# Which part of a judgement tells you where it came from?

**Learning elements**

- Observation provenance
- Exposure time
- Camera transforms
- Retained views

The conflict room asked for sources. Here the source travels visibly with the verdict.

<!-- @situated_readout -->

Read all four panels. Keep SUBJECT #4729 fixed in your comparison and record each verdict, confidence and footer. Return to the first panel and identify which fields changed between panels.

Then keep one panel in view. COVER puts a strip over its address; FOOTNOTE restores the footer; WITNESS adds a symbolic eye and station frame. The verdict and percentage remain unchanged. What has become easier to question, and what evidence is still missing?

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


<!-- study-spine:museum_witnesses -->

## Return: The room arrives late

Change the delay from three seconds to one; retain the camera and compare the recorded times. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, trace, array, situation. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`witness`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Study and making notes](/book-review/doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html). The display stays fixed while its data, words or images change. RESET returns the original comparison.

<!-- study-edit:museum_witnesses -->

### One source change: The room arrives late

Change the initial delay from 3.0 to 1.0 and reload. D stays blank until enough frames exist. Compare A and D using their exposure times; then HOLD E and change VIEWPOINT. The first edit uses the clock and retained state. The supplied SubViewport cameras share the current museum World3D; the bounded image buffer is a close-reading extension, not a prerequisite for the edit.

```gdscript
var delay_seconds := 1.0
```

Source: `commons/artifacts/spine_studies/museum_witnesses.gd`. Use the prepared scene to run and compare.

<!-- study-reference:museum_witnesses -->

### Reference and scope

The ZKM presentation describes five episodes on separate monitors linked by steel tubing. Our five monitors carry museum cameras, not Gilligan’s films. The relation concerns distributed attention, mediation and dependence on a shared system.

[ZKM: Melanie Gilligan, The Common Sense](https://zkm.de/en/artwork/the-common-sense).

<!-- witness-portable-cameras -->

### Take a view

Cameras A and B are the pink grabbable bodies beside the original readouts; C stays fixed. On desktop, right-click to pick up, look to aim, and right-click again to release. The usual XR pickup grip moves and turns the same bodies. They stay in the released pose. RETURN CAMERAS restores the current starting views; release the cameras before using return, VIEWPOINT or RESET. Returning the cameras keeps an explicitly held screen image. RESET also clears the held image.

The camera follows the physical body's transform, with its lens 0.32 metres forward. The delayed and held records retain their exposure pose and source label as well as the image and time. Moving A does not rewrite those earlier frames. This reuses coordinates and transforms; constructing the camera housing and pickup system remains supplied.
