# Particle Tutorial Path: One Mover to an Unfinished System

**Status:** five-hall curriculum proposal; no existing scene or `tutorial.md` has been changed. Based on the placed artifacts in `commons/maps/Particles_*/map_data.json` on the tracked `palm-scanner-door-entry` branch (14 October 2026 review). The five map folders currently contain `blurb.md` and `map_data.json` but no `tutorial.md`.

## Position in the curriculum

Particles already unlock as a branch after Forces in `commons/maps/curriculum_spine.json`. Keep that architecture. The student should arrive with `Vector3`, position, velocity, acceleration, forces, arrays, Node3D, transforms and elementary scene instancing. Revisit exact inherited code by link rather than reprinting every prerequisite. The new content belongs between established vectors/forces and the more exploratory randomness/noise/flow materials.

**Canonical learning loop:** encounter → observation → prediction → one-variable intervention → consequence → reconstruct from a fresh scene → reflect. The last stage may end with a new, unresolved problem instead of a supplied answer.

## P1. A particle has a state (`Particles_SingleAndArrays`)

**Installed anchors:** `example_4_1_single_particle_vr`, `example_4_2_array_particles_vr`, `dark_sphere`, science screen. **Code to inspect:** `algorithms/particles/example_4_1_single_particle_vr.gd`, `algorithms/particles/example_4_2_array_particles_vr.gd`, `core/particle.gd`.

- **Entry action:** follow one coloured mover; identify its position, velocity, acceleration, mass, trail and relevant field. Stop the motion and predict which way it will resume.
- **Exact new operation to teach:** integration through time. Name the time step and distinguish a fixed simulation tick from rendered frame timing. Do not substitute a visually plausible path for the actual update used by the code.
- **Construction:** make one Node3D particle in a separate test scene; initialize state, advance it and render the trace. Then create an array of movers using the same update, with a bounded count and cleanup.
- **Trial:** keep initial position/velocity, change one force or update interval, record final position and trail. Replay with the same implementation before making any stochastic change.
- **Artist's question:** is the particle an individual object, or is its path the visible signature of a field?
- **Verification:** script loads alone, no hidden scene dependencies, reset restores initial state, one-change differences are measured, no unsafe VR paths or controls.

## P2. An emitter is a rule about births (`Particles_Emitters`)

**Installed anchors:** `example_4_3_particle_emitter_vr`, `example_4_4_multiple_emitters_vr`, `example_particle_body`, `sub_emitters`. **Code:** `core/particle_emitter.gd`, example scripts.

- **Entry action:** identify where particles appear and how often. Two apparently similar clouds may have different birth histories.
- **New operation:** encapsulate emission rate, position and initial-velocity assignment; assign lifetime and collect dead particles. Distinguish a birth process from the later dynamics of already-born particles.
- **Construction:** reuse the P1 particle update; introduce one emitter, then two, then a nested/sub-emitter if its source actually supports it. Print or link the complete new emitter code and existing inherited code.
- **Trial:** compare a regular birth schedule with stochastic or burst timing at the same mean rate, once implemented. Save the event schedule if exact replay is required; a saved seed alone may not reproduce variable-frame emissions.
- **Artist's question:** does the identity of a system lie at its origin or in the population it creates?
- **Verification:** bounded counts/memory, reset clears births, Quest-accessible rate controls. The existing example's keyboard-only inputs must not silently become claimed VR controls.

## P3. A field organizes freedom (`Particles_Forces`)

**Installed anchors:** `force_fields`, `example_2_6_single_attractor_vr`. **Later optional bridge:** existing `curl_noise_particles`, currently placed in `Random_Space_Geometry`.

- **Entry action:** stand by the field, predict the particle's next turn, change the force and watch the path.
- **New operation:** apply a force to mass, integrate acceleration, and show where state persists. Start with a fixed direction or attractor before introducing stochastic impulses.
- **Construction:** build one effect each from constant force, attractor and optional flow-field lookup. A local field may be entirely deterministic even if made from seeded noise.
- **Trial:** same particles at the same locations; compare (A) fixed force, (B) independent random impulses, (C) spatially coherent field, and optional (D) curl field. Label (B–D) as proposed comparison modes until code exists.
- **Artist's question:** how does a rule governing every particle resemble a landscape? Where can the particle refuse it?
- **Verification:** correct coordinate frames and units; preserve initial state; numerically measure deviations; use Quest-safe movement and visual scale.

## P4. The population outlives its members (`Particles_LifetimeAndTypes`)

**Installed anchors:** `example_4_5_inheritance_polymorphism_vr`, `lifetime_curves`, `particle_systems`.

- **Entry action:** follow a single particle from birth to death, then notice the apparently continuous system that persists.
- **New operation:** a base Particle class, a typed behavioural variation, life-cycle evaluation, removal and pooling or equivalent bounded memory. Introduce curves only after a linear lifetime is understood.
- **Construction:** link to the audited core/particle.gd, show one exact subclass or replaced method, test two lifetime laws; for the GPU demonstration, explain that a high-particle-count effect is not necessarily reconstructed line-for-line from the CPU lesson.
- **Trial:** keep birth rate fixed and alter lifetime distribution. Compare live counts over time and the visible density of the system.
- **Artist's question:** what is the work's enduring object: a particle, a shape, or the continual replacement of a population?
- **Verification:** no runaway particle counts, clear mortality/removal method, proper attribution to Nature of Code material, performance and replay limits declared.

## P5. A recognizable fire that might cease to be a fire (`Particles_Collision`)

**Installed anchors:** `example_4_6_particle_repeller_vr`, `particle_campfire`.

- **Entry action:** encounter repulsion/boundaries; stand near the flame and distinguish smoke, sparks and embers by trajectories rather than by colour alone.
- **New operation:** repulsion/collision and the combination of force, emission, lifetime and appearance into a material-seeming phenomenon.
- **Construction:** reassemble the fire from previously learned elements. Inspect current implementation before promising collision accuracy or interactivity; explain what is an effect, what is simulated physics and what is merely a renderer.
- **Trial:** change gravity, drag, spawn pattern or lifespan singly until the fire no longer looks like a fire. Preserve the settings and compare the changed result with the starting display.
- **Artist's question:** who decided which arrangement of moving points deserves the name 'fire'? What further phenomenon could the same operations support?
- **Verification:** isolate emitter contributions, ensure visible/reachable controls, capture an actual Quest walk. A surprising failure may be saved as a research question rather than labelled a pedagogical mistake.

## Companion experiments, not new mandatory halls

**X1 — Randomness enters the population.** In or after P2, compare deterministic birth schedules, seeded stochastic birth schedules and a freshly captured OS-backed random seed. Never present a hash of tracked hand movement or GPU timing irregularity as validated entropy. Keep one event log to test exact replays.

**X2 — Noise directs the population.** Link P3 to `Random_Space_Geometry` and `Noise_Space_10`. Reuse `curl_noise_particles`; contrast independently drawn impulses with spatially correlated direction fields and, when validated, curl flow. Preserve the same initial position set, bounded simulation time and a measured comparison of path curvature/dispersion. `particle_field_comparator` is a **proposed** artifact, not an installed one.

**X3 — The rules become negotiable.** A later speculative experiment may allow particle birth, identity, collision response or the available force types themselves to change. This is a state-space/grammar investigation, not just a higher-entropy emitter. Hold one piece of the old system constant to see what the revision actually permits.

## Tutorial / final / field-note split

**Tutorial.md:** code inheritance, complete new method, testable prediction, measurement, cold reconstruction and diagnostics. **Final.md:** bodily encounter, historical associations, unstable relation, odd unplanned consequences and an open question. **Field notes/learning debt:** verified observation, source/version, unresolved inference, AI/human contribution and a next experiment. Do not force the literary passage to pretend to know an experiment whose result has not happened.

## Acceptance test common to all five tutorials

The ghost student receives only previous linked lessons and this lesson. They can create the example in a new Godot project or clean scene, produce the claimed effect, make one intervention, compare, reset and articulate the result. A source-only success is not headset usability: run scene load tests, actual VR controls/visibility, frame-time and motion comfort checks separately. Record failures with source paths and exact reproduction steps. Adapted Nature of Code examples should retain their source and license notices.
