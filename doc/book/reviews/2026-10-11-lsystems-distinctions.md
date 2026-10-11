# L-systems: distinctions kept in the current halls

11 October 2026. Palle approved the selected L-systems clarifications and the Menger body-width correction. This pass changes seven reflective texts. The tutorials, printed code, artifacts, maps and museum plan are unchanged by this pass.

## What changed

| Hall | Reflective addition | Technical detail retained in tutorial.md |
| --- | --- | --- |
| Grammar Lab | Turning signs occupy the sentence without drawing; symbols without replacement pass through. | Symbol/segment counts, dictionary fallback, separate old/next strings. |
| Growth | F uses the current stride; STEP reveals a recorded reading; the interpreter gives instructions their consequences. | Complete saved-state inventory, deep copies, trace frames and cursor. |
| Grammars and Curves | Finite constructed paths do not occupy every point of a room. | The existing reflection-versus-rotation caption and explanation remain. |
| Architecture | Connected lines and a body's usable passages are two different accounts of connection. | The 0.6 m test capsule, actual collider checks and avatar distinction. |
| Living | The hand can cross a generation threshold or change branch geometry; Forks and Arrange supply parts of the replacement rule. | F becomes a stem and bracketed branches; S becomes FF; parameter conversion and interpreter code. |
| Shape Grammars | A face's normal explains the direction of extrusion; petal curvature follows a chosen rule without added noise. | Normal calculation, mesh replacement and selection/tag lineage. |
| Menger Sponge | Qualify the 40 cm capsule as the headset default at unit world scale; name the separate 64 cm desktop walker. | Passage remains something to test with the actual body. |

Assemblage already explains retained samples, changed decisions and changed marks. Competition keeps its focus on order and consumption. Neither text was changed. Growth's complete state inventory stays in the tutorial rather than becoming another list in the reflection.

The proposed description of two controls moving smoothly was qualified after inspection: the installed Living hand has 41 detent positions. The distinction is what the parameter changes, not a claim that this hand interface is continuous.

## Existing-map evidence

The sequence order remains Grammar Lab → Growth → Grammars and Curves → Architecture → Competition → Living → Shape Grammars → Assemblage. Current map tokens/configuration were compared with `commons/data/museum/em_plan.json`; all nine checked halls agree. No plan regeneration or map change was needed.

| Hall | Placed artifacts | Map/plan tokens and configuration |
| --- | ---: | --- |
| LSystems_Grammar_Lab | 8 | Match |
| LSystems_Growth | 5 | Match |
| LSystems_Grammars_And_Curves | 7 | Match |
| LSystems_Architecture | 9 | Match |
| LSystems_Competition | 3 | Match |
| LSystems_Living | 6 | Match |
| LSystems_Shape_Grammars | 2 | Match |
| Assemblage_Same_Desire | 9 | Match |
| Fractal_MengerSponge | 6 | Match |

Registry entries were followed to their scenes and active scripts. The relevant lesson flags are enabled in Grammar Lab, Growth, Curves, Architecture and Living. Menger has both lesson and flight_box enabled. The mesh family and canopy are installed in Shape Grammars; the floor-curve gallery and Hilbert3D remain in Curves.

- `commons/artifacts/lsystem_editor/lsystem_editor.gd`: dictionary fallback retains unmatched symbols; the reader separates movement from turning.
- `commons/artifacts/parametric_lsystem/parametric_lsystem.gd`: brackets save/restore position, orientation axes, depth, length and angle; the trace is generated during interpretation. `commons/artifacts/growth_lesson/growth_lesson.gd`: STEP increments the cursor into trace_frames.
- `commons/artifacts/space_filling_curve_gallery/space_filling_curve_gallery.gd` and `algorithms/lsystems/Hilbert3D.gd`: finite-depth constructions, retained as collection comparisons rather than new tutorial exercises.
- `commons/artifacts/architecture_lesson/architecture_lesson.gd`: footprints and boundary construction. `tools/probes/architecture_passage_room.gd` and `architecture_passage_lesson.gd`: the passage test creates a capsule with radius 0.3 m; this is a test fixture, not the avatar's declared size.
- `algorithms/nature_system/morphology/tree_morphology.gd`: Depth conversion, Forks-to-bracket-count mapping, Arrange-to-turn mapping, F and S productions. `commons/artifacts/genetic_tree_sculptor/living_hand.gd`: the hand position is rounded to 0–40 detents.
- `commons/artifacts/form_grammar_family/form_grammar_family.gd`, `commons/mesh_grammar/operations/extrude_face_op.gd`: selected faces extrude along their normals. `commons/artifacts/form_grammar_canopy/form_grammar_canopy.gd` and `commons/mesh_grammar/operations/petal_splay_op.gd`: authored curl, width and twist; no noise sampling.
- `commons/scenes/endless_museum_vr.tscn` instances `base.tscn`, which instances XRTools PlayerBody without a radius override. `addons/godot-xr-tools/player/player_body.gd` defaults to radius 0.2 m and scales it by XRServer.world_scale. `commons/scenes/endless_museum.gd` creates the desktop walker with radius 0.32 m. The separate visible doll mesh is not the collision capsule.

## Verification and commit boundary

This is source verification, not a new Godot or headset run. All nine tutorials are byte-identical to the start of this pass. Code fences and student-code markers in all eighteen checked texts are preserved. The source checks concern the current shared working tree.

The six L-systems finals already contained uncommitted revisions before this task. Their revised wording is retained; the targeted text commit includes those current drafts with these clarifications, the Menger footnote and this receipt. Other pending files are not staged. The differences below isolate this pass from the earlier revision, whose compression is not claimed as new work here.

## This pass: exact before/after receipt

### commons/maps/LSystems_Grammar_Lab/final.md

```diff
--- before/commons/maps/LSystems_Grammar_Lab/final.md
+++ after/commons/maps/LSystems_Grammar_Lab/final.md
@@ -11 +11 @@
-Advance again. More letters appear; the held drawing stays. Each F has become a short sequence of movements and turns. The new letters wait for the next generation before they too can be replaced. A small loop has a rhythm, and a place where its repetition must stop.
+Advance again. More letters appear; the held drawing stays. Each F has become a short sequence of movements and turns. The turning signs also occupy places in the sentence without leaving segments. A symbol without a replacement passes through unchanged. The new letters wait for the next generation before they too can be replaced. A small loop has a rhythm, and a place where its repetition must stop.
```

### commons/maps/LSystems_Growth/final.md

```diff
--- before/commons/maps/LSystems_Growth/final.md
+++ after/commons/maps/LSystems_Growth/final.md
@@ -15 +15 @@
-The dark sphere is our handle; the pale point records where the drawing has arrived. Step to the opening bracket. Nothing extends. The readout says SAVE. A state has been kept, and the next stride has shortened, although the point has not moved. An operation has taken place without adding anything to the outline.
+The dark sphere is our handle; the pale point records where the drawing has arrived. Step to the opening bracket. Nothing extends. The readout says SAVE. A state has been kept, and the next stride has shortened, although the point has not moved. An operation has taken place without adding anything to the outline. STEP reveals a reading already recorded by the interpreter; it does not pause the calculation between presses.
@@ -21 +21 @@
-It returns to the fork. The branch remains, with no return line joining its tip to the trunk. The next F continues upward from the saved place. The branch's turn and shorter stride have not become the trunk's next instructions.
+It returns to the fork. The branch remains, with no return line joining its tip to the trunk. The next F continues upward from the saved place. The branch's turn and shorter stride have not become the trunk's next instructions. F still means draw forward; the distance it travels depends on the state in which the turtle reads it.
@@ -37 +37 @@
-The animated tree, obstacle-querying tree, earlier L-system tree and cypress remain beyond the desk. They approach growth through other operations. Carry the saved state forward. In the next hall, even forward may be read sideways.
+The animated tree, obstacle-querying tree, earlier L-system tree and cypress remain beyond the desk. They approach growth through other operations. A sentence supplies instructions; an interpreter decides what they do. Carry the saved state forward. In the next hall, even forward may be read sideways.
```

### commons/maps/LSystems_Grammars_And_Curves/final.md

```diff
--- before/commons/maps/LSystems_Grammars_And_Curves/final.md
+++ after/commons/maps/LSystems_Grammars_And_Curves/final.md
@@ -45 +45 @@
-The tube bay is another encounter with a path, available beyond the main lesson. The finite floor curves and volumetric path also remain in the collection. In Architecture, the desire to inhabit a drawing becomes more demanding: a step acquires width, and a body will test where it can go.
+The tube bay is another encounter with a path, available beyond the main lesson. The finite floor curves and volumetric path also remain in the collection. Each visits a finite set of grid locations; none occupies every point of the room. In Architecture, the desire to inhabit a drawing becomes more demanding: a step acquires width, and a body will test where it can go.
```

### commons/maps/LSystems_Architecture/final.md

```diff
--- before/commons/maps/LSystems_Architecture/final.md
+++ after/commons/maps/LSystems_Architecture/final.md
@@ -21 +21 @@
-Try the wider version. What has changed is the space available to this body. Another body may require another opening. Adding more branches would not answer the question that width made concrete.
+Try the wider version. What has changed is the space available to this body. We now have two accounts of connection: one follows the lines, the other asks where this body can pass. Another body may require another opening. Adding more branches would not answer the question that width made concrete.
```

### commons/maps/LSystems_Living/final.md

```diff
--- before/commons/maps/LSystems_Living/final.md
+++ after/commons/maps/LSystems_Living/final.md
@@ -15 +15 @@
-The data structure is called DNA. Here that name describes parameters used to construct a body. It does not establish that the specimen is alive. Those values help produce a sentence, and the turtle reads it through the movements and returns we have learned.
+The data structure is called DNA. Here that name describes parameters used to construct a body. It does not establish that the specimen is alive. Forks chooses how many bracketed branches a replacement contains; Arrange chooses the turns between them. The turtle reads the resulting sentence through the movements and returns we have learned.
@@ -17 +17 @@
-Select Angle and move the dark point. Now a small change turns the branches without adding a generation. The hand meets a similar control, but the body changes differently. The appearance of an interface cannot tell us what kind of change it offers.
+Select Angle and move the dark point. Now a small change turns the branches without adding a generation. The same hand movement can cross a counting threshold in Depth or alter branch geometry in Angle. The appearance of an interface cannot tell us what kind of change it offers.
```

### commons/maps/LSystems_Shape_Grammars/final.md

```diff
--- before/commons/maps/LSystems_Shape_Grammars/final.md
+++ after/commons/maps/LSystems_Shape_Grammars/final.md
@@ -19 +19 @@
-Follow one projection down to the cube. Earlier steps remain in its surface. Beside it, a wider pair rises to the same height. The number of extensions stayed fixed; each inward movement became smaller. Another specimen begins on all twelve triangles, reaching sideways and down as well as up. Walk around to find the projections hidden from the entrance.
+Follow one projection down to the cube. Earlier steps remain in its surface. Beside it, a wider pair rises to the same height. The number of extensions stayed fixed; each inward movement became smaller. Another specimen begins on all twelve triangles, reaching sideways and down as well as up. Each extrusion follows its face's outward normal, the direction perpendicular to that face. Up belonged to the first selection of faces. Walk around to find the projections hidden from the entrance.
@@ -31 +31 @@
-Beside it, curved strips spread from the face's centre. Their tips lift and narrow; spaces remain between them. A different builder has entered. Its name, petal splay, brings a resemblance with it. Follow one strip closely enough to see the sampled turns in its surface.
+Beside it, curved strips spread from the face's centre. Their tips lift and narrow; spaces remain between them. A different builder has entered. Its name, petal splay, brings a resemblance with it. Follow one strip closely enough to see the sampled turns in its surface. No noise has been added; the curve follows a chosen rule.
```

### commons/maps/Fractal_MengerSponge/final.md

```diff
--- before/commons/maps/Fractal_MengerSponge/final.md
+++ after/commons/maps/Fractal_MengerSponge/final.md
@@ -51 +51 @@
-[^body]: The museum uses a collision capsule forty centimetres wide whose height follows the tracked head. Flight does not shrink it or remove collision with retained cubes. Crouching through a one-metre opening remains a bodily test, not a promised route. Within the glass enclosure, NEXT, BACK and RESET wait until everyone has left and a new press requests the change; GHOST and FRAME can still change the view.
+[^body]: The headset rig's default collision capsule is forty centimetres wide at unit world scale, with height following the tracked head. The desktop museum walker is sixty-four centimetres wide. Flight does not shrink it or remove collision with retained cubes. Crouching through a one-metre opening remains a bodily test, not a promised route. Within the glass enclosure, NEXT, BACK and RESET wait until everyone has left and a new press requests the change; GHOST and FRAME can still change the view.
```
