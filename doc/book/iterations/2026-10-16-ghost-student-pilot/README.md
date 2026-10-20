# A student made of light

Palle asks for holographic ghost students with two arms and VR hands, bringing the halls to life by operating artifacts and helping us inspect their texts through play. This first pilot is installed at the optional prefab bench in Random_Entropy, grid (13,3). Reload the hall or run `commons/artifacts/prefab_disorder/preview.tscn` and press WATCH. [Native recording and evidence](index.html).

The rehearsal begins with originals, moves the slider to separated parts and hybrids, changes the seed, keeps an intermediate form, returns to originals, changes the seed again and replays. Both hands are used: the left drags the slider; the right presses buttons. The head turns towards the controls and then the resulting objects. Pauses leave the consequences visible. A visitor watching from the front for six seconds starts one rehearsal; using a control suppresses further automatic demonstrations. WATCH toggles a manual rehearsal.

## How this brings playtesting closer

The useful unit is **a text claim, an attempted action, an observable consequence, and an unresolved question**. The tutorial's preservation contract becomes a sequence of control events. The final's question about differences made available becomes a reason to compare the arrangements; it is not mechanically marked true. Every step records its source excerpt/hash, starting state, actual result and assertion. A disconnected control must fail. A missing excerpt prevents an outdated script running. No model reads prose autonomously at runtime: the assistant reads it, writes an explicit adapter, then inspects the actual run and its images.

The receipt is `user://ghost-students/prefab/<session>/rehearsal.json`. Its own save pointer/gallery index are in that folder. The kept arrangement uses the existing timestamped prefab save format. The human pointer, gallery store, page and selection are restored after every synchronous event; they never become the ghost's permanent save destination. Normal completion or WATCH-stop restores the visitor's starting state. Taking over retains the current arrangement and applies the visitor's input. Closing a scene records interruption and releases synthetic presses.

The replay check compares all rendered transforms at Godot's float32 precision, plus stored targets, memberships, raw integer draws, seed and stage. An early hash compared float64 JSON spellings and falsely rejected matching geometry; conversion to actual engine transform precision fixed that test. Source edits during development also triggered the stale-text guard, as intended; the anchor now follows the current record contract without reversing the new gallery instructions.

Looking at the rehearsal also exposed a stale readout: after pressing ORIGINAL, moving the slider still left “Original assembly and grid restored” beneath the new arrangement. Slider input now supplies its own guidance. Coordinate roundoff at the midpoint could label 0.50 as SEPARATING; a tolerance of 0.00001 snaps the three landmarks exactly. A close-up exposed incorrect arm scaling; scaling along the bone's local axis fixes it, and a joint-endpoint check now verifies the rendered segments. These are concrete apparatus revisions produced by inspecting the rehearsal, not claims about a learner.

## What is and is not being tested

The visible hands dispatch `XRToolsPointerEvent` through the controls' public pointer interface. This exercises actual slider/button handlers and observes the resulting geometry; it does not perform a headset tracking, collision-hand, haptic or reachability trial. The actor is non-colliding and has no player groups. Human pointer input and native slider grabs take ownership. A shared scalar-pointer hook announces an input request so the ghost releases an already-held slider before a visitor takes it.

The actor is scripted, with procedural arms and fingered controller-sized hands. There is no learned policy, curiosity, natural-language comprehension or user-study result. The current adapter is for this bench only. Its explicit route exposes assumptions—two hands, a reachable console, an authored sequence, a stored comparison—and makes those assumptions editable. It deliberately leaves the choice of what is interesting to the visitor.

Three variants worth comparing next: a demonstrator that completes the loop; a companion that stops before KEEP and waits for the visitor; and a skeptical tester that changes one condition to challenge a claim. The first is built. The latter two are proposals, not shipped modes. The missing research evidence is whether the demonstration invites action or closes possibilities too early.

## Small research loop

1. Select one claim from tutorial or final; name the consequence that could contradict it.
2. Run the same baseline, control actions and pauses; retain state and source version.
3. Inspect what changed, including a failed/no-op action and what the rendering hides.
4. Have a person interrupt or continue it. Record their own account, assistance and null responses.
5. Revise one artifact behavior, staging choice or passage; replay both versions. Keep the reason.

The existing VR-link walker already offers hall scan/look/interact operations; its documentation is `doc/VR_AGENT.md`. Combining travel with this local articulated actor is future work. Start with adapters for the 48-value bench and abacus, then the Shannon/Boltzmann instrument. The 48-value bench remains the first research pilot; the canonical six-stop Entropy final/order are unchanged.

## Re-run and inspect

`python doc/book/iterations/2026-10-16-ghost-student-pilot/run.py` runs the native control, isolation, interruption and negative tests. `museum_probe.gd`, launched through `tools/run_encounter_probe.py`, loads the actual Entropy hall and checks approaches and the same nine-action loop. `film.py` captures the native rehearsal and encodes it as MP4. `publish.py` assembles the review and hashes the relevant current sources. These scripts use local Godot; they do not launch or control a person's headset.

Files: `commons/ghost_students/hologram.gd` (reusable body); `commons/artifacts/prefab_disorder/ghost_student.gd` (adapter, itinerary, handover and receipts); the host/preview integrate WATCH; `commons/interactables/scalar_pointer.gd` adds the input-request signal. A whole-hall population, autonomous exploration, teaching efficacy and headset performance remain untested.
