# A line to move with

Editorial pilot · 15 September 2026

> Follow-up: [Read Point One → Line → Trace → Grid](primitives-encounters.html). Point One has returned to the earlier text Palle preferred. [The reading review](primitives-reading-review.html) records our revised process: preserve the baseline and read local proposals before applying them. The original pilot below remains a historical draft.

The unit of revision is an encounter: something the visitor can do, something the program makes possible, and something the encounter leaves open. Text and artifact can each suggest the next experiment. We will calibrate this relationship in Point–Line, then use it while continuing the first traverse of the spine.

This is a proposed passage, separate from the current book chapter. It concentrates on two existing artifacts; the rest of the hall still matters. It is not a new restriction on how many artifacts a room can hold.

## The small brief

| Thread | Point–Line |
| --- | --- |
| Carry in | From Point One: a position needs a frame; a visible body needs further decisions; we begin while the program is already running. |
| Do here | Follow or walk beside the floor stripe. Pick up and turn the short rod. Compare a fixed span with a changing journey. |
| Technical foothold | Two endpoints describe a segment. Their difference supplies displacement; its length supplies distance. Neither stores the journey between them. |
| Opening | Straightness can guide, invite correction, or give movement something stable to play with. What else can we do with the relation we have learned? |
| Carry onward | Want to keep some of the movement itself. Trace introduces samples; Grid offers a shared reference and another choice about precision. |

## Proposed book passage

*This passage would develop “Read it with your feet” and “Carry the whole line.” It assumes the earlier encounter with two endpoints remains in the chapter. The code below is an illustrative calculation, not the floor marking's implementation.*

The point gave us somewhere to begin. Now there is something to follow.

On the floor, a white stripe: **WALK THIS LINE.**

Try moving along it. Let your pace be your own. You might look down to keep it under you, then look ahead and trust it for a while. Move alongside it. The stripe is still available. It can help you find a direction without having to become the whole of your journey.

I keep thinking of a dance pole: the rod stays straight; the body finds turns around it. Here the line lies on the floor. What movements does that change invite? Following, crossing, keeping company at a small distance. There is pleasure in having something steady to vary a relation with.

The words may also make you correct yourself. A little sideways movement can begin to feel like a mistake. This marking does not score your walk. Its script makes the stripe and the lettering; it does not check whether you obey. Yet you have read an instruction, and perhaps begun to arrange yourself around it. Stay with that perhaps. Another visitor may read an invitation where you read a demand.

Pick up the short rod. Carry it across your view. Turn it. Its two ends move together, keeping their distance. A direction you followed on the floor can now be a direction you hold in your hand.

We can give a segment two positions in one coordinate frame:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

From A to B: one metre along the positive x-axis. The subtraction keeps a direction as well as an amount. The length gives us the amount alone. These few lines let us hold a relation steady enough to compare it with another.

Now imagine travelling between those same ends by a wide curve. The subtraction still gives the same answer. Your hesitation, the curve, the time spent looking at something halfway: none of those events entered these variables.

There is usefulness in that small answer. We can measure without having to carry every journey into the measurement. There is also a reason to want more. I want to keep the turn your hand made, the movement that the two ends cannot tell apart from a direct passage.

The next room gives us a way to begin keeping it. We will save positions along the movement. Even then, we will have to choose how many.

Bring the detour.

## What the artifacts already support

- **walk_this_line_marking:** its script constructs a stripe and text. It supplies no obedience score or route tracking. A visitor's sense of correction is an invitation to notice, not a predicted response from every body.
- **grabbable_line:** one pickable body carries both endpoints at a fixed length. Its existing position-dependent jitter, sound and controller feedback deserve their own encounter later in the passage; they are not evidence of faulty tracking.
- **line and line_demo:** the existing endpoint and connection work supplies the geometry introduced before this excerpt. The barrier's authored response remains a valuable further complication.
- **Point Trace:** supplies the next operation—retaining selected positions. Its current text already opens with “Bring the detour.”

The dance pole is the narrator's association. The short virtual rod is not a weight-bearing pole. This pilot does not claim that ordinary Euclidean lines become curved in VR, or that every visitor experiences drift or disorientation. Source inspection grounds the described operations; embodied reception still needs human testing.

## How we iterate from here

1. **Read this one encounter together.** Mark the sentence where you become curious, where explanation arrives too soon, and what you want to try next. Those reactions are more useful than asking you to specify a complete voice in advance.
2. **Make one focused revision.** If the passage wants an action the artifact cannot offer, record that gap and choose whether the action or the passage should change. If the existing encounter already works, strengthen its visibility or description first.
3. **Check the first four halls as a passage.** Point → Line → Trace → Grid should accumulate both capabilities and desires. Preserve strong existing passages and relevant artifacts. Reconcile book anchors and primary roles when a complete revised chapter is accepted.
4. **Continue through the spine with the small brief.** Carry one unresolved question forward. Save larger additions for the next pass, unless a missing interaction prevents the current encounter from working.

These fields guide our editing; they need not become headings in every chapter. A poem, a surprising observation, or a technical problem can start the movement. A hall can linger where another moves quickly.

For each proposed addition, ask: **what does this let the reader do, notice, or ask that the current encounter does not?** Keep a short record of that answer. This makes an improvement reusable without making every room the same.

## Next actionable improvement

Calibrate this passage before commissioning another artifact. Then revise the complete Point–Line chapter around the strongest existing encounters, checking the handover from Point One and into Trace. The immediate uncertainty is the voice and pacing; the two artifacts already offer a workable experiment.

## Source record

Inspected for this pilot: `commons/maps/Point_Lines/final.md`, `commons/artifacts/walk_this_line_marking/walk_this_line_marking.gd`, and `commons/primitives/line/grabbable_line.gd`. Earlier discussion also examined Point One, Trace and Grid. This pilot changes no map, artifact, primary role or canonical `final.md`.

The separate Isosurfaces work remains in progress: ISO_Introduction implementation and its desktop checks are complete, but its illustrated review and publication are pending. This editorial pilot does not mark that work finished.
