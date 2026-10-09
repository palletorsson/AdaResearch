# Fable: develop the next two Wavefunctions halls

Prepared for Claude / Fable 5.1, 10 September 2026.

**Geometry follow-up:** the [whole-spine audit](spine-recovery.html) corrected 62 additional maps while preserving the newer partitions in nine rebuilt galleries, as requested. The real GridSystem arenas already build numeric heights; do not apply a blanket wall-threshold rewrite to them. This does not expand W1 beyond Pendulum and Sine Space. Recovery contract: `python tools/recover_spine_platforms.py --check`. Physical verification remains pending.

Palle's instruction: **“we want progress in the same way you did.”**

Carry the museum and book forward together. Make substantive decisions about the artifacts, how a body encounters them, and what the prose lets a reader discover. Deliver the two improved rooms and their revised `final.md` files. Use the existing plan as material to work from; revise a proposed solution when the implementation gives you a better one.

Repository: `C:/Users/palle/Documents/GitHub/AdaResearch_46`

Shared instructions: `doc/research/waves-chance-noise/HANDOFF.md`  
Current source review: `doc/book/handoffs/astra-wcn-pilot-review-2026-09-10.md`  
Progress page: [Waves, Randomness and Noise](http://localhost:3003/research/waves-chance-noise/index.html)

## Scope and starting point

Develop **WaveFunctions_Pendulum**, then **WaveFunctions_Sine_Space**. These are adjacent active halls, batch W1. Return both for Astra's review before beginning further halls.

The three earlier pilots are implemented and corrected in source. Their museum runtime checks remain open. Read the review and preserve its corrections. If Godot is available, run those existing probes serially and inspect their results; commands are in `ada_run/waves_chance_noise/2026-09-10-pilots-batch.md`. If it is occupied, continue independent implementation and provisional writing within these two rooms, recording what still needs a run. Do not stop after producing another audit or another plan.

The latest instruction permits this bounded W1 work while pilot acceptance is pending; it supersedes the earlier blanket instruction to wait before expanding the batch. It does not mark any pilot accepted. Avoid propagating new, unverified shared behaviour.

Read the actual scene and code, the current map, and existing final/tutorial/technical/critical texts. Preserve current uncommitted work and meaningful arrangements before changing them. The recovered wave structure is deliberate: interior numeric `2` gives a one-metre platform in the museum; outer walls are explicit `w`; `museum.wall_height: 3` and `gate_depth_rows: 0` preserve the distinction and doorway. Check history before moving structure. Keep the current main route.

## How to work

For each hall:

1. Identify what the visitor brings from the preceding room and what becomes newly possible here.
2. Choose one or a few primary artifacts that can carry that discovery. Preserve useful developed secondary work.
3. Make the most consequential improvement to the encounter: its form, approach, scale, support, gesture, feedback or comparison. If a part already works, keep it.
4. Try the available interaction, examine the consequence and revise. Choose materials and proportions that make the mechanism perceptible and give the room a character of its own.
5. Write from the configured artifact and actual code. Allow an observation to trouble the first explanation. Reconcile the four registers: space, tutorial order/roles, critical inquiry and book.
6. Read the transition into the next hall. Leave a concrete next question and a record of what this room taught us while making it.

Make routine local design and implementation decisions autonomously. Document consequential departures from the card with the evidence that prompted them. A change to the research question, removal of meaningful developed work or alteration of the main route belongs in an explicit editorial discussion.

## Hall 1 — WaveFunctions_Pendulum

**Question: Where does a movement put its past?**

From Intro we bring a bob whose return to the centre can carry two different velocities. This room gives motion a visible history. The primary is `PendulumWave`; trace it through:

- `commons/maps/WaveFunctions_Pendulum/map_data.json`
- `algorithms/wavefunctions/oscillation_driver/PendulumWave.tscn`
- `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`
- `doc/research/waves-chance-noise/maps/WaveFunctions_Pendulum.md`

The source audit found a receding trail with a default limit of 300 samples. Motion and recession use frame delta while sample insertion follows rendered frames. Verify that current behaviour before deciding how to improve it.

**Design direction:** make the bob and its history readable as one installation, with a clear view along the trail. Consider a suspended ribbon, an instrument that carries marks away, or another form appropriate to this code. You choose the form. Give the count a deliberate casing beside the trace and at a useful viewing height. Let the visitor discover the oldest mark disappearing as the record fills.

Expose the retained sample count and actual time span, with an understandable sampling interval or policy. Use a bounded fixed-time sampler or make the existing frame-based policy explicit. Compare two sampling intervals while keeping the motion rule and initial conditions controlled. Account for numerical integration differences if render rate also changes. Keep memory bounded. Add reset/replay only if you build and connect it; reset the local experiment, never claim to restart the museum clock.

The visible improvement should let a learner connect **motion → sampling → finite record**, including what cannot be retained. A number placed in the room becomes useful when the learner can relate it to a mark arriving or leaving.

**Write the final:** begin with the apparent second body behind the bob. Let the reader follow its direction, find equivalent crossings and notice what is missing from a sparse record. Introduce a short excerpt of the actual append/evict mechanism and explain the time-to-depth mapping. Let an old mark disappear before interpreting the loss. Recall Point_Trace without retelling it. Carry the periodic value into Sine Space, where repetition will shape a passage.

**Show it works:** record sample count and retained duration under two sampling conditions; verify eviction and bounded history; inspect the bob, whole trail and readout together in the museum. State which controls were exercised and how. Do not infer hand reach from source coordinates alone.

## Hall 2 — WaveFunctions_Sine_Space

**Question: What kinds of passage can a repeating rule make?**

The previous room made a history visible. Here a periodic rule is read as a spatial arrangement around the visitor. The primary is `sine_wall_corridor`; trace it through:

- `commons/maps/WaveFunctions_Sine_Space/map_data.json`
- `algorithms/wavefunctions/sine_wall/sine_wall_corridor.tscn`
- `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`
- `doc/research/waves-chance-noise/maps/WaveFunctions_Sine_Space.md`

The source audit found that the placed scene enables animation and disables collision, overriding the script defaults. Its starting corridor is only one metre wide and 24 metres long before placement transforms. Establish the actual museum bounds and route.

**Design direction:** turn the relation between the facing walls into an encounter a body can understand. Provide a clear approach, a place to compare, reachable controls and an exit or museum bypass. Plush folds, translucent membranes or architectural ribs are possible directions; choose what makes crests, gap and motion legible. Use the existing skin/ribs/strata/lattice possibilities where appropriate.

Expose amplitude and relative phase as separate comparisons. Keep frequency and material steady while each comparison is made. Moving through a spatial wave and watching phase advance while standing still should become distinguishable.

Choose a physical arrangement you can demonstrate: deliberately rebuilt static collidable states, animated visible surfaces around a stable walk, or another well-supported solution. If you implement animated collision, verify its update cost and that exposed settings cannot trap the player. Let the difference between visible and colliding surfaces be discoverable where it matters. The appearance alone cannot establish that a wall supports or obstructs a body.

**Write the final:** enter through the gap and notice how the facing surfaces relate. Invite one change before naming amplitude or phase. Use one real sine contribution before discussing its sum with others; explain the units the code uses. Return to the bodily consequence of the gap. A surface that moves, a collision boundary and an available route can disagree. Carry that specific question into `WaveFunctions_Effect_Sound`, the next active hall, where periodic variation becomes audible.

**Show it works:** measure clearance through the exposed settings, check the actual player collider's route, and verify that controls reach the relevant mesh/material and any collider. Capture the installation from its approach and from the comparison point.

## The voice and the freedom

Write with an oscillation between strangeness and first principles:

**notice → try → inspect → read the consequential code → try again → uncover a remainder → move forward.**

This rhythm need not become six repeated headings. Let each room find its own cadence. Code blocks are part of the book's poetry because their operations do something precise. Quote the implementation, label reduced excerpts, and let the reader discover why those lines matter.

Keep good existing writing. Retain good artifacts. A short, exact observation can carry more than a generic critical paragraph. The queer inquiry asks what other bodies, relations and uses these same procedures make possible, and which are absent from the chosen representation. Test those questions against the material; do not make noise, disorder or a particular style stand automatically for freedom.

Choose the casing, spatial composition, material character, sensory emphasis and small surprises. You can propose a better primary encounter if you justify it and align placement, roles, tutorial order and book anchors. The question and the reader's access to evidence must survive the change.

## What to return

Use `doc/research/waves-chance-noise/REVIEW_TEMPLATE.md` for one concise W1 batch report. Put raw evidence under `ada_run/waves_chance_noise/MAP/`.

Return:

- The improved rooms and revised finals, with relevant supporting texts and primary/book alignment.
- A short before/after account of what the visitor can encounter, plus one design decision and one discovery from making each room.
- Actual source paths for the final's code excerpts.
- Runtime results and captures where obtained; explicit pending observations where unavailable. Keep source checks, emitted signals, desktop interaction and tracked hands distinct.
- One reuse candidate with its limits: for example, how the finite-history display differs from Point_Trace, or how the corridor's visible/colliding boundary differs from a stable arena.

Use the existing targeted checks. Fix failures before describing their expected outcomes as observed. Keep reports proportionate to the two experiments. A completed source pass is useful progress, and its status must remain distinct from a room verified in the museum.

After both rooms are handed back, Astra will inspect the changes, read the two finals consecutively, check the experiments, and improve what remains weak. Do not begin the sound-room batch yet.
