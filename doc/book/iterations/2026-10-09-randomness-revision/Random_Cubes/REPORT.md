# Random Cubes — a six permits another draw

**Fifth of fourteen Randomness halls revised.** One primary tutorial object: a column whose growth is governed by the continuing-die rule. The inherited PointBody operates the small reconstruction.

## What changes

The old tutorial focused on bevelled cube edges. It referenced missing construction functions and a prepared scene, and claimed every generated profile would be unique. That was neither a complete runnable example nor the strongest lesson offered by the hall.

The replacement keeps the cube as a unit of height. One draw returns an integer from one through six; the value enters an ordered history and a running total. Six permits another event. A different face closes the chain. A display cap can leave the rule unfinished. The whole program and its unchanged point-class dependency are printed in `tutorial.md`.

The lesson states its boundary: this is a **coded draw**. The installed die reads a physical orientation after release and settlement. The generator can reproduce a number sequence; it cannot replay the visitor's hand. In both cases the result can enter the same continuation rule.

## What the student brings

10 PRINT supplied a local generator, a record and a rule for interpreting each draw. The new example expands two choices to six and makes one outcome decide whether another event is allowed. Trace and Arrays supply the list and loop; the cube returns as a visible unit. The sphere retains its existing pickup and action behaviour.

The new work is therefore small: an event adds a contribution, then changes permission. The student's edits alter that decision or the display budget. They do not need to build dice physics, a histogram, paired throws and edge-profile geometry in the same lesson.

## What the two texts do

The reflection was already strong. It keeps the physical die, rewards, paired columns, continuing chain, coins, disappearing heap and profiled slabs. Its opening now connects with the previous two-mark field. The two-line code fragment becomes prose. A short passage distinguishes the tutorial's reproducible stream from the hand's throw.

The tutorial makes the continuation rule reconstructible. The reflection asks where the permission to keep growing resides, what a record retains, and how conditions of a throw disappear from a tally. The wider museum remains available without every artifact becoming compulsory code.

## Student changes and predictions

| Case | Record | Total | Ending |
|---|---|---:|---|
| Six-only rule, supplied 6, 6, 3 | 6, 6, 3 |15|Closed|
| Five-place budget, five sixes |6, 6, 6, 6, 6|30|Unfinished at limit|
| Last allowed result is not six |Earlier sixes, then 3|Depends on budget|Closed, not limited|
| Three-place edit, three sixes |6, 6, 6|18|Unfinished at limit|
| Default seed 42, six-only rule |6, 5|11|Closed|
| Same seed 42, five-or-six rule |6, 5, 3|14|Closed after one more event|

The first four rows test defined rule cases. The last two are actual generated runs in the tested Godot 4.6 build. A seed is not a permanent cross-version guarantee. The inclusive bounds of `randi_range(1, 6)` are part of the declared operation. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

## Test evidence

The exact printed program and two source edits—five-or-six continuation and a three-place cap—each passed **32 checks**. All four faulty variants were rejected: sampling zero through five, overwriting the total, treating the cap as closure, and drawing again after the chain had ended.

Checks cover initialization, independent bounded draws, retained order and sum, replay, invalid values, no draws after closure or limit, all six predicate cases, direct supplied inputs, visual section boundaries, accumulated height, redraw without mutation, smaller displays and separate instances. They compare generator state, not just the visible result. No test requires a short run to look evenly distributed.

The native museum run passed **32 checks**, including six capture-camera checks. A real low drop onto the installed tray produced one six and kept the chain open; waiting did not count it again. Explicit event inputs exercised repeated-result rejection, six-six-three closure, return versus reset, five-sixes limitation and closure on the final place. These supplied events are identified as tests, not represented as hand-thrown outcomes. The paired-dice comparison retained both contributions and waited for its second result.

The extracted learner program then ran in a temporary bay beside the existing exhibit. Floor and a body-sized approach were checked. The inherited point action drew, closed and replayed a chain. The three-place code edit showed an unfinished eighteen-unit column.

The images use seed 364 for six-six-three and seed 119 for three sixes. Both seeds were deliberately located for those demonstrations, then replayed through the real generator. They show possible cases, not typical runs. Each image labels its seed and CODED DRAW.

## What remains open

This was an author-informed reconstruction, not a blind student reading or physical-headset test. A scripted low drop exercises settlement but does not establish fairness of hand throws. Full walking-route and headset reach remain untested.

The temporary study was removed after capture. The map, installed artifact code and inherited point class match their saved pre-edit hashes. The accepted runs contain no script or parse errors; the existing unknown-UID warning remains. A type-inference error in the new test harness was corrected before these accepted runs.

Native images were inspected directly. Printed code parity, local links and the review ZIP were checked. Browser layout was not inspected because the available browser blocks local file URLs.

Next is Random Rotate: keep the cube, distinguish assigning an orientation from accumulating a turn, and make the history of those changes inspectable.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Review ZIP](random-cubes-review.zip)
