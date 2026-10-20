# Post-crisis: build, retain, return

<!-- latest-rerun -->
Latest requested rerun: **12 October 2026, 10:42 +0200**. All eight lessons passed again; no lesson changes were required. The saved body and pending prediction matched across separate Godot processes. [Timestamped run receipt](latest-run.json).
<!-- /latest-rerun -->

All eight canonical tutorials now contain complete new code, named inherited files, explanations, runnable assertions and a supplied scene that opens their existing museum hall. The ghost reconstruction passes 141 model assertions and interaction checks. The eight native museum studies pass 117 checks, including the actual saved handoff from Assembly to Synthesis.

## What the student carries

Euclid supplies the already developed PointBody and LineSkin; Russell supplies the initialized bench, readout and controls; Florensky supplies the support-pair operations. All four files are carried unchanged. The first new lesson adds the shared pickup/release adapter. Later lessons add behaviour without rebuilding the sphere.

| Hall | Reused capacity | New, testable operation | What survives |
| --- | --- | --- | --- |
| Bias | Point, arrays, interpolation | Move authored positions; measure two gaps | Six word identities |
| Applied Ethics | Whole meshes, trigonometry | Rearrange seats; change an acceptance criterion | Positions remain fixed while the criterion changes |
| Paraconsistent Engineering | Florensky support pairs | Select a branch without deleting its report | Both source records; unsupported Q |
| Situated Computation | Source-tagged claims | Cover a presentation copy | Original provenance |
| Collective Knowledge | Position edits and records | Separate additions, sources and revisions | Original pose, source, lifetime totals |
| Rhizome Network | Seeded sampling, indices, cylinders | Rewire, cut, restore and count components | Positions and stored adjacency |
| Assembly | Graph plus local coordinates | Move a joint or reroute an endpoint; optionally predict first | Thirteen positions, twelve edges, edit count; separate prediction |
| Synthesis | Validated persistence and renderers | Read and compare; optionally retain an observation and reason | Actual saved pose; one inspectable experiment |

The first five halls sharpen operations the student already knows. Rhizome is the largest new algorithmic step: nearest-neighbour selection and graph traversal. Its explanation walks through the stack, visited set and outer component count. Assembly reuses this graph without running its growth rule. Synthesis is deliberately short because it imports the model and validator already written.

The lineage is more than a shared visual style. `viewpoints.gd` imports `claims.gd`; `body.gd` imports `network.gd`; Synthesis imports `Body` and `PoseFile`. The reconstruction checks each relative dependency against the files available at that point in the sequence. There are no undeclared future student imports.

## What the ghost student actually did

This was an **author-operated reconstruction**, not an independent novice assessment. The runner extracted 28 newly printed scripts plus four explicitly inherited files from the canonical tutorials into a separate learner folder. Native studies loaded those extracted files. The runnable code was not reconstructed by copying private artifact implementations.

Each of the eight documented assertion commands also passed individually. These repeat assertions included in the 141-check aggregate; they are not counted a second time. Every command exited successfully and printed PASS. Every native hall receipt passed with no GDScript error. Engine warnings are retained in the logs and native evidence index; passing does not mean the larger museum has no warnings.

Checks cover model results, independent copies, preserved records, invalid indices, graph components, rejected links, coordinate conversion under a rotated parent, actual button signals, held/released point adapters, missing/malformed files and refusal to overwrite an invalid record. A changed selection keeps the same point instance.

The native Assembly run moved the left hand, then rerouted one endpoint from hand to head. It saved two edits, one displaced joint and a body with two connected components. The next Godot process opened Synthesis and reconstructed that exact record. The publisher compares all saved positions, connections and the edit count between the two process receipts. Selecting and rereading left the source file bytes unchanged.

The revised run also recorded a deliberately wrong synthetic prediction before editing: the body would stay connected. Synthesis read that exact pending prediction in another process, then retained the observation of two components and a reason for keeping the case. Assertions verify the before/after snapshots, refusal to replace an existing note, refusal to attach to a pose changed on disk, invalid-data handling and recognition that a later pose differs. Test prose is explicitly synthetic; the learner's fields start empty.

Test records have private paths. They do not overwrite the installed workshop's visitor record. The student's two lessons share `user://ada_postcrisis_pose_v1.json`; the installed workshop and return body continue to use their existing record.

The optional experiment uses `user://ada_postcrisis_observation_v1.json`. It adds no participant identity or tracked hand path. Prediction, observation and reason are learner-written script values; a VR text-entry interface is not part of this lesson.

## What the run improved

- The first launchers assumed the previous sequence's raised floor. Measured floor support and collision checks found usable positions in each actual hall. The final pass checks fixed launcher positions; it performs no automatic relocation.
- The hand probe initially moved a frozen body only once. It now supplies continuous updates while held, as the existing controller does. The student adapter keeps the last held local position for release and places the unheld marker at the current selection after physics.
- A raised sphere can appear aligned with the wrong pad from one angle. Situated Computation now colours the selected pad and joins it to the sphere with a short cylinder.
- A distant capture viewpoint fell behind a wall in Synthesis. Captures now use the supported standing area and test the sightline to the readout.
- The Rhizome explanation makes traversal explicit: a stack schedules visits, a set prevents revisits, and each remaining active start adds one connected component.
- The feedback pass adds RULE in Applied Ethics: the same ring passes a 0.50 m centre-distance criterion and fails 0.90 m. This tests the authored criterion rather than claiming to measure access or fairness.
- The project's default audio bus now uses its existing resource path instead of a stale UID. The XRTools display scene no longer serializes an unbound ViewportTexture; its script attaches the correct per-instance texture when ready. Two native instances are checked for separate materials and textures. Both reported errors are absent from the revised runs. Artifact construction-time warnings remain listed for a separate performance pass.

## What the examples claim

These are complete, bounded teaching reconstructions beside existing exhibits. Six equal seats make a controlled comparison; the installed furniture changes more than position. The student graph has 24 points rather than the installed grower's 40. One sphere edits selected joints and one connection rather than recreating the workshop's whole interface. Every reduction is named in the tutorial.

The tests establish the operations promised by the code. They do not establish social fairness, calibrated confidence, collaborative knowledge, anatomical correctness or accountability merely because those subjects motivate a hall. A saved pose has no gesture path, participant identity or complete version history. The optional note retains an authored observation and reason; it cannot verify their truth, establish agreement or provide an Undo command. Those limits connect the runnable lesson to its reflection.

## Reading the two texts together

The progression holds: representation gives distinctions room; arrangement gives positions a relation; conflicting accounts require retention; retention requires provenance; contributions require careful counting; networks separate position from connectivity; Assembly lets those choices alter a body; Synthesis asks what its record can support.

The eight existing `final.md` texts remain the reflective reading. They refer to installed artifacts; tutorials explicitly say where their working copies simplify those mechanisms. Facing pages keep that distinction visible. No existing artifact was removed, and map layouts, museum plan and sequence order are unchanged by this pass.

## Remaining human checks

The rendered tests load isolated actual halls and use synthetic button and desktop-hand inputs. They do not walk the entire museum route, test physical controller reach, assess headset comfort or establish that a new reader understands the material. Try the supplied scenes in VR, then ask an independent reviewer to rebuild from the text.

Reproduce in the prepared Ada project:

```text
python tools/test_postcrisis_reconstruction.py
python tools/run_postcrisis_rooms.py
python tools/publish_postcrisis_reconstruction.py
```

Open `index.html` for summaries and native images, `parallel.html` for both texts, or use `postcrisis-review.zip` for the complete review package. The ZIP requires the existing Ada project to run its Godot scenes.
