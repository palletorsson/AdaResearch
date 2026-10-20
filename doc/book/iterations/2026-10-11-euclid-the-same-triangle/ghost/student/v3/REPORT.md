# Final packet — same-agent revision rerun

The final supplied packet reconstructed verbatim and passed **144 / 144 full-host and geometry checks** plus **25 / 25 repeated shear checks**, with both Godot processes exiting 0. This is a revision rerun by the same experienced coding AI, not a new independent student or a novice-human learning result. The initial assessment and its three failed one-shot synthetic-grab checks remain intact in the parent directory.

## Packet and source comparison

| Input | Final packet SHA-256 |
| --- | --- |
| tutorial.md | `fdd920b6ce166c24dd8a45d111cf403a4e342fde4e51a75b561035da71027cfd` |
| final.md | `9efa7a337274af60f261b9d258c861519b8d0d6be4a6d3ed02d431f708ab9be1` |

All four listings were extracted from `ghost/final-input/tutorial.md`, with a new minimal scene attaching the final host. Independent comparison confirms that `triangle_record.gd`, `point_body.gd`, `line_skin.gd` and `final.md` are unchanged from the initial packet. The host changes are limited to presentation:

- Guide and Reset roots move from local y=0.94 to y=1.03.
- Setting each button root's rotation to zero cancels the supplied scene's rotation, making its cap face the host's local +Y direction.
- The three corner labels and two button labels explicitly use outline size 0.
- The readout explicitly uses outline size 6 and white outline color.

`packet.diff` and `source.diff` record the comparison with the initial packet. `final_vs_intermediate.diff` confirms that the final packet differs from the frozen intermediate packet only by the readout's outline size 0→6 and addition of white outline color. Intermediate preparation remains in `../v2`, clearly marked as superseded before engine execution, with zero runs. No initial files were changed; `results.json` verifies their hashes against the final rerun's pre-execution manifest.

## Predictions, test changes and provenance

`predictions.json` and `pre_run_manifest.json` were frozen before the final packet's first engine invocation at `2026-10-11T19:11:27.922387+00:00`. A freeze milestone with final input hashes was sent to the parent before execution. The numerical and shear predictions are the original pre-execution predictions; the model did not change.

`probe.diff` records the changes from the initial test: local paths point to this new reconstruction, a synthetic hand continuously supplies pose in process and physics callbacks, and presentation assertions inspect the final button and label properties. The continuous driver was informed by the retained first-run failure and successful follow-up. It is input to the unmodified lesson host, not a replacement geometry implementation or a canonical fix.

Additional lesson reads were restricted to the separately supplied revised/final packets. Source comparison used my own earlier reconstructed files. No author tests, canonical study implementation, earlier external assessment, import repair or production source was inspected. Dependency understanding came from the initial recorded reads. `reading_assistance_log.json` and the prediction/manifests retain the reading and assistance trail. The parent's stated presentation intention informed what to inspect; actual source differences and numerical runtime properties were checked independently.

## Runtime results

| Probe | Checks | Engine exit | Evidence |
| --- | --- | --- | --- |
| Final full host and numerical geometry | 144 passed, 0 failed | 0 | `primary_results.json`, `primary_execution.json`, `primary.stdout.log`, `primary.stderr.log` |
| Previously predicted shear, repeated separately | 25 passed, 0 failed | 0 | `shear_results.json`, `shear_execution.json`, `shear.stdout.log`, `shear.stderr.log` |

Both runs used Godot 4.6 with the requested workspace, `--headless --xr-mode off --audio-driver Dummy --script … -- --no-bridges`, Python `subprocess.CREATE_NO_WINDOW`, UTF-8 log capture and a 90-second timeout. Neither timed out.

The full host retained all initial numerical tests: known right-triangle angles/area; measured unequal initial corners; coincident, collinear, extremely thin and tiny coordinates; recovery; and uniform scaling of an independently specified scalene triangle. The unit-scale host remained translated to `(4,1,-3)` and rotated by `(0.2,0.65,-0.12)` radians. Its points, edge endpoints, face vertices, label positions/text, measured readout and guide geometry matched the model.

The continuous synthetic input passed the original grab checks, including the across-frame assertion that failed under one-shot input. A hand position corresponding to local `(1.7,4.2,-1.4)` recorded A=`(1,-1)`, kept the held sphere at the supplied world pose, and showed the projected point in labels/edges. Release placed the sphere at local `(1,1.12,-1)`, and released-position maintenance passed. The real supplied area's press/release callback chain, held-point trigger signal, keyboard callbacks, refusal to reset while held, reset and guide-preference behavior also passed.

The added 22 presentation checks established:

- Tabletop upper surface: local y≈1.0.
- Both button roots: local y≈1.03.
- Both cap axes: host-local +Y, even with the host rotated in world space.
- Both cap mesh lower bounds at rest: local y≈1.035, above the tabletop.
- Both cap lower bounds after the actual press tween: local y≈1.015, still above the tabletop.
- Both caps move down by 0.02 on press and return to their rest bounds on release.
- Six host Label3D nodes exist; the five corner/button labels have no outline, and the readout has a six-pixel white outline.

Cap bounds were computed by transforming all eight corners of each actual mesh AABB into the host frame, before/after the supplied tween. These are geometry/property assertions, not a rendered readability claim.

The logs still contain the unrelated unrecognized UID `uid://rwex60pqapc`; the host log also retains Jolt's unsupported custom solver-bias warning. Successful assertions therefore do not mean an entirely clean project startup. No infrastructure repair was attempted.

## Transfer result and limits

The separately run shear repeats the originally predicted independent variation `x' = x + 0.5y`, `y'=y`. For `(0,0), (0.8,0), (0.2,0.6)` → `(0,0), (0.8,0), (0.5,0.6)`, measured area remains ≈0.24 and sum remains ≈180°, while all three angles change to approximately 50.194429°, 63.434949° and 66.370622°. Side-length and parallel-guide checks also pass. This retains the limited transfer claim: this experienced agent independently selected and tested a transformation beyond the supplied scaling exercise, distinguishing area/sum invariance from preservation of angles/lengths. This repeated run adds regression evidence, not a second independent learning demonstration.

The initial `119/122` primary outcome, separate `12/12` continuous-input follow-up, and `25/25` independent shear outcome remain in the parent directory with their original predictions, logs and hashes. The final green rerun does not erase those results.

There is no claim here about physical XR, actual desktop ray targeting, rendering/readability in the museum, navigation, performance or novice learning. Those require their own evidence. I made no canonical file changes.
