# Array feedback — three clarifications

6 October 2026. The supplied review recommends keeping both texts and making three small clarifications. I agree: these strengthen the existing lesson without adding another subject or exercise.

| Feedback | Decision in the tutorial |
| --- | --- |
| Indices do not come with spatial axes. | Explain once that our placement and reading code assign X and Z to the indices. This prepares the later change in storage order. |
| Fresh inner arrays deserve a concrete comparison with shared references. | Show in prose what would happen if X entries 0 and 1 reached the same inner array: writing `[0][2]` would also change the value read at `[1][2]`. Connect it to two references to one cube. |
| Persistent tutorial labels differ from the museum encounter. | State the intentional difference: all tutorial labels stay; the museum row loses its cube label; the square grid retains its floor plate. The addresses remain in both museum records. |

The unchanged reflection already asks what an empty place means and makes the label difference felt. It does not need another technical recap. The shared-reference example replaces a general explanation rather than adding an exercise or extra code listing.

**The lesson's governing relation remains:** Transformation lets us change a body; Arrays lets us choose which body or stored value to change. The tutorial keeps the address usable; the reflection asks what the record does not tell us about that place.

## Evidence and scope

Only three tutorial passages changed. `lesson.gd` and the complete printed code are byte-identical to the native-tested version. The 150-check result, three explicit exercise variants and six rejected faults remain the prior native run. No new Godot run was needed for the prose edit; `feedback-prose-verification.json` checks code equivalence and records the current manuscript hash while the original native verification remains unchanged.

The previous draft and verification are in `before-feedback/`; the supplied review is in `external-feedback.txt`; the exact prose diff is in `feedback-tutorial.diff`. `final.md`, canonical map manuscripts, museum code and plan acceptance are unchanged. This remains a review draft.
