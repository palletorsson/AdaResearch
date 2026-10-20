# Two accounts of one arrangement

15 October 2026. User-authorized implementation in Random_Entropy. The 48-value seed bench remains the first research pilot.

## What was built

A two-compartment bench at source-grid (8,9), facing the entrance. Sixteen fixed sites always hold eight A and eight B occupants. Its left display measures marginal Shannon colour entropy; its right shows configurational Boltzmann entropy divided by k_B, ln Ω(k), where k counts A on the left. The model has no temperature, heat exchange, momenta or physical gas dynamics. Same-colour occupants are not individually labelled; sites are.

Controls: deliberate A LEFT −/+, SAME k permutations, seeded ONE SWAP or RUN/PAUSE, RESET, KEEP and REPLAY. KEEP writes an exact event record; REPLAY reads that record without new draws. Saving partway through replay keeps the visited prefix. Editing then continues from the current configuration and generator state. The latest-record button does not browse older files. The event limit is 1,024.

The jar now identifies H(colour | six height bands), a 0–1 bit conditional colour statistic. The live display and registry no longer claim irreversible mixing, a second-law demonstration or an absolute maximum above an arbitrary threshold. Bead physics and the existing disclosure modes are retained.

## Observation → inference → next decision

**Baseline:** seed 435, k=8, fixed 8 A/8 B; H=1 bit, Ω=1, S_B/k_B=0.

**Intervention:** move one A across the divider at a time, keeping the inventory and both definitions fixed. At k=4, Ω=4,900 and S_B/k_B≈8.497; H remains 1. The next exchange to k=3 lowers Ω to 3,136 and S_B/k_B≈8.051. The full sweep reaches separation at the other end and returns to Ω=1.

**Second intervention:** SAME k changes a balanced site list while both readings stay fixed. At complete separation this control has no visible effect. These null/unchanged readings are retained rather than treated as failed demonstrations.

**Seeded run:** 64 requested pair swaps from seed 435 include same-colour swaps and decreases in multiplicity. RESET plus the same requests reproduces every retained state. This is a reproducible simulation, not new physical unpredictability or evidence that every finite path must increase entropy.

**Inference:** neither chosen statistic preserves the full arrangement. They concern different random variables/state descriptions, so their difference does not refute either definition. The simple unchanged H is intentional: the variable being counted is colour over the whole board, not uncertainty over microstates.

**Alternative explanation to examine:** the comparison could appear to be two arbitrary gauges if the visitor cannot identify their respective questions. The finite counting model also does not validate a physical second-law claim.

**Next decision:** use the same-k pair to motivate saving full site lists. Invite a learner to add a declared adjacency measure, or a researcher to change the macro-description. Choose the next instrument from the observed omission, not from a requirement to raise an entropy score. A human may find this difference uninteresting; no such judgement has been invented.

## Evidence and boundaries

- [Native apparatus checks](verification.json): 52 checks pass, including all 12,870 configurations, nine multiplicities, real button callbacks, save/reopen/replay, retained notes, partial replay, corrupt-record rejection, deterministic requests, and jar fixtures/disclosure modes.
- [Reconstruction](reconstruction/verification.json): 52 checks pass in a fresh copied scene using the model extracted from tutorial.md and only its declared host/scene/preview. [Manifest](reconstruction/manifest.json). This is an executable completeness check, not an independent learner's experience.
- [Museum checks](museum-report.json): 16 checks pass in the actual authored hall, including supported and unobstructed standing positions, reachable control height, callbacks, saved replay and rendered labels. The probe flushes deferred artifact construction before inspection.
- [Kept comparison](kept-trial.json): exact state history and notes, with RNG integers stored as strings to avoid JSON precision loss.
- [Before-state hashes](before.json), [after-state hashes](after.json), source snapshots and captures preserve the change. The actual restored RNG state is checked independently of the JSON number representation of small site IDs.

Headset touch/comfort, full-route human traversal, sustained Quest performance, independent reconstruction and reader response remain untested. No cross-hall seed/record transfer is promised. The current bridge to Definition is conceptual; the new local generator begins at 435.

Engine logs retain inherited Jolt shape-bias warnings and compatibility-renderer feature warnings; some standalone runs report ObjectDB instances at shutdown. These do not invalidate the checked quantities but are not a clean-shutdown or performance certification. The whole-museum exporter also reports pre-existing layer-size disagreements in Random_Rotate_Random_XYZ and Noise_Inside_Noise; this task does not repair those maps.

## Text, map and plan

The room/final route is ledger → jar → two compartments → displaced points → ruin → signal room. Butterflies and hardware decay are optional. The writing wall stores this order, tutorial/final tags and encounter notes. The final uses the adopted local “we” voice and is about 1,250 words. Its bench passage follows the native observations; descriptions of other encounters rely on their existing implementation and earlier evidence.

The tutorial isolates 25 nonblank model lines and declares the supplied visualization, controls and record host. The previous complete counts lesson survives unchanged as `commons/maps/Random_Entropy/counts-and-neighbours.md`; its existing test now reads that file. The historical text generator is guarded against overwriting the new canonical lesson.

E1 (jar repair), the multiplicity part of E3 and the native/text part of E4/E5 are implemented. Conditional prediction, editable jar partitions/radial shells, human trials and thermal dynamics remain separate work in the [research plan](../../course/text-plans/Random_Entropy/research-brief.md). Both tutorial and final may motivate the next apparatus revision; this experiment does not confirm QFEP as a scientific law.

## Reproduce

From the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-15-entropy-compartments/run.py --render
python -X utf8 doc/book/iterations/2026-10-15-entropy-compartments/reconstruct.py
python -X utf8 doc/book/iterations/2026-10-15-entropy-compartments/derive_hall.py
python -X utf8 tools/em_bake.py --pearl "randomness/random entropy" --timeout 120
python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag entropy-compartments --probe doc/book/iterations/2026-10-15-entropy-compartments/museum_probe.gd
python -X utf8 tools/long_museum.py --apply
python -X utf8 doc/book/iterations/2026-10-15-entropy-compartments/publish.py
```

`derive_hall.py` calls the existing authored-map compiler for this row; every other plan row remains equal to the before snapshot. An initial template `spine_run` regenerated unrelated Randomness arrangements; that unadopted output is retained separately and was replaced with the exact pre-task plan before deriving only Entropy. The targeted bake also refreshes the adjacent Random Remove segment. No authored cells in other maps are changed.

## Definition references

Shannon's information measure: [A Mathematical Theory of Communication](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf). Statistical-mechanics definitions and assumptions: [David Tong, Statistical Physics, section 1](https://www.damtp.cam.ac.uk/user/tong/statphys/statmechhtml/S1.html). The experiment's exact finite counts are independently enumerated in the native test; no source is used as a substitute for that check.
