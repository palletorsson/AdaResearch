# QFEP — one inherited sphere, explicit measurements

Introduction, F Term, E Term and Lambda Spectrum have completed this reconstruction pass. The remaining four halls are planned in `doc/book/course/QFEP-READING-PASS.md`.

Use this folder inside the prepared AdaResearch Godot project. Open `introduction.tscn` and run the current scene (F6). It loads the actual QFEP Introduction museum hall and mounts the learner's bench beside the existing exhibits. It does not replace the permanent hall configuration.

Printed new files: `balance.gd`, `introduction_study.gd`, `balance_checks.gd` in `commons/maps/QFEP_Introduction/tutorial.md`. Carried files: `point_body.gd` and `line_skin.gd` from Euclid's tutorial; `bench.gd` from Russell's tutorial. XRTools and `commons/interactables/push_button.tscn` are supplied museum dependencies. The scene and `introduction_museum.gd` are supplied environment setup.

TERM selects an input. Hold and lift the sphere along that input's height range; release before pressing a button. KEEP copies the four values for this run. PAIR A and PAIR B demonstrate equal totals with different contributions. ZERO L removes E's contribution to the total, not E's stored value.

From the project root:

```
python tools/test_qfep_introduction.py
python tools/run_encounter_probe.py QFEP_Introduction --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_introduction_museum.gd
python tools/publish_qfep_introduction.py
```

The first command reconstructs the code from the printed lessons before testing it. To intentionally reprint edited working code into the tutorial, use `python tools/build_qfep_introduction.py --write-tutorial`, then repeat tests. Do not substitute a stale passing receipt after changing code.

Synthetic tests establish bounded behaviours. They do not establish independent learner success or headset ergonomics. This console uses supplied dimensionless quantities; it does not measure free energy or prescribe a desirable social arrangement.

## F Term

Open `f_term.tscn` and run F6. It loads the actual F Term hall. The same sphere now controls p for a fixed 64-draw sample. P .1 / P .9 are exact comparison presets; EXPECT 0 / EXPECT 1 change only the guess; KEEP retains the reading and bits. Dark/cyan tiles show outcomes; amber marks show mismatches. The original workbench uses 256 draws, so compare its first 64 when checking observed counts against this working copy.

New printed files: `prediction.gd`, `f_term_study.gd`, `prediction_checks.gd` in `commons/maps/QFEP_F_Term/tutorial.md`. The carried files are unchanged. `f_term_museum.gd` and `f_term.tscn` are supplied museum setup.

```
python tools/test_qfep_f_term.py
python tools/run_encounter_probe.py QFEP_F_Term --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_f_museum.gd
python tools/publish_qfep_f_term.py
```

To deliberately reprint changes to the working code, use `python tools/build_qfep_f_term.py --write-tutorial`, then repeat its checks. H is binary source entropy; expected error is a probability under that source; observed mistakes count this sample. None is relabelled F. E Term follows.

## E Term

Open `e_term.tscn` and run F6. It loads the existing E hall with a learner bench. ONE / TWO / OPEN select one, two or three continuations at each of four stages; the same sphere selects these settings by hand height. PRUNE closes eighteen third-stage branches and removes fifty-four endings. KEEP copies the path list and reading for this run. Cyan tips are completed paths; amber caps are closures. H = ln(N), in nats, assumes equally weighted endings.

New printed files: `possibilities.gd`, `e_term_study.gd`, `possibility_checks.gd` in `commons/maps/QFEP_E_Term/tutorial.md`. Carried files remain unchanged. `e_term_museum.gd` and `e_term.tscn` supply the museum setup.

```
python tools/test_qfep_e_term.py
python tools/run_encounter_probe.py QFEP_E_Term --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_e_museum.gd
python tools/publish_qfep_e_term.py
```

Use `python tools/build_qfep_e_term.py --write-tutorial` only to deliberately reprint edited working code, then rerun affected checks. Lambda Spectrum follows. Keep the inventory and its probability assumption distinct from the weight assigned to it.

## Lambda Spectrum

Open `lambda.tscn` and run F6. The same sphere edits WEIGHT (lambda in the carried calculation) or STRIP (a spatial recommendation). KEEP records both; RETURN restores the strip alone; ZERO L leaves E stored while making its weighted contribution zero. All twenty-four cubes retain their identities, transforms and colours. The model uses Introduction's dimensionless E=0.2, not an entropy inferred from those cubes.

New printed files: `recommendation.gd`, `lambda_study.gd`, `recommendation_checks.gd`. Also carry `balance.gd` unchanged from Introduction alongside the same three earlier files. `lambda_museum.gd` and `lambda.tscn` supply the real museum setup.

```
python tools/test_qfep_lambda.py
python tools/run_encounter_probe.py QFEP_Lambda_Spectrum --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_lambda_museum.gd
python tools/publish_qfep_lambda.py
```

Reprint intentional working-code edits with `python tools/build_qfep_lambda.py --write-tutorial`, then repeat affected tests. The installed walk-in spectrum keeps its own animation; the miniature isolates a static comparison. The museum currently warns of a blocked authored entry and uses its safe fallback. This test does not certify the entire walking route. Phi Term is next.

## Phi Term

Open `phi.tscn` and run F6. Continue with the same PointBody, LineSkin and Bench. The sphere now edits a signed weight. Two supplied readings and a declared interval give a signed difference, average rate and weighted contribution. REVERSE, 2s / 4s, KEEP, ZERO PHI and LABELS each change only their named part. The values are authored fixtures; the nearby pattern is not sampled or controlled.

New printed files: `signed_change.gd`, `phi_study.gd`, `change_checks.gd`. The `phi_museum.gd` adapter supplies the real hall setup and places the learner copy at (6,0,12), yaw 0. It does not edit the permanent map. Introduction's full calculation is retained separately; this study isolates its last contribution with a variable difference.

```
python tools/test_qfep_phi.py
python tools/run_encounter_probe.py QFEP_Phi_Term --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_phi_museum.gd
python tools/publish_qfep_phi.py
```

Reprint intentional code edits with `python tools/build_qfep_phi.py --write-tutorial`, then rerun affected checks. 25 printed assertions, 19 synthetic input checks and 32 native checks pass. This is author-operated synthetic evidence, not a headset or independent learner study. Next: Edge of Chaos, with equal model time made explicit when comparing numerical updates.


## Edge of Chaos

Open `edge.tscn` and run F6. The same sphere edits lambda on a paired-field bench in the actual museum. Each +6 TIME action advances equal model time with different step counts. Restart, seed, timestep and KEEP controls isolate the comparison. The field is adapted from the earlier CA operation to match this exhibit's coefficients and stencil; the tutorial explains the changes.

New printed files: `timed_field.gd`, `step_comparison.gd`, `edge_study.gd`, `step_checks.gd`. `edge_museum.gd` supplies the existing hall and checked bench location (12,0,6.5), yaw PI/2. Three inherited files remain unchanged. Both screen textures cover a single QuadMesh face.

```
python tools/test_qfep_edge.py
python tools/run_encounter_probe.py QFEP_Edge_Of_Chaos --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_edge_museum.gd
python tools/publish_qfep_edge.py
```

Reprint intentional code changes with `python tools/build_qfep_edge.py --write-tutorial`, then rerun affected checks. 34 printed assertions, 19 synthetic input checks and 29 native checks pass. KEEP preserves compared B fields for this run, not a full resumable state or parameter-edit history. The 32-square lesson matches a same-sized installed solver; do not compare it numerically to the differently sized installed screen. No headset or independent learner claim. Next: Sandbox and explicit receiver connections.


## Sandbox

Open `sandbox.tscn` and run F6. The same sphere edits offered lambda or phi; an explicit signal route may deliver them to one named receiver. The cube uses received colour and speed. CONNECT sends current values, CUT holds used values without stopping motion, REPEAT resets time/distance only, KEEP copies both pairs and the current response.

New printed files: `routed_receiver.gd`, `input_route.gd`, `sandbox_study.gd`, `route_checks.gd`. Three carried files remain unchanged. `sandbox_museum.gd` supplies the actual hall and a checked bay at (3,0,8), yaw PI. The permanent museum retains its original artifacts.

```
python tools/test_qfep_sandbox.py
python tools/run_encounter_probe.py QFEP_Sandbox --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_sandbox_museum.gd
python tools/publish_qfep_sandbox.py
```

Reprint intentional code edits with `python tools/build_qfep_sandbox.py --write-tutorial`, then rerun affected checks. 26 printed assertions, 17 synthetic input checks and 34 native checks pass. The cube is a reduced receiver using matching colour/speed mappings, not a full reactor or particle simulation. KEEP is in-memory; synthetic tests are not a headset or independent learner study. Next: Synthesis, the final QFEP hall.


## Synthesis

Open `synthesis.tscn` and run F6. A carried PointBody edits local lambda/phi; a new soft receiver reuses the sphere geometry. PULSE / STEADY changes forcing, NUDGE acts on the current body, KEEP copies settings for this run. The same receiver and mesh survive all actions.

New printed files: `morphology_map.gd`, `synthesis_study.gd`, `morphology_checks.gd`. Three inherited files remain unchanged. `synthesis_museum.gd` mounts the lesson in the actual hall at (3.5,0,2.5), yaw PI/2. The first overlapping bay was rejected. Final support/approach and all-artifact separation checks pass.

```
python tools/test_qfep_synthesis.py
python tools/run_encounter_probe.py QFEP_Synthesis --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_synthesis_museum.gd
python tools/publish_qfep_synthesis.py
```

Reprint intentional edits with `python tools/build_qfep_synthesis.py --write-tutorial`. 23 printed assertions, 23 synthetic input/physics checks and 29 native checks pass. On tested Godot 4.6-stable/Jolt, pressure and damping update live, drag is unused, and running stiffness edits do not rebuild constraints. The readout shows this distinction. Construction-time stiffness does affect the response, verified with matching bodies and versioned source. Do not erase that finding by testing only property assignments.

All eight individual lessons now have reconstruction receipts. A new combined audit, complete walking route, physical headset and independent learner study remain separate work. Older soft-body explanations may need the same engine-limit correction.
