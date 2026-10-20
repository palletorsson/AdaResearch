# A particle learns to become a system

**Revised five-hall tutorial proposal, 14 October 2026.** Keep the existing order: **Single/Arrays → Emitters → Forces → Lifetime/Types → Collision**. These are specifications for five reconstructable tutorials, not five completed programs. Field comparison and rule revision are optional later returns in existing halls, not required sixth and seventh lessons.

Compared with the committed proposal, basic age/retirement remains in P1 so the population stays bounded; P4 develops lifetime curves and types after forces. P5 no longer depends on the unbuilt field lab. The five current folders still have map data and a blurb but no tutorial, technical or final chapter in the audited state.

The particle sequence is a declared branch from Forces in the curriculum spine, but is absent from the current Endless Museum chapter declaration and generated plan. Preserve that branch relationship; reconcile the sequence's vectors-only unlock metadata before integration. A proposal is not an already-working portal.

## The object that continues

Bring position, velocity, acceleration, force/mass, arrays, Node3D, transforms and scene instancing from linked prerequisites. The learner model adds stable identity, birth tick, age and a simple fixed lifetime. Later add emitter ID, kinds and versioned relation rules. Keeping a picture is different from keeping enough state to continue it.

The production Particle/ParticleEmitter, confetti, MultiMesh, body, field and campfire scenes are audited comparisons. Their global draws, wall-clock animation, per-update damping and differing inputs are not hidden starter assumptions. Reuse their tested parts only with an explicit explanation of inheritance and changes.

Use MAKE / BRING / GIVEN / BUILD / CHECK / INVESTIGATE / CARRY / LATER. Before running, predict one observable change. Print the first small program once; subsequent lessons supply exact edits plus the complete resulting program. Each starts from the preceding tested learner output or a declared fixture. A person receives only those linked prerequisites, printed code and declared assets for reconstruction. Record AI assistance and gaps discovered; do not quietly borrow missing production code.

Each hall has a deterministic local baseline and the same seven-step experiment cycle. Import/export is optional. X2 can supply birth data when built, but no tutorial waits for the whole randomness route. [Research records and learning debt](RESEARCH_RECORD.md) distinguish measured output, unverified interpretation and the next proposed change.

## P1 · One point, then several — Particles_SingleAndArrays

**MAKE:** A particle with an inspectable state, followed by a bounded population using the same update.

**BRING:** Position, velocity, forces/integration, arrays, the point and a retained trace. A deterministic starter is available before the randomness sequence.

**GIVEN:** Prepared room, player, XRTools, existing point input/renderer and a declared fixed simulation tick. Keep STEP, RUN, PAUSE, RESET and KEEP reachable in both desktop and VR. The richer single-particle and array artifacts remain beside the learner version.

**BUILD:** Start with one deterministic particle. Draw its position from state, update velocity from acceleration and position from the updated velocity, reset accumulated force, advance age. Name this velocity-first integration rule. Then add stable IDs and an array. Retire expired particles without skipping their neighbours; preserve a held snapshot by value. A cap limits active entities.

**CHECK:** Under zero force, a given velocity produces the expected displacement over a fixed number of ticks. The kept state stays unchanged while the running copy moves. Empty population and two simultaneous deaths work. Replaying recorded initial state and ticks reproduces the declared state. The same tick schedule survives changed render cadence. A fixture that accidentally shares the kept array must fail.

**INVESTIGATE:** Keep one particle and then ten with the same individual rule. What, if anything, becomes visible only in the population? Allow “nothing yet” and ask what interaction would have to be added. There is no emergence claim merely because the count increased.

**CARRY:** Version P1, initial state, final state, fixed tick, identity and lifetime records.

**LATER:** Random birth, emitter scheduling, pair interaction, GPU simulation. The existing production scene's gravity wells do not have to be reconstructed here.


## P2 · Birth is an authored event — Particles_Emitters

**MAKE:** One emitter, then two independent emitters whose births can be replayed.

**BRING:** P1 and its population cap. After the randomness opening, add a local generator and a declared distribution; before that, use a small deterministic birth table.

**GIVEN:** Existing single/multiple emitter displays and the same input/record bench. `sub_emitters` and `example_particle_body` are optional previews, not hidden dependencies.

**BUILD:** An emission accumulator and explicit scheduled birth events. Separate emitter transform from already-emitted particle state. Declare local/world coordinates. Retain emitter ID, birth tick and sampled position/velocity. Give each emitter an independent recorded stream, or use a retained birth table. Choose an explicit full-cap policy—initially drop and count scheduled births while full, rather than accumulating an invisible burst of debt. Zero rate must be a valid stopped emitter.

**CHECK:** A declared rate over a declared duration produces the specified scheduled count with the boundary convention stated. Changing emitter B does not consume A's stream. Moving the emitter leaves old world-space particles unchanged. At capacity, skipped births are counted. REPLAY restores the accumulator and next ID as well as the seed. When X2 is available, the distribution-hall transfer changes future births, not existing state; the local birth table remains usable without it.

**INVESTIGATE:** First keep births fixed and change only the origin. Then, as a separate trial, compare regular and burst schedules with the same total births over the declared interval (hence the same mean rate). Retain exact event times, cap/skipped counts and population traces. Does the cloud differ despite the equal average? Stochastic timing is a later version with its event log retained. Each comparison changes one condition.

**CARRY:** P2, emission schedule, per-source state, birth records and the chosen cap policy.

**LATER:** Poisson timing and exponential waits as separate extensions; firing an event at a jittered interval is not automatically a Poisson process. Defer recursive children until parent identity and lifetime exist.


## P3 · A force is a relationship — Particles_Forces

**MAKE:** A population under a visible, movable, bounded force field.

**BRING:** P2 and force/mass from the earlier course.

**GIVEN:** `force_fields` and `example_2_6_single_attractor_vr`; a hand target and desktop equivalent. An adapter records target position in the apparatus's local coordinates, including under rotation/scale.

**BUILD:** Apply a selected acceleration/force law to every particle from the old state, then integrate once per tick. Distinguish a force integrated into velocity from a field directly assigned as velocity. Define distance clamping and behaviour at zero distance. Use recorded hand positions for replay. If damping is added, state a per-second law or fixed-tick convention rather than inheriting frame-dependent drag unnoticed.

**CHECK:** Zero force, reversed direction, declared mass response and coincident positions produce finite expected behaviour. A rotated/scaled host uses correct coordinates. Replaying the recorded target trace repeats the tested state. A stationary target and an animated fallback are visibly different input modes.

**INVESTIGATE:** Keep the same births and initial conditions while moving only the attractor. Which trajectories are captured, pass by or leave? The apparatus should let a visitor retain a counterexample to an attractive explanation.

**CARRY:** P3 plus force law, target trace, coordinate convention and integrator settings.

**LATER:** Fluid simulation and pair forces. Do not call a passive particle cloud a swarm with sensing/decision rules.


## P4 · A population persists while members leave — Particles_LifetimeAndTypes

**MAKE:** Lifetime-dependent appearance and two kinds that respond to the same update interface.

**BRING:** P3, birth records, age, retirement and the tested force update.

**GIVEN:** `lifetime_curves`, the mixed particle/confetti scene and the existing particle-system display. Their “species” language is an artistic description, not evidence of biological evolution.

**BUILD:** Normalized age from age/lifetime with a defined zero-lifetime policy. Map age to size/opacity using a selected curve. Keep appearance mapping distinct from dynamics and death. Add a second behaviour through a clear update interface; explain whether this uses a dictionary tag, composition or a class. Add one bounded parent→children event only as a follow-on, with generation depth and population budget recorded.

**CHECK:** Changing an appearance curve preserves particle positions and RNG state. Extending lifetime changes retirement but not the original births. Simultaneous deaths do not skip entries. Children are emitted once per parent-death event; depth/count limits stop recursive growth. A held parent/child record survives reset.

**INVESTIGATE:** Can two populations look stable while their turnover differs? Keep births fixed, vary lifetime, and observe occupancy. Then ask whether visual persistence is the same as individual persistence.

**CARRY:** P4, lifetime/curve definitions, kinds and optional parentage.

**LATER:** Genetic inheritance, selection and self-modifying categories. A code subclass is not an evolutionary lineage.


## P5 · What stops, leaves or passes through — Particles_Collision

**MAKE:** A comparison of boundary policies and one explicit repulsion/collision operation.

**BRING:** P4 and the same population/force state. No noise-field implementation is required.

**GIVEN:** Existing hand repeller with selectable force laws and particle collision, plus `particle_campfire` as a composition to investigate.

**BUILD:** Compare absorb, reflect and periodic wrap with the same incoming trajectory. State the actual surface and contact rule. Keep repulsion from a field separate from pair collision. Introduce one two-particle contact case before a population. Capture hand input, event order and contact-policy version. Record deaths, exits, bounces and births separately.

**CHECK:** Defined single-axis reflection reverses the expected component; wrapping preserves particle identity; absorption retires exactly once. Two simultaneous contacts and zero separation remain finite. Pair-update order is deterministic in the declared reference implementation. The test must expose any energy gain/loss the chosen collision approximation permits. Keep a small tested budget before scaling a quadratic pair loop.

**INVESTIGATE:** Can the same emitter appear to produce a different community because of what the boundary lets leave? Then compose a small fire/smoke/ember study from known rules and state where it is a visual model rather than combustion physics. Predict and change gravity, drag, birth pattern or lifespan singly until the work no longer reads as fire. Preserve each predecessor and the viewer's interpretation, including disagreement; visual recognition is not a universal numerical test.

**CARRY:** P5, boundaries, event log and a retained composition. If the optional rule bench is built, X6 carries a selected population to Random Space.

**LATER:** Full fluids, combustion, arbitrary rigid-body replay and physical cloth.


## E1 · What the field asks of a moving point — optional return to Particles_Forces

**MAKE:** A controlled comparison between independent kicks and transport through a saved coherent field.

**BRING:** Completed P1–P5, Random Walk, and the field/address/receiver distinction from Geometry and Noise One. This is the point where an early Forces visitor returns after learning the randomness/noise material.

**GIVEN:** The existing `curl_noise_particles` as a comparison after its claims and replay path are corrected; `related_weather` as prior art for distinct raw, accumulated and filtered records. A frozen field is the first required case.

**BUILD:** Start with fixed motion, then compare independent kicks and a frozen vector field using the same retained births. Do not change renderer, integration step, boundary policy or population budget between modes. Define the stochastic kick distribution and tick scaling; distinguish an authored discrete random walk from a numerical approximation to Brownian motion. Define the field's vector interpretation explicitly. A scalar-noise input needs a named adapter. Keep field animation time separate from simulation time. Add boundary modes one at a time. Reuse a single local stream for all stochastic respawns in the bounded comparison.

**CHECK:** Record a bounded path/dispersion measure and exits in addition to the trace; name the units and interval. Querying a static field twice at the same address returns the same value without spending a draw. Changing display colour does not move a particle. Replay includes field phase and boundary events. A finite-difference curl construction needs a numerical divergence investigation with stated tolerances and domain; do not infer global incompressibility or nonintersection from the label. Random respawn is recorded and never described as wrapping.

**INVESTIGATE:** Keep initial conditions and a frozen field. Change only the receiver from direct velocity to force. Then restore that baseline and change spatial scale. Which difference reorganizes the paths? Smooth motion alone does not answer whether randomness was sampled during the run.

**CARRY:** E1, field record, receiver mapping, kick/respawn records and boundary counts. X3 connects Geometry/Noise One to this comparator. Referenced returns can meet the existing curl display in Random Space Geometry or the crossing in Noise Space 10. A separate Field Lab is deferred.

**LATER:** Time-varying fields, exact Brownian limits, higher-order integration and GPU scale. A GPU version must declare which replay guarantees remain meaningful; [Godot's fixed-seed particle controls](https://docs.godotengine.org/en/4.6/classes/class_gpuparticles3d.html) do not by themselves prove cross-device identity.


## E2 · The particle can acquire a new relation — optional rule bench in Random_Space

**MAKE:** One bounded rule revision with a preserved predecessor and a consequence that can be compared.

**BRING:** P5, stable identity, records and explicit relationships. A visitor coming from the grid route can use the same sixteen-entity fixture without completing every particle exercise. The dedicated Rule Workshop remains deferred; this is an extension, not a sixth required tutorial.

**GIVEN:** A proposed rule bench at Random Space, drawing support inspired by `ParticleBody`, and a visible link between old and revised experiments. Current `ParticleBody` links are geometry; coupling forces, persistent bonds and role changes are new work. Its DELAUNAY mode currently delegates to nearest neighbours and must not be taught as a Delaunay implementation.

**BUILD:** First allow two particles to connect under a declared rule while keeping original random samples fixed. Retain IDs and rule version. Then distinguish a drawn link from a force-bearing bond. Choose one reversible relation edit—detach, connect, or turn a particle into a sensor. A new state space is demonstrated through a stated previously-unavailable relation, not merely through new colours. Rollback returns to the retained predecessor without erasing its child experiment.

**CHECK:** The old rule cannot produce the selected relation under the stated fixture; the new one can. Replaying either version retains the same input record and appropriate rule. Removing an entity removes/reports its connections; unknown roles are not silently discarded. A saved parent stays intact. Independently reconstruct the small revision from the tutorial.

**INVESTIGATE:** Does the new relation matter to the visitor's question? A connected cluster may be awkward, boring or unstable. Keep that outcome. Let its observation produce the next proposed edit. The imagined sleeve is one possible question, not a compulsory endpoint.

**CARRY:** A parent/child experiment pair, rule difference, observation and next question. Return to the seed bench or take the qualified QFEP Sandbox link.

**LATER:** General grammar editing, bodily garments, evolutionary rule search and autonomous AI rewriting. Each needs its own declared experiment.


## Verification and learning time

At every stop, use the agreed seven-step cycle and keep three evidence levels: artifact correctness, the complete experiment cycle, and only the cross-hall links promised by design. Record scene/runtime/performance/headset evidence separately. The field comparator does not pass because its particles look beautiful; a technically accurate display also does not pass the cycle until someone can compare, retain, replay and reconstruct its outcome.

AI can propose the next edit, supply an explanation or help with reconstruction. Record the assistance rather than requiring unaided typing as proof of learning. Ask the person to predict a change, inspect what occurred and identify what the program still cannot express. The result may be a sharper question instead of a completed answer.

The source lineage includes Daniel Shiffman's [particle-system work](https://natureofcode.com/particles/) as acknowledged by the existing scenes. Preserve those attributions when adapting code. The five-lesson continuation, experiment records and optional relation study are this proposal's additions; they are not claimed as existing source behaviour.


For each of the five lessons, retain a completion record with the exact incoming/outgoing program versions, predicted and observed difference, baseline/variant, replay scope, an independent reconstruction attempt, the assistance used and a next intervention. Keep scene loading, memory/performance, actual headset reach/visibility/comfort and human comprehension as separate evidence. A scripted or AI ghost student can reveal missing steps, but cannot close the human learner or physical headset checks. Preserve Nature of Code source and license notices for reused code.


## A passage can propose the next particle experiment

After a selected reconstructed lesson, preserve a paragraph and make its interpretation explicit. “The wall remembers” might become a contact counter that changes one response; “the points belong together” might become drawn links or force-bearing constraints. These are different implementations of an open proposition, not its definitive meaning. [The Text Simulation Loop](TEXT_SIMULATION.md) and [unbuilt examples](text_experiments.json) provide the companion record.

An executed comparison can generate several accounts, or expose a mistaken assumption in the first passage. Keep the before/after program and wording, label the evidence level, and ask what should change next. E2 may host a remembering-wall variant after the five lessons; it is not a new prerequisite. An author's later return can discover something in material they did not personally compose. Record that learning and any remaining debt separately from passing the tutorial's technical checks.

## First-pilot return

The [seed-bench observations](../../experiments/random-definition/seed-bench-001/observations.md) now record a scoped execution and preservation repairs. The human reconstruction remains open. Retain the current hall/particle order; any later import should preserve exact values and distinguish stored replay from new draws. This local pilot does not certify a particle or cross-hall implementation.
