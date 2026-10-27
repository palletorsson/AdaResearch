# Portal element / falling assembly model — 2026-10-27

Latest user direction supersedes the prior S-with-middle-landing design: start with a standing thick rectangular portal, end upside down/on its head, one falling gesture, no extra middle step. Use rotations in all directions to shape it. Complete new model in `s_portal_copies`, preserving earlier smooth/cutaway trials and main tower.

24 equal outer elements (2.3 ×3.5 ×1.35 m canonical, opening1.6 ×2.8 m) sample a descending half-ellipse with a small lateral curl. Main pitch goes0→180°, yaw adds an envelope up to30°, cross-axis Z adds an envelope up to20°, both zero at endpoints. Entire study1:10, top-to-bottom drop1.2 m. First portal UP dot globalUP> .999, last<−.999. No LevelGuide6 or landing. Separate starting portal beside chain. 29 editable members.

`commons/modular/portal_piece.gd` builds each actual CSG piece. A common union of every transformed opening cuts each outer box. Previous outer volumes trim overlaps while pieces keep independent editor identities. Per-piece cuts are derived for the authored arrangement; independently dragging one does not regenerate all shared cuts or guarantee continuity. Web source-element preview differs from native shared-cut geometry; editor GLBs are actual native pieces.

Important narrow fix: `recipe_area.gd` now orthonormalizes the local basis before extracting member Euler rotation. Calling get_euler directly on scale .1 flattened X rotations (59.85° became4.96°). Source scale is still stored separately. New 29-member native/Three.js pose comparison passes with YXZ order.

14 native assembly checks and five editor checks pass. Includes equal outer dimensions, all24 booleans, centreline links without caps, endpoint upright/inverted, no middle landing, XYZ rotation, real GLBs, independent copy/move/rotate, isolated save/reload/Desktop mirror/stale conflict, source layouts preserved. This is not a full-size body-clearance, ball, landing, VR or gameplay acceptance. Earlier smooth study checks do not transfer to this new geometry.

Evidence: `doc/book/iterations/2026-10-27-portal-copies/`; raw `ada_run/s-portal-copies-2026-10-27/`. Commands: `python tools/run_s_portal_copies.py`, `python tools/export_void_trial.py s_portal_copies`, `node tools/test_s_portal_copies_editor.cjs`. Native work serial through OS lock; no native job left running by this task. Never scan runtime junctions/delete lock. Claude Colour family / Arrangement|Colour page integration untouched.
