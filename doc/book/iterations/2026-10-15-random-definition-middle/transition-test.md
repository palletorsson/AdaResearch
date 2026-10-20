# First transition test: does the frame study earn its place?

15 October 2026. Scope: book → frame study → source comparison, following Palle's request to test whether the middle revision improves the passage.

**Evidence status:** editorial comparison, inspection of existing artifact code, and Palle's response to the isolated book passage (recorded below). No full-text reading judgement, independent learner, live room or headset outcome has been observed. The current final, room order and wall seeds remain the baseline while Palle reads the whole text.

## Compared versions

**A — before the middle revision.** The book ends: “The historical table made a number available later. This page makes keeping it an event.” The trace starts: “Beside it, the frame study measures the application's intervals.” The source comparison then distinguishes calculation and physical measurement.

**B — current revision.** The book ends: “But stopping a digit does not tell us how it was obtained. Neither would saving the whole page.” The trace proposes judging randomness by irregular appearance, finds that insufficient, and leaves an account of origin missing. The comparison begins that account.

**B minus the frame study — removal test.** Read these unchanged sentences consecutively:

> But stopping a digit does not tell us how it was obtained. Neither would saving the whole page.
>
> The comparison exhibit begins that account by separating calculation from state and measurement of a physical source of uncertainty.

The argument still connects. Removing the trace loses a warning about appearance and one opportunity for visual attention, but does not remove a necessary distinction or an enacted discovery. This does not prove the stop is worthless: rhythm, pleasure or an actual encounter could justify it. Those effects have not yet been observed.

**B with comparison before frame — swap test.** The source distinction can precede the warning about appearance without contradiction. What changes is the proposed timing: the reader receives the distinction before encountering the temptation it might answer. B therefore has a plausible rhetorical preference, not a demonstrated dependency.

## Editorial findings

| Criterion | A → B result | What supports it / what remains unknown |
| --- | --- | --- |
| A carried question is explicit. | Stronger in B. | The end of the book and beginning of the comparison now refer to the same missing account. |
| The frame artifact contributes an irreplaceable operation. | Not yet established. | Removing it leaves the argument coherent. The prose names an impression but does not use the instrument's controls. |
| Attention develops without being prescribed. | Mixed. | “The appearance we were looking for” attributes an intention to the reader. The passage may be more directive than the response warrants. |
| The next definition is motivated. | More clearly proposed in B. | An account of origin is explicitly missing. Whether the reader wants that account remains a reading question. |
| Reader curiosity, rhythm and spatial experience improve. | Unassessed. | No reader response or live encounter has been recorded. |

**Verdict:** B improves the explicit logical connection. It does not yet establish that the frame stop earns its place. Keep the overall editorial estimate unchanged; do not equate a clearer bridge with a better encounter.

## Candidate C: let the existing instrument do the work

The implementation at `algorithms/randomness/seed_replay/frame_jitter_scope.gd` supports HOLD and RANGE. While held, `cycle_range()` changes the plotting range and redraws without changing `intervals` or `baseline_usec`. The plot divides deviations by that range and clips outside it. This supports a comparison of two views of the same retained timing data. It is not an entropy measurement and is not a recorded runtime test.

Proposed replacement for the frame paragraph, **not installed**:

> At the frame study, a held recording supplies another way to inspect what we have kept. Change the display range and the same timing differences stretch into peaks or settle close to the line. No interval has changed. The image can become more agitated while its source remains the same. If we judge chance by the shape alone, part of our judgement belongs to the scale of the drawing. We still need to ask how those intervals were obtained.

This makes a specific intervention available. It also anticipates the lamps' selective sensor and the Geiger study's clock. The distinctions must remain clear: the frame experiment changes the view of retained values; the lamp experiment changes sampled input; the Geiger experiment changes interval quantization and extracted bits. Do not flatten them into three copies of “measurement changes things.”

C costs more words and could become too instructional for the final. Test its actual rhythm against B; the tutorial can carry detailed button operation. Its merit would be that a spatial action now supports the argument and makes the frame stop harder to remove without losing a particular discovery.

## Reader prompt and next decision

Palle was shown the current two-paragraph book passage, then asked what he is attending to and what he wants to investigate or encounter next. This is not a blinded trial: he has already seen the larger sequence. Record his words rather than recasting them as confirmation.

- If his attention turns toward the reliability or appearance of the retained numbers, compare B and C next.
- If he wants to remain with holding, losing or retrieving a digit, inspect that direction before insisting on the source question.
- If the book passage itself feels uninteresting, revise that encounter before strengthening its bridge.
- If no difference between B and C matters to him, consider shortening the frame stop or making it optional in a future joint room/text revision.

No room order changes follow from this editorial test alone. The first editorial finding was the missing enacted comparison; Palle's subsequent response supplies a distinct direction to investigate.

## Palle's response

> What holds my attention is the difference between a number being produced, a number being recorded, and a number being selected. but I need to see the whole text, where is it

This is evidence of attention to three distinct acts in the isolated passage, not approval of the whole route or candidate C. The complete current `commons/maps/Random_Definition/final.md` was offered for reading. No prose or room revision was made in response to the request to see it.

**Next editorial hypothesis:** test whether production → recording → selection gives the middle a more compelling movement than the proposed appearance → origin bridge. Clarify what selection means in each apparatus: selecting one outcome, selecting which events enter a record, and selecting a stored value for use are different operations. Ask how the full passage develops Palle's distinction before adopting a new order. Candidate C remains uninstalled.

## Subsequent trial, 15 October

After reading the complete sequence, Palle identified keeping while something disappears as the chapter's continuity. He requested a clearer passage into the definition and slower, top-entry falling rows. A shortened version of C is now installed alongside a three-question distinction and the corrected RAND passage. This is a response to that full reading, not a retrospective claim that the earlier trial proved C. See [the preservation revision](../2026-10-15-preservation-and-row-fall/README.md) for changes, evidence and remaining checks.
