# Noise testing: a measured intervention

**9 October 2026 — extension to the uncertainty plan**

The two new notes make a useful change: hold a working object, intervene at a named point, and compare what follows. The first implemented experiment is **G0, The Uncertain Surface**, in `Random_Noise_Types`. It is a small opt-in addition to the Noise opening; the 25-sequence order and the other work packages remain intact.

The broader “fuzzy computer” is a research direction. Gaussian displacement demonstrates neither fuzzy inference nor adaptation. Fuzz testing generates inputs and checks properties; noise injection adds a specified disturbance; fuzzy inference combines graded memberships under explicit rules. They can share a comparison apparatus without becoming one algorithm.

## G0 — Keep the connections; move the positions

The student returns to an indexed mesh, a position array and a local seeded generator. Two 2 × 2 metre planes share 289 vertices and 512 triangles. One stays unchanged; the other receives three independent Gaussian draws per vertex. A physical strength slider scales the same saved sample. NEXT SEED changes the sample. ZERO and RESET recover their stated baselines. A removable edge overlay makes connectivity visible. The student predicts what halving strength will do, then verifies it from the stored positions.

**New operation:** `changed[i] = original[i] + saved_noise[i] * sigma`. **Carry:** original positions, index list, saved offsets, seed, units and measured deviation. **Defer:** topology mutation, collision, temporal variation, distribution switching and automatic failure classification.

The prototype has bounded parameter ranges and fixed geometry counts, but the underlying Gaussian distribution has no finite support. No sample clipping or centroid recentering is hidden in the calculation. Both surfaces have the same material; plinths and controls are separate from the noncolliding experimental mesh. Readouts distinguish measured RMS from population RMS. A valid index list does not prove a nonintersecting embedding.

The [artifact companion](../../../../commons/artifacts/geometry_noise/README.md) records the implementation and units. The [native museum review](../../iterations/2026-10-09-geometry-noise-test/index.html) includes before/after overhead, raised and visitor views, code, measurements and test receipts. Exact files are printed in the [companion tutorial](../../../../commons/artifacts/geometry_noise/tutorial.md). This optional study does not certify that the entire existing opening tutorial has been rewritten.

## A shared experiment contract

Use the same *questions* for each substrate; introduce a shared implementation only when a second real experiment shows which code is reusable.

1. **System and original:** what runs, what data is preserved, and the version of its dependencies.
2. **Injection point:** exactly which input, state update or output is changed. The original remains separately addressable.
3. **Process:** distribution plus spatial/temporal dependence. Gaussian names a marginal distribution; white describes a correlation property. They are not mutually exclusive options in a single list.
4. **Magnitude:** value in the system's units. A percentage slider may control it, but does not make metres, newtons, seconds and missing messages comparable.
5. **Clock and random stream:** seed, draw order, fixed simulated duration where relevant, static versus resampled input. Sweeping amplitude with one sample is a paired comparison; testing robustness across seeds is another study.
6. **Observation:** defined difference from the reference, finite data and control bounds. A large difference is not automatically failure.
7. **Failure criterion:** an explicit task or invariant, named before measuring failure rates. Retain exceptions and do not invent a universal glitch score.
8. **Recovery and transfer:** replay/reset restores all relevant state; the student varies an independent case and predicts its consequence.

If plotting failure incidence, record the sample population, number of trials, seeds, criterion and uncertainty. Do not present conceptual curves as Godot measurements. If claiming adaptation, identify what changes in the controller or model and test its response on held-out disturbances; a fixed damped pendulum is not learning.

## Where the twelve proposed interventions belong

These are candidates, not twelve new required lessons. Each reuses an earlier object and needs its own inspection before implementation.

| Substrate | Existing sequence / carrier | Intervention and unit | Observation / boundary |
|---|---|---|---|
| Coordinates | Transformation's cube; return in Noise | Saved translation offset in metres, or angle in radians, one at a time | Reference pose difference; don't conflate local and global axes. |
| Mesh geometry | **G0: Noise / Random_Noise_Types** | Independent Gaussian xyz offsets; sigma 0–0.25 m | Measured RMS/max/centroid; fixed index list. Implemented first. |
| Physics | Forces' point sphere and spring | Add a recorded disturbance in newtons or a separate impulse in N·s | Compare trajectories with same mass, clock and initial state; bounds and reset. |
| Time | Change → Forces P1 → Waves | Vary one simulated timestep or a recorded delay in seconds | Matched simulated duration; never perturb headset frame delivery. |
| Collision | Forces, later Soft Bodies | Change one documented shape margin or sampling setting in an isolated study | Actual contacts/penetration measured. A decorative wall cannot establish tunnelling. |
| Materials | Colour → Shaders P4 | Modify saved channel values or UV coordinates, separately | Same source, receiver and camera; mapping and corruption distinguished. |
| Rendering | Shaders | Change in-world render-target resolution in pixels | Image difference and cost. Leave the live headset/stereo pipeline intact. |
| Navigation | Procedural Generation / Swarms | Perturb goal or observed obstacle distance in metres | Target reached, duration, path cost; distinguish sensing errors from graph changes. |
| Perception | Swarms → Machine Learning | Recorded distance noise, delay or observation dropout | Log true versus observed value and chosen command; missing is not zero. |
| Memory/state | CA → PostCrisis P6 | One delayed, skipped or aliased update | Original versus changed history; violated synchronous/snapshot invariant. |
| Procedural rules | L-systems / Procedural Generation | Mutate one symbol or parameter under declared constraints | Syntax, budget, connectivity and reachability checked separately. |
| Communication | Graph Theory / PostCrisis | Simulate queue delay in seconds, duplicate or drop a numbered message | Receiver histories and recovery. Bounded local queue first, not a network rewrite. |

Earlier Forces and Waves may show a recorded disturbance before students reconstruct its generator in Randomness/Noise. State that dependency rather than introducing an unannounced statistics lesson. Later halls return to the method only where it strengthens their main subject.

## G1 and G2 built

**G1 — The same release / a recorded push. Built in Vectors_Act4b_Oscillation.** Pull either inherited point to set the pair's release angle. OFF/ON matches drag and changes only the external input; SAME INPUT matches the saved force and changes B's drag. Forty saved Gaussian values, each held0.1s, provide four seconds of horizontal force. The angle model runs at120Hz for20s, stores a30Hz history, and reports peak absolute angle and a terminal settling window. There is no contact solver or Jolt hinge in this small study. The fixed-length projection follows existing constrained hand controls; the angular equation extends the museum's existing pendulum model. Springs remain the hall's primary reconstruction.

43 native core checks and21 installed-room checks pass, including actual controls, supplied XR point/slider poses,176 supported capsule samples and native captures. The first headless teardown crashed after assertions; stopping the child handles and waiting through a physics frame before freeing the manually driven rig resolved it. Its log remains in the review. Headset and independent learner assessment remain open. [Images, full code, text and evidence](../../iterations/2026-10-09-pendulum-a-recorded-push/index.html); [artifact contract](../../../../commons/artifacts/pendulum_noise/README.md).

This supplies a measured response, not closed-loop control, adaptation or stochastic resonance. The next P2 return still needs an explicit output measurement feeding a controller.

**G2 — A navigator receives an imperfect observation. Built in SwarmIntelligence_Agent_Based_Modeling_ABM.** Two inherited point spheres share an authored course, obstacle, goal, detour, speed and starting pose. One has accurate range; the other receives recorded Gaussian range error or dropout as separate modes. A missing value is null; STOP and HOLD give it different consequences. The fixed20Hz kinematic model checks swept disc contact and course exit, records the decision and actual path, and finishes within20simulated seconds. Known position/direction and waypoints are supplied; this is not a navmesh, learned policy or Jolt simulation. The colony remains primary, and the companion reconstructs this smaller policy explicitly rather than treating earlier ABM fragments as complete.

40core assertions and40checks on freshly extracted printed code pass. Two real mutations—missing-as-zero and endpoint-only contact—fail the expected assertions.21native museum checks include supplied hand poses, six nearby buttons and72supported route samples. Seed1847 with65% missing blocks reaches contact at3.65s under HOLD and the goal at19.15s under STOP. All20paired results from seeds1847–1856 and the actual saved input arrays are retained; no population robustness estimate is claimed. The front-bay placement was rejected for pillar occlusion; the final study occupies the open end of the existing room. Physical headset and independent learner checks remain open. [Images, code and receipts](../../iterations/2026-10-09-navigator-an-imperfect-observation/index.html); [artifact contract](../../../../commons/artifacts/navigator_noise/README.md).

The three G studies now make position, response and observation distinct intervention sites. P1 is built in Launch. P3 now extends the existing Monte Carlo dartboard with a replayable sample budget and eight-seed comparison; [native views and tests](../../iterations/2026-10-09-samples-and-disagreement/index.html) distinguish all counted samples from visible markers. P4 now supplies the saved-record receiver and decoder; P2 feedback is next. No further generic injection framework is implied.

Build one at a time. A generic NoiseInjection component that modifies arbitrary properties would obscure units, invariants and dependencies. G0's data helper is reusable for meshes; it does not pretend to operate a pendulum or navigation policy.

## What belongs in the two texts

**Tutorial:** identify inherited code; save an original; sample once; apply scaled displacement; recompute normals; measure actual results; operate/replay; predict another case. Print runnable complete files and declare the museum controls as supplied infrastructure. The tiny formula does not excuse omitted construction code.

**Reflection:** a form can change while its connections remain. Which property was the viewer expecting to survive? What did the reference make visible, and what did it fail to name? A measured deviation gives a question a location; it does not settle recognition, pleasure or political meaning.

**Compressed continuation:** G0installedRandom_Noise_Types:289vertices512faces;xyzGaussian savedseed1847;strength*.25m;original+indicesfixed;measuredRMS/max/centroid;populationRMSseparate;no meshcolliders. Strength≠probability;Gaussian≠bounded;white≠Gaussianalternative;fuzz≠fuzzy. Core+museumreceipts. G1pendulum_noise installedForcesOscillation:43core+21museum;G2navigator_noise installedABM:40core+40printed+2mutants+21museum;P1+P3built;P3:24core+24printed+8exampleasserts+2mutants+25museum;P4built:37core+37printed+8exampleasserts+2mutants+121museum;P2nextoriginalpackage. Preserve25order/primarylessons;onecarrier/newoperation;noadaptationclaimwithoutpolicychange.


## 9 October extension: camera image becomes body

`camera_glitch_study` is installed in Shader_05_Patterns: scanline strips, brightness relief, RGB planes, corrugation, curl, tile permutation, held/live bands, row-address offsets, luminance discard, torus wrap. One shared 640×360 camera; the source remains separately visible. Display mappings, not evidence of engine failure. [Museum views and tests](../../iterations/2026-10-09-camera-image-becomes-body/index.html). P4 now extends this same apparatus with its saved RGB8 record and decoder contract. [P4 native views and exact-code tests](../../iterations/2026-10-09-one-record-many-readings/index.html). P2/P5/P6 remain proposals. P3 has its separate sampling receipt.

The PIXELS bank adds ten flat-screen operations to the same camera: chopping, wrong row width, scanline repetition, block permutation, channel misregistration, one-band tearing, retained blocks, quantisation, missing blocks and alternate reversed rows. Pixel addresses, values and image time are separate interventions. [Ten native pixel views](../../iterations/2026-10-09-cut-the-image-pixels/index.html). Source data stays intact; no vertex displacement, actual file corruption or invalid memory access is claimed.
