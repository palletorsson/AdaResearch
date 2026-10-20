# Ghost student assessment — frozen first packet

The supplied listings reconstruct and run in the prepared Godot 4.6 project. The numerical model, scene construction, displayed state, and synthetic control callbacks behaved as predicted. The first host test retained three failures caused after a one-time synthetic move across physics frames; a separately predicted follow-up with continuous hand-pose input passed all 12 focused checks without changing any lesson script. This is a qualified software result, not a physical XR or rendered museum assessment.

## Identity, reconstruction, and information boundary

I am an experienced coding AI, not a novice human. I already know GDScript, vector arithmetic, angle formulas, rigid-body update timing, and test construction. I read the complete `ghost/input/tutorial.md` and `ghost/input/final.md`. Four named listings were extracted verbatim into `triangle_record.gd`, `euclid_study.gd`, `point_body.gd`, and `line_skin.gd`. `minimal.tscn` attaches the reconstructed host script to a unit-scale Node3D named EuclidStudy. The probe instantiates that scene under an otherwise empty Node3D; it adds no camera, light, player or substitute geometry.

The tutorial identified all required source files and the external push-button dependency. The prepared project's global classes and transitive infrastructure loaded normally enough to execute the probes. The only additional source reads were the required Ada dispatcher/auditor skills and declared button/XRTools dependencies needed to understand the real button press chain and interpret the grab timing. Detailed reads, assistance, paths and hashes are recorded in `reading_assistance_log.json` and `followup_predictions.json`. I did not read author tests, production study sources, earlier assessments or prior solution probes. No editor run, import repair, dependency patch, or canonical fix was made.

The parent later said a separate native inspection required a presentation revision. No details or revised lesson content were used in this first-packet assessment; that message merely establishes that any later packet must be evaluated separately.

## Frozen prediction and provenance

`predictions.json` and `pre_run_manifest.json` were written before the first engine invocation. The manifest covers the reconstructed scripts, minimal scene, both independently authored probes, runner and provenance documents. I sent the parent a freeze milestone before running Godot.

Input SHA-256:

| Input | SHA-256 |
| --- | --- |
| tutorial.md | `0e21f99d803632499c020e838f11a2021d060bced5cbbe7b7485ef172e2f7e49` |
| final.md | `9efa7a337274af60f261b9d258c861519b8d0d6be4a6d3ed02d431f708ab9be1` |

The first invocation was `2026-10-11T19:03:55.527758+00:00`. Follow-up hypotheses and the continuous-input probe were separately frozen at `2026-10-11T19:05:39.859085+00:00`, before that follow-up ran. The original predictions, source, probe and failed result remain unchanged.

## Executed evidence

| Run | Result | Evidence |
| --- | --- | --- |
| Primary geometry and full host | 119 / 122 checks passed; engine exit 1 | `primary_results.json`, `primary_execution.json`, `primary.stdout.log`, `primary.stderr.log` |
| Independent shear variation | 25 / 25 checks passed; engine exit 0 | `shear_results.json`, `shear_execution.json`, `shear.stdout.log`, `shear.stderr.log` |
| Continuous synthetic grab follow-up | 12 / 12 checks passed; engine exit 0 | `continuous_grab_results.json`, `continuous_grab_execution.json`, corresponding logs |

Every engine call used the requested executable, project path, `--headless --xr-mode off --audio-driver Dummy --script … -- --no-bridges`, Python `subprocess.CREATE_NO_WINDOW`, a 90-second timeout and UTF-8 log files. None timed out. The first Python runner's console echo failed to encode an unrelated checkmark under Windows cp1252 after it had saved all engine logs, results and execution metadata. Subsequent calls used `python -X utf8`; no probe or lesson code changed to repair this console issue.

The primary test checked independent numerical expectations for the right triangle (90°, 45°, 45°, area 0.5), initial unequal corners (~55.00798°, ~55.00798°, ~69.98404°, area ~0.7), coincident points, collinearity, thin-triangle tolerance, absolute minimum scale, and the suggested uniform scaling exercise. Doubling my scalene points doubled side lengths and changed area from ~0.24 to ~0.96 while preserving each angle. These checks compare model numbers, not only text containing 180.

The complete host was translated to `(4,1,-3)` and rotated by `(0.2,0.65,-0.12)` radians at unit scale. Checks covered three visible sphere meshes and collisions, finite edge endpoints and lengths, actual face vertices, corner-label positions/text, initialized readout, guide midpoint/direction/length, guide invariance of points and measurements, actual supplied-button area enter/exit callbacks, synthetic held-point trigger, keyboard callback dispatch, reset rules, degenerate-state refusal, hidden face/guide, zero edge visibility, and recovery.

The button test invoked the supplied area's `_on_button_entered` / `_on_button_exited` chain with a synthetic Node3D, exercising the dependency's pressed/released state and host callback wiring. It did not simulate ray targeting or physical contact.

## Retained failures and interpretation

The first probe called `on_desktop_grab`, teleported the rigid body once, and verified the immediate local clamp and displayed projection successfully. After several frames the body returned to its earlier pose. Consequently, three checks failed:

1. `grab.after_frames_sphere_stays_with_hand`: expected world `(5.390377,5.165361,-4.790704)`, observed `(3.934502,2.092441,-2.159356)`.
2. `release.projected_world_position`: expected `(4.423271,2.171124,-4.305263)`, observed `(3.934503,2.092441,-2.159356)`.
3. `release.physics_maintains_position`: same mismatched projected expectation after the earlier model drift.

The follow-up changed only the synthetic input to keep supplying a pose in process and physics callbacks. After eight held cycles, A remained `(1,-1)` in model coordinates and the sphere remained with the synthetic hand. After release, the sphere rested at `host.to_global((1,1.12,-1))`, preserved the model coordinates, and recovered that rest position after an external perturbation. Reset and guide-state retention also passed. Its per-cycle samples are retained.

This supports the explanation that the first failure depends on insufficiently sustained synthetic input and physics timing. It does not establish the behavior of the actual desktop controller or tracked XR hand. I did not silently replace the failing results with a green rerun, and I do not classify the original primary run as passed.

All runs logged `ERROR: Unrecognized UID: "uid://rwex60pqapc"`. Host runs also logged Jolt's unsupported custom solver-bias warning. These did not prevent the assertions from running, but they mean the runtime logs are not clean. The probes did not repair or trace unrelated project infrastructure. Autoload logs mention the lack of a player in the deliberately minimal root; the real museum launcher was outside this test.

## Independent transfer exercise

I selected an area-preserving shear, beyond the tutorial's suggested uniform scaling: `x' = x + 0.5y`, `y' = y`. The original scalene triangle `(0,0), (0.8,0), (0.2,0.6)` becomes `(0,0), (0.8,0), (0.5,0.6)`. I predicted the operation, points, individual angles, side lengths, area and sum before either probe ran, then executed it in a separate engine process.

| Quantity | Original prediction | Sheared prediction | Observation |
| --- | --- | --- | --- |
| A angle | 71.565051° | 50.194429° | Both within 0.0001° |
| B angle | 45° | 63.434949° | Both within 0.0001° |
| C angle | 63.434949° | 66.370622° | Both within 0.0001° |
| Area | 0.24 m² | 0.24 m² | Both within 0.0001 m² |
| Sum | 180° | 180° | Both within 0.0001° |
| Guide | Centred on C, parallel to AB | Centred on transformed C, parallel to AB | Passed |

The independent exercise demonstrates limited conceptual transfer by this experienced agent: preserved area and angle sum do not imply preserved angles or lengths. It also distinguishes a general affine change from a similarity. It does not prove that a novice learned this from the text, and mechanical extraction of four supplied listings is reconstruction rather than invention. Neither successful exercise proves a geometric postulate or universality beyond the selected flat coordinate model.

## Gaps and limits

- The lesson supports complete reconstruction inside its declared prepared project; it is intentionally insufficient for a blank Godot project without XRTools and the button dependency.
- Its reset-while-held and bounded hand-projection rules were clear enough to formulate and test. A ghost test must continuously supply a held pose to make claims across physics frames; the first failed run is evidence for documenting that requirement in the evaluation protocol.
- The numerical policy is not scale invariant at extremely small absolute sizes: a right triangle with legs `1e-6` is rejected by `longest <= EPS`. This was predicted and matches the listing's explicit numerical-policy discussion; it is not evidence against mathematical angle invariance.
- No graphical readability, actual museum placement, navigation, desktop pointer targeting, physical XR grabbing, haptics, performance, or human learning was tested. Parent's separate native inspection should cover presentation.

No canonical fix is proposed by this assessment. The concrete retained gap is qualification of synthetic interaction evidence and non-clean infrastructure diagnostics.
