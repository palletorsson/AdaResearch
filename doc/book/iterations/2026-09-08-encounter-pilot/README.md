# The first encounter pilot

The complete first manuscript now has a small implementation loop to build on. This pass follows Array, Tutorial_Single and Tutorial_Disco, then restores Random_Remove as a second application of historical recovery. The room cores stay small, supporting artifacts remain, and no learner baseline has been accepted.

[Start with the Array comparison](http://localhost:3003/museum-progress?sequence=array_tutorial&room=Array&action=array-addresses-persist). Museum Progress carries four concrete actions, their observations, acceptance conditions, critical questions and reuse candidates.

## What a visitor can investigate

| Room | Paired change | Next learner observation |
| --- | --- | --- |
| Array | The grid keeps address plates after collection; the row keeps its contrasting disappearing labels. Primary row/grid footprints now have level floor. The rectangular table dimensions were corrected. | Can the visitor locate an empty slot, distinguish its address from its value, and say what a zero fails to record? |
| Single | The pickup recognizes the actual desktop museum walker while retaining VR detection. Its obstructing gate is disabled and metadata describes contact. | Can the visitor distinguish idle motion, the collection event and the resulting absence? |
| Disco | The highlighted step agrees with the sounding step; each floor follows its own hall's sequencer. Prose now tests an inactive cell and exposes the 16-step/12-column fold. | Can the visitor predict a note, silence its address, and explain why the floor cannot identify every sequencer step? |
| Random Remove | Git's lost candidate-grid relationship becomes an owned 8-by-8 bench with visible eligibility, one-step removal and reset. The chapter describes this working encounter. | Can the visitor name the candidates before the draw, predict the exhausted region, and use stopping as a deliberate drawing decision? |

Array's floor change is limited to twenty structure cells under its two primary arrangements and the corresponding two basin boundaries. Its other basins, objects and placements remain. The row-return probe had previously failed at the one-metre pit lip. After the change, actual walker contact changes exactly one table value, and both tested return segments pass.

![The grid keeps addresses after collection](array-grid-eye.png)

## What joined the registers

The live curriculum had three Array rooms, while the generated museum plan still put Array in colour and omitted Single and Disco. Random_Remove was also absent. The scoped refresh restored these four memberships: 151 generated rows became 154 because the old Array row was relocated. Existing template identities were retained. Only randomness ordering metadata changed in its six existing neighbours; their geometry and objects did not.

Three saved whole-room hand stamps then overrode the new map placements. Their `stamp` flags are now false, preserving their saved arrangements and every other hand entry. The current map owns these pilot rooms again. No global hand-precedence rule was changed.

`tools/em_refresh_sequence.py` is the reusable result of this finding. It derives only a selected sequence or room, checks that unrelated rows remain identical, keeps timestamped backups and supports a dry run. These calls refresh the pilot after a map edit:

```powershell
python tools/em_refresh_sequence.py array_tutorial --apply
python tools/em_refresh_sequence.py randomness --room Random_Remove --align-order --apply
```

The Python deriver also now handles `gridagent:copy`'s nonnumeric rotation field like the live Godot deriver, using zero rotation. A stale hand stamp is a separate authority and must be inspected deliberately; refreshing the plan does not silently discard one.

## Evidence and its scope

[Verification summary](verification.json) records the passing reports, 22 Python regression tests, scoped plan audit and current evidence for all four dashboard actions. The earlier five actions are preserved.

- [Array scene checks](array-runtime.json): 21 checks, including a rectangular 3-by-2 fixture, retained plate addresses, exact value changes and contact/negative cases.
- [Array in the museum](array-museum.json): four support rays and four controlled movement segments; the actual Walker collects the requested row/grid occupants and only the corresponding values change.
- [Single in the museum](single-museum.json): three support rays, approach, pause without collection, contact and return. [Pickup detector evidence](pickup-after.json) preserves VR and demo behaviour and rejects an unrelated desktop-layer body.
- [Disco scene checks](disco-runtime.json): sounding/displayed address agreement, silent-cell and wrap cases, room isolation, stable cell identity, tempo and the floor's representational limit. [Museum placement and render](disco-museum.json) check the authored panel pose and its approach.
- [Random Remove scene checks](random-runtime.json) and [museum checks](random-museum.json): exact candidate sets, removal without replacement, exhausted/empty sets, reset, detector access and survival of unrelated objects. [Historical reconstruction](random-remove.md) explains what was recovered and what was adapted.

These are actual-scene tests, controlled physics probes and inspected desktop renders. The museum probe pauses museum input and catch logic while driving the real CharacterBody; its short movement segments do not establish continuous entrance-to-exit gameplay. A passing detector ray does not establish comfortable controller use. Headset reading, sound, reach, comfort and independent learning remain open.

Existing engine logs contain shader-cache/debug-log/UID or certificate warnings, and the headless UI tests contain viewport-texture warnings. Rendered panels were inspected separately. The museum's generic mesh extent helper omits MultiMesh geometry; a zero bound for the disco floor is therefore not evidence that the floor is absent.

Source manifests record inputs at launch. The museum regenerates its private bake during each run, so that output no longer has the seed bake's input hash. Array's recorded whole-plan hash also precedes the final Single gate change; Array's own map and implementation hashes still match. A final scoped derivation audit found no changes needed for any of the four pilot rooms: both plan copies contain 154 rows, with 24 artifact placements across the four rooms matching their maps and all three retired hand stamps inactive. Historical manifests have been retained rather than relabelled as later runs.

The full museum is still ahead of this pilot. Seven other current randomness rooms remain absent from the generated plan, and Single's secondary synthesis stand lacks a live scene. Those findings remain development tasks. The 190 manuscript files are coverage; they are not 190 accepted encounters.

## What can transfer

Array and Disco provide two implementations of a useful invariant: an address remains identifiable while its value changes. A row with disappearing labels supplies a contrasting case; Disco adds repeated reading in time and a lossy secondary display. The experimental method transfers, while the representational limits stay specific to each room.

Melencolia and Random_Remove establish two uses of historical recovery. One restores a spatial composition; the other restores the grid a computation depends on. The shared method is to recover the relationship, adapt its present implementation, and verify the appropriate spatial or behavioural consequence.

The next human check is deliberately small: one visitor predicts and performs the Array comparison, then tries the silent cell in Disco. Record what they do and what they infer before supplying the explanation. Keep a teacher-led observation and an independent visit as separate evidence.
