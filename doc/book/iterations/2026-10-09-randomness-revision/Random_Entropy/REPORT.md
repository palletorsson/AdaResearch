# Random Entropy — keep the counts, change the neighbours

**Second of fourteen Randomness halls revised and tested.** The tutorial now builds one small comparison from the familiar cube and held point. The reflection keeps the larger encounter with the ledger, jar, displaced points, ruin and black-and-white room.

## What the student learns

The last hall changed the assignment of random values. This hall retains a record and asks what counting it keeps. Sixteen integer symbol IDs select four colours. Two rows show the original and a copy. Sorting the copy changes the neighbours while retaining the counts, the original and the generator state. Four bars show shares on a fixed scale.

The student meets counting and copying before the entropy calculation. A deliberately regular cycle supplies the decisive test: **0123 repeated has H = 2 bits per symbol**, the maximum marginal entropy for four categories, even though its next entry is easy to predict. Sorting that cycle reduces unlike adjacent pairs from fifteen to three without changing H. The label's “neighbours” number counts unlike pairs, not all pairs.

The categorical sample is new. It is not an unexplained conversion of the previous RGB record or an invented save/load handoff. Cube construction, local RNG and the unchanged PointBody return; the new operation is explicit.

## What changed in the texts

`tutorial.md` now contains the complete 132-line study and unchanged 26-line PointBody, followed by focused explanations and two actual code edits. It distinguishes the original from its copy, category IDs from colour values, empirical counts from source probabilities, and marginal entropy from predictability or thermodynamic entropy. The complete code builds every display object and label inside the prepared museum.

`final.md` keeps its existing scenes and questions. Five code blocks became short prose, so the reader can follow what the gauge leaves out without switching into implementation. Its handoff remains concrete: the ruin already chooses among eligible exposed stones; Random Remove makes that eligible set the next subject. The historic ruin image is retained and identified as existing documentation, not a new capture from this test.

## Native evidence

| Reconstruction | Result |
|---|---|
| Printed program extracted into fresh files | 31 checks passed |
| Actual cycle edit in the printed append line | 31 checks passed |
| Actual single-symbol edit | 31 checks passed |
| Aliasing the original instead of copying | Rejected; original order is lost |
| Dividing by the alphabet size instead of the sample total | Rejected; known entropy values fail |
| Spending a random request while sorting | Rejected; generator state changes |
| Current museum with a temporary learner reconstruction | 26 checks passed, including camera checks |

The code checks cover initialized labels, distinct materials, exact draw requests, replay, copying, zero-count handling and the known values 0, 1.75 and 2 bits. A second instance with twelve entries and three categories checks transfer to another alphabet: H = log₂(3), with eleven versus two unlike pairs. Both instances keep independent records and generators.

The real museum check compares the student's counts and entropy with the installed ledger's calculation. It also verifies the installed SORT and CONTRAST operations, floor and a clear approach at the learner bay, and the inherited point's action dispatch at prescribed positions. The installed contrast has counts `[109, 46, 20, 17, 6, 2, 0, 0, 0, 0]` and H ≈ 1.818, supporting the reflection's specific description.

## What failed and changed

The first proposed placement treated the full map width as the entrance chamber's width. The study and its approach had no floor. The museum's first chamber is narrower. The corrected bay is hall-local `(14.8, 0, 8.0)`, Y rotation −90 degrees, facing into that chamber. Both floor checks now pass; the actual wall appears behind the reconstruction.

The first museum checker also assumed that a manually placed, unheld rigid body would retain its pose across capture frames. The point had returned to its initial x position, so the later action replayed the seed instead of sorting the cycle. The corrected checker explicitly places it before each supplied action. This repairs the test setup; it does not demonstrate physical headset pickup. The failed receipt, probe and images are preserved.

No production museum artifact, map placement or inherited PointBody was changed. The reconstruction was added only to the isolated test scene. Its placement instruction is now in the tutorial so a learner can create it there.

## How the pair reads

The progression holds when the operation leads: draw → retain → copy → count → compare. The entropy formula arrives as a tool for a question the student has already seen. The critical text can then ask how much authority we grant a measurement that ignores relations. It does not need to turn every artifact into another compulsory coding exercise.

The room is still visually busy. The installed ledger's control console partly hides its front account from the straight-on camera. The learner comparison is larger and legible in the captured wall bay, although headset reach and comfort are untested. This pass makes the text and reconstruction precise; it does not claim the hall's entire layout is resolved.

## Scope and next hall

These are author-informed reconstructions, not a blind student trial or proof of understanding. Physical XR grab, travel through every passage and an unfamiliar reader's experience remain open. Godot's log retains an existing unknown-UID error and compatibility-renderer warnings; there were no script or parse errors in the accepted lesson/museum runs.

The browser's URL policy blocked opening the local HTML for layout inspection. The pages and their links were checked as files, and native museum images were inspected. Browser layout remains unverified; open the saved facing pages for review.

**Next: Random Remove.** Keep a list of eligible addresses, select from that list, remove one member, and preserve its original address. Test the empty list before making another draw. Twelve halls remain planned rather than validated.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum results](museum/report.json) · [Rejected museum attempt](first-museum-attempt/report.json) · [Review ZIP](random-entropy-review.zip)
