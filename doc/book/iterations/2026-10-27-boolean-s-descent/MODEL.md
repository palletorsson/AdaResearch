# Boolean Tunnel / continuous S descent

Model-first variation of the museum `boolean_tunnel`. The original `booleanHollowCube.tscn` supplies the subtraction operation and default opening dimensions. The original straight generator repeats hollow cubes; this variation instead sweeps the outer solid and a single extended bore over one shared S route, then asks Godot CSG to subtract the bore. The resulting actual Boolean mesh is baked once and supplies both the displayed shell and its physical collision. The original artifact and first S model remain unchanged.

Canonical route: entry12 m, upper slide to6 m, level 180-degree landing, return slide to0 m and exit. Model scale1:10, drop1.2 m; clear passage1.6 m wide ×2.8 m vertical headroom, wall .35 m. Entire route rotated18 degrees relative to floor guides. It remains wider than a4 ×4 m shaft.

```json
{"t":"boolean_s_descent_model","with":{"model_scale":0.1,"yaw":18,"passage_width":1.6,"headroom":2.8,"wall":0.35,"xray":true}}
```

Eight editable members: ContinuousPassage, RouteTrace, EntryMouth, ExitMouth, StudyStand, LevelGuide0, LevelGuide6, LevelGuide12. The Boolean body stays continuous when copied/moved/rotated as one member; no internal CSG child is reparented independently. The mouth dimensions follow the cutter bindings. Native CSG can be regenerated through the recipe's width/headroom/wall/path bindings; arbitrary independent movement of a detached landing is not represented as a still-connected bore.

X-ray changes only exterior opacity, preserving roof/wall/floor collision. Solid mode shows the closed shell. Smooth study materials replace the source per-triangle wire shader because CSG subdivision made it too dense to read. The palette remains charcoal, pale interior and pink mouths/trace. This is not the source wire shader rendered unchanged.

Three.js constructs an analytical hollow boundary preview from the same route/profile. The lab editor loads actual Godot-exported Boolean geometry. No web CSG evaluation or browser physics is claimed.

Evidence:18 native checks, including171 supported centreline samples, capsule clearance, no interior caps, open entrance/exit, two separate Jolt ball drops, production desktop walker around the level landing, and a moved/rotated negative-floor copy retaining collision. Full tower traversal, slide comfort and a physical headset remain untested. No tower slab openings are installed in this model pass.

Native check runner: `python tools/run_boolean_s_descent.py`. Export: `python tools/export_void_trial.py s_descent_boolean`. Editor parity: `node tools/test_boolean_s_descent_editor.cjs`. All native/export work uses the existing OS lock; never delete it or recursively scan staged-runtime junctions.
