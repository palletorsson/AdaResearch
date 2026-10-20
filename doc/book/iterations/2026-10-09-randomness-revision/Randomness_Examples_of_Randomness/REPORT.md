# A draw estimates

**Randomness, hall 11 of 14.** The point returns as the learner's control. Two sampled coordinates become a retained position, a circle verdict and one step in an estimate's history.

## What changed

The earlier tutorial surveyed four works. It now reconstructs one operation in complete code: uniform sampling of a square to estimate the inscribed circle's area. Arrays, conditions, ratios, sphere markers and the inherited PointBody do familiar work. The new question is whether the sampling procedure supports the estimate being claimed.

The complete program builds its own board, graph and labels in the prepared Endless Museum. It starts with no samples and shows `--`, avoiding a ratio with a zero denominator. ONE adds a point, BATCH adds sixteen, REPLAY clears and rewinds. A finite 256-point budget keeps every sample visible. The graph retains each intermediate estimate; it does not replace the previous answer with a promise of progress.

## What the comparison reveals

At seed 42, 205 of 256 uniform samples fall inside: **3.203125**. With the same seed and only the horizontal range narrowed to a central strip, 255 fall inside: **3.984375**. These are observations from the executed examples, not universal outcomes. The latter program runs correctly, but its sampling area no longer supports the original factor-four estimate of π. That distinction connects the technical exercise to the reflection without making either text repeat the other.

Changing BATCH to 32 preserves the complete sample sequence. Changing the seed to 43 changes it. The student can predict and test those consequences before judging whether the final number looks convincing. In the original seed-42 run, 171 additions moved the estimate farther from π than the preceding one; individual improvement is not guaranteed.

## The installed hall

The learner board was reconstructed temporarily at hall-local (10.5, 0, 13), yaw 180°. Its origin and standing approach have floor support; the approach is clear for a body-sized collision capsule. The close native captures make the square, circle, counts and history readable. The high view shows the study beside the existing painting and dartboard, with the pipe and particle works farther along. This is a tested learner placement, not a newly registered museum exhibit.

Concurrent project work changed the installed dartboard while this lesson was being prepared. The first museum run caught a parse error in that new option; it was corrected by the concurrent work before this task's attempted fix. The next run revealed that the old THROW/AUTO/RESET controls had been replaced in this hall by a sampling-budget console. Those failed receipts are preserved. This task made no production-code or map edits.

The final text and probe follow the current console: THROW, +100, FILL, REPLAY, NEXT SEED and 8 SEEDS. Its dial selects budgets of 100, 500, 2000 or 8000; that dial range was checked in source. Runtime checks exercise the current 500-sample setting and actual button signals, including replay and comparison without changing the current run. The installed board keeps only its newest 300 marks while retaining the complete count. The printed study keeps all 256. Under shared seed 42, the source and learner tally agree for all 256 trials.

## The reflective track

The four encounters remain: painting, estimation, bounded pipe growth and five particle procedures. The revision updates the console directions, removes fragile left/right cues, and adds a short passage about a steady number that answers a different question. The historical naming anecdote is removed from this encounter; it was not needed to explain what the player can observe. The handoff remains Pheromone, where a visit changes the conditions of a later choice.

## Evidence and limits

- **21 checks for each of four complete printed programs passed:** original, batch 32, seed 43 and the deliberately biased strip.
- **Four faults rejected:** omitted seed rewind, integer division, a smaller counting circle, and world coordinates used for local action zones.
- **28 native museum checks passed**, including the installed sample/count relation, button signals, finite visual budget, private comparisons, learner placement and supplied PointBody actions.
- Six native captures accompany the report. Principal learner and hall images were visually inspected. The first failed runs remain separately labelled.

The harness is author-informed. It tests code, source edits and supplied interaction events; it is not an unfamiliar reader or a physical headset session. Existing UID, renderer and shutdown-resource warnings remain in the logs; the accepted run has no script or parse errors. The whole hall's visual quality and Quest performance are not established by these checks.

[Tutorial and reflection side by side](parallel.html) · [Before / after](changes.html) · [Review ZIP](random-examples-review.zip)
