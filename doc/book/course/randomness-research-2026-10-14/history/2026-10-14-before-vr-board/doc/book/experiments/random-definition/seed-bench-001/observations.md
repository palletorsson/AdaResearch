# First run: a changed assignment and a repaired record

**14 October 2026. Scripted native cycle and rendered museum encounter completed; human encounter, independent reconstruction and physical VR remain untested.** The text simulation remains a prediction. These observations come from executed Godot 4.6 code, preserved reports and Codex image inspection.

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
