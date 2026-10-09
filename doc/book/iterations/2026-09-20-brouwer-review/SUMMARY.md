# Brouwer: the next term waits

20 September 2026. A bounded encounter and manuscript pass on `Brouwer_Intuitionism`, following Escher. The room now has a visitor-chosen finite sequence to compare with a rule-driven construction. All eight existing artifact families remain; Cantor joins the choice sequence and witness specimen as the third primary.

## What the review helped us find

The review correctly identified an absent choice, but its account of the timer was inaccurate. The old script did not generate successive values: it displayed a fixed set of dots and animated their positions. The earlier manuscript made that absence into the room's central irony and argued against repairing it. Here the encounter itself earns the revision: let the visitor choose, then ask who supplied the available choices.

The earlier manuscript also treated “not yet constructed” as a third truth value, prohibited proof by contradiction generally, mistook preset geometry for an absence of construction, and described the Cantor display as producing complete real numbers. These needed correction, not an artifact built to confirm the errors. The revised text distinguishes a finite witness, the property established about it, the mathematical argument and the limits of the illustration.

## Decisions implemented

- **Choice sequence:** opt-in physical CHOOSE 0 / CHOOSE 1 / RESET controls, an actual ordered prefix and a visible unchosen next term. Waiting supplies nothing. The display retains the latest ten terms, storage stops at 256 without overwriting earlier terms, and the limit is labelled as an instrument limit. Earlier horizon variants remain available in placements without the new mode.
- **Cantor:** promote the existing workbench. Its finite N-bit construction is the positive example of supplying something that meets a stated property. Captions and registry now say finite strings. The monitor sits beside the console in this hall, exposing the red row from the standing approach. The algorithm and stable earlier bits are preserved.
- **Supporting comparisons:** retain the cube, reading slider, timed staircase, triangle, parallel lines and sum-over-hypotheses apparatus. The cube illustrates a witness rather than proving an arbitrary claim; the slider changes an explanation rather than deciding a proposition; the staircase is a timed finite model without player-supporting treads. A specified but costly procedure is distinct from a missing constructive proof.
- **Space:** keep the 13×16 map envelope and all eight artifact families. Ground the approach bays, clear the central aisle, and use `map_info.museum.artifact_placement = map`. The earlier setting let a four-object arrangement override the map. Disable this hall's optional entry gate and template piers: the gate crossed immediately behind the choice bench and blocked the tested passage. No global gate policy changed.
- **Registers:** revise `final.md`, five artifact descriptions/captions, primary order, core encounter hashes, book hero and wall speech, both trunk copies and both museum plan copies. The other seven Foundations manuscripts/maps and unrelated registry/plan entries are preserved by checks.

## Evidence and limits

- `model-checks.json`: 33 assertions passed, exercising physical button signals, pause, invalid choices, reset, bounded storage/display, legacy mode, rebuild preservation, the five Cantor sizes and their diagonal disagreements, stable earlier bits, and both logic captions. **The standalone model runner wrote this result but failed on shutdown: earlier runs timed out; a camera-equipped retry exited with Windows access violation 0xC0000005 after reporting all assertions passed. Do not report it as a clean process pass.** The latest runner logs are retained; the cause is unresolved.
- `Brouwer_Intuitionism-runtime.json`: the real museum probe exits **0**. All eight artifacts instantiate; five selected collision-body walks pass. Captured button presses produce the expected prefix, and the Cantor slider produces both photographed settings. The player-input/catch logic is paused in this probe, so this is not a continuous gameplay certification.
- `content-checks.json`: 58 integration and preservation checks pass. `current-inputs.json` records the before/current hashes; `before/` preserves the pre-edit source and manuscript. `final.diff` is the exact manuscript change.
- Five current Godot images are published on the existing comparison page. The paired images show two states of the revised apparatus, not two software versions. The test walker's costume is hidden for photographs only. The console and museum objects remain real rendered scene content.
- Headset comfort, tracked-hand operation, binocular reading, learner understanding and continuous routes remain unverified. No live museum restart, bake replacement or commit was performed. Existing unrelated map-size, stale pack-ledger, UID and certificate-store warnings remain outside this pass.

The mathematical scope was checked against Joan Moschovakis, [Intuitionistic Logic](https://plato.stanford.edu/entries/logic-intuitionistic/), sections 1–2, and Joan Rand Moschovakis, [Brouwer's Notion of Choice Sequence and Its Descendants](https://www.math.ucla.edu/~joan/Oslonewzoom2022handout.pdf). These are linked in the chapter footnotes. The physical binary bench is our teaching model, not a claim to implement unrestricted mathematical choice sequences.

## Remaining work

**Next: Florensky_Paraconsistent**, still missing an authored museum hall; then Crisis Synthesis. Keep the distinctions made here when treating contradiction in the next room. Do not turn philosophical imagery into a claim that the engine implements a formal logic it does not implement.

Brouwer's older `critical.md` and supporting historical prose still contain the earlier overstatements. They were not silently rewritten in this pass and should not be used as an authority over the revised chapter/captions. The legacy DNA variation notes also describe historical presentation choices, not a mathematical classification. The standalone model-runner shutdown failure deserves a focused harness/engine investigation before reusing it as a CI gate. These are named follow-ups, not reasons to reopen all the earlier halls.
