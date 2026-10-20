# First run: a changed assignment and a repaired record

**14 October 2026. Scripted native cycle and rendered museum encounter completed; human interface feedback is now recorded below; the full human comparison, independent reconstruction and physical VR remain untested.** The text simulation remains a prediction. These observations come from executed Godot 4.6 code, preserved reports and Codex image inspection.

[Evidence index](../../../course/randomness-research-2026-10-14/implementation/003/evidence.json) · [Report](../../../course/randomness-research-2026-10-14/implementation/003/REPORT.md) · [Text decisions](revision.md) · [Human trial](HUMAN_TRIAL.md)

## O1 — A visible change, with a known loss

The captured seed-42 record contains 48 values in 16 ordered triples. B changes the right grid's height rule while preserving every value, generator state, RGB colour, XZ location and cube dimension. The left grid stays a flat reference. Native assertions and the rendered museum probe agree. The invented red `(1,0,0)` and green `(0,1,0)` fixture cells both have centre height 0.20 m.

The mean omits channel order. This expected mathematical result gives us a concrete question: does that loss help a reader recognize the mapping, or does the extra geometry obscure what they wanted to follow? Neither a passing assertion nor a screenshot answers the human question.

## O2 — A preserved result needs more than a seed

The first run failed import after KEEP → EXPORT → CLEAR. JSON had converted integer fields to floating-point numbers, and strict nested-dictionary comparison rejected valid parameters. Validating exact numeric values across those two types repaired the boundary without accepting strings, booleans, new parameters or unknown versions.

A fresh-process check then caught a second failure: five decimal values shifted after parsing, by at most `1.1102230246251565e-16`. The picture could look the same while exact equality failed. Failed reports are retained. Their early source versions were not snapshotted; the final repaired source is recoverable.

The repaired format includes exact double bytes and readable decimal values that must agree within `1e-15`. Import restores the bytes. Seed and generator states remain signed decimal strings. Final fresh-process replay preserves the complete serialized record exactly without calling the generator. A separate same-build check regenerates seed 42; neither check acquires new unpredictable randomness or promises permanent generator compatibility.

## O3 — Reconstructed program, not yet a reconstructed understanding

The complete printed continuation yields all three source files. Its extracted program passes 46 checks, including construction of the arrays and their measured heights. The original program passes 46 checks; fresh-process replay passes three. Four deliberately faulty variants fail as intended: aliased KEEP, a value changed during switching, a wrong height formula and an importer that mutates state before validation.

The authoring agent performed mechanical reconstruction. An independent reader has not attempted it. The tutorial names the record adapter and inherited XRTools point as supplied support and asks the reader to record what they borrowed, understood or needed help with. Extraction cannot close that learning debt.

## O4 — Museum encounter and limits

The actual Random_Definition hall loads with its existing seed instrument. The pilot occupies the learner bay at hall-local `(10.5, 0, 18.5)`, Y `-90°`, unit scale, with trays one metre above the origin. A scripted point-trigger signal selects B. Dispatched Godot keyboard events keep, export, acquire another seed, clear and import successfully. All ten scoped museum checks pass, including floor at the approach.

Codex inspected A/B captures. The carried point initially covered labels; parking it to the left made them visible in the final image. This is an image-based layout repair, not a VR comfort result. The point remains large and controls below the trays need a person's reach/legibility assessment.

The short run has existing registry warnings, unavailable Compatibility-renderer effects and an authored-entry fallback warning. No script errors occurred in the successful probe. Sustained performance, whole-museum stability, headset usability and cross-hall transfer are not established. The installed route and live hall texts remain unchanged.

## Return to work

The tutorial receives a complete continuation and explicit preservation rules. The final's source passage is retained with reasons: “one more agreement” still opens the right question, and no human account warrants replacing it. Both reviews are linked independently.

The provisional next-work decision is **defer apparatus expansion**. First record a human encounter and independent reconstruction. A first-channel height mapping is a small candidate if that encounter motivates it. The sleeve and Source Lab do not automatically follow. The five-lesson particle path retains its order and separate dependencies.

An input audit also found that the museum already used F6/F7. The first UI probe had called the handler directly and missed that routing conflict. The pilot now consumes its function keys before the museum; the final run sends actual Godot input events. This changes the test method as well as the apparatus.

## O5 — The first human return concerns the interface

The user requested VR controls like the existing demo, rectangular buttons grouped closely on one board, and a close button. The exact reply is preserved in the evidence record and [VR_BOARD.md](VR_BOARD.md). This redirects work toward access before another mapping. It does not establish headset use or a preference for either height interpretation.

## O6 — Board revision and return test

The revised apparatus groups eight rectangular controls and a status display on one tilted board, using the shared demo's hand/pointer button mechanism. CLOSE hides and disables the controls while retaining the result; CONTROLS reopens it. All 18 museum checks pass, including physics overlap near a rectangular edge, withdrawal, XR pointer events, close/reopen and the complete saved-result cycle through the board. Native and printed reconstruction remain 46/46, fresh-process replay 3/3. Codex inspected the rendered board. Physical reach, headset legibility and comfort remain open.

The tutorial now prints the board implementation and declares borrowed XR components. The final remains unchanged because the human return describes interface needs, not yet the encounter with height. The next-work decision redirects the return trial toward board usability, then the mapping question and reconstruction.

## O7 — the visitor changes the geometry

The user requested a smaller cube/bar gutter, gentler amplification and bars growing from fixed bottoms. The follow-up explicitly excludes button gaps. See [ANCHORED_BARS.md](ANCHORED_BARS.md) and its verbatim receipt. This is an actual apparatus decision, not a claim of improved learning or headset comfort.

## O8 — anchored-bar implementation

The new recipe retains all 48 draws and RGB assignments, narrows the grid gutter to 1.5 cm, and uses bar lengths of 4–16 cm with fixed bottoms at 8 cm. Old floating-cube records retain their original geometry on import/replay. The native and printed probes check independent kept copies, exact replay, the invented fixture, fixed bottoms, dimensions and legacy migration; deliberate faults include a drifting bottom. See the current run receipts in experiment.json.

## O9/O10 — fill the display trays

The user adds: “we should fill the board”. The grid now occupies 90% of each tray width: 9 cm cell width/depth, 1.5 cm gutters, 2.25 cm outer margins. Height remains 4 cm for FLAT and 4–16 cm for BARS, with the same fixed bottom. Earlier floating and compact-bar results retain their original geometry on replay. Current scoped checks and source receipts are in experiment.json.

## O11/O12 — simultaneous spatial assignments

The user requests flat, bars and combo at once, and clarifies that random values should control object scale and rotation. The broader borders are also requested. Five panels now reuse the same sixteen triples. RGB is direct; height, scale and turn use their mean. Native/printed checks pass 66 each; fresh replay 3; museum 22; all five deliberate faults are detected. The rendered image shows all five assignments and the broader bronze frames. This is technical and Codex image evidence, not a learning result. See [SPATIAL_VIEWS.md](SPATIAL_VIEWS.md).
