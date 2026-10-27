# Boolean Tunnel / continuous S model — 2026-10-27

User explicitly requested the Boolean Tunnel lineage as one continuous hollow S descent, model first, editable in lab editor, screenshots. Completed separate `s_descent_boolean` trial; preserves original `s_descent_model`, museum/shaft artifact and main tower arrangements. No full-size tower placement.

Recipe `boolean_s_descent_model`: model_scale .1, yaw18, passage_width1.6, headroom2.8, wall .35, xray true. Entry12 m → slide → level turning landing6 m → return slide → exit0 m; model drop1.2 m. Canonical path171 points.

`commons/modular/boolean_passage.gd` uses the original hollow-cube scene's subtraction operation and opening defaults, then applies the operation to one swept outer solid and one continuous extended bore. Godot CSG generates the actual surface; this result is baked to one mesh/collider. The straight repeated-cube generator is not called or changed. Smooth charcoal/pale/pink study materials adapt its palette because the source triangle wire shader becomes dense after CSG subdivision. X-ray is visual only; collision is unchanged.

Eight independent members: ContinuousPassage, RouteTrace, EntryMouth, ExitMouth, StudyStand, LevelGuide0/6/12. The passage remains one part to preserve its common void. Mouth sizes follow width/headroom/wall bindings and are offset to avoid coplanar flicker. `recipe_area.prepare_editor_preview` now awaits direct source hooks and refreshes measured bounds after asynchronous Boolean baking.

Web `modular-boolean-passage.ts` draws an analytical boundary preview, not a web Boolean solver; editor GLBs are the actual Godot result. Member pose and passage/trace bounds parity passed. New TypeScript module strict check passed. Five editor receipts cover real meshes, independent copy/move/rotate validation, isolated save/reload/Desktop mirror/stale conflict, user/main layouts untouched.

Eighteen native checks passed: actual saved model, dimensions, source lineage, one baked mesh/body,171 floor samples, conservative upright capsule clearance, no internal caps, open mouths, separate Jolt ball drops down each slide, production desktop walker around landing, independent copied body plus its moved/rotated negative-floor collision, five photos. Native export loads final source without errors. Last change after physics receipt merely obtains the same operation enum from the source and its default dimensions instead of hardcoding them; explicit tested bindings and operation remain identical.

Evidence: `doc/book/iterations/2026-10-27-boolean-s-descent/`; raw `ada_run/s-descent-boolean-2026-10-27/`. Runners: `tools/run_boolean_s_descent.py`, `tools/export_void_trial.py s_descent_boolean`, `tools/test_boolean_s_descent_editor.cjs`. Native/export jobs use OS lock; no job left running for this task. Do not delete lock or scan runtime junctions.

Limits: complete footprint exceeds4 ×4 m shaft; full-size slab openings, approach/arrival, sliding comfort/health/recovery and desktop/physical-headset traversal are not accepted here. Claude Colour family and Arrangement|Colour switch were preserved; this task did not edit that page or his new files.
