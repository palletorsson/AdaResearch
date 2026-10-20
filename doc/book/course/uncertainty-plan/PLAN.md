# When the rule meets its conditions

**Working plan · 8 October 2026; updated 9 October · Endless Museum**

Keep the existing 25-sequence order. Thread these questions through objects the student already knows: **the point, its trace, the cube, the array, the field and the saved state**. Each return changes one condition under which the object works. We do not need six new sequences, or a new failure lesson in every hall.

The progression is: **construct → compare → measure a difference → follow a consequence → question the contract → compose with what remains**.

P1, P3 and P4 are now built; P2, P5 and P6 remain proposed additions. The later authorised geometry-noise, pendulum and observation experiments are recorded as built below; the spine and agreed primary tutorial subjects remain intact. The CA history work completed alongside the original audit is a separate continuation of the existing lesson. Edit this file to change the plan; regenerate its reading page with `python -X utf8 tools/build_uncertainty_plan.py`. The [sequence checklist](SEQUENCES.md), [source audit](INVENTORY.md) and [machine-readable inventory](inventory.json) are companions.

## 9 October extension: noise testing

The later geometry-noise brief authorises a first built experiment, **G0: The Uncertain Surface**, in the Noise opening. Its [noise-testing extension](NOISE_TESTS.md) records G0, G1 and G2 as built, with P1/P3/P4 built and P2/P5/P6 still proposed. P1 is the separate time-step comparison in Launch. The [museum report](../../iterations/2026-10-09-geometry-noise-test/index.html) records its own evidence.

## 9 October extension: camera image becomes body

**Built, optional Shader_05_Patterns study:** one real museum camera and ten declared image/receiver treatments. The original pattern lesson remains. This prepared P4, now built as the optional READ RECORD bank in the same apparatus. The four earlier studies pass 164 fresh checks. [Ten native views and validation](../../iterations/2026-10-09-camera-image-becomes-body/index.html).

**Pixel extension:** the same apparatus now also offers ten operations on a flat screen: chopped bands, wrong row width, repeated scanlines, block permutation, channel offsets, tearing, saved/live blocks, quantisation, missing blocks and reversed rows. PIXELS / FORM selects the bank. [Pixel views and current validation](../../iterations/2026-10-09-cut-the-image-pixels/index.html). This remains one camera study. P4 now adds a saved RGB8 record, receivers and explicit decoding checks.

## What changes in the supplied proposal

| Family | Recommended teaching home | Earlier encounter / later return |
|---|---|---|
| Numerical error and instability | **Forces: VFM_05_Launch**, after the velocity/integration preparation in Change | Change already compares finite sums. Return in Form Finding and Soft Bodies. Separate integration error, floating-point error and genuine dynamical sensitivity. |
| Feedback | **WaveFunctions_Synthesis_Lab**, building on a measured mechanical response in Forces | Reuse the spring/point, then the existing audio delay. CA and Swarms return to state influencing later state. Oscillation alone does not establish feedback. |
| Approximation and computation budgets | **Already begins in Primitives; measured in Change; stochastic estimation in Randomness** | Continue through Noise, Shaders and Isosurfaces. Randomness is one method of estimation, not the definition of approximation. |
| Data interpretation and data bending | **Shader_05_Patterns**, after Arrays and Colour | Trace → Grid and CA history already prepare “same record, different use.” Reserve deliberate decoder mismatch for the later crisis return. |
| Fuzzy logic | **ML_Classification, as a small explicit comparison after crisp categories** | Continuous colour and soft CA are preparations, not claims that fuzzy inference has been taught. Fuzzy rules can be hand-authored; they are not automatically learned. |
| Glitch and fault injection | **PostCrisis_Synthesis**, returning to tested earlier objects | Introduce small named boundary cases where relevant. Distinguish a deliberate intervention from a bug, a valid but unwanted consequence, and an intended visual effect. |

The proposed hosts are exact existing maps, not permission to crowd them. Before placing a new bay, inspect the current hall from above and at eye height. Reuse or replace a redundant example before adding floor area. A different host may be selected within the same sequence without changing its teaching contract; record why.

## Keep the distinctions usable

- **Representation error:** a finite mesh or sample grid stands for something else. Coarse does not mean defective or aesthetically inferior.
- **Numerical error:** an implemented calculation differs from a stated reference. A small finite-time discrepancy is not by itself instability.
- **Dynamical sensitivity:** nearby initial conditions separate under the same rule. It is not automatically a floating-point bug.
- **Feedback:** a measured output returns to influence the next input. Name the measurement, return path, gain and any delay.
- **Fuzzy membership:** degree of belonging to an authored set. It is not probability, confidence, a softmax score or permission to classify a person's identity.
- **Data bending:** change how a saved dataset is interpreted or decoded. A channel permutation is a mapping; a declared byte-layout mismatch is a different experiment.
- **Glitch:** a discontinuity relative to a stated expectation or contract. A collapsed stack can be mechanically correct; its unwanted result does not establish an engine error.

Godot's default GDScript scalar float and vector components do not have the same precision. Precision demonstrations must name the actual storage type and engine build; do not destabilise the live museum's coordinates. [Godot: large world coordinates](https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html)

## What is already there

The audit followed the current spine and sequence files into selected map placements, registry entries and source implementations. It is a targeted static audit, not a run of every artifact. The source inventory distinguishes “exists,” “placed in this spine” and “tested.” All 18 selected registry entries, including the newly built G0, G1 and G2, resolve to scene files; several have no placement in the current spine.

Strong material to reuse includes the held sphere's decreasing resolution, the Riemann comparison and held result, the seeded Monte Carlo dartboard, an actual audio delay with feedback, and the Rule 30 history with three receivers.

Four names currently promise more than their source establishes:

1. `euler_drift` draws a genuine explicit-Euler comparison, but its wall is only a mesh. It does not demonstrate a collision detector missing a hit.
2. `numerical_integration` uses velocity-first stepping for its “Euler” path; its exported `time_step` is unused in the update, which uses `delta`. Godot physics is labelled “ground truth,” although it is another numerical system with its own collision response.
3. `fuzzy_cloud` builds hairy spheres. No membership/inference lesson was found in that implementation or in the targeted membership/defuzzification source search.
4. `Shader_10_ReactionDiffusion` loads a shader that expects a previous texture. Its inspected scene and host script do not bind that texture or construct a persistent two-buffer update. The equation's presence is not evidence that the hall runs the claimed simulation.

There is another repair to queue before teaching from `the_threshold_opinion`: its extraction makes beads at sampled edge crossings, not a connected triangle surface. It also replaces negative interpolation denominators with a positive epsilon, misplacing descending crossings. Correct the interpolation and the claim before using it as evidence for marching-cubes accuracy. These are source findings; this proposal does not patch those artifacts.

## Work packages

The numbers identify packages; the execution queue below sets their priority. Neither changes the student's sequence order. Each package has one primary reconstruction. Finish and review its evidence before expanding the next.

### P0 — Establish a trustworthy comparison

**Do first.** Use the [inventory](INVENTORY.md) to record the selected source path, current host map, tutorial paragraph, existing dependencies and known defects. Preserve the current baseline and one independent test case. Correct misleading names/claims only in the selected package's scope; do not bulk-rewrite the corpus.

For every comparison, state what is held fixed, what changes, the unit of the readout, the reference and its limitations. An engine trajectory is not an exact solution. A 4096-sample integral is a numerical reference, not a symbolic proof. A high-resolution mesh is not automatically the true shape.

**Output:** one short lesson contract and baseline receipt per selected experiment. Existing exact-code lesson harnesses provide the format; no new universal framework is required.

### P1 — The same throw, different steps

**Built 9 October in VFM_05_Launch.** The existing registered Euler artifact selects a new step-study child with `lesson:step_study`; one bay beside the launch chamber, all prior works retained. Complete code and explanations are printed in the hall tutorial; three reflective paragraphs extend final.md. 53 native core checks, 51 checks on fresh printed-code reconstruction, two rejected mutations and 22 museum checks pass. The museum checks include endpoint retention after rendered frames, five pointer buttons, the held XRTools step slider and a supported approach. Default small-board geometry remains; its unsupported tunnelling caption is corrected. Physical headset and independent learner tests remain open. [Images, full texts and receipts](../../iterations/2026-10-09-the-same-throw-different-steps/index.html). The contract below remains available for revision.

**Primary host:** VFM_05_Launch. **Carrier:** the familiar point sphere and its saved trace. **Reuse:** `euler_drift`'s constant-gravity formula and geometry; inspect the current launch court before choosing its comparison position. **New work:** an interactive, bounded time-step comparison, not another full physics engine.

The student gives one sphere an initial velocity. A reference arc and a stepped copy begin together. A hand control chooses a simulation step; both are compared at the same simulated time. Coarser steps change the miss. The tutorial reconstructs explicit Euler: update position from the old velocity, then velocity from gravity. It measures distance from the analytical constant-acceleration position. No bounce, drag, engine collision or RK4 is needed in this first test. The existing launch pad remains the bodily encounter with impulse and gravity.

**Reference:** `p(t) = p0 + v0*t + 0.5*g*t*t`. Use a fixed simulated duration T=1 second and steps 1/10, 1/20 and 1/40. For this explicit-Euler case, endpoint error is `0.5*length(g)*T*h`, up to floating-point tolerance. With |g|=9.8, expect approximately 0.49, 0.245 and 0.1225 metres. Do not generalise exact halving to every integrator or force.

**Pass:** three measured errors match the formula; the finer trajectory reduces error in this fixture; changing display-frame cadence does not alter the step sequence; replay reproduces it; the trace budget stays bounded; old snapshots remain intact. Also assert the signed vector difference: `p_euler(T) - p_reference(T) = -0.5*g*T*h`. A deliberately velocity-first update must fail this assertion: it produces the opposite vector, although its error magnitude is the same. Test code extracted from tutorial.md, then the actual museum control and capture.

**Reflection:** a trajectory depends on the intervals through which we calculate it. More precision changes a bargain; it does not determine what deserves to be made.

**Carry:** position, velocity, simulation time, trajectory and an explicit reference. **Defer:** spring instability, floating-point cancellation, tunnelling and engine-wide settings. The Nature of Code's integration discussion is a companion, not a substitute for this fixture. [Nature of Code: physics libraries](https://natureofcode.com/physics-libraries/)

### P2 — A response returns

**Primary host:** WaveFunctions_Synthesis_Lab. **Earlier use:** springs in Vectors_Act4b_Oscillation. **Carrier:** one point sphere on a bounded rail. **Reuse:** the sphere, trail and supplied museum controls; the existing `ambient_patch` is the audible companion.

Move a target by hand. The body measures its distance from that target and applies a restoring command. First disconnect the return path, then connect it. Change gain while keeping mass and the step fixed; introduce delay only after the immediate response is legible. Show target, measured position and applied command together. The lesson explains the actual return path; a sine animation with a gain label cannot carry it. Preserve the spring demonstration as a related force law rather than silently calling it a complete PID controller.

**Pass:** an open loop does not respond to the measured error; feedback changes command when error changes sign; zero error/velocity is an equilibrium; two recorded parameter fixtures produce the predicted settling and overshoot; the delay buffer uses past samples; pause/replay reset the buffer as well as position. Visual divergence stays bounded inside the study. For audio, retain the existing limiter and measure the delay/output; do not use uncontrolled microphone feedback.

**Reflection:** correction can sustain motion, suppress it or amplify it. Stability is a chosen relation between a body, a target and what the controller can sense. Fuzzy control and swarm coordination can return to this distinction later.

**Dependency:** P1's clock and state discipline; forces and oscillation already introduced. **Defer:** full PID tuning, transfer functions and every type of resonance.

### P3 — Spend samples, keep the disagreement

**Built 9 October in Randomness_Examples_of_Randomness.** The existing dartboard opts into `lesson:sample_budget`: four budget settings, replay, next seed and eight-seed comparison. Every count is retained; newest 300 marks shown. One local dial and six rectangular buttons replace its earlier controls. 24 core checks, 24 checks on the printed sampler, eight printed-example assertions, two rejected faults and 25 native museum checks pass. The main PointBody tutorial is separately authored and tested; this optional study has its own runnable companion. Physical headset and independent learner review remain open. [Native before/after views, code and receipts](../../iterations/2026-10-09-samples-and-disagreement/index.html).

**Primary host:** Randomness_Examples_of_Randomness. **Carrier:** its existing `monte_carlo_dartboard`; do not add a competing dart estimator. **Earlier forms:** primitive sphere resolution and Change_Intro's Riemann comparison.

Keep a seeded run, increase its sample budget, and compare counts with the estimate. Start from actual uniform samples; the student's hand can choose budget or inspect a sample, but hand-thrown locations must not be presented as independent uniform draws. Then compare several seeds at the same budget. The familiar finite construction has become an estimate with variability.

**Pass:** boundary samples classify correctly; identical seed and draw count reproduce counts; reset rewinds the local random stream; more draws do not promise improvement on every individual step. Use a fixed multi-seed fixture to inspect aggregate error, not a test that every random run converges monotonically. Preserve full counts even when older visible darts are recycled. Pinning this artifact must not reseed neighbouring works.

**Reflection:** confidence can increase while particular results still disagree. Approximation has several sources: mesh resolution, quadrature, random sampling and reduced precision are different choices.

**Carry:** seed, draw count, classification, estimate and measured difference. **Defer:** confidence intervals and Monte Carlo variance reduction until the basic sampling contract is secure.

### P4 — One record, different readings

**Built 9 October in Shader_05_Patterns.** READ RECORD extends the existing camera console with five interpretations of one saved 8 × 8 RGB8 record: RGB/BGR colour, unsigned/signed height and explicit invalid-layout refusal. A declared fixture exposes byte boundaries; source hash remains visible. 37 core checks, 37 printed-code checks, eight printed-example assertions, two rejected faults and 121 native museum checks pass (82 cover the earlier camera study). Optional complete data-core lesson and reflection added to canonical texts; the pattern lesson stays first. Physical headset and independent learner reconstruction remain open. [Native views, texts and receipts](../../iterations/2026-10-09-one-record-many-readings/index.html).

**Primary host:** Shader_05_Patterns, after its repeating-pattern lesson. **Carrier:** one saved 8 × 8 sample array with RGB values. **Reuse:** the array address, colour work and surface comparison. **New work:** two explicit receivers and one controlled reinterpretation.

Keep the original array visible beside a wall image. Read each sample first as colour, then map one channel to height on a small surface. A hand control changes the receiver or channel permutation, not the source array. Only then offer a separately labelled decoder experiment: the same finite byte buffer read as unsigned values or signed values. An encoding assumption has changed. Image-to-sound remains an optional later return.

**Pass:** source hash unchanged by receiver switches; every known sample reaches the declared coordinate/channel; identity mapping reproduces the baseline; a channel permutation is reversible; signed/unsigned fixtures decode expected bytes; malformed layouts are represented by an explicit invalid result inside the study. Do not ask Godot to read out of bounds. Show separate effects of mutation and reinterpretation.

**Reflection:** a record does not arrive with one inevitable body. The receiver gives the values a role, just as CA's one becomes ornament or support.

**Dependency:** Arrays, Colour, local coordinates and shader inputs. **Defer:** actual codec datamoshing and file-format corruption. The existing texture-glitch shader is a visual cousin, not proof that its “memory leak” or “datamosh” names implement those mechanisms.

### P5 — Categories overlap, an action still follows

**Primary host:** ML_Classification, after its crisp comparison; exact footprint remains to review. **Carrier:** the familiar point sphere and a small actuator. **New work:** a minimal hand-authored fuzzy controller. Do not reuse `fuzzy_cloud` as evidence for inference.

Move the point through overlapping “near” and “far” ranges. Display both membership values. Two explicit rules produce action strengths, then combine them into one actuator command. Begin with a zero-order Sugeno example using a weighted average, so the entire calculation can be inspected. Return to the feedback body's target only after this open calculation is understood. Explain that these rules were authored, not trained, and the memberships need not behave like probabilities over exclusive classes. [MathWorks: fuzzy inference](https://www.mathworks.com/help/fuzzy/fuzzy-inference-process.html)

**Pass:** boundary and overlap fixtures produce values in [0,1]; stated rule weights and consequents reproduce the expected output; no-active-rule input has a declared fallback; moving a membership boundary changes only the intended relation; replay is deterministic. Do not call this Mamdani inference or claim that a soft classification score proves fuzzy logic.

**Reflection:** the categories remain decisions even when their borders soften. Begin with distance or load, not a device that claims to measure whether someone is queer, plant-like or human. A later artistic association must remain distinct from the measured variable.

**Dependency:** functions, comparisons, weighted combination, crisp classification; P2 only for the later closed-loop extension. **Defer:** t-norm catalogue, linguistic-rule editors and full defuzzification survey.

### P6 — Reopen an earlier contract

**Primary host:** PostCrisis_Synthesis. **Carrier:** copies of earlier verified studies, initially only CA's saved row and P4's decoder. **Reuse:** existing reset, step, witness and snapshot formats. **New work:** one visible intervention switch per copy.

Run a saved baseline. In a bounded copy, replace a snapshot with an alias, change update order, or choose the wrong declared decoder. Keep the intervention log visible and compare the resulting state with the untouched reference. Restore the contract without deleting the record of the result. The student may keep an unexpected composition while explaining the mechanism that produced it.

**Pass:** the baseline passes its earlier assertions; each fault is detected by a specific invariant rather than a generic “looks wrong”; the intervention affects only its copy; replay reproduces the fault; reset restores baseline state, random stream and buffers. Non-finite arithmetic and invalid-index cases use tagged invalid states. No native memory corruption, renderer race or uncontrolled crash.

**Reflection:** “everything worked and this happened” belongs beside, but is not identical to, a broken contract. Keep Menkman's technological interruptions and Russell's political refusal as distinct reading questions; a malfunction does not establish emancipatory politics. Source and verify any quotations when writing that final.md passage.

**Dependency:** at least two earlier packages with real assertions. **Defer:** a giant glitch room containing every failure, network races, adversarial ML and topology surgery. They can become later studies if a specific question warrants them.

## Execution queue and workload

| Priority | Work | Educational value / felt consequence | Reuse / feasibility | Exit condition |
|---|---|---|---|---|
| 0 | P0 comparison contracts and source claims | Prevents teaching a label as an operation | Very high reuse; documentation plus focused probes | Selected artifact's claim matches actual mechanism |
| 1 | P1 same throw | Clear reference, visible disagreement, carried sphere/trace | High reuse; bounded new interaction | Exact code and native comparison pass; one independent throw |
| 2 | P3 sample budget | Returns to the student's finite sphere and measured area | Very high reuse; existing seeded dartboard | Seed/count contract and independent sample fixture pass |
| 3 | P4 same record | Direct continuation of array, colour and saved trace | High reuse; modest explicit receiver code | Data identity and mapping assertions pass |
| 4 | P2 response returns | Strong bodily encounter; more calibration and timing work | Existing spring/point/audio; medium complexity | Measured control response, bounded display, delay reset pass |
| 5 | P5 overlapping categories | Fills the clearest mechanism gap | New minimal inference core; keep scope small | Hand-computed overlap fixtures and learner variation pass |
| 6 | P6 reopen contracts | Synthesises capacities already earned | High reuse only after earlier receipts exist | Every intervention detected and recoverable |

This queue does not dictate the student's reading order. It front-loads experiments with trustworthy references and strong reusable objects. There is no need to complete all six before continuing the current CA tutorials.

## Every implementation must deliver

1. **A short contract before prose:** existing encounter → inherited object/code → one new operation → changed condition → observable consequence → independent variation → what travels onward.
2. **Three responsibilities:** tutorial.md reconstructs the operation with complete minimal code; final.md follows the encounter and its stakes; the hall can contain additional works with no obligation to turn each into a lesson.
3. **Executable evidence:** extract the printed code; load it inside the declared museum host; initialise every referenced object; assert the expected mechanism, a counterexample, replay and an independent learner variation. Carry previous code explicitly; do not silently rely on an omitted completion.
4. **Spatial evidence:** overhead and eye-height before/after images, reachable hand control, clear route and adjacent reset. Do not hide a wall to make the evidence persuasive. Sampling a capsule route is not a headset comfort test.
5. **Review receipt:** precise source revisions, baseline/intervention settings, seed and simulated time where relevant, passed/failed checks, measured cost, known limits and the next lesson's dependency. Source existence, a passing solver test, native interaction and tracked VR are separate evidence levels.

P1, P3 and P4 are built with runnable code and native views. P2 (a measured response returns to affect an action) is next in the execution queue. Keep the remaining packages editable as proposals; inspect each current host before implementation.

## P1 implementation record and reusable procedure

| Step | Work boundary | Completion evidence |
|---|---|---|
| 1 | Read `commons/maps/VFM_05_Launch/{map_data.json,tutorial.md,final.md}` and its currently placed launch works. Capture the hall before editing. | Placement choice preserves the existing launch encounter and a clear route. If there is no suitable footprint, return a host alternative rather than adding clutter. |
| 2 | Extend `algorithms/forces/euler_drift/euler_drift.gd` through an opt-in configuration, or add a local `step_study.gd` child to that artifact. Reuse a declared existing PointBody file. | Default legacy scene remains unchanged; new mode constructs its own point/trace/labels and local control. No project-wide physics settings change. |
| 3 | Add complete learner files under `doc/book/studies/forces-through-the-hands/` and print them in the selected hall's tutorial. Carry supplied host dependencies explicitly. | The printed files alone reconstruct the declared study inside Day Zero's museum host. All objects referenced are created or carried from a named earlier file. |
| 4 | Add a focused probe under `tools/probes/` and an extraction runner under `tools/`, following the existing CA pattern. | Formula, three step sizes, same simulated time, alternate launch, wrong-order mutation, reset and cap assertions pass. |
| 5 | Change only the chosen artifact token/placement and the selected hall's tutorial/final additions. If the registry needs a new entry, follow its existing family schema; do not duplicate a registered artifact unnecessarily. | One target museum-plan row rederived; other rows unchanged; native hand action and placement checked. |
| 6 | Publish a dated iteration folder containing full texts, code, settings, logs, before/after captures and a compact handoff. | Tutorial claim matches the evidence; tracked-headset and Quest status named separately. Promote the package status only after these receipts exist. |

For the remaining P2/P5/P6 packages, repeat this bounded procedure with the source and host listed in each package. Their exact edits remain proposals until their own source/space check; the plan does not give an agent permission to fill missing mechanisms with theatrical substitutes.

## The Sieve for this plan

**What becomes thinkable?** The same familiar body can carry a position, a sampled trace, an error, a response and an interpretation. The student gains ways to compare claims with mechanisms.

**What could this foreclose?** A compulsory failure explanation in every room would turn exploration into diagnosis. Keep many encounters open and protect the existing subject of each sequence.

**What remains in the dark?** The tests can check a mechanism and still miss pleasure, fatigue, surprise, another interpretation or another person's access to the room. Preserve those as questions for play and reflection, not as scores the harness claims to certify.

## Short instruction for the next AI

Existing Endless Museum; preserve25spine. Point→trace→cube→array→field→state. Oneprimary reconstruction/principle; restmaymuseum/final. P0auditclaims→P1throw→P3estimate→P4receiver→P2feedback→P5fuzzy→P6faultreturn. Tutorial fullminimalcode+exactGodotasserts;finalreflection. Fixedreference/intervention/witness/reset/transfer. Noenginegroundtruth;nooscillation=feedback;nomembership=probability;noeffect=mechanism;nocatastrophe=bug. Nativeabove+eyeviews;handcontrols;loglimits. P1BUILT:53core+51printed+2mutants+22museum;P3BUILT:24core+24printed+8exampleasserts+2mutants+25museum;P4BUILT:37core+37printed+8exampleasserts+2mutants+121museum(includes82prior);P2/P5/P6proposed. G0geometry_noise BUILT in Random_Noise_Types;28core+16museumchecks;headsetuntested. NOISE_TESTS.md:G0contract+12substrates;G1pendulum_noise BUILT Vectors_Act4b_Oscillation;43core+21museum;G2navigator_noise BUILT SwarmIntelligence_Agent_Based_Modeling_ABM;40core+40printed+2mutants+21museum. P2nextoriginalpackage;P1endpointprojectiontestedafterrender.
