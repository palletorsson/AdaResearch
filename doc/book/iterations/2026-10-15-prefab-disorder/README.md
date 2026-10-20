# Prefab disorder: whole objects and their parts

Palle requested a disorder slider using gallery prefabs, and chose to compare moving whole objects with separating their pieces. The installed optional study uses a cardboard box, CRT monitor, laboratory stool and microscope: four prefabs and fifty visible mesh parts on each side.

[Open the visual comparison](index.html). The buttons switch native Godot captures at disorder 0, 0.5 and 1. The live slider is in Random_Entropy near the entrance, at grid (13, 3), and in `commons/artifacts/prefab_disorder/preview.tscn`.

## What the trial establishes

At zero the two sides contain matching assemblies. At half and full disorder the left retains the relationships among each object's parts; the right changes those relationships. The captures show recognizable objects persisting through whole-object rotations while their counterparts separate into surfaces, legs and rings. Whether that difference is compelling or legible to a visitor remains a reading and headset trial.

The useful question is **what is being permitted to come apart?** The two sides retain the same inventory but define their movable units differently. The slider controls geometric displacement and rotation; it does not report an entropy value. The nearby Shannon–Boltzmann bench retains its own explicit variables and readings.

## Verification

- [36 native apparatus checks](verification.json): source inventory, rigid whole-object motion, independent part motion, tray clearance, exact zero, slider callbacks, KEEP/REPLAY, reconstruction in a fresh scene, invalid-record rejection and source signatures.
- [17 actual-hall checks](museum-report.json): both instruments installed, facing and placement, supported approaches and clear standing space, slider height, native controls and saved replay. Existing Shannon–Boltzmann initial readings remain intact.
- [Source manifest](manifest.json) and [hall capture provenance](source_manifest.json).
- [Kept sample record](kept-trial.json) and [implementation guide](implementation.md).

Both native runs completed with exit code 0. These checks establish software behavior and geometry, not headset comfort, Quest frame rate or independent student learning. The engine emitted its existing Jolt custom-solver-bias warning. The web export still reports pre-existing layer-size mismatches in Random_Rotate_Random_XYZ and Noise_Inside_Noise, outside this study.

Run the native verification from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-15-prefab-disorder/run.py
python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag prefab-disorder --probe doc/book/iterations/2026-10-15-prefab-disorder/museum_probe.gd
python -X utf8 doc/book/iterations/2026-10-15-prefab-disorder/publish.py
```

## Place in the research loop

The writing wall tags this as an optional tutorial encounter; the tutorial adds the baseline, comparison, KEEP/REPLAY and reconstruction procedure. The adopted room/final sequence remains ledger → jar → compartments → displaced points → ruin → signal room. The 48-value seed bench remains the first research pilot.

Next human observation: at what slider setting does one object stop being recognizable, and which retained relationship might recover it? That result can motivate a new grouping rule rather than simply increasing the disorder slider.

Local source galleries: [artifact gallery](http://127.0.0.1:3003/galleries/artifact) and [props DNA gallery](http://127.0.0.1:3003/props-dna-gallery).
