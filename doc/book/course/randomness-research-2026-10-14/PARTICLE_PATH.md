# A particle learns to become a system

**A proposed tutorial path, not seven completed runnable lessons.** This specifies what each lesson must let someone make, investigate and carry. Full printed programs, exact continuation edits and their evidence are implementation tasks. All five existing particle halls currently have map data and a blurb but no `tutorial.md`, `technical.md` or `final.md` in the inspected folders.

The sequence currently orders Single/Arrays → Emitters → Forces → Lifetime/Types → Collision. Proposed order: **Single/Arrays → Emitters → Lifetime/Types → Forces → Field Lab → Collision → Rule Workshop**. Moving lifetime earlier makes birth, persistence and retirement understandable before adding more motion laws. Field Lab is one new particle hall. Rule Workshop is shared with the main research route.

The particle sequence is a declared branch from Forces in the curriculum spine, but it is absent from the current Endless Museum chapter declaration and live plan. Route integration is a task, not an already-working portal. Its sequence metadata also names vectors as its unlock requirement; reconcile those two entry descriptions during integration.

## The object that continues

Bring the familiar point from the earlier course and give it explicit state: stable ID, position, velocity, accumulated force, mass, birth tick, age and lifetime. Later add emitter ID, kind, parent IDs, boundary policy and a versioned relation rule. Rendering is a view of that state. Keeping a picture is different from keeping enough state to continue it.

The first learner model should be deliberately small. The production scenes already include `Particle`, `ParticleEmitter`, confetti, MultiMesh renderers, a particle-body generator, force fields, lifetime displays, fireworks and a campfire. They are useful comparisons. They also contain global draws, wall-clock animation, per-update damping and differing input conventions. Importing those classes without explanation would hide precisely the conditions this path needs to expose.

Use the project's MAKE / BRING / GIVEN / BUILD / CHECK / LATER reconstruction contract. Print the initial small program once; thereafter provide exact edits and a complete downloadable resulting program. Mark every incoming program as a tested preceding output or an explicit starting assumption. The proposed fixture is not a real student's portfolio.

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

**CHECK:** A declared rate over a declared duration produces the specified scheduled count with the boundary convention stated. Changing emitter B does not consume A's stream. Moving the emitter leaves old world-space particles unchanged. At capacity, skipped births are counted. REPLAY restores the accumulator and next ID as well as the seed. The distribution-hall transfer changes future births, not existing state.

**INVESTIGATE:** Use the same recorded births with two origins, or two origins with matched laws. What belongs to the source and what belongs to the released particles? Change one, not both, for the first comparison.

**CARRY:** P2, emission schedule, per-source state, birth records and the chosen cap policy.

**LATER:** Poisson timing and exponential waits as separate extensions; firing an event at a jittered interval is not automatically a Poisson process. Defer recursive children until parent identity and lifetime exist.

## P3 · A population persists while members leave — Particles_LifetimeAndTypes

**MAKE:** Lifetime-dependent appearance and two kinds that respond to the same update interface.

**BRING:** P2, birth records, age and retirement.

**GIVEN:** `lifetime_curves`, the mixed particle/confetti scene and the existing particle-system display. Their “species” language is an artistic description, not evidence of biological evolution.

**BUILD:** Normalized age from age/lifetime with a defined zero-lifetime policy. Map age to size/opacity using a selected curve. Keep appearance mapping distinct from dynamics and death. Add a second behaviour through a clear update interface; explain whether this uses a dictionary tag, composition or a class. Add one bounded parent→children event only as a follow-on, with generation depth and population budget recorded.

**CHECK:** Changing an appearance curve preserves particle positions and RNG state. Extending lifetime changes retirement but not the original births. Simultaneous deaths do not skip entries. Children are emitted once per parent-death event; depth/count limits stop recursive growth. A held parent/child record survives reset.

**INVESTIGATE:** Can two populations look stable while their turnover differs? Keep births fixed, vary lifetime, and observe occupancy. Then ask whether visual persistence is the same as individual persistence.

**CARRY:** P3, lifetime/curve definitions, kinds and optional parentage.

**LATER:** Genetic inheritance, selection and self-modifying categories. A code subclass is not an evolutionary lineage.

## P4 · A force is a relationship — Particles_Forces

**MAKE:** A population under a visible, movable, bounded force field.

**BRING:** P3 and force/mass from the earlier course.

**GIVEN:** `force_fields` and `example_2_6_single_attractor_vr`; a hand target and desktop equivalent. An adapter records target position in the apparatus's local coordinates, including under rotation/scale.

**BUILD:** Apply a selected acceleration/force law to every particle from the old state, then integrate once per tick. Distinguish a force integrated into velocity from a field directly assigned as velocity. Define distance clamping and behaviour at zero distance. Use recorded hand positions for replay. If damping is added, state a per-second law or fixed-tick convention rather than inheriting frame-dependent drag unnoticed.

**CHECK:** Zero force, reversed direction, declared mass response and coincident positions produce finite expected behaviour. A rotated/scaled host uses correct coordinates. Replaying the recorded target trace repeats the tested state. A stationary target and an animated fallback are visibly different input modes.

**INVESTIGATE:** Keep the same births and initial conditions while moving only the attractor. Which trajectories are captured, pass by or leave? The apparatus should let a visitor retain a counterexample to an attractive explanation.

**CARRY:** P4 plus force law, target trace, coordinate convention and integrator settings.

**LATER:** Fluid simulation and pair forces. Do not call a passive particle cloud a swarm with sensing/decision rules.

## P5 · What the field asks of a moving point — Particles_Field_Lab (new)

**MAKE:** A controlled comparison between independent kicks and transport through a saved coherent field.

**BRING:** P4, Random Walk, and the field/address/receiver distinction from Geometry and Noise One. This is the point where an early Forces visitor returns after learning the randomness/noise material.

**GIVEN:** The existing `curl_noise_particles` as a comparison after its claims and replay path are corrected; `related_weather` as prior art for distinct raw, accumulated and filtered records. A frozen field is the first required case.

**BUILD:** Use the same retained births in both comparisons. Define the stochastic kick distribution and tick scaling; distinguish an authored discrete random walk from a numerical approximation to Brownian motion. Define the field's vector interpretation explicitly. A scalar-noise input needs a named adapter. Keep field animation time separate from simulation time. Add boundary modes one at a time. Reuse a single local stream for all stochastic respawns in the bounded comparison.

**CHECK:** Querying a static field twice at the same address returns the same value without spending a draw. Changing display colour does not move a particle. Replay includes field phase and boundary events. A finite-difference curl construction needs a numerical divergence investigation with stated tolerances and domain; do not infer global incompressibility or nonintersection from the label. Random respawn is recorded and never described as wrapping.

**INVESTIGATE:** Keep initial conditions and a frozen field. Change only the receiver from direct velocity to force. Then restore that baseline and change spatial scale. Which difference reorganizes the paths? Smooth motion alone does not answer whether randomness was sampled during the run.

**CARRY:** P5, field record, receiver mapping, kick/respawn records and boundary counts. X3 connects the research route to this lab.

**LATER:** Time-varying fields, exact Brownian limits, higher-order integration and GPU scale. A GPU version must declare which replay guarantees remain meaningful; [Godot's fixed-seed particle controls](https://docs.godotengine.org/en/4.6/classes/class_gpuparticles3d.html) do not by themselves prove cross-device identity.

## P6 · What stops, leaves or passes through — Particles_Collision

**MAKE:** A comparison of boundary policies and one explicit repulsion/collision operation.

**BRING:** P5 and the same population/field state.

**GIVEN:** Existing hand repeller with selectable force laws and particle collision, plus `particle_campfire` as a composition to investigate.

**BUILD:** Compare absorb, reflect and periodic wrap with the same incoming trajectory. State the actual surface and contact rule. Keep repulsion from a field separate from pair collision. Introduce one two-particle contact case before a population. Capture hand input, event order and contact-policy version. Record deaths, exits, bounces and births separately.

**CHECK:** Defined single-axis reflection reverses the expected component; wrapping preserves particle identity; absorption retires exactly once. Two simultaneous contacts and zero separation remain finite. Pair-update order is deterministic in the declared reference implementation. The test must expose any energy gain/loss the chosen collision approximation permits. Keep a small tested budget before scaling a quadratic pair loop.

**INVESTIGATE:** Can the same emitter appear to produce a different community because of what the boundary lets leave? Then compose a small fire/smoke/ember study from known rules and state where it is a visual model rather than combustion physics.

**CARRY:** P6, boundaries, event log and a retained composition. X6 carries a selected population to the workshop.

**LATER:** Full fluids, combustion, arbitrary rigid-body replay and physical cloth.

## P7 · The particle can acquire a new relation — Random_Rule_Workshop (shared)

**MAKE:** One bounded rule revision with a preserved predecessor and a consequence that can be compared.

**BRING:** P6, stable identity, records and explicit relationships. A visitor coming from the grid route can use the same sixteen-entity example without completing every particle exercise.

**GIVEN:** The shared rule bench, drawing support inspired by `ParticleBody`, and a visible link between old and revised experiments. Current `ParticleBody` links are geometry; coupling forces, persistent bonds and role changes are new work. Its DELAUNAY mode currently delegates to nearest neighbours and must not be taught as a Delaunay implementation.

**BUILD:** First allow two particles to connect under a declared rule while keeping original random samples fixed. Retain IDs and rule version. Then distinguish a drawn link from a force-bearing bond. Choose one reversible relation edit—detach, connect, or turn a particle into a sensor. A new state space is demonstrated through a stated previously-unavailable relation, not merely through new colours. Rollback returns to the retained predecessor without erasing its child experiment.

**CHECK:** The old rule cannot produce the selected relation under the stated fixture; the new one can. Replaying either version retains the same input record and appropriate rule. Removing an entity removes/reports its connections; unknown roles are not silently discarded. A saved parent stays intact. Independently reconstruct the small revision from the tutorial.

**INVESTIGATE:** Does the new relation matter to the visitor's question? A connected cluster may be awkward, boring or unstable. Keep that outcome. Let its observation produce the next proposed edit. The imagined sleeve is one possible question, not a compulsory endpoint.

**CARRY:** A parent/child experiment pair, rule difference, observation and next question. Return to the seed bench or take the qualified QFEP Sandbox link.

**LATER:** General grammar editing, bodily garments, evolutionary rule search and autonomous AI rewriting. Each needs its own declared experiment.

## Verification and learning time

At every stop, use the agreed seven-step cycle and keep three evidence levels: artifact correctness, the complete experiment cycle, and only the cross-hall links promised by design. Record scene/runtime/performance/headset evidence separately. The field laboratory does not pass because its particles look beautiful; a technically accurate display also does not pass the cycle until someone can compare, retain, replay and reconstruct its outcome.

AI can propose the next edit, supply an explanation or help with reconstruction. Record the assistance rather than requiring unaided typing as proof of learning. Ask the person to predict a change, inspect what occurred and identify what the program still cannot express. The result may be a sharper question instead of a completed answer.

The source lineage includes Daniel Shiffman's [particle-system work](https://natureofcode.com/particles/) as acknowledged by the existing scenes. Preserve those attributions when adapting code. The seven-stop design, experiment records and proposed rule workshop are this proposal's additions; they are not claimed as existing source behaviour.
