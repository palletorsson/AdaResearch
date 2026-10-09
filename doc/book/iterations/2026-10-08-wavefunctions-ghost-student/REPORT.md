# Wavefunctions — a ghost student goes through the sequence

**All twelve printed studies ran successfully from newly extracted files. The sequence holds as a continuation of the earlier spine. The main remaining work is reducing reading friction, especially around audio.**

This is a same-assistant ghost-student simulation. I had already read and helped develop the material and its tests. It is a fresh reconstruction and an executable reading, not a blind learner study. A prepared Endless Museum project supplies XR Tools, player, camera, light and floor. These are not standalone empty-project examples.

## What was tested

- Read the twelve current `tutorial.md` and `final.md` pairs in spine order. Each tutorial matched the review ZIP.
- Extracted all **32 complete printed listings** into new hall folders; no production lesson script filled a missing dependency.
- Saved predictions before the fresh run. Reconstructed the six companion exercise versions required by the existing checks, plus a new variation for every hall.
- Ran the existing teacher-authored checks against the extracted files: **334 assertions passed across 12 halls**.
- Executed the new twelve-hall variations: **37 checks passed**, after correcting one faulty test assertion described below.
- Deliberately broke three rules. All three were rejected for the intended reason: mixed old/next state, a score redrawn during replay, and unsigned harmonic contributions.
- Loaded the extracted opening, Effect Sound and Synthesis programs inside the actual Endless Museum: **223 checks passed across those three representative halls**. Captured and inspected their images.

No lesson-code or manuscript correction was needed to run the required examples. The 24 canonical manuscripts remain unchanged. This run does not certify human understanding, audible timbre, headset comfort, all twelve placements afresh, or continuous travel through every portal. Audio ran through Godot's Dummy driver; sample data and playback/contact behaviour were checked rather than listened to.

## What the student can carry

The continuity is in objects **and operations**. The cube carries a prescribed return into a measured swing and later becomes a tread. PointBody returns as a physical ball, an ungrabbable marker, a hand control and several independent controls. Those role changes are declared. Trace's recorded list becomes timestamped history and later an event score. The final sum extends two named contributions into a list and loop.

This is not one script receiving an extra function in every room. It is a set of related studies in the same prepared world, reusing known constructions. That distinction should remain explicit. No new order is needed on the evidence of this run: Bernini and Sky Stairs are deliberate returns to spatial construction, and Cage interrupts periodic expectation with retained choices. The transitions now explain those turns.

## Where I would improve the teaching next

1. **Guide the first reading through functions.** Pendulum jumps from 33 to 107 main-script lines. Its swing, recorder and display deserve three distinct reading passes. Effect Sound and Air Music need an equally clear core-operation route before their encoding and display support. Keep complete code available; do not shorten it into an incomplete example.
2. **Separate prediction from the answer.** Many useful predictions are immediately followed by their results. For a stronger learner test, collect the prediction before revealing the explanation, then ask for another parameter choice. This run's edited versions demonstrate executable possibilities, not that an unassisted reader discovered them.
3. **Make the learner study easier to identify in the museum.** The fresh opening capture contains background orbital labels, and the Synthesis readout is small against other exhibits. Existing objects need not be removed. A quiet display backing and nearby readable instructions are candidates for a separate visual pass.

The reflective texts continue to do their own work: they ask what a record omits, what support a drawing promises, what chance can select and what restoring a recipe cannot restore. They should not become another copy of the implementation explanation. Several exact distinctions in the tutorials give those questions something to rest on.

## First-run failure: the test was wrong

The first transfer run passed 36 of 37 checks. My Air Music assertion expected sample 60 from `int((60.0 / 44100) * 44100)`. In this run the floating-point result truncated to **59**. The lesson's sample lookup behaved as written; the checker assumed exact arithmetic at a bin boundary. The measured sum was −0.1295205542 instead of the checker's −0.1334269234.

I preserved [the first result](transfer-first.json), [its log](transfer-first.log) and [the original checker](transfer-first-probe.gd). The corrected check chooses ages inside the intended bins, at 60.25 and 180.25 samples. [The corrected result](transfer-corrected.json) passes all 37 checks and records the boundary diagnosis. No lesson code was altered to make the test pass. An earlier Python setup guard also needed newline-normalized hashing on Windows; it failed before Godot execution and did not change the saved predictions.

## Scope of the engine results

The museum runs still log an unrecognized project UID; Effect Sound also logs two ViewportTexture setup errors from the existing environment. No GDScript parse or runtime script error was reported, and the nominated checks passed. These logs are retained: a passing lesson is not a claim that the whole project has no warnings or errors. The rendered captures show the learner studies in the real halls, not substitute rooms.

## Hall-by-hall reading

### 01. Cube

**Carries:** Time → position; inherited cube. **Read/change:** height_at; amplitude, frequency, phase.

The smallest entry works: 33 lines, all objects initialized. A photograph of the middle cannot distinguish rising from falling; the reflection gives a reason to inspect phase.

**Attention:** Make the second-cube prediction before consulting the supplied table. A successful copy alone does not demonstrate that distinction.

**Before execution:** Amplitude .25, frequency .25, phase PI/2: start at 1.55 m; bottom 1.05 m at 2 s; period 4 s.

**Result:** 23 existing checks + 3 new transfer checks passed. Main program: 33 lines; complete listing with helpers: 33 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_Intro/tutorial.md) · [Reflection](packet/WaveFunctions_Intro/final.md) · [Reconstructed main script](attempt/WaveFunctions_Intro/01_cube_return.gd) · [Changed version](attempt/WaveFunctions_Intro/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_Intro/teacher-checks.json)

### 02. Pendulum

**Carries:** Forces integration + Trace → timestamped observations. **Read/change:** _physics_process; Sample; display_position.

The 20-slot variation retained 1.9 seconds after eight simulated seconds. The swing was unchanged. Data, retention policy and drawing can be varied separately.

**Attention:** First density jump: 33 to 107 main-script lines. Read the swing update, then the record, then the drawing in three passes; do not treat all three as equally new.

**Before execution:** Sample every .1 s with 20 slots: after 8 s about 1.9 s retained; swing unchanged. Halving trail speed halves drawn depth, not stored positions.

**Result:** 36 existing checks + 3 new transfer checks passed. Main program: 107 lines; complete listing with helpers: 107 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_Pendulum/tutorial.md) · [Reflection](packet/WaveFunctions_Pendulum/final.md) · [Reconstructed main script](attempt/WaveFunctions_Pendulum/02_pendulum_record.gd) · [Changed version](attempt/WaveFunctions_Pendulum/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_Pendulum/teacher-checks.json)

### 03. Sine Space

**Carries:** Grid + faces + carried physical PointBody → a contact surface. **Read/change:** height_at; row/column indices; the mesh used for collision.

Separate X and Z frequencies produced different spatial periods without changing connectivity. The code and text distinguish static terrain from a wave moving in time.

**Attention:** Retain the explicit finite-sheet limitation: the ball may roll off. The broad walkable museum basin is a separate, larger encounter.

**Before execution:** Separate spatial frequencies: X=.5 and Z=1. At (.5,.25), height=.98; at (0,.25), .8. X repeats over 2 m, Z over 1 m. Still 289 positions and 512 faces.

**Result:** 25 existing checks + 3 new transfer checks passed. Main program: 61 lines; complete listing with helpers: 85 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_Sine_Space/tutorial.md) · [Reflection](packet/WaveFunctions_Sine_Space/final.md) · [Reconstructed main script](attempt/WaveFunctions_Sine_Space/03_sine_surface.gd) · [Changed version](attempt/WaveFunctions_Sine_Space/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_Sine_Space/teacher-checks.json)

### 04. Unit Circle

**Carries:** One angle → circle coordinates and graph coordinates. **Read/change:** circle_position; graph_position; one shared angle.

Changing radius, centre and angular speed preserved the shared height and the independent four-metre angle axis.

**Attention:** The lesson comes after using sine. This works as a return that opens an already-used function; it should not be sold as the first-ever introduction to sine.

**Before execution:** Radius .6, centre (-.4,1.6,0), angular speed PI: top (-.4,2.2,0) at .5 s. Circle period 2 s; graph axis stays 4 m.

**Result:** 26 existing checks + 3 new transfer checks passed. Main program: 75 lines; complete listing with helpers: 131 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_Unit_Circle/tutorial.md) · [Reflection](packet/WaveFunctions_Unit_Circle/final.md) · [Reconstructed main script](attempt/WaveFunctions_Unit_Circle/04_circle_coordinates.gd) · [Changed version](attempt/WaveFunctions_Unit_Circle/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_Unit_Circle/teacher-checks.json)

### 05. Propagation

**Carries:** Forces + arrays → neighbour coupling. **Read/change:** reset; step; old and next arrays.

The first step matched a hand calculation. Reversing iteration for 120 steps preserved the result; an in-place mutation failed. This is a substantial new capacity.

**Attention:** Keep the numerical timestep and boundary explanation. A wave-shaped animation is not evidence of coupling; the reflection asks exactly the useful question.

**Before execution:** Seven points; initial centre .3 m. At dt=1/60, centre velocity=-.14 and displacement=.2976667; adjacent displacement=.001, next neighbour zero. Reversing traversal with separate next arrays preserves results.

**Result:** 28 existing checks + 3 new transfer checks passed. Main program: 79 lines; complete listing with helpers: 135 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_3D_Wave_Propagation/tutorial.md) · [Reflection](packet/WaveFunctions_3D_Wave_Propagation/final.md) · [Reconstructed main script](attempt/WaveFunctions_3D_Wave_Propagation/05_neighbour_motion.gd) · [Changed version](attempt/WaveFunctions_3D_Wave_Propagation/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_3D_Wave_Propagation/teacher-checks.json)

### 06. Effect Sound

**Carries:** Oscillation + the carried hand control → phase-modulated audio. **Read/change:** phase_depth; sample_at; reference versus captured comparison.

Changing the ratio to 1.5 preserved all zero-depth bytes and changed the positive-depth sound data. Both retained 26,460 samples. The fresh museum study loaded and accepted its action.

**Attention:** Highest conceptual load: modulation, envelopes, PCM bytes, asynchronous playback and plotting coexist. The text already identifies the core and supplied encoder. Protect that distinction in layout; do not require mastery of every support function.

**Before execution:** Ratio 1.5: modulator 660 Hz. Zero-depth sample bytes unchanged from ratio 2; positive-depth bytes differ. Length and amplitude limits unchanged.

**Result:** 31 existing checks + 3 new transfer checks passed. Main program: 96 lines; complete listing with helpers: 152 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_Effect_Sound/tutorial.md) · [Reflection](packet/WaveFunctions_Effect_Sound/final.md) · [Reconstructed main script](attempt/WaveFunctions_Effect_Sound/06_phase_note.gd) · [Changed version](attempt/WaveFunctions_Effect_Sound/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_Effect_Sound/teacher-checks.json)

### 07. Bernini

**Carries:** Unit Circle + face lists → a turn distributed through height. **Read/change:** ring_position; rebuild; separate parent rotation.

The taller twelve-corner shaft produced 206 positions and 408 faces. Triggered rotation changed its pose without rewriting stored geometry.

**Attention:** The oval profile makes the operation legible. The reflection can ask what the gallery contributes without making mathematical generation explain the whole architectural reference.

**Before execution:** Height 3.6, twelve corners: 206 positions and 408 faces. Half-height corner (0,2.05,-.4), top (-.4,3.85,0). Rotating the parent leaves stored positions intact.

**Result:** 39 existing checks + 3 new transfer checks passed. Main program: 116 lines; complete listing with helpers: 172 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/Wavefunctions_Bernini/tutorial.md) · [Reflection](packet/Wavefunctions_Bernini/final.md) · [Reconstructed main script](attempt/Wavefunctions_Bernini/07_twisted_shaft.gd) · [Changed version](attempt/Wavefunctions_Bernini/transfer.gd) · [Runtime receipt](evidence/Wavefunctions_Bernini/teacher-checks.json)

### 08. Cage

**Carries:** Recorded observations → a retained event score. **Read/change:** new_score; replay; elapsed time and cursor.

A .75-second interval produced six cumulative timestamps. A late frame dispatched four overdue events in order. Replay preserved the score and RNG state.

**Attention:** This is a bounded introduction to chance before Randomness. Keep the focus on choosing once versus replaying; do not expand it into distributions here.

**Before execution:** Both intervals .75: six times .75,1.5,2.25,3,3.75,4.5. Replay leaves voice choices and RNG state unchanged; late dispatch retains order.

**Result:** 30 existing checks + 3 new transfer checks passed. Main program: 115 lines; complete listing with helpers: 199 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_John_Cage/tutorial.md) · [Reflection](packet/WaveFunctions_John_Cage/final.md) · [Reconstructed main script](attempt/WaveFunctions_John_Cage/08_chance_score.gd) · [Changed version](attempt/WaveFunctions_John_Cage/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_John_Cage/teacher-checks.json)

### 09. Air Music

**Carries:** Contact events + recorded audio → independent voice lifetimes. **Read/change:** _on_contact; ages_now; sum_at.

Real sphere-area contacts started two equal-pitch voices at different ages. The first continued when the second began. Same sound data did not imply one shared clock.

**Attention:** Nearly 200 printed lines including helpers. Read contact and voice ownership first, then the scope. The plain decaying sine does not model metal resonance; the revised text states that correctly.

**Before execution:** Both bars 392 Hz: same sample bytes, but separate starts. Touching bar 1 after bar 0 must not restart bar 0. Equal pitch is not shared age.

**Result:** 21 existing checks + 3 new transfer checks passed. Main program: 109 lines; complete listing with helpers: 198 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_AirMusic/tutorial.md) · [Reflection](packet/WaveFunctions_AirMusic/final.md) · [Reconstructed main script](attempt/WaveFunctions_AirMusic/09_contact_voices.gd) · [Changed version](attempt/WaveFunctions_AirMusic/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_AirMusic/teacher-checks.json)

### 10. Sky Stairs

**Carries:** Cube + sampled coordinates → support. **Read/change:** sample_position; tread transform; matching shape dimensions.

Constant radius with a new rise gave top heights 0, .75 and 1.5 m. Tread transforms matched sampled tops. Existing teacher checks also exercised physical contact.

**Attention:** This study proves construction, not a comfortable climb. The reflection productively distinguishes a visible invitation from bodily access. Keep the step controller outside the promised lesson.

**Before execution:** Constant radius 2.5 and rise .15: eleven centres on the same circle, tops 0,.75,1.5 at indices 0,5,10; collider tops match. No claim that this proves player ascent.

**Result:** 25 existing checks + 3 new transfer checks passed. Main program: 70 lines; complete listing with helpers: 102 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/Wavefunctions_Sky_Stairs/tutorial.md) · [Reflection](packet/Wavefunctions_Sky_Stairs/final.md) · [Reconstructed main script](attempt/Wavefunctions_Sky_Stairs/10_sampled_treads.gd) · [Changed version](attempt/Wavefunctions_Sky_Stairs/transfer.gd) · [Runtime receipt](evidence/Wavefunctions_Sky_Stairs/teacher-checks.json)

### 11. Beats

**Carries:** Independent waves → a signed sum and relative phase. **Read/change:** values_at; candidate_frequency; restart_pair; plot gain.

The 6 and 5.75 Hz variation cancelled after two seconds and reinforced after four. It retained the envelope period despite different source rates.

**Attention:** The half-gain label matters: an equally tall picture need not represent equal raw amplitude. Return explicitly to Air Music after the spatial stair interlude.

**Before execution:** A=6 Hz; initial point Y=.95 selects B=5.75. Envelope period 4 s, cancellation after 2 s. Raw source sum and display gain stay distinct.

**Result:** 24 existing checks + 3 new transfer checks passed. Main program: 94 lines; complete listing with helpers: 150 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_TrigWalkingPath/tutorial.md) · [Reflection](packet/WaveFunctions_TrigWalkingPath/final.md) · [Reconstructed main script](attempt/WaveFunctions_TrigWalkingPath/11_two_cycles.gd) · [Changed version](attempt/WaveFunctions_TrigWalkingPath/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_TrigWalkingPath/teacher-checks.json)

### 12. Synthesis

**Carries:** A two-wave sum → a list of harmonic contributions. **Read/change:** contribution; sum_at; duplicate baseline; shared phase.

The new odd recipe gave .5 at PI/2. Removing H3 raised it to 1. Restoring baseline preserved phase and hold. The fresh museum reconstruction also passed.

**Attention:** The finite visual instrument completes the required tutorial. Audible synthesis and Room Memory remain extensions. Small labels and a busy background deserve a separate visual refinement; no need for another mandatory concept.

**Before execution:** Recipe [1,0,.5,0,0]: at PI/2 signed sum=.5. Half-cycle sign reverses. Removing H3 raises the sum to 1. Baseline restores recipe without restoring phase.

**Result:** 26 existing checks + 4 new transfer checks passed. Main program: 103 lines; complete listing with helpers: 159 lines. These are scope counts, not learning scores.

[Printed tutorial](packet/WaveFunctions_Synthesis_Lab/tutorial.md) · [Reflection](packet/WaveFunctions_Synthesis_Lab/final.md) · [Reconstructed main script](attempt/WaveFunctions_Synthesis_Lab/12_five_amounts.gd) · [Changed version](attempt/WaveFunctions_Synthesis_Lab/transfer.gd) · [Runtime receipt](evidence/WaveFunctions_Synthesis_Lab/teacher-checks.json)

## Evidence and continuation

[Predictions before the run](predictions-before.md) · [Source manifest](manifest.json) · [All existing-check results](regression-results.json) · [New variation results](transfer-corrected.json) · [Deliberate faults](mutation-results.json) · [Verification](verification.json)

Keep the current sequence and its required studies. The next useful evidence is an unfamiliar reader recording predictions and reconstruction difficulties without access to these answers, followed by a headset visit for the physical comparisons. The current exercise confirms that the printed construction can support that test; it does not replace it.
