# From a review lead to a playable change

2026-09-19 · CA_SoftRules · local Godot implementation

This pilot applies [The Instrument Was Blind First](http://localhost:3003/blog/2026-09-19-the-instrument-was-blind-first) and the author's [review principles](../../book/REVIEW_PRINCIPLES.md): investigate and improve the encounter before cutting strong prose.

## What changed

The book asks the visitor to compare two identical beginnings, STEP, watch W, advance further, and then change neighbourhood exchange. Source inspection and a rendered museum run confirmed that the wall titles and instrument readout already announced A / EXCHANGE ON and B / EXCHANGE OFF at tick zero.

The fields now begin as **A** and **B**. Numerical readings, the clock and all eight controls remain available. STEP, RUN, +100, VIEW, COAT and INJECT do not automatically reveal which field exchanges with neighbours. The first use of EXCHANGE B changes the setting and restores the matched beginnings as before; it also reveals the actual settings on both wall plates and the readout. Subsequent changes update those labels. REPLAY retains the explanation already revealed. A newly instantiated study begins with A/B again.

EXCHANGE B remains plainly named and usable immediately. Visitors can choose to inspect that relation early; the implementation does not impose a mandatory waiting period or a correct-answer gate. This changes the timing of the explanation, not the experiment's arithmetic. No artifact was removed, no role was demoted, and no manuscript passage was cut.

Production change: `commons/artifacts/rd_artifact/exchange_study.gd`.

## Play the comparison

Open **Cellular Automata → CA_SoftRules** in a newly loaded local museum hall.

1. Look at the matched beginnings. Find W on the instrument; predict whether its first change will be the same in A and B.
2. Press STEP. Compare the numerical readings with what can be seen on the table and wall. The small numerical difference may not yet be visually obvious.
3. Press +100. Allow the batch to finish and compare again. The plates still say A and B.
4. Press EXCHANGE B. Read the newly disclosed settings, then STEP or +100 from the matched beginning. Toggle back and repeat.
5. Explore VIEW U/V, COAT and INJECT: distinguish a changed image from a changed simulation. Try a different order, including changing exchange immediately.

For a human playtest, record whether the visitor could find and operate the controls, notice a difference before being told its cause, and use the change of exchange to test an idea. Hesitation and unexpected experiments are observations, not automatic failures. Neither correct numerical output nor completing the button sequence proves learning.

## Evidence

- [Before: room capture](before/arrival.png), [instrument](before/readout.png), and [runtime labels](before/report.json).
- [After: arrival](after/arrival.png), [after observation](after/observed.png), and [after changing exchange](after/revealed.png).
- [Runtime checks and action trace](after/checks.json): **31 checks passed**, including all eight controls through the project's real desktop interaction pointer with synthetic mouse input.
- [Run receipt](after/run.json): exit 0, no script/parse errors, relevant source hashes unchanged during the test.
- [Probe](play_probe.gd): loads the museum through the isolated files prepared by `tools/run_encounter_probe.py`. Museum movement logic is paused while the separate desktop interaction rig operates the instrument.

The checks include independently calculated first-step values at W, the exact +100 update count, full-field equality when both use exchange, divergence when B does not, display-only changes, injection, replay, and label timing. These establish the tested behavior; they do not establish headset readability, reach, comfort, learner understanding or Quest performance. No APK was rebuilt or deployed.

The captures use different resolutions and the interaction run includes an additional desktop rig. They document label states, not a controlled comparison of lighting or overall visual quality. Existing museum startup diagnostics and slow artifact-build warnings remain in the logs; this pilot does not resolve those performance issues.

## What can be generalized

Use a short loop: **review lead → check current source and prior placements → observe the running encounter → make one change → repeat the action → record remaining human questions**.

Classify visitor text before changing it: an instruction needed to operate a control, an observation or measurement, an explanation, or a claim that the implementation cannot support. Instructions and measurements may need to be visible immediately. An unsupported claim needs correction or development; merely delaying it does not make it true.

For other comparisons, keep the evidence available, let the visitor choose an intervention, and reveal an explanation at a meaningful point. Preserve useful secondary artifacts and returns. This is a candidate pattern to test hall by hall, not a bulk rule to hide every label.

The [post-change extraction](after/source-state.json) still contains EXCHANGE ON from `_readout`. This is expected: the explanation still exists. Static extraction alone cannot verify its on-screen timing. Record a finding as investigated, source-confirmed, runtime-tested, and later human-tested as appropriate. A clean model result is not a substitute for any missing stage.

The TypeSafe judge was not called in this pilot. The article's extractor coverage is not a measurement of judge accuracy, and model agreement with review labels would still need separate runtime and learner checks.
