# Compare what remains uncertain

The room now presents versions together. There are no buttons, sliders or save controls. Walk between the objects; the wall explanation identifies the conditions and readings. The seven encounters remain in the same order as the final text, directly after Random Definition.

## The observation and reconstruction loop

1. Choose two labelled versions. State what is held fixed and what differs before interpreting a number.
2. Predict a changed reading or a useful unchanged reading. Compare the objects, then consult the wall.
3. Record the versions, the prediction and what the comparison actually made visible. An unclear or unhelpful difference is evidence too.
4. Reconstruct the small calculation below or its counterpart in `model.gd`. Alter one condition in that reconstruction, keeping the installed comparison as the baseline.
5. Return to the original parameters and reproduce the reading. Propose another visible version if it would make a better question.

This hall offers prepared comparisons, rather than a visitor-operated experiment console. It cannot establish that a visitor can independently design or rebuild the apparatus; that remains a separate tutorial trial. The **48-value seed bench remains the first research pilot**, including its fuller save/replay loop.

## Start with the chair colours

Four groups contain eight ordinary-sized chairs each. A and B both have four pink and four black chairs in different sites. C has seven pink and one black; D has eight pink. Imagine an equal-chance draw of one chair, returning it, and recording its colour. Nothing is actually sampled or removed by this display.

Build this small calculation first:

```gdscript
func colour_entropy(pink: int, black: int) -> float:
    var total := float(pink + black)
    if total <= 0.0:
        return 0.0
    var h := 0.0
    for count in [pink, black]:
        if count > 0:
            var p := float(count) / total
            h -= p * log(p) / log(2.0)
    return h
```

Call it with `(4, 4)`, `(7, 1)` and `(8, 0)`. Expect 1, approximately 0.544 and 0 bits. Draw eight coloured objects from those counts. Change their positions without changing the counts: the image changes while this reading does not. Then change the recorded outcome from colour to one of eight equally likely IDs; its entropy is 3 bits regardless of the colour assignment.

## The seven comparisons

| Encounter | Versions visible together | Reconstruction and limit |
| --- | --- | --- |
| Shannon | A: four of each; B: same counts rearranged; C: seven to one; D: one colour | Colour entropy is 1, 1, 0.544 and 0 bits. The measurement concerns a declared draw, not visible disorder. |
| Boltzmann | A: all four pink on the left; B and C: different arrangements with two pink on each side | Enumerate assignments to eight fixed sites, keeping four pink/four black and treating same-colour chairs as interchangeable. Ω(k) = choose(4,k) × choose(4,4−k). A permits 1 assignment; B and C each permit 36. The wall gives S/kB = ln Ω; this is a counting analogy, not furniture's thermal entropy. Colour-draw H remains 1 bit. |
| Algorithmic complexity | Grid, one edit, repeated motif, seeded scatter; all recipes stay on the wall | Rebuild six-chair groups with `Model.chairs(435, group)`. A short generator can make an irregular image. Count the seed and shared generator as part of the description. These are candidate programs; no exact Kolmogorov complexity is claimed. |
| Dynamical entropy | Two door pairs: closing and expanding. A third door keeps the passage open. | Each pair starts at 0.8 and 0.8 + 1/512. Compare x/2 with (2x) mod 1 over steps 0–8, repeated automatically. Enumerate LOW/HIGH words over 1,024 equal starting bins. Eight-symbol entropy is 1 bit versus 8 bits. This finite observation is not itself an asymptotic entropy-rate measurement. |
| Thermodynamic entropy | Three cups show 0, 15 and 60 seconds of one model | C₁=400 and C₂=4000 J/K; starting temperatures 353 and 293 K; decay timescale 15 s. Energy remains C₁T₁+C₂T₂. Each ΔS=C ln(T/T₀); cup ΔS is negative, bath ΔS positive, total increases. These are simultaneous snapshots. The shader illustrates warmth, not evaporation. |
| Conditional entropy | The same chair behind clear, frosted and opaque screens | Eight equal identities: two colours × four arm/back variants. The record preserves identity, colour, or no distinction. H(X|Y)=0, 2, 3 bits. The number describes this record channel, not a measured human capacity to see through a shader. |
| Min-entropy | Three identical pits: equal-ID draw, colour record, weighted-ID draw | Sixteen balls, with replacement. H-min=−log₂ p(max): 4, about 0.093, and 1 bit. In the third rule the large ID has weight 15 and each other ID weight 1. Size alone changes no probability. These are declared sampling rules; the display does not perform draws. |

## Reconstruct a version, not an interface

Seven scene wrappers use `comparison.gd`. It places copies of `encounter.gd` with `controls_enabled=false`; `model.gd` contains the calculations and `objects.gd` builds full-scale furniture. `wall_text.gd` places each 1.60 × 0.98 m explanation in a frame on its own floor-to-top support. Small letters or numbers on the floor connect versions with the text. The seven groups retain their independent editor placements.

For a separate code reconstruction, instantiate `encounter.gd`, set `kind` and `controls_enabled=false` before adding it, then set the relevant `setting`, `experiment_seed`, `seconds` or `steps` and call `rebuild()`. A version's `capture()` and `restore(record)` retain the earlier research record format. Save the returned dictionary and source revision in the research record if needed; these methods are not exposed in the hall. Returning to a prior cooling snapshot is a digital reconstruction, not physical reversal.

## Leave a question on the research wall

Just beyond the paired chairs, the shared research wall stands as an independent partition, with a passage on each side. Its framed text, provisional overhead room image, whiteboard and three sticky notes occupy separate sections. This is a support for the seven encounters, not an eighth entropy measure.

Pick up the dark or red marker and touch its nib to the whiteboard. The same marker writes on the sticky notes. Lift the nib to break a stroke; touch with the eraser to remove ink locally. Grab a note, move it, and release near the wall to pin it. A release away from the wall returns the note to its previous position. Released tools that fall or become lost return to the shelf.

Writing and pinned positions save locally after a short pause, and return when this wall loads again. There is no save button. Start with a small claim, such as “same colours, different pattern,” and draw the comparison that led to it. A sticky note can keep the question that remains. This records observations, not an automatic proof of learning.

The shared wall is separately movable in the editor. It has gallery, workshop and night appearances; the drawing, notes and illustration sections can be enabled individually in the scene. The image slot is ready for the illustration work proceeding separately. Changing its image or appearance preserves the notes.

Current wall checks and native views: [research wall trial](../../../doc/book/iterations/2026-10-16-research-info-wall/index.html). The preceding [visible states trial](../../../doc/book/iterations/2026-10-16-entropy-visible-states/index.html) records the unchanged finite models. Headset reach, writing comfort, legibility and independent rebuilding remain human trials.
