# A fresh ghost student takes Motion

The revised lesson is reconstructable by a fresh AI reader. Its unchanged first submission passes **64/64 native checks**: 43 on code and behaviour, 21 in the actual museum. The reader copied the complete reference, made the requested mass edit, authored the two-clock comparison and chose a further 3 kg / 3 second experiment. Predictions were recorded before execution.

This was a new agent with no conversation history. It received only the revised lesson, its reflective companion and the copied prerequisite readings/helpers. It did not receive the previous student's answer, production force code or teacher checks. The AI brought existing programming and algebra knowledge, which it names in its review. This is one reconstruction test, not a human comprehension or physical-headset test.

## What it could do

| Task | Prediction | Executed result |
| --- | --- | --- |
| Reconstruct the three points | 1 / 0.5 / 0.25 m/s after the pulse | Matches on Jolt; complete printed code reproduced. |
| Change the third mass to 8 kg | 0.125 m/s | 0.125000 m/s. |
| Give 1 kg a one-second push and 2 kg a two-second push | Both finish at 1 m/s, with distances near 1.5 / 1 m | Both reach 1 m/s; retained display reads 1.508 / 1.008 m at the 60 Hz boundary. |
| Choose another mass and duration | 3 kg, 1 N, 3 seconds gives 1 m/s | 1.000002 m/s. |
| Press again halfway through the original pulse | Force lasts 1.5 seconds in total; velocity is retained | 1.499999 m/s for the 1 kg point. |
| Turn the study / hold the point | Force follows the study frame; held time is lost | Both verified; pickup uses real XRTools with supplied input. |

The held-point check supplies zero release velocity explicitly. It does not establish the result of an arbitrary hand throw. Distances above are the retained end readings; the independently observed positions and later screenshot occur after further coasting.

## What the reader still had to supply

**One measurement detail:** the mass-edit exercise predicts 0.125 m/s, but the printed two-decimal caption cannot show that value exactly. A useful small edit would be: “In this variation, use `%.3f` in the speed caption so you can read 0.125 m/s.”

**One origin decision:** “Keep each starting position before the run” could mean at scene creation or before every press. The reader chose scene creation and correctly retained the existing journey on another press. A useful clarification would be: “Store starting positions once in `_ready()`. Another press adds motion; restarting the study gives a fresh comparison.”

**One reasoning step:** combining two clock conditions with a once-only snapshot required a small event guard. Earlier lessons contain booleans and conditions, but the reader used prior programming knowledge to combine them. The independent exercise is demanding enough to require that transfer; a short hint or a human trial would tell us whether the step is well placed.

These are findings, not edits installed in the chapter. The canonical tutorial, reflection and authored lesson data are unchanged in this fresh test.

## Reading both texts

The student could explain why the force ends while velocity continues, then connect that result to the reflection's account of present state and incomplete history. It also identified the limit: its small code has no trail, so it cannot demonstrate the museum's trail truncation. That distinction keeps the tutorial's construction and the reflection's wider encounter from making unsupported claims for one another.

## A correction to the checker

The first run passed 42 of 43 checks. The failing check required the entire caption to remain unchanged during coasting. The student's valid solution shows live distance and speed alongside a retained end-distance pair. The checker was corrected to inspect the retained line. No student code changed. The first checker, log and result remain archived; the final run passes 43 of 43. The separate museum run passes 21 of 21.

## Read the evidence

- [Student's predictions, written before execution](attempt/predictions.md)
- [Student's first-person reading and construction account](attempt/review.md)
- [Student's interpretation after receiving measurements](attempt/after-run.md)
- [Reading packet](packet/README.md)
- [Independent comparison code](attempt/comparison.gd) and [new mass/duration code](attempt/transfer.gd)
- [Native code checks](native-checks.json) and [actual museum checks](museum/report.json)
- [First checker result](first-checker-native-checks.json)
- [Source and submission record](verification.json)
- [Current tutorial and reflection](../2026-10-08-motion-build-and-investigate/parallel.html)
