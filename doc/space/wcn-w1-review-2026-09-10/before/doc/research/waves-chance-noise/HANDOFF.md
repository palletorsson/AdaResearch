# Fable 5.1: Waves, Randomness and Noise

**Current instruction, 10 September:** Palle wants the same hall-by-hall development used for Primitives and Transformation: improve the encounter, discover what its implementation makes possible, and write the room from that work. Read [the next batch brief](NEXT_BATCH.md) and [Astra’s pilot review](pilot-review.html). The three pilots are corrected in source; runtime acceptance remains pending. Finish that verification when Godot is available. Work may also advance within the two named W1 rooms below, without treating the pilots as accepted or spreading their unverified code across the sequence.

Implement this plan in `C:/Users/palle/Documents/GitHub/AdaResearch_46`. The user wants the museum, its teaching arrangement, critical inquiry and book to develop together. The central research question is **what bodies are possible with the tools we have now?**

Read `README.md`, then the relevant cards in `maps/`. `plan.json` contains the editorial instructions; `audit.json` records the source state on which they were based. The browser guide is at http://localhost:3003/research/waves-chance-noise/index.html. This handoff is for Fable 5.1 as requested by the user; no implementation run has been dispatched by preparing it.

## Work as a maker and writer, hall by hall

Own the development of the room. Make the design decisions the evidence supports and carry them into the game and book. Choose the most consequential improvement the visitor can experience: a relation that was hard to see, a gesture that lacked a consequence, a lost platform, or a control that makes a useful comparison possible. Describe what the visitor could do before and can do after. If the encounter already works, preserve it and improve the weak part.

Use this working rhythm:

1. **Carry something in.** Name the capability learned in the previous hall and the new question this hall can put to it. Read the existing room and source before selecting a solution.
2. **Choose the primary encounter.** Start with one or a few relevant artifacts; a developed room can keep more. Preserve useful secondary examples. Recover meaningful old structure where the museum conversion hid it.
3. **Build a legible encounter.** Improve proportion, placement, support, approach, controls and consequences together as needed. Think through where a body stands, looks and reaches. Choose the material and form that make this particular behaviour perceptible.
4. **Try it, then revise it.** Follow the actual visitor action and examine the result. Fix what the attempt exposes. Small source checks belong alongside the edits; runtime tests and captures establish what happens in the installation when available.
5. **Find the productive remainder.** Ask what the procedure retained, discarded or made possible unexpectedly. Give the reader a way to encounter that difference. Keep an invisible point invisible; place a trace display beside its evidence; let an old mark disappear when the buffer actually evicts it.
6. **Write and reconcile the room.** Revise `final.md` around the configured primary artifacts. Move between observation, first principles and a few lines of actual code. Let a further attempt complicate the first explanation. Align primary roles, book anchors, tutorial order and supporting texts.
7. **Carry the discovery forward.** Read the end of this room with the opening of the next. Record a reusable solution with the conditions it depends on, then continue within the assigned batch.

Use judgment within the agreed scope. Materials, proportions, casing, arrangement and modest local interaction repairs are implementation decisions to make and inspect. Keep the user involved when a choice changes the research question, removes meaningful developed work or changes the main route. A batch should return improved rooms and their prose, with a concise account of what was learned.

Source-only work must remain labelled as such. If Godot is occupied, continue independent source repairs, layout preparation and provisional writing within W1; record which visitor claims still need observation. Leave the existing Godot session untouched and follow the project's serial-run rule. Runtime acceptance and reuse of a new shared behaviour wait for evidence; an unavailable run does not require another plan instead of making the bounded changes already possible.

## Current pilots and the next two halls

The Wavefunctions structure prerequisite has now been completed. Read [the recovery report](recovery.html) and `doc/space/wave-platform-recovery-2026-09-10/README.md` before editing. Interior numeric `2` remains a two-cube grid stack with a one-metre museum deck; perimeter `2` was made explicit `w`, and `museum.wall_height` is `3`. Gates sit at the outside doorway via `gate_depth_rows: 0`. Keep this distinction. Do not normalize the maps again or replace interior `2` with `p`: the standalone grid interprets `p` differently.

Six active halls passed 630 architecture checks; Intro and Effect Sound also passed 189 and 152 geometry/placement checks with artifacts loaded. The sound hall exposed initialization errors in `UniversalVRAudioController.gd` and `MelodyChaser3D.gd`: their configuration code uses child nodes before `_ready`. Treat these as open encounter repairs, not evidence that all sound interactions work. The six wave extensions have source checks but no new runtime walkthrough.

The same correction has now been applied to 17 maps across Randomness, Noise and Cellular Automata. Read [the follow-up structure report](structure-recovery.html). Preserve the new platform/wall declarations and the three access repairs: interior spawns in Random_Mushrooms and Randomness_Examples_of_Randomness, and the landing before Noise_Inside_Noise's exit. All current artifacts and configurations were retained. These maps have source and before/after path checks; their physical museum probe is still pending. The CA audit does not add CA implementation work to this handoff's scope.

First record the current working-tree state and inspect the sources. These pilots have already been implemented and corrected; resume their outstanding runtime checks:

1. **WaveFunctions_Intro:** a reachable pendulum whose returning position can be distinguished from its changing state.
2. **Random_Definition:** a seed/replay comparison that makes an irregular result repeatable.
3. **Noise_Perlin_Simplex:** repair the incorrectly matched noise bases and create a fair comparison.

Hand the runtime results and any corrections back to Astra. Keep their acceptance status visible. The next development batch is **W1: WaveFunctions_Pendulum, then WaveFunctions_Sine_Space**. [NEXT_BATCH.md](NEXT_BATCH.md) gives each a concrete design direction and a prose opening to investigate. Develop the two in that order and return the rooms together; use existing stable components while new pilot behaviour is still awaiting verification.

After the pilot and W1 reviews, continue in batches of two or three neighbouring active halls. Finish each encounter and its prose together, then develop the sixteen extension maps as standalone rooms. All thirty-five maps have individual instructions. Main-route insertion of extensions is a separate editorial decision; improve their maps and texts without silently adding them to the museum spine.

## What is fixed, and what you can invent

Keep each card's question and its observable comparison. Keep the teaching sequence **question → do → observe → explain with actual code → test the limit → carry something forward**. A student walking alone needs access to the same evidence a teacher would point out.

The proposed lead is a starting choice. You can replace it with a better existing artifact or build a modest new one when that makes the experiment clearer. Explain what the alternative lets the visitor discover and update placement, roles, order and book anchors together. A matched set can be one primary encounter; do not impose an arbitrary maximum of two objects. Keep useful developed comparisons and archive meaningful arrangements before removing them.

You choose materials, proportions, casing, spatial composition, small surprises and how evidence is revealed. Each card includes latitude. Do not copy one generic laboratory bench into every room. An intimate instrument, an architectural passage, a garment specimen and a field of strange creatures can teach different bodily relations. Excess, tenderness, ornament and desire can belong here when they remain connected to what the procedure does.

You can revise an experiment if source inspection disproves the plan's assumption. Record the evidence and the replacement. Do not preserve a false claim merely because it appears in a card, map title, registry description or old essay.

## Inspect before changing

The source lists contain **35 maps**, while `commons/data/map_authored.json`, the current `ada_run/em_plan.json` and `commons/data/museum_order_effective.json` agree on **19 active halls**: six Waves, seven Randomness, six Noise. All 35 currently have a `final.md`; all 35 have matching primary/book anchor sets in the source audit. Those agreements do not establish runtime quality.

For each room, read its map, existing final, technical, critical, tutorial and intent texts where present. Trace the registry token to the scene, scene overrides, scripts, shader and interaction path. Exported settings are not automatically visitor controls. The JSON audit lists direct scene resources as entry points; it is not a complete transitive code review.

Before moving a room's structure, inspect its map history and relevant pre-museum version. Use `git log --follow -- commons/maps/MAP/map_data.json` and `git show REV:commons/maps/MAP/map_data.json`; determine the relevant revision from history rather than guessing a universal transition date. Save the current map and relevant old layout under a dated `doc/space/` folder with provenance. Recover a useful platform, pit or approach before inventing a substitute. Do not overwrite the current map with an old file wholesale.

The worktree is already dirty. Save a baseline diff/status and limit edits to the assigned scope. Nails plinths and the Rainbow celebration are an independent workstream with uncommitted changes and publication still pending. Do not alter Color_Nails, Color_Rainbow, their artifacts, their captures, or the existing possible-bodies guide while doing this handoff. Shared infrastructure changes need a narrow diff and a second consumer check.

## The book voice

The book alternates between something that does not quite fit and the precise procedure that lets us investigate it. Give the reader an observation to make before supplying its interpretation. A brief question, a concrete gesture and a strange consequence are enough to begin. Use the room's actual artifact, not a general essay with the artifact's name pasted into it.

Revise rather than mechanically replace the existing `final.md`. Keep observations that already work. Cut repeated instructions that ask the reader to describe the same thing without discovering anything new. A focused hall may need roughly 400–750 words; that is a working range, not a quota. Lab_Path can be much shorter. Leave space around the code and let the rhythm of the prose vary.

Each final should normally include:

- One opening question attached to something perceptible in this room.
- A feasible action or sustained observation, followed by a comparison the reader can make.
- A compact excerpt from the implementation that actually runs, with enough explanation to read its variables and units.
- A second attempt, counterexample or deliberate misuse that makes the rule's boundary felt.
- A transition into the next actual hall, or an explicit optional return from an extension.

Code is part of the voice. Prefer a few consequential lines over a tutorial dump. Copy from the final implementation and record the source path/function in the review report. If omission or renaming is necessary, label the excerpt as reduced; do not present invented pseudo-code as the live script. A physical pendulum update, a phase-modulated audio sample and a prescribed sine motion are different procedures.

Keep `<!-- @token -->` anchors on the encounters the reader actually uses; `<!-- @ -->` is an intentional end/reset marker. Ignore empty markers and `sub:` editorial markers in role comparisons. If a controlled series is primary, anchor the relevant tokens deliberately and keep role order coherent with the walk. Do not promote every mentioned piece of decoration to primary. The encyclopedia's `from_book` hero flag is not a complete test of all manuscript anchors.

Critical writing should arise from a specific implementation decision. Examples include the strip losing order when it becomes a histogram; the limited attempts that leave a point population incomplete; a field that moves the visible surface while its collider stays still; or a ground seed that does not reproduce the mushrooms. These are stronger than attaching a generic paragraph about freedom to every algorithm.

Use queer inquiry to keep the permitted possibilities open: which variation was given a control, what still counts as a column, which body can use this path, and what else could the same values become? Do not assign virtue automatically to noise, disorder, smoothness, a particular colour or a supposedly optimal setting. A title such as chaos, entropy, growth or Perlin is a claim to check. The noise chapters are not quantum wavefunction lessons merely because of the sequence name.

Distinguish mathematical topology from geometric deformation and bodily reachability. Changing height or rotation need not change mathematical topology; thresholding can change a sampled occupied set; collision and player dimensions determine a different accessibility question. Do not publish a numerical 'topological entropy', universal lambda threshold or edge-of-chaos optimum without a defined system, measure and evidence. The book can keep these as research questions.

Correct conflicting supporting documents when you change the encounter. `technical.md` can carry implementation detail, `critical.md` the longer question, and `tutorial.md` the encounter order. Do not leave an old 'Perlin erosion' label beside a corrected periodic-deformation final.

## Reusable methods: prove a second use

| Method | First uses | Contract to preserve when reusing |
|---|---|---|
| R1 Controlled comparison | Pendulum, seed replicas, noise bases | Name the changed variable and hold the others fixed. Support reference/reset; do not rebuild from a new random state while claiming a single-variable change. |
| R2 Housed readout | Pendulum trail, histogram, field probe | Human-scale reach, readable values and units, source-consistent counts, casing beside the phenomenon rather than obscuring it. |
| R3 Explicit time | Trace, propagation, random platform | Distinguish game time, experiment time, simulation steps, render frames and audio samples. Local pause never claims to stop the museum clock. |
| R4 Sample-to-body mapping | Additive sum, noise torus, voxel, terrain | Share actual data/state when saying 'the same field'; separately name colour, displacement, occupancy, collision and agent response. |
| R5 Museum/arena boundary | Sine Space, removal grid, crossing, terrain | Recover original layout; keep a level margin, intentional entrance/exit, and a clear museum route. Walls and glass support staging only where they serve the encounter. |
| R6 Local state/seed | Replay, walks, mushrooms, warp | Record basis/version, seed, draw order, step cadence and reset scope. Avoid global RNG side effects. Seed alone does not guarantee arbitrary simulations replay. |
| R7 Measurement contract | Entropy, Gaussian, count displays | State sample size, bins, alphabet/range, clipping and normalisation. Do not mistake appearance, sample entropy or a proxy for a different physical quantity. |
| R8 Bounded simulation | Traces, audio, voxel, creatures | Bound retained history, work per step, generated nodes and rebuilds. Check teardown and two nearby instances. |
| R9 Route/book reconciliation | All final handoffs | Distinguish authored list, museum route and optional extension. Keep navigation, roles and prose aligned. |

Do not build a universal framework first. Implement one method locally, use it in a second genuinely different room, and extract shared code only when the contracts agree. Existing `apply_grid_config`, ControlPanel, value_mapper and evidence/readout variants are preferred starting points. A common visual casing can be reused without pretending all simulations share a sampler.

## Evidence and handback

For each changed room, leave a report under `ada_run/waves_chance_noise/MAP/` and a concise entry in a batch Markdown report. Keep source-only checks, desktop runtime checks and tracked-headset checks separate. Never label a source audit or screenshot as proof of reachability.

Use [REVIEW_TEMPLATE.md](REVIEW_TEMPLATE.md) for the handback, leaving the Astra review section empty for independent review.

The report must include: baseline and final source hashes; changed files; the actual primary tokens/configurations; the chosen experiment and any departure from the plan; controls exercised; numerical/behavioural observations; before/after museum captures; remaining limitations; and the final's code excerpt source. Record runtime version, rendering mode, relevant seed and simulation cadence. An edited/generative mockup is not a runtime capture.

Use the existing museum probes in `commons/testing/` as patterns, especially `probe_color_recovery.gd` and the focused lesson probes. Instantiate the actual museum room, not only the artifact scene. Measure reach from the world-space floor, actual dynamic bounds, entrance/exit and collision alignment. Test the real control/input signal path; a direct method call only proves the method. State clearly when a button signal was emitted programmatically and when a tracked hand was used.

Test the mathematical invariant or behavioural claim the visitor is meant to discover. The per-map cards specify such checks. Avoid large suites of assertions that merely restate the implementation. Re-test a shared component in its second consumer. Reload/unload each changed room to catch persistent audio, material sharing, RNG leakage and orphan nodes.

Refresh derived role/order and museum indexes with their existing generators only after inspecting their diff. Never hand-edit `museum_order_effective.json`. Relevant tools are `tools/build_spine_artifact_order.py`, `tools/long_museum.py` and `tools/museum_necklace.py`; these can touch wider generated outputs, so preserve unrelated work and report the scope. Rebuild this handoff audit with `python tools/build_waves_chance_noise_plan.py`. Test the encyclopedia's actual primary view and composed final for each changed room after refreshing the source-backed data.

Do not mark a room done simply because every file exists. Use the status **implemented — awaiting review** until Astra has reviewed it. Astra's review will ask:

1. Can a visitor discover the stated difference through the actual installed controls or observation?
2. Does the program and its collision/audio/visual output support the book's claims?
3. Is the critical question specific to this experiment, with an unresolved possibility worth carrying onward?
4. Do room, primaries, order, prose and route agree?
5. Does the proposed reusable solution work in a second room without erasing its difference?

Return the W1 rooms, their finals and exact changed files, together with any pilot runtime results obtained. Wait for Astra's review before beginning further halls. Leave unresolved evidence plainly visible; do not compensate for a broken interaction with more confident prose.
