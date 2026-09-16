# Folded strip study in the triangle hall

2026-09-16. Follows the bounded form search in `../2026-09-16-folded-strip-research/`.

## Installed encounter

The existing `folded_strip` placement in `Point_Triangle_Context` now opts into the study:

```text
folded_strip:90:1:0.75#offset:0,0,-0.5#study:1
```

The runtime museum places it at `(2.5, 1, 7)`, yaw 90°, scale 0.75. The 48-second loop is flat, one hinge to 70°, flat, paired hinge turns to 40°, then flat. It interpolates hinge angles and rebuilds rigid rotations from the original coordinates; it does not interpolate between target vertex positions. Edges retain their lengths to floating-point tolerance during the automatic study. Unconfigured placements remain manual.

Grabbing a point stops the study. Free movement can change edge lengths. Releasing preserves the edit, and the existing museum pointer/hand button restarts the study only when no point is held. The plinth keeps REPLAY near 1.05 m above the floor. The visible point size now matches the existing grab radius; the per-point floating coordinate labels are hidden during this study. Disabling the controller restores their previous appearance.

## Source changes

- `commons/primitives/folded_strip/folded_strip.gd`: consistent triangle winding, one face with double-sided material, consistent normals, placement-specific study configuration.
- `commons/primitives/folded_strip/folded_strip_study.gd`: angle-based sequence, hand interruption, persistent manual edit, replay and staging.
- `commons/primitives/point/drag_point_set.gd`: fixes callback argument order. `Callable.bind(index)` appends the index after the pickable emitted by the signal; the old methods expected the reverse and failed during real pickup/drop signals.
- `commons/maps/Point_Triangle_Context/map_data.json`: only the existing strip token changes in this pass.
- `commons/maps/Point_Triangle_Context/final.md`: only the existing strip encounter paragraph expands; roles and other encounters are retained.
- `commons/maps/Point_Triangle_Context/technical.md`: corrects the planar starting geometry, source/render vertex distinction, affected triangle indices and new interaction behavior.

The earlier research gallery remains a historical capture of the previous artifact code, including its rendering defects. Its source hash is deliberately not regenerated after this production change. The review page now adds actual museum captures above that earlier evidence.

## Verification

`runtime-checks.json` records the production scene's geometry, coherent normals, timing continuity and real pickup/pointer signal checks. `museum-report.json` records the actual endless-museum configuration, sampled motion bounds, floor hits and capture results. The hall harness samples 97 poses across the full loop. This is not continuous collision proof or a human/headset trial.

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --xr-mode off --audio-driver Dummy --path . --log-file ada_run/folded-strip-study-probe.log --script res://ada_run/probe_folded_strip_study.gd --quit-after 360
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --xr-mode off --audio-driver Dummy --path . --rendering-method gl_compatibility --resolution 1600x1000 --log-file ada_run/folded-strip-museum.log --scene res://ada_run/folded_strip_museum_check.tscn --quit-after 900
python -X utf8 ada_run/publish_folded_strip_integration.py
```

The museum's existing route diagnostic flags neighboring `triangleprofiles` as sealing a route. That broader room issue is not fixed by this strip change. The new strip's sampled positions and control bounds are checked against its own alcove. Existing engine cache, certificate and UID warnings are recorded separately from the relevant checks.
