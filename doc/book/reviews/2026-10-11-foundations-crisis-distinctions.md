# Foundations crisis: distinctions and current-hall records

11 October 2026. Palle approved the selected foundations-crisis clarifications, a check against existing maps, an update of the final-lap records and a scoped commit.

## The two texts keep different work

The six revised finals develop the encounter and its consequences. Euclid and Gödel already contain the needed reflective distinctions and are unchanged. The tutorials explain implementation and its limits. Their older fragments are **not complete runnable examples**: this pass corrects their claims and identifies the installed reconstruction target, while preserving every code fence and student-code marker. A source review is not a ghost-student pass.

| Hall | Reflection | Tutorial correction / reconstruction target |
| --- | --- | --- |
| Euclid | No addition needed. | Declaration versus measurement; the five-plinth/reading-gated-door sketch is not the installed plaque. Preview visibility does not establish independence. |
| Non-Euclidean | Return to parallels within the plane, sphere and hyperbolic disk models. | Separate host selection from radial deformation. The old warp supplies no corresponding metric or geodesic integration. |
| Russell | Name the inconsistent self-membership demand; distinguish it from independence. | Distinguish a finite snapshot/filter from unrestricted comprehension. Rebuild the installed IN/OUT and restricted-domain test. |
| Gödel | No addition needed. | Modulo encoding loses information; the proof helper is absent. A bounded miss cannot certify truth or unprovability. |
| Escher | A closed measured route must return its height; representation needs evidence beyond recognisability. | Correct the three rises and negative return; cyclic differences telescope to zero. The open forms and level-centre tilted form need distinct checks. |
| Brouwer | Name the work of finding a witness, and the inspectable finite diagonal witness. | A checklist flag does not make a proposition true. Use the installed prefix/diagonal studies; unresolved status is not a third truth value. |
| Florensky | Separate warrants for assertions from consequences of incompatible premises. | Independent reports differ from coupled confidence values. Neither those values nor opacity are a quantum state or a paraconsistent calculus. |
| Synthesis | Scope incompleteness to the requisite effective arithmetic theories. | The four-wing summit and its visit gate are not installed. The logistic parameter is independent of lambda. Brouwer’s bench is recalled, not present here. |

The proposed blanket equation of the fifth postulate with K = 0 is not restored. Neither are the claims that the trident has an unlocatable transition, that constructive mathematics loses analysis or every proof using contradiction, or that Florensky supplies one established logic. Quantum measurement is not used as authority for the contradictory-report study. The existing diagonal and preset-geometry discussion already distinguishes an example from a general proof; no extra duplicated tour was added.

## Map and plan evidence

Current map tokens and configuration match the Endless Museum plan in all eight halls. All 55 placements resolve through the modular registry to existing scenes. The map files, museum plan, artifacts and runtime code are unchanged by this task. The sequence order is unchanged. Its obsolete artifact-group inventory was reconciled, including the missing Escher group.

| Hall | Placed artifacts | Active focus |
| --- | ---: | --- |
| Euclid_Parallel | 4 | lesson_controls:on on the postulates plaque |
| NonEuclidean_Spaces | 7 | triangle workbench starts at model:plane; separate surface sketch |
| Russell_Paradox | 7 | membership_controls:on; initial_cell:5 |
| Godel_Incompleteness | 10 | sentence/proof comparisons, plaque, sorter, tower and surrounding studies |
| Escher_Impossible | 4 | lesson_controls:on; perspective study with track_viewer:on |
| Brouwer_Intuitionism | 8 | visitor_choices:on; finite diagonal workbench |
| Florensky_Paraconsistent | 4 | report_controls:on; hold_both:on |
| Crisis_Synthesis | 11 | reading_study:on; dispute-calibrated rails; independent r at 3.2; sentence study |

Primary implementation evidence:

- `commons/artifacts/triangle_curvature_workbench/triangle_curvature_workbench.gd`: host-specific edge tangents and angle calculation. The decorative saddle uses a separate surface construction.
- `commons/artifacts/russell_paradox_workbench/russell_paradox_workbench.gd`: `evaluate_membership`, finite `restricted_members`, enabled input flags and one-based initial cell configuration.
- `commons/interfaces/foundations/escher_staircase.gd` and `escher_staircase_study.gd`: the five forms, open-route stop and world-space tread-centre differences. `commons/artifacts/impossible_trident/impossible_trident.gd` constructs ordinary rods, tines and connecting surfaces.
- `commons/artifacts/brouwer_choice_sequence/brouwer_choice_sequence.gd`: explicit 0/1 input, stored finite prefix, capacity 256 and a latest-term display. `commons/artifacts/cantor_diagonal_workbench/cantor_diagonal_workbench.gd`: `_d[i] = 1 - _list[i][i]` for the finite displayed list.
- `commons/artifacts/both_true_gate/both_true_gate.gd`: independent report flags and Q = NO SUPPORT. `florensky_sphere` keeps both when configured. `schrodinger_box` uses a desktop input and random outcome; `superposition_display` animates opacity without a measurement operation.
- `commons/interfaces/qfep/lambda_slider.gd`, `phi_slider.gd`, `formula_display/qfep_formula_3d.gd` and `commons/interfaces/foundations/bifurcation_diagram.gd`: local controls, formula-reading configuration and an independent logistic parameter. `commons/artifacts/spine_studies/sentence_authority.gd` supplies the retained sentence-edit application.

Mathematical scope was checked against the sources cited in the finals: Cornell’s geometry course for model geodesics, the set-theory references already in Russell, Joan Moschovakis on intuitionistic logic, and Olivier Bournez’s INF412 incompleteness notes. These support distinctions; a rendering is not being used as proof of them.

## Final-lap records and remaining work

`doc/final_lap_scores.json` now records the actual inventories, enabled interactions, tutorial status and separate next tutorial/headset checks for each hall. The previous thesis ratings are retained, not newly awarded. Current helper/aesthetic ratings are null because this pass did not assess the rooms spatially. Russell’s and Gödel’s earlier 3/2 values and notes remain as dated history, and earlier metadata is retained. The QFEP laboratory and post-crisis map records and cross-sequence issues are untouched.

The next tutorial pass must supply complete code for the named reconstruction, carry dependencies explicitly and run the printed program with meaningful assertions. The present code fragments remain labelled legacy material; they are not ready to be presented as successful student reconstructions. Each hall’s `next_tutorial_check` states the behaviour to test. `next_headset_check` separately names the interaction or spatial check.

## Verification

- map_plan_matches: 8
- placed_artifacts_resolved: 55
- protected_code_blocks: 79
- protected_text_files: 16
- unchanged_reflections: ['Euclid_Parallel', 'Godel_Incompleteness']
- other_sequence_scores_unchanged: True
- museum_maps_and_scripts_unchanged: True
- runtime_test: Not run; legacy sketches still require complete reconstruction.
- headset_test: Not run.

The check concerns the current shared working tree. Other sessions have pending work elsewhere. This commit includes only these text and record changes plus this receipt.

## Exact before/after receipt

### doc/final_lap_scores.json

````diff
--- before/doc/final_lap_scores.json
+++ after/doc/final_lap_scores.json
@@ -4 +4 @@
-    "updated": "2026-04-19 (phase 2c — helper-layer lift on 4 under-developed maps: Russell, Gödel, Rhizome, Lab. Under-developed count: 4 → 2. Russell + Gödel cleared (T=3→4). Rhizome + Lab remain flagged — well-scaffolded now but still only 1 artifact each at T=3; honest signal that they'd benefit from a second artifact or a content pass.)",
+    "updated": "2026-10-11: foundationscrisis records reconciled with the eight current map/plan inventories and active source branches; no new spatial or headset scores.",
@@ -10 +10,13 @@
-    "source_review": "2026-09-15: final eight halls reconciled with primary source. Historical numeric aesthetic/helper scores retained; no new headset walk claimed."
+    "source_review": "2026-10-11: foundationscrisis source and text review only. Prior thesis ratings retained; helper/aesthetic are unassessed for the current halls. Earlier numeric helper/aesthetic values are preserved as historical records. Other sequences are unchanged.",
+    "foundationscrisis_review": {
+      "date": "2026-10-11",
+      "basis": "Current sequence, map tokens/configuration, museum plan, registry scenes and active scripts; mathematical sources cited in the texts.",
+      "runtime": "Not run in this pass.",
+      "headset": "Not tested in this pass.",
+      "tutorials": "Legacy fragment sketches: explanatory claims corrected and current reconstruction targets named; complete executable replacements and ghost-student tests remain pending.",
+      "receipt": "doc/book/reviews/2026-10-11-foundations-crisis-distinctions.md"
+    },
+    "prior_record_metadata": {
+      "updated": "2026-04-19 (phase 2c — helper-layer lift on 4 under-developed maps: Russell, Gödel, Rhizome, Lab. Under-developed count: 4 → 2. Russell + Gödel cleared (T=3→4). Rhizome + Lab remain flagged — well-scaffolded now but still only 1 artifact each at T=3; honest signal that they'd benefit from a second artifact or a content pass.)",
+      "source_review": "2026-09-15: final eight halls reconciled with primary source. Historical numeric aesthetic/helper scores retained; no new headset walk claimed."
+    }
@@ -37 +49,13 @@
-      "aesthetic": null
+      "aesthetic": null,
+      "source_review": "2026-10-11",
+      "artifact_count": 4,
+      "placed_artifacts": [
+        "science_screen",
+        "euclid_postulates_plaque",
+        "parallel_lines",
+        "angle_sum_triangle"
+      ],
+      "note": "One postulates plaque has lesson_controls:on; the triangle and parallel-lines studies distinguish declarations from measurements. The screen is a grid display.",
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Rebuild the declaration/measurement comparison with complete scene setup; assert measured data independently of displayed labels.",
+      "next_headset_check": "Check plaque reach, readout legibility and approach to the triangle."
@@ -42 +66,16 @@
-      "aesthetic": null
+      "aesthetic": null,
+      "source_review": "2026-10-11",
+      "artifact_count": 7,
+      "placed_artifacts": [
+        "film_curvature_triangle",
+        "triangle_curvature_workbench",
+        "curvature_slider",
+        "elliptic_surface",
+        "poincare_disk",
+        "hyperbolic_surface",
+        "riemann_sphere"
+      ],
+      "note": "The triangle bench starts at PLANE and compares plane, sphere and disk using model-specific edge tangents. The separate slider only changes its own sketch; the saddle is not a constant-curvature hyperbolic metric.",
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Replace the radial-warp sketch with a runnable three-host angle comparison; assert the plane sum and verify spherical excess and disk deficit for specified triangles.",
+      "next_headset_check": "Check model selection, tangent/angle legibility and access around the large surfaces."
@@ -46,3 +85,24 @@
-      "helper": 3,
-      "aesthetic": 2,
-      "note": "PHASE 2c 2026-04-19 — 4 3t labels walking the paradox: SET OF ALL SETS / THAT DO NOT CONTAIN THEMSELVES / IF IT DOES→IT DOESN'T / IF IT DOESN'T→IT DOES. Still only 1 artifact (russell_set_box) but now the paradox structure is readable from the room."
+      "helper": null,
+      "aesthetic": null,
+      "note": "Seven placed artifacts replace the old single-box record. The workbench has membership_controls:on and initial_cell:5; IN/OUT tests lead to the restricted finite domain. The returning plaque keeps independence distinct from contradiction.",
+      "historical_assessment": {
+        "date": "2026-04-19",
+        "helper": 3,
+        "aesthetic": 2,
+        "note": "PHASE 2c 2026-04-19 — 4 3t labels walking the paradox: SET OF ALL SETS / THAT DO NOT CONTAIN THEMSELVES / IF IT DOES→IT DOESN'T / IF IT DOESN'T→IT DOES. Still only 1 artifact (russell_set_box) but now the paradox structure is readable from the room.",
+        "status": "Retained as history; not a rating of the current hall."
+      },
+      "source_review": "2026-10-11",
+      "artifact_count": 7,
+      "placed_artifacts": [
+        "euclid_postulates_plaque",
+        "russell_paradox_workbench",
+        "self_membership_set",
+        "barber_paradox",
+        "russell_set_box",
+        "liar_loop",
+        "hilbert_hotel"
+      ],
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Reconstruct the Boolean membership test and finite-domain filter; assert both unrestricted choices fail and the restricted OUT choice agrees.",
+      "next_headset_check": "Check both membership buttons and the cell selector are reachable; read the rule and result from the same position."
@@ -52,3 +112,27 @@
-      "helper": 3,
-      "aesthetic": 2,
-      "note": "PHASE 2c 2026-04-19 — 5 3t labels narrating the argument: EVERY FORMAL SYSTEM / CAN NAME ITSELF / G—I AM UNPROVABLE / TRUE BUT UNDECIDABLE / SELF-REFERENCE IS THE EDGE. The plaque now has a reading path."
+      "helper": null,
+      "aesthetic": null,
+      "note": "Ten placements include the sentence machine, verifier and regress comparisons, plaque, provability sorter and tower. The final distinguishes a bounded search from an unprovability theorem; the old island/plaque-only record is obsolete.",
+      "historical_assessment": {
+        "date": "2026-04-19",
+        "helper": 3,
+        "aesthetic": 2,
+        "note": "PHASE 2c 2026-04-19 — 5 3t labels narrating the argument: EVERY FORMAL SYSTEM / CAN NAME ITSELF / G—I AM UNPROVABLE / TRUE BUT UNDECIDABLE / SELF-REFERENCE IS THE EDGE. The plaque now has a reading path.",
+        "status": "Retained as history; not a rating of the current hall."
+      },
+      "source_review": "2026-10-11",
+      "artifact_count": 10,
+      "placed_artifacts": [
+        "negative_control_fixture",
+        "critic_regress_stack",
+        "godel_sentence_machine",
+        "rice_verifier_booth",
+        "print_gallery_recursion",
+        "synthesis_stand",
+        "fluency_seam",
+        "godel_statement_plaque",
+        "provability_sorter",
+        "incompleteness_tower"
+      ],
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Replace the lossy encoding and unsupported verdict strings with a complete bounded proof-checking example; a search miss must remain not found.",
+      "next_headset_check": "Check the route between comparisons, plaque sightlines and readouts without treating display authority as mathematical evidence."
@@ -59 +143,13 @@
-      "aesthetic": null
+      "aesthetic": null,
+      "source_review": "2026-10-11",
+      "artifact_count": 4,
+      "placed_artifacts": [
+        "magritte_pipe",
+        "escher_staircase",
+        "penrose_triangle",
+        "impossible_trident"
+      ],
+      "note": "STEP reads tread-centre heights with lesson_controls:on. Closed routes balance ascent/descent; OPEN RUN and SCAFFOLD stop before closing; TILTED TREADS has level centres. The Penrose study tracks the viewer.",
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Supply a complete stored-centre model and assert the closed sum, the negative return and the open-run stop separately.",
+      "next_headset_check": "Check all five forms and the perspective mark in stereo; verify what the player can reach without implying the model is a walkable staircase."
@@ -64 +160,17 @@
-      "aesthetic": null
+      "aesthetic": null,
+      "source_review": "2026-10-11",
+      "artifact_count": 8,
+      "placed_artifacts": [
+        "brouwer_choice_sequence",
+        "intractable_evidence",
+        "constructive_proof",
+        "cantor_diagonal_workbench",
+        "excluded_middle_demo",
+        "angle_sum_triangle",
+        "constructive_staircase",
+        "parallel_lines"
+      ],
+      "note": "visitor_choices:on enables a finite 0/1 prefix; the diagonal bench constructs an inspectable finite witness. Timed stairs and supplied geometry remain comparisons, not hand-built proofs or general proof checkers.",
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Replace the proof-block checklist with complete prefix/diagonal examples; assert waiting preserves the prefix and the new string differs at every diagonal index.",
+      "next_headset_check": "Check choice/reset buttons, diagonal readout visibility and the distinction between a marker, model and supporting surface."
@@ -69 +181,13 @@
-      "aesthetic": null
+      "aesthetic": null,
+      "source_review": "2026-10-11",
+      "artifact_count": 4,
+      "placed_artifacts": [
+        "both_true_gate",
+        "florensky_sphere",
+        "superposition_display",
+        "schrodinger_box"
+      ],
+      "note": "The gate has report_controls:on; OPEN and CLOSED persist independently while Q has no support. The sphere has hold_both:on. The box uses a desktop-only random opening and the opacity display has no measurement operation.",
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Replace coupled confidence values with the independent report store; assert toggling one flag leaves the other unchanged and does not infer an unrelated claim.",
+      "next_headset_check": "Check the report controls and passage through the ghost leaves; confirm the headset limitation of the older box is legible."
@@ -74 +198,20 @@
-      "aesthetic": null
+      "aesthetic": null,
+      "source_review": "2026-10-11",
+      "artifact_count": 11,
+      "placed_artifacts": [
+        "lambda_slider",
+        "phi_slider",
+        "qfep_formula_3d",
+        "godel_statement_plaque",
+        "bifurcation_diagram",
+        "goedel_atrium",
+        "russell_paradox_workbench",
+        "russell_set_box",
+        "escher_staircase",
+        "florensky_sphere",
+        "sentence_authority"
+      ],
+      "note": "Eleven placements include reading_study:on, dispute-calibrated lambda/phi rails, an independent visitor-controlled logistic r starting at 3.2, the recursive atrium and sentence-authority study. Brouwer’s bench is recalled from its hall; there is no placed constructive wing or four-visit summit gate.",
+      "tutorial_status": "Legacy sketch; prose corrected, code preserved, reconstruction and runtime assertions pending.",
+      "next_tutorial_check": "Retire the four-wing prototype as the reconstruction target. Validate the installed sentence edit and separate parameter ownership; one logistic step is not a bifurcation diagram.",
+      "next_headset_check": "Check all local handles and the atrium passage; verify r stays independent of lambda and the sentence can be compared across three scales."
````

### commons/maps/Euclid_Parallel/tutorial.md

````diff
--- before/commons/maps/Euclid_Parallel/tutorial.md
+++ after/commons/maps/Euclid_Parallel/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed hall uses one postulates plaque with lesson controls, parallel lines and a triangle comparison. Reconstruct a declaration and a separately measured example; the five-plinth layout and timed door below are an earlier proposal.
@@ -11 +13 @@
-Five postulates. The first four feel inevitable. Build a room that exposes the fifth as a choice.
+Inspect this earlier display sketch. A postulate rendered as text is a declaration; a constructed example needs a separate measurement.
@@ -53 +55 @@
-Animate parallel lines that actually stay parallel.
+Draw five static parallel segments.
@@ -80 +82 @@
-Turn the fifth off and a second preview appears. Lines that should stay parallel begin to diverge. The postulate was doing work; without it, the picture fractures.
+This function switches preview visibility. It supplies no alternative metric or line construction, so it cannot demonstrate the independence of a postulate. The active branch also leaves the other preview’s visibility unchanged.
@@ -89 +91 @@
-Five names across two millennia. Every one tried to prove the fifth from the first four. Every one failed — because it is independent.
+These names belong to different contributions to geometry; the list does not establish that they all attempted the same proof.
@@ -99 +101 @@
-The door waits until the scroll has been dwelt with. Reading is the action, not clicking.
+This proposed handler needs a reading event and a door object. Neither is supplied here or promised by the installed hall.
@@ -101 +103 @@
-You have seen geometry as a list of choices. The next map, NonEuclidean Spaces, turns the fifth postulate off and walks what remains.
+Next, NonEuclidean Spaces compares explicit distance models. Hiding a preview does not change the geometry of the museum.
````

### commons/maps/NonEuclidean_Spaces/final.md

````diff
--- before/commons/maps/NonEuclidean_Spaces/final.md
+++ after/commons/maps/NonEuclidean_Spaces/final.md
@@ -17,0 +18,2 @@
+
+Return to the last hall's question about parallels. In the Euclidean plane, one line through a point off a given line avoids meeting it. On the sphere, any two distinct great circles meet twice, at antipodal points. In the hyperbolic disk, more than one geodesic through a point off a given geodesic can avoid meeting it. These are consequences of the respective models; the triangle bench does not itself perform all three parallel tests. Each model supplies its own account of straightness.
````

### commons/maps/NonEuclidean_Spaces/tutorial.md

````diff
--- before/commons/maps/NonEuclidean_Spaces/tutorial.md
+++ after/commons/maps/NonEuclidean_Spaces/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed triangle workbench switches between PLANE, SPHERE and DISK. Its angle calculation uses edge tangents in the selected model. The separate curvature slider changes a surface sketch. The radial warp below supplies neither those metrics nor their geodesics; it is not a reconstruction of that workbench.
@@ -11 +13 @@
-Two alternatives, equally consistent with the first four postulates. Build a curvature slider that moves continuously between hyperbolic, Euclidean, and elliptic space.
+Inspect the difference between deforming coordinates and defining a distance model. The installed hall compares three hosts; this older sketch only alters a drawing.
@@ -26 +28 @@
-A single scalar controls everything. Negative is hyperbolic, zero is Euclidean, positive is elliptic. The slider is the curvature.
+This scalar is a deformation parameter. Its sign and name do not give the mesh a hyperbolic or spherical metric.
@@ -38 +40 @@
-The grid starts flat. Each frame, vertices warp according to the current curvature. The mesh is the same vertex list differently placed.
+Each call overwrites the stored vertices. Repeated calls compound the warp rather than rebuilding from a retained original. The snippet has no frame callback and does not define grid_mesh.update_from.
@@ -49 +51 @@
-Parabolic scaling with distance from origin. Close to the slider, the warp is subtle; far away, it bends dramatically.
+The multiplier depends on squared distance from the origin. For vertices in the plane y = 0, the result remains in that plane. It does not create the hall’s sphere or saddle.
@@ -51 +53 @@
-Draw two parallel geodesics.
+Inspect the paths called geodesics in this prototype.
@@ -60 +62 @@
-Two lines start parallel. At k=-1 they diverge.
+The paths begin with parallel directions. At k = 0 the warp is the identity. Their behaviour at other values must not be used as evidence for spherical or hyperbolic parallels: no corresponding metric has been supplied.
@@ -62,3 +64 @@
-At k=0 they stay parallel. At k=+1 they converge and meet.
-
-Integrate a geodesic step by step.
+Inspect the path update.
@@ -78 +78 @@
-Forty steps per geodesic. Direction updates each step by tangent to the warped grid. The line walks the curvature rather than assuming it.
+Forty iterations update a direction using differences of warped positions. Calling this function _geodesic does not establish that its paths are geodesics in any of the three intended models.
@@ -89 +89 @@
-Hyperbolic, euclidean, elliptic. The slider passes through all three continuously. No regime is privileged.
+These are thresholded labels, not measured geometries. In a replacement lesson, select the host model explicitly and compute angles from its edge tangents, as the installed workbench does.
@@ -99 +99 @@
-Cool toward negative, warm toward positive. The learner's steps tell them which geometry they're inside.
+The parameter changes the tint. It changes neither the player’s movement metric nor the geometry of the museum floor.
@@ -101 +101 @@
-You have moved continuously through three geometries. The next map, Russell Paradox, turns from geometry to logic and finds the first genuine contradiction.
+Keep the distinction between a declared model and a persuasive picture. Russell Paradox next asks whether a declared membership rule can be satisfied.
````

### commons/maps/Russell_Paradox/final.md

````diff
--- before/commons/maps/Russell_Paradox/final.md
+++ after/commons/maps/Russell_Paradox/final.md
@@ -44 +44 @@
-In standard ZF with Foundation, no set belongs to itself. Other choices of axioms require their own examination. “Self-reference is bad” would teach us too little: a program can name itself without collapsing, and a recursive call can have a perfectly good stopping condition. We need to find the particular demand that cannot be met.
+In standard ZF with Foundation, no set belongs to itself. Other choices of axioms require their own examination. “Self-reference is bad” would teach us too little: a program can name itself without collapsing, and a recursive call can have a perfectly good stopping condition. We need to find the particular demand that cannot be met: unrestricted comprehension asks for a set whose self-membership holds exactly when it does not. Neither naming oneself nor using negation alone imposes that demand.
@@ -70 +70 @@
-The returning postulates plaque keeps the earlier question in view. Changing the parallel postulate led to other geometries. Russell asks us to withdraw a different permission: we cannot assume that every description calls a set into being. We can still state the question. Indeed, stating it carefully is how we learn why the unrestricted set cannot exist.
+The returning postulates plaque keeps the earlier question in view. Changing the parallel postulate led to other geometries. Independence from the remaining geometric assumptions left a choice of models; the unrestricted Russell demand gives a contradiction. Russell asks us to withdraw a different permission: we cannot assume that every description calls a set into being. We can still state the question. Indeed, stating it carefully is how we learn why the unrestricted set cannot exist.
````

### commons/maps/Russell_Paradox/tutorial.md

````diff
--- before/commons/maps/Russell_Paradox/tutorial.md
+++ after/commons/maps/Russell_Paradox/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed workbench tests IN and OUT against the unrestricted demand, then against a finite domain. Its lesson controls are enabled and it starts at cell 5. The box sketch below needs declared labels, nodes and event connections; it does not construct an unrestricted Russell set.
@@ -12 +14 @@
-The set of all sets that don't contain themselves. Build two boxes and the third box that breaks both.
+Inspect a finite membership filter, then distinguish it from the unrestricted demand tested by the installed workbench.
@@ -26 +28 @@
-A box holds named members. `contains_self` checks whether the box's own label is in its own member list. Recursion as a property.
+A box holds named members. `contains_self` checks whether the box's own label is in its own member list. A self-label in data is not a recursive function call.
@@ -38 +40 @@
-Build Russell's set.
+Filter a supplied finite collection.
@@ -49 +51 @@
-The filter returns all boxes that do not contain themselves. This list is the rule for the third box.
+The filter returns labels from the supplied all_sets array at that moment. Its finite domain and the time of evaluation matter.
@@ -51 +53 @@
-Create the paradox box.
+Store the snapshot in another box.
@@ -59 +61 @@
-Russell's box collects every non-self-containing box. Then ask whether it belongs to itself.
+The result contains labels selected from the supplied domain. Storing it does not make it satisfy unrestricted comprehension or update it when its inputs change.
@@ -72 +74 @@
-Either answer produces the opposite requirement. The function returns the two halves of the paradox as a sentence.
+These strings state the two consequences of the unrestricted demand. They do not prove that the finite snapshot just constructed satisfies that demand.
@@ -83 +85 @@
-The box pulses because it cannot resolve. Its geometry is a visual restlessness.
+The box pulses because _process changes its scale with a sine. The animation illustrates restlessness; no logical contradiction forces it to move.
@@ -94 +96 @@
-The alarm is not playful. Naive set theory is broken at the foundation. The readout says so in full.
+This proposed opening handler triggers an alarm and a text display. The membership argument, not the alarm, identifies the inconsistent unrestricted assumption.
@@ -112 +114 @@
-The counts let the learner compare sizes at a glance. Russell's count shifts whenever a non-self-containing set is added elsewhere in the room.
+The counts report stored array lengths when this function is called. No automatic recollection or change listener is supplied here.
@@ -122 +124 @@
-Classical inference halts. The lamp darkens. The room makes the failure of the system visible.
+This disables a proposed node named classical_engine. No inference engine is defined here; switching a property is not a logical derivation.
@@ -133 +135 @@
-Reset clears the paradox and re-enables inference. The learner can rebuild from scratch. The sequence continues.
+Reset clears the stored array and changes two supplied-node properties. It does not repair the unrestricted definition. The replacement lesson must test both Boolean assumptions and then show what restricting the domain changes.
````

### commons/maps/Godel_Incompleteness/tutorial.md

````diff
--- before/commons/maps/Godel_Incompleteness/tutorial.md
+++ after/commons/maps/Godel_Incompleteness/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The current hall separates statements about proof from bounded searches and visual representations. The sketch below does not implement Gödel numbering, a proof calculus or an incompleteness proof. Its verdict strings must not be treated as test results.
@@ -11 +13 @@
-Encode statements as numbers. Build a statement that refers to its own unprovability and watch the system refuse to prove or disprove it.
+Inspect why a label about unprovability is not an incompleteness proof. A reconstruction must distinguish a checked proof from an unsuccessful bounded search.
@@ -13 +15 @@
-Declare a Gödel encoding.
+Inspect the proposed numeric encoding.
@@ -25 +27 @@
-A toy encoding using primes. Real Gödel numbering is more careful; the principle is the same. Statements become integers, and integers become arguments inside arithmetic.
+This encoding loses information: characters with the same remainder modulo 10 collide, primes are reused, and the integer can overflow. It cannot serve as the required recoverable encoding of syntax.
@@ -27 +29 @@
-Decode a code back to a key.
+Make a truncated display key.
@@ -34 +36 @@
-The decoded key is what the system uses to look up a statement. Lookup on integers is the trick that lets the system talk about itself.
+Modulo 100000 discards more information. This function formats a key; it does not decode a statement or supply a lookup table.
@@ -46 +48 @@
-The statement is stored as text and as a code. The system can hold both representations and reason about the code numerically.
+The snippet stores a sentence and computes a number. It supplies neither an arithmetic representation of provability nor the diagonal construction needed for the theorem.
@@ -59 +61 @@
-A finite search. The function returns either a proof or the absence of one within the depth budget. Gödel's theorem says the absence is permanent, not a budget issue.
+The helper _derives is undefined. The loop repeats the same call without advancing a search state. Even a working bounded search returning not found would not establish unprovability.
@@ -61 +63 @@
-Detect the impossibility.
+Inspect the unsupported verdict strings.
@@ -72 +74 @@
-Either outcome is an incompleteness. The text says so. The formal system is closed; the question is not.
+Neither verdict follows from the supplied program. In particular, not found does not mean true or unprovable. These strings are claims to replace, not successful assertions about a tested proof system.
@@ -82 +84 @@
-Cream-yellow on a stone plaque. The verdict is not rewritten on each visit; the result is stable and inescapable.
+This formats the returned string. Colour and persistence give it no additional warrant.
@@ -94 +96 @@
-You have encountered the hardest limit on formal systems. The next map, Escher Impossible, translates the limit into architecture the body can walk.
+Keep the distinction between a statement and its warrant. Escher Impossible next tests a different matter: height differences around a model, not a spatial proof of Gödel’s theorem.
````

### commons/maps/Escher_Impossible/final.md

````diff
--- before/commons/maps/Escher_Impossible/final.md
+++ after/commons/maps/Escher_Impossible/final.md
@@ -41 +41 @@
-Cycle back. Five arrangements, five ways of handling the desire to keep going up. Which one first persuaded you that it might?
+Cycle back. In a closed route the measured gains must be returned; the model can relocate that return, but cannot remove it. OPEN RUN and SCAFFOLD leave the route unfinished. TILTED TREADS changes what the eye follows while the measured centres stay level. Five arrangements, five ways of handling the desire to keep going up. Which one first persuaded you that it might?
@@ -67 +67 @@
-The pipe has been waiting beside the first experiment: *Ceci n'est pas une pipe.* A mesh, a frame, a sentence. You recognised a pipe before asking what you could do with it.
+The pipe has been waiting beside the first experiment: *Ceci n'est pas une pipe.* A mesh, a frame, a sentence. You recognised a pipe before asking what you could do with it. The engine can render this object consistently without fulfilling everything its image promises. A representation needs another kind of evidence before it can answer for the thing represented.
````

### commons/maps/Escher_Impossible/tutorial.md

````diff
--- before/commons/maps/Escher_Impossible/tutorial.md
+++ after/commons/maps/Escher_Impossible/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed STEP control measures changes between tread centres. FORM compares RETURN SIDE, CLOSING DROP, OPEN RUN, SCAFFOLD and TILTED TREADS. Reconstruct that measurement and its closed-route check. The fragments below omit the corners array and scene setup and do not build an impossible staircase.
@@ -11 +13 @@
-Local truth, global impossibility. Build a staircase where every step is correct and the whole cannot exist.
+Inspect a finite list of heights. Predict the return difference before adding the closing edge.
@@ -24 +26 @@
-Four sides, each rising by the same amount. The graph is a perimeter loop with monotonic height. Locally consistent by construction.
+SIDES declares four directions, but build_corners below uses only their count. It does not use those directions to make a perimeter.
@@ -39 +41 @@
-Four corners, each raised by rise_per_side above the previous. Every edge feels like a normal staircase.
+The function places four boxes in a row with three rises between their centres. It does not populate the corners array required by the later fragments.
@@ -55 +57 @@
-The edge from the last corner back to the first is the impossibility. Height has risen four times; the return edge must descend all four rises in one step or the loop does not close.
+If those four centres are stored, the closing edge descends three rises. That is a possible segment, and exactly the height needed to close the route.
@@ -65 +67 @@
-The seam only disappears from one viewing angle. The illusion depends on perspective. Move your head and the trick shows.
+The dot-product threshold hides a segment over a range of viewing directions. This is an explicit visibility switch, not the installed perspective study.
@@ -76 +78 @@
-The creature walks forever. Each step is valid locally. The loop never ends because height climbs every leg.
+With a populated corners array and advancing t, interpolation traverses each edge and wraps to the first point. The closing leg descends.
@@ -86 +88 @@
-Each edge reports its height change. All four read positive. The contradiction is global only; no edge is lying.
+For the four centres above and a positive rise, three differences are positive and the closing difference is negative. Their signs expose the return directly.
@@ -100 +102 @@
-The sum around the loop must be zero for the staircase to close. The plaque shows it is not. Gödel's result, rendered as a floor plan.
+The cyclic differences telescope to zero, up to floating-point rounding: each height is added once and subtracted once. This is the check to assert in the replacement lesson. It is not an incompleteness result.
@@ -102 +104 @@
-You have walked a local truth with a global impossibility. The next map, Brouwer Intuitionism, responds by restricting logic to what can be built.
+The current exhibit moves a marker while the player stays on the museum floor. Brouwer Intuitionism next asks what a construction can witness.
````

### commons/maps/Brouwer_Intuitionism/final.md

````diff
--- before/commons/maps/Brouwer_Intuitionism/final.md
+++ after/commons/maps/Brouwer_Intuitionism/final.md
@@ -51 +51 @@
-The constructive demand asks for that missing identification. It changes what we accept as evidence. It does not make every classical proof worthless, or require every mathematical object to be a physical object we have touched.
+The constructive demand asks for that missing identification. It changes what we accept as evidence. An existence proof that supplies no witness may need a different construction, and some classical conclusions cannot be carried over unchanged. This is work within mathematics, including analysis, rather than the loss of analysis itself. It does not make every classical proof worthless, or require every mathematical object to be a physical object we have touched.
@@ -67 +67 @@
-This is a finite stage of diagonalisation. The mathematical argument for infinite binary sequences applies the same rule to every row of a proposed countable list. The headset displays finite strings, up to 32 bits here. Their disagreement is real and inspectable; displaying it does not display the completed infinite object.
+This is a finite stage of diagonalisation. The mathematical argument for infinite binary sequences applies the same rule to every row of a proposed countable list. The headset displays finite strings, up to 32 bits here. Their disagreement is real and inspectable; displaying it does not display the completed infinite object. Here the red string is the witness: you watched it being made and can check its difference from each displayed row.
````

### commons/maps/Brouwer_Intuitionism/tutorial.md

````diff
--- before/commons/maps/Brouwer_Intuitionism/tutorial.md
+++ after/commons/maps/Brouwer_Intuitionism/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed choice bench appends a 0 or 1 only when you press a button; the diagonal workbench constructs a string differing from every displayed row. These are the reconstruction targets. The checklist and physical proof-block bench below are an earlier proposal, not the current room or a proof checker.
@@ -11 +13 @@
-No existence without construction. Build a room where claims are only valid if the learner assembles them step by step.
+Inspect this older checklist proposal alongside the installed finite-prefix and diagonal studies. A recorded action and a mathematical proof require different validation.
@@ -24 +26 @@
-A proposition has a name and a record of construction. It is not true until `constructed` flips. Proof is assembly, not assertion.
+This resource records a name, a Boolean and strings. Flipping constructed records a program state; it does not make a proposition true or prove it.
@@ -45 +47 @@
-Each step is a text operation the learner performs. The display updates so the learner sees the proof growing in front of them.
+This appends a string to a checklist. No inference rule is checked.
@@ -58 +60 @@
-Required steps are listed per proposition. Missing any means the proposition stays unconstructed. No proof by absence.
+The missing required_steps_for helper would supply a checklist. Testing string membership does not check order, dependencies or logical validity.
@@ -60 +62 @@
-Reject law of excluded middle.
+Report the stored construction status.
@@ -69 +71 @@
-Classical logic returns either "true" or "false" for every proposition. Brouwer's room returns "not yet constructed" instead of "false". The third option is the whole point.
+Not yet constructed is a status message, not a third truth value. Classical logic does not provide an algorithm deciding every proposition. This function implements neither classical nor intuitionistic logic.
@@ -92 +94 @@
-Blocks are physical. The learner assembles proofs by moving blocks onto the bench. Construction is a bodily act.
+This proposes instancing block scenes; it supplies no pickup, assembly or proof-validation behaviour. The installed hall instead lets the visitor choose bits and inspect a diagonal witness.
@@ -106 +108 @@
-You have built without proving by contradiction. The next map, Florensky Paraconsistent, accepts contradictions without collapse.
+Intuitionistic logic still uses contradiction to establish negations; double-negation elimination is unavailable in general. Florensky Paraconsistent next distinguishes conflicting reports from the consequences they license.
@@ -119 +121 @@
-The tally rises only when propositions are actually built. Claims without construction do not count. The tally is a running honesty check.
+The tally counts true constructed flags. Its reliability depends on validation that this sketch has not supplied.
````

### commons/maps/Florensky_Paraconsistent/final.md

````diff
--- before/commons/maps/Florensky_Paraconsistent/final.md
+++ after/commons/maps/Florensky_Paraconsistent/final.md
@@ -70 +70 @@
-Brouwer's hall asked what you could construct and what counted as a witness. This hall asks what follows when the available claims conflict. One question does not answer the other.
+Brouwer's hall asked what you could construct and what counted as a witness. This hall asks what follows when the available claims conflict. One tightens what warrants an assertion; the other limits what incompatible premises license us to conclude. They change different demands, and one response does not supply the other.
````

### commons/maps/Florensky_Paraconsistent/tutorial.md

````diff
--- before/commons/maps/Florensky_Paraconsistent/tutorial.md
+++ after/commons/maps/Florensky_Paraconsistent/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed gate stores OPEN and CLOSED as independent reports and leaves an unrelated alarm claim unsupported. Reconstruct that limited record. The confidence model below is an earlier comparison, not the gate, a paraconsistent inference engine or a quantum simulation.
@@ -11 +13 @@
-Classical logic collapses from one contradiction. Florensky's supralogic holds both. Build a Schrödinger box where A and not-A coexist.
+Distinguish storing conflicting reports from deriving consequences. The current gate demonstrates a limited record; Florensky’s religious antinomies do not supply a single established formal logic.
@@ -35 +37 @@
-Equal confidence in both states. The box is properly superposed before any observation. Classical logic would already have panicked.
+Two equal confidence values do not constitute quantum superposition or a logical contradiction. Uncertainty between alternatives is compatible with classical logic.
@@ -47 +49 @@
-Lavender, translucent. The sphere is readable from every angle. Its colour shifts gently as confidences diverge.
+This assigns one constant translucent colour. No connection from confidence to colour is supplied.
@@ -61 +63 @@
-A nudge shifts confidence but never zeroes the opposite. Both sides stay in play. The system is tolerant of disagreement.
+The clamp permits either value to reach zero or one. The two values are linked to sum to one; they are not the independent report flags used by the installed gate.
@@ -63 +65 @@
-Run classical inference on the stable parts.
+Filter by a confidence threshold.
@@ -73 +75 @@
-Only near-certain claims pass to classical inference. The box shields the rest of the system from its own superposition.
+This returns a label when its confidence exceeds 0.9. No classical inference engine is called.
@@ -75 +77 @@
-Detect ex falso prevention.
+Check membership in the filtered labels.
@@ -82 +84 @@
-Any derivation must cite a safe claim. Contradictions exist in the box; they cannot escape as "anything follows."
+This Boolean tests list membership. It defines no derivation rules and cannot establish that a logic is paraconsistent.
@@ -93 +95 @@
-Two dials, one sum. The sum is always 1.0; the distribution is what changes. The box is stable under contradiction.
+After initialization and these nudges, the two values sum to one, within floating-point precision. That arithmetic invariant is different from a rule about contradictory premises.
@@ -95 +97 @@
-You have held both A and not-A. The next map, Crisis Synthesis, gathers the four responses into a single architecture.
+Reconstruct the independent report store before claiming to have reproduced the gate. Crisis Synthesis returns to several encounters and recalls Brouwer’s choice bench from the preceding hall.
````

### commons/maps/Crisis_Synthesis/final.md

````diff
--- before/commons/maps/Crisis_Synthesis/final.md
+++ after/commons/maps/Crisis_Synthesis/final.md
@@ -69 +69 @@
-A system can contain a description of itself. This atrium makes that relation approachable. Gödel's argument required something more specific: an effective arithmetic theory able to encode statements and proofs, together with the relevant consistency or soundness assumptions. A model on a plinth does not perform that proof.
+A system can contain a description of itself. This atrium makes that relation approachable. Gödel's argument required something more specific: an effective arithmetic theory able to encode statements and proofs, together with the relevant consistency or soundness assumptions. A model on a plinth does not perform that proof. A weaker theory can be complete. The obstruction concerns consistent, effectively axiomatized theories with enough arithmetic, not every system that describes itself.[^4]
@@ -121,0 +122,2 @@
+
+[^4]: Olivier Bournez, [*Gödel Incompleteness Theorem*, INF412 course notes](https://www.enseignement.polytechnique.fr/informatique/INF412/uploads/Main/chap10english-goodINF412ENGLISH.pdf), states the effective-theory and arithmetic hypotheses. The scope of the theorem matters when a miniature room supplies the image of self-description.
````

### commons/maps/Crisis_Synthesis/tutorial.md

````diff
--- before/commons/maps/Crisis_Synthesis/tutorial.md
+++ after/commons/maps/Crisis_Synthesis/tutorial.md
@@ -1,0 +2,2 @@
+
+**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The current hall has eleven placed artifacts, including the formula study, separate controls and the returning encounters. Brouwer’s choice bench is recalled from its own hall, not placed here. The four-wing summit below is an earlier proposal. The installed sentence-authority study is identified separately at the end.
@@ -10 +12 @@
-Four wings, one summit, one complete formula. Build the synthesis that turns crisis into capacity.
+Inspect the earlier four-wing proposal, then use the installed sentence study below to change a presentation while keeping its words fixed.
@@ -26 +28 @@
-Four wings, four names, four words. The registry is the map key. Each wing hosts one artifact from the sequence.
+This is a proposed name-to-topic dictionary. It is not the current map registry and does not place artifacts by itself.
@@ -52 +54 @@
-The complete formula for the first time. Earlier maps showed fragments. The summit holds the whole.
+The label prints the formula. The current study treats its terms as a research proposal requiring defined quantities and units; displaying the expression does not validate it.
@@ -65 +67 @@
-The bifurcation rides λ. Low λ is stable; moving λ up opens doublings and then chaos. The diagram explains the critical zones visually.
+This samples a proposed _logistic_step once for each starting value. It does not generate a bifurcation diagram, which requires iterating and discarding a transient for each parameter. The installed diagram has its own r control, independent of λ.
@@ -79 +81 @@
-Each slider rewrites the summit's readout. The wings update to show what their response implies under the current parameters.
+These callbacks propose a coupling that is not installed. In the current hall λ and φ update their own displays; the logistic diagram keeps its separate parameter.
@@ -89 +91 @@
-Proximity is the trigger, not a button. Walking toward Gödel unlocks Gödel. The learner pieces the argument together at their own pace.
+This proposed handler would need a proximity signal and a wing scene with the stated method. It is not the current hall’s access rule.
@@ -100 +102 @@
-All four wings must be visited before the summit lights fully. The formula only reads complete after every response to the crisis has been witnessed.
+This is proposed visit tracking, not an installed completion requirement. The current hall does not require four wing visits to display its formula.
@@ -102 +104 @@
-You have assembled the crisis into capacity. The next map, Chamber Foundations, embodies Gödel as a creature you cannot distinguish from itself.
+The next sequence is the QFEP laboratory. Carry the distinction between the displayed proposal, the implemented model and evidence for its claims.
@@ -114 +116 @@
-A gentle pulse once the four wings are visited. The pulse is slow enough to read as breath.
+This changes the light whenever called; it contains no visit check. Connecting it to a completion event is absent from the sketch.
````

### commons/maps/sequences/foundationscrisis.json

````diff
--- before/commons/maps/sequences/foundationscrisis.json
+++ after/commons/maps/sequences/foundationscrisis.json
@@ -89,86 +89,122 @@
-		{
-		  "map": "Euclid_Parallel",
-		  "position": "intro",
-		  "artifacts": [
-			"parallel_lines",
-			"angle_sum_triangle",
-            "euclid_postulates_plaque"
-		  ],
-		  "size_budget": "compact_only",
-		  "rationale": "Three compact geometry artifacts introduce Euclidean certainty with minimal density"
-		},
-		{
-		  "map": "NonEuclidean_Spaces",
-		  "position": "intro",
-		  "artifacts": [
-			"hyperbolic_surface",
-			"elliptic_surface",
-			"curvature_slider",
-			"poincare_disk",
-            "riemann_sphere"
-		  ],
-		  "size_budget": "mixed",
-		  "rationale": "Five artifacts across split dual landscape; surfaces are room_scale, slider and models compact"
-		},
-		{
-		  "map": "Russell_Paradox",
-		  "position": "foundation",
-		  "artifacts": [
-            "russell_set_box"
-		  ],
-		  "size_budget": "compact_only",
-		  "rationale": "Single focused artifact at center of nested concentric structure embodies self-reference"
-		},
-		{
-		  "map": "Godel_Incompleteness",
-		  "position": "exploration",
-		  "artifacts": [
-            "godel_statement_plaque"
-		  ],
-		  "size_budget": "compact_only",
-		  "rationale": "Single plaque artifact; the spatial layout of unreachable islands carries the concept"
-		},
-		{
-		  "map": "Brouwer_Intuitionism",
-		  "position": "exploration",
-		  "artifacts": [
-			"excluded_middle_demo",
-			"constructive_proof",
-            "brouwer_choice_sequence"
-		  ],
-		  "size_budget": "compact_only",
-		  "rationale": "Three compact artifacts on stepping-stone platforms; fragmented layout enacts constructivism"
-		},
-		{
-		  "map": "Florensky_Paraconsistent",
-		  "position": "integration",
-		  "artifacts": [
-			"florensky_sphere",
-			"schrodinger_box",
-            "superposition_display"
-		  ],
-		  "size_budget": "mixed",
-		  "rationale": "Three artifacts across overlapping diamonds; sphere is room_scale centerpiece, others compact"
-		},
-		{
-		  "map": "Crisis_Synthesis",
-		  "position": "synthesis",
-		  "artifacts": [
-			"qfep_formula_3d",
-			"lambda_slider",
-			"phi_slider",
-			"bifurcation_diagram",
-			"goedel_atrium",
-			"russell_paradox_workbench",
-			"godel_statement_plaque",
-			"russell_set_box",
-			"escher_staircase",
-			"florensky_sphere",
-            "sentence_authority"
-		  ],
-		  "size_budget": "environment",
-		  "rationale": "Level 19 by 24 gallery: local formula reading, independent logistic-map control, walk-in recursive atrium, Russell workbench and four retained comparisons.",
-		  "application_studies": {
-			"sentence_authority": "Change one sentence once; follow the same words across label, strip and wall."
-		  }
-		}
+	    {
+	      "map": "Euclid_Parallel",
+	      "position": "intro",
+	      "artifacts": [
+	        "science_screen",
+	        "euclid_postulates_plaque",
+	        "parallel_lines",
+	        "angle_sum_triangle"
+	      ],
+	      "size_budget": "compact_only",
+	      "rationale": "One postulates plaque has lesson_controls:on; the triangle and parallel-lines studies distinguish declarations from measurements. The screen is a grid display."
+	    },
+	    {
+	      "map": "NonEuclidean_Spaces",
+	      "position": "intro",
+	      "artifacts": [
+	        "film_curvature_triangle",
+	        "triangle_curvature_workbench",
+	        "curvature_slider",
+	        "elliptic_surface",
+	        "poincare_disk",
+	        "hyperbolic_surface",
+	        "riemann_sphere"
+	      ],
+	      "size_budget": "mixed",
+	      "rationale": "The triangle bench starts at PLANE and compares plane, sphere and disk using model-specific edge tangents. The separate slider only changes its own sketch; the saddle is not a constant-curvature hyperbolic metric."
+	    },
+	    {
+	      "map": "Russell_Paradox",
+	      "position": "foundation",
+	      "artifacts": [
+	        "euclid_postulates_plaque",
+	        "russell_paradox_workbench",
+	        "self_membership_set",
+	        "barber_paradox",
+	        "russell_set_box",
+	        "liar_loop",
+	        "hilbert_hotel"
+	      ],
+	      "size_budget": "compact_only",
+	      "rationale": "Seven placed artifacts replace the old single-box record. The workbench has membership_controls:on and initial_cell:5; IN/OUT tests lead to the restricted finite domain. The returning plaque keeps independence distinct from contradiction."
+	    },
+	    {
+	      "map": "Godel_Incompleteness",
+	      "position": "exploration",
+	      "artifacts": [
+	        "negative_control_fixture",
+	        "critic_regress_stack",
+	        "godel_sentence_machine",
+	        "rice_verifier_booth",
+	        "print_gallery_recursion",
+	        "synthesis_stand",
+	        "fluency_seam",
+	        "godel_statement_plaque",
+	        "provability_sorter",
+	        "incompleteness_tower"
+	      ],
+	      "size_budget": "compact_only",
+	      "rationale": "Ten placements include the sentence machine, verifier and regress comparisons, plaque, provability sorter and tower. The final distinguishes a bounded search from an unprovability theorem; the old island/plaque-only record is obsolete."
+	    },
+	    {
+	      "map": "Escher_Impossible",
+	      "position": "exploration",
+	      "size_budget": "mixed",
+	      "artifacts": [
+	        "magritte_pipe",
+	        "escher_staircase",
+	        "penrose_triangle",
+	        "impossible_trident"
+	      ],
+	      "rationale": "STEP reads tread-centre heights with lesson_controls:on. Closed routes balance ascent/descent; OPEN RUN and SCAFFOLD stop before closing; TILTED TREADS has level centres. The Penrose study tracks the viewer."
+	    },
+	    {
+	      "map": "Brouwer_Intuitionism",
+	      "position": "exploration",
+	      "artifacts": [
+	        "brouwer_choice_sequence",
+	        "intractable_evidence",
+	        "constructive_proof",
+	        "cantor_diagonal_workbench",
+	        "excluded_middle_demo",
+	        "angle_sum_triangle",
+	        "constructive_staircase",
+	        "parallel_lines"
+	      ],
+	      "size_budget": "compact_only",
+	      "rationale": "visitor_choices:on enables a finite 0/1 prefix; the diagonal bench constructs an inspectable finite witness. Timed stairs and supplied geometry remain comparisons, not hand-built proofs or general proof checkers."
+	    },
+	    {
+	      "map": "Florensky_Paraconsistent",
+	      "position": "integration",
+	      "artifacts": [
+	        "both_true_gate",
+	        "florensky_sphere",
+	        "superposition_display",
+	        "schrodinger_box"
+	      ],
+	      "size_budget": "mixed",
+	      "rationale": "The gate has report_controls:on; OPEN and CLOSED persist independently while Q has no support. The sphere has hold_both:on. The box uses a desktop-only random opening and the opacity display has no measurement operation."
+	    },
+	    {
+	      "map": "Crisis_Synthesis",
+	      "position": "synthesis",
+	      "artifacts": [
+	        "lambda_slider",
+	        "phi_slider",
+	        "qfep_formula_3d",
+	        "godel_statement_plaque",
+	        "bifurcation_diagram",
+	        "goedel_atrium",
+	        "russell_paradox_workbench",
+	        "russell_set_box",
+	        "escher_staircase",
+	        "florensky_sphere",
+	        "sentence_authority"
+	      ],
+	      "size_budget": "environment",
+	      "rationale": "Eleven placements include reading_study:on, dispute-calibrated lambda/phi rails, an independent visitor-controlled logistic r starting at 3.2, the recursive atrium and sentence-authority study. Brouwer’s bench is recalled from its hall; there is no placed constructive wing or four-visit summit gate.",
+	      "application_studies": {
+	        "sentence_authority": "Change one sentence once; follow the same words across label, strip and wall."
+	      }
+	    }
````
