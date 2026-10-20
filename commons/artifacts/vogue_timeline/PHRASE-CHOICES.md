# Teach the sphere two phrases

Continue at **Teach a sphere**, beside the dance in the Endless Museum's **ML_Perception** hall. The same object now distinguishes two short movements you name A and B. It can also withhold a decision.

After teaching both classes, [CHECK your intention](PHRASE-CHECK.md) adds a small evaluation board. Declare A, B or neither before a new take, then compare that intention with the answer. Changed model versions get separate counts, preserving earlier evidence. This is optional; the basic TEST and TRY below remain available.

## Play

1. Choose **PHRASE**, then **A**. This enters TEACH A. Record three complete four-second performances with CAPTURE. Prepare during the three-second count-in, then move both hands over eight beats at 120 BPM.
2. Choose **B**. Record three performances of a different short phrase. Reversing the order of A is one experiment; you can invent another. Keep timing and starting position repeatable.
3. Press **TRAIN**. Each label gets two timed mean paths, one per hand. Both classes need at least three coherent complete takes before classification can run. The board shows both take counts. A or B selects the teaching and preview set; REPLAY explicitly previews that set.
4. Choose **TEST → CAPTURE**. Perform either phrase again without selecting its label. Both models are compared. The result is A, B, UNKNOWN or AMBIGUOUS. TEST does not move the sphere or change either learned model.
5. Press **TRY**. After the count-in, perform another phrase. A recognised A or B makes the same sphere replay that learned path. UNKNOWN and AMBIGUOUS leave it waiting. The selected teaching label never tells inference the answer.
6. Teach A and B almost the same movement, then test a movement between them. Inspect the two distance scores. When both pass and the scores are too close, the station says AMBIGUOUS. This is different from neither fitting.
7. **UNDO** removes the last complete take of the selected label and requires training again. **SAVE / LOAD** keeps both sets locally. RESET requires two presses and clears A and B in memory together. ONE, pose and height examples remain. Saved files change only when you SAVE.
8. **ONE** returns to the earlier single-phrase activity. Switching POSE / HEIGHT / PHRASE keeps the datasets and cancels unfinished capture or replay. SOUND toggles the click; visual beats remain.

## One-paragraph lesson

Carry the same sphere, hand traces, timestamps and four-second capture. Teach two labelled sets of whole performances. Fit one timed prototype per label; compare a new complete take against both, regardless of the selected teaching label. Let a clear match replay its learned path. Contrast unfamiliar movement with overlap between categories. Change the demonstrations and inspect how the distinction changes. Keep testing separate from teaching.

## The actual model

`phrase_library.gd` composes two instances of the existing `movement_learner.gd`. Each fits 41 six-coordinate means and per-hand distance limits from complete demonstrations. No new neural-network architecture is introduced. Capture, coordinate frame, interpolation, timing, data validation and minimum motion remain as documented in [PHRASE.md](PHRASE.md).

For each label, recognition first applies the original two-hand gate: both RMS errors within fitted limits, neither peak beyond 2.5 times its limit, both hands moving enough. An invalid or incomplete take produces no result. With two trained classes and a valid complete take:

| Result | Decision |
| --- | --- |
| UNKNOWN | Neither prototype passes its two-hand gate. |
| A or B | Only that prototype passes; or both pass and it is clearly nearer. |
| AMBIGUOUS | Both pass, but their normalised scores differ by less than 0.20. |

Each score is the larger of the left and right RMS errors divided by that hand's fitted limit. A good left hand cannot cancel a poor right hand. Lower means closer relative to the particular model's tolerance; these numbers are **not probabilities or confidence estimates**. The 0.20 margin is a visible authored policy. Training determines the mean paths and bounded per-hand tolerances; it does not discover the meaning of the labels or choose that margin.

The mean paths remain fixed during testing. Recognition has no expected-label argument. For A or B, the existing response follows the selected prototype's two-hand midpoint and changes size with separation. The test fixture teaches B as a reversed A: this checks that temporal order matters, rather than merely recognising a set of positions.

## Records and tests

The two-label activity saves to `user://ada_two_hand_phrase_library_v1.json`. It contains both complete example sets, fitted parameters and the policy version. Restore validates both models against their examples before replacing either one, then starts a fresh evaluation record. The ONE activity still saves to `user://ada_two_hand_phrase_v1.json`. Pose and height saves remain separate. Visitor sessions start without demonstrations; fixtures are restricted to tools.

Run `python tools/test_phrase_library.py`. Native Godot assertions cover fresh A/B performances, changed labels, unknown movement, overlapping categories, order, both hands, incomplete takes, unchanged models during tests, numeric save/load, atomic rejection, buttons, capture completion, scoped reset and the same sphere. The single-phrase runner additionally exercises actual XR nodes using supplied tracker poses, tracking loss and timing interruption. Run the pose, height, single-phrase and dance runners for regression coverage.

Museum evidence: `python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag phrase_library --probe tools/probes/phrase_library_museum.gd`. Publish with `python tools/publish_phrase_library.py`.

Tests use fresh whole synthetic performances. They establish the tested behaviours, not human accuracy. A and B may overlap; head-relative tracking, fixed rhythm, the minimum movement and our thresholds all affect results. Headset use and varied human performances remain to be tried. This is a local short-phrase recogniser; it does not infer full-body choreography or evaluate dance quality.

## Reflection

The names arrive before the model understands a distinction. You decide what belongs to A and B, demonstrate those decisions and discover whether the recorded relations support them. If two labels describe almost the same measured movement, the sphere's hesitation exposes that overlap. A distinction meaningful to you may depend on something this model never recorded: intention, fingers, the rest of the body, or context. You can change the teaching, change the measurement, or allow the distinction to remain unresolved.

## Compact instruction

Same sphere. ONE retained. A/B: three whole takes each; fit two timed prototypes. TEST new takes against both. TRY replays clear match; UNKNOWN neither; AMBIGUOUS overlap. Compare both-hand distance, never confidence. Relabel/reteach to change categories. Separate local save. Real assertions + labelled museum fixtures; human play still needed.
