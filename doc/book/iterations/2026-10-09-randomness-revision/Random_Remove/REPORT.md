# Random Remove — the set before the choice

**Third of fourteen Randomness halls revised and tested.** One primary tutorial object: the familiar cube grid, operated by the unchanged PointBody. The new subject is an eligible set that shrinks after each draw.

## What changes in the lesson

The old tutorial described pieces of the installed program. The new `tutorial.md` prints a complete small reconstruction and its PointBody dependency, names the museum placement, and explains the difference between a candidate-list offset and a cube's persistent address. Offset zero initially means address eighteen, not cube zero.

The procedure is small: filter → choose an offset → look up the address → hide its cube → remove the candidate. An empty list returns without drawing. Reset restores both the list and the generator. The display retains all sixty-four slot plates, so an absence still has an address.

The eight-by-eight board connects with Random Definition, and the changing list returns to Random Entropy's arrays. This is reuse of known construction, not an invented transfer of the previous hall's saved values. The new lesson deliberately omits the size slider: the count changes here because eligibility changes.

`final.md` keeps the existing board, replacement hoppers and walkable arena. Six code blocks have become prose, retaining the distinction between a chosen member, its disappearance and the withdrawal of physical support. The row/column comparison stays because the same number of candidates can describe different possible places. Its next room is now clearly 10 PRINT.

## Independent changes the student can make

| Eligibility rule | Candidates on an 8 × 8 board | What to verify |
|---|---:|---|
| Columns 2–5 and rows 2–5 | 16 | Only the central square empties |
| Even column + row | 32 | The checkerboard empties without repetition |
| Row 3 | 8 | The other seven rows remain |
| Column 3 | 8 | Same seed gives the transposed row order |
| Always false | 0 | No draw, no deletion, no crash |

All five are actual edits of the printed eligibility function, executed as separate scripts. Each also runs on a four-by-four board to test the same address logic at another size.

## Evidence

| Check | Result |
|---|---|
| Exact printed listing | 30 checks passed |
| Checkerboard, row, column and empty-set edits | 30 checks each passed |
| Incorrectly use list offset as cube address | Rejected |
| Leave the selected member in the candidate list | Rejected |
| Reset without reseeding the generator | Rejected |
| Actual museum plus temporary student reconstruction | 34 checks passed, including nine camera checks |

The tests check initialized objects, independently specified candidate addresses, colour/eligibility agreement, request bounds, no repetition, visibility, surviving slots, exhaustion, replay, point-action dispatch and separate instance state. They also compare the row and column orders after transposing their addresses. Empty calls preserve the generator state. Larger cells must remain above their plates.

At seed 42, both the student reconstruction and the installed remover produced this complete order:

`35, 44, 20, 18, 28, 29, 43, 21, 26, 37, 45, 34, 27, 19, 42, 36`.

This is a receipt from the tested Godot build, not a promise that an engine's random-number implementation will never change.

The native museum check also verifies the board's red warning, ignored busy presses, cancellation of a pending removal on reset, and full replay. The hoppers begin with the same chosen number but retain eight versus seven eligible members. The arena's first removal disables its selected collider; a downward ray confirms there is no remaining floor support at that cell. A close capture shows the opening over the fire. Replay restores all ninety-nine. These controls were supplied by the checker, not by a physical headset session.

## What the images changed

The installed console appears in front of the board after the museum applies its control layout. The reflection now agrees with that image rather than assuming the fixture's unmodified right-side placement. In the student board, column labels moved to the near edge so the cubes do not hide them. Cell height follows cell size so a smaller grid's larger cubes clear the slot plates.

The learner bay at hall-local `(13.2, 0, 8)`, Y rotation −90 degrees, has floor and an approach clear of other collision bodies. The native images show the complete printed program in that bay, plus its checkerboard edit. This reconstruction was temporary in the inspection scene. The production artifact scripts, map configuration and inherited PointBody were unchanged.

## How the two texts progress

Definition asks what a seed needs to reproduce a picture. Entropy asks what a count keeps and loses. Remove asks what can enter a choice at all, then makes each result change the following choice. That is a cumulative progression through the same kinds of objects and records. The tutorial implements it; the reflection follows what it means when an exclusion is decided before the apparently even draw.

The next hall gives every grid cell two possible diagonal marks. Keep the local generator and the distinction between the permitted choices and the draw. Change what the result does.

## Limits of this pass

This is an author-informed reconstruction with assertions and deliberate faults, not a blind reading by an unfamiliar student. Physical pickup, headset reach and a complete walk through the arena remain untested. The temporary display plinth is visual only, as the tutorial states.

The museum log reports an existing blocked authored-entry location and uses a safe spawn fallback. The unknown-UID and renderer warnings also remain. No script or parse errors occurred in these accepted tests. This pass does not certify every passage in the hall.

Local HTML was checked for links and exact printed-code parity. Browser layout was not inspected because local file URLs are blocked by the available browser tool. Native Godot images were inspected directly.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions before running](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Review ZIP](random-remove-review.zip)
