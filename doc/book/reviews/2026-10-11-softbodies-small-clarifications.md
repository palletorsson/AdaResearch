# Softbodies — small clarifications

11 October 2026. Scope: the selected prose changes requested after the nine-hall reading. This is an incremental edit of the current working-tree texts; earlier uncommitted work is retained.

## Decisions

- Deformation: add form as an ongoing result of retained relations. Correct the mill's contact claim in the reflection and its technical explanation.
- Carousel: let deformation make the consequences of the driven support visible, without claiming calibrated measurement.
- Obstacles: distinguish prescribed flag animation from pressure-driven soft-body response. Describe the visible outline of contact without claiming rigid bodies lose their history.
- Contact: identify High Drag versus Vacuum with coefficient variation disabled. Keep values and predict/replay instructions in the tutorial.
- Reaction–diffusion: remove the guaranteed reveal after 100 steps. Ask the reader to observe changes under the chosen rates and initial disturbance.
- Cloth already states its boundary-condition argument; no extra sentence needed. Keep the other four hall reflections unchanged, including Morphogenesis: its old passage measurements described a different volume.

## Source checks

- The nine halls' 61 artifact tokens and configurations match the current Endless Museum plan. No map or plan edits.
- `softmill.tscn` attaches `algorithms/physicssimulation/softbody3d/softbody3d.gd` to its sphere. `_setup_physics()` sets layer/mask 1/1; `rotating_arm.gd` sets 2/0. The desk's MILL action stops the non-SoftBody scripts while the sphere keeps its own script and simulation. It does not reconcile the filters.
- `flagdancer.gd` supplies bone poses from clock-based functions. The placed `breathing_room.tscn` instead uses `breathing_room_scene.gd` with `lesson:true`; it supplies oscillating pressure to its authored soft bodies.
- `softbody_test_gallery.gd`: High Drag and Vacuum share the sphere construction, cube collider and relative starting offsets. With coefficient variation off, their physical recipes differ in damping (.8 versus .01); Vacuum's pressure 0 repeats the default. This is the gallery comparison, not the learner's separate .1/.6 panel pair.
- The reaction hall places resolution 32 and centre seeding. Its technical record identifies the developed Stripes image as 1,000 steps; that is not a universal threshold or a new test in this pass.
- The Morphogenesis technical record already distinguishes the current rectangular scene volume from older eight-unit cubic-study measurements. No old clearance numbers restored.

## Verification

All fenced code and all HTML comments/lesson markers in the edited files are byte-identical to the pre-edit snapshot. Other snapshotted hall texts, map JSON, sequence JSON, museum plan and implementation files are unchanged. Changed-line whitespace checked. No new Godot or headset test; no runtime changes. No commit created in this pass.

## Exact prose changes

### commons/maps/SoftBodies_Soft_Body_Deformation/final.md

```diff
--- before/commons/maps/SoftBodies_Soft_Body_Deformation/final.md
+++ commons/maps/SoftBodies_Soft_Body_Deformation/final.md
@@ -7 +7 @@
-In the last sequence, a body followed from a description, a field or a sample. Here the description also includes conditions under which a body may keep changing. Its surface retains its connections. The positions those connections join are no longer still.
+In the last sequence, a body followed from a description, a field or a sample. Here the description also includes conditions under which a body may keep changing. Its surface retains its connections. The positions those connections join are no longer still. The form is something those relations keep producing.
@@ -25 +25 @@
-Turn toward the mill. Its moving apparatus brings a repeated encounter to a soft sphere. Stop the drive. The sphere's physics continues; something the mechanism has set in motion outlasts the mechanism's movement.
+Turn toward the mill. An arm revolves beside a soft sphere. Stop the drive and keep watching the sphere. Their closeness suggests an encounter the collision rules have not supplied.
@@ -27 +27 @@
-The cube exposes its coefficients. The mill exposes a source of disturbance. The room supplies further conditions: contact, support, gravity and the points required to stay. Which of these belongs to the object when we call the object soft?
+The cube exposes its coefficients. The mill makes contact itself a question. Support, gravity and the points required to stay still act on a body even when the encounter we imagined does not. Which of these belongs to the object when we call the object soft?
```

### commons/maps/SoftBodies_Soft_Body_Deformation/technical.md

```diff
--- before/commons/maps/SoftBodies_Soft_Body_Deformation/technical.md
+++ commons/maps/SoftBodies_Soft_Body_Deformation/technical.md
@@ -24 +24 @@
-Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.
+The mill's sphere runs `algorithms/physicssimulation/softbody3d/softbody3d.gd`, whose `_setup_physics()` explicitly sets collision layer 1 and mask 1. The rotating arm sets layer 2 and mask 0. Neither mask admits the other's layer. The hall desk does not change these filters, so the current setup cannot support the claim that the arm repeatedly strikes the sphere.
@@ -26 +26 @@
-The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.
+MILL disables the apparatus's scripted drive while leaving the SoftBody3D and its script active. The sphere retains its own pressure cycle and simulation; continued motion is not evidence of an earlier strike by the arm. This correction follows the placed scene and scripts, not a new runtime contact test.
```

### commons/maps/SoftBodies_Carusell/final.md

```diff
--- before/commons/maps/SoftBodies_Carusell/final.md
+++ commons/maps/SoftBodies_Carusell/final.md
@@ -9 +9 @@
-You have turned a body before. Here the turn reaches other bodies through an attachment. They meet the next movement with whatever the last one has left in them.
+You have turned a body before. Here the turn reaches other bodies through an attachment. They meet the next movement with whatever the last one has left in them. Their changing outlines make the pull of the moving support visible.
```

### commons/maps/SoftBodies_Obsticals/final.md

```diff
--- before/commons/maps/SoftBodies_Obsticals/final.md
+++ commons/maps/SoftBodies_Obsticals/final.md
@@ -19 +19 @@
-The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.
+The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. The soft body makes the encounter visible in its changing outline. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.
@@ -21 +21 @@
-The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the floor that carries you through this hall does not deform. A deforming wall and an onward route make different promises.
+The flag dancer makes a similar softness visible by another means: its ripples are prescribed by the clock. The walls receive a pressure wave; their shapes depend on the bodies' response. Yet the floor that carries you through this hall does not deform. A deforming wall and an onward route make different promises.
```

### commons/maps/SoftBodies_Obsticals_Part2/final.md

```diff
--- before/commons/maps/SoftBodies_Obsticals_Part2/final.md
+++ commons/maps/SoftBodies_Obsticals_Part2/final.md
@@ -7 +7 @@
-Names arrive before contact. High Drag invites us to expect resistance. Vacuum begins with the same zero pressure used as the gallery's default: its name supplies an event the setting has not specified. A familiar word can organise what we see before we have looked at what the body does.
+Names arrive before contact. High Drag invites us to expect resistance. Vacuum begins with the same zero pressure used as the gallery's default: its name supplies an event the setting has not specified. With extra variation off, these two cells let us follow a difference in damping while keeping the same shape and contact geometry. A familiar word can organise what we see before we have looked at what the body does.
```

### commons/maps/SoftBodies_Obsticals_Part2/tutorial.md

```diff
--- before/commons/maps/SoftBodies_Obsticals_Part2/tutorial.md
+++ commons/maps/SoftBodies_Obsticals_Part2/tutorial.md
@@ -20 +20 @@
-The existing gallery contains twelve named encounters. High Drag gives a sphere more damping; Corner Strike changes where it meets a collider. Other cells change shape, stiffness or pressure together. Looking across the array can suggest a question, but it does not isolate its cause.
+The existing gallery contains twelve named encounters. With VARIATION off, compare High Drag with Vacuum. Both use the same sphere mesh, cube collider and relative starting positions; their physical recipes differ only in damping: 0.8 versus the default 0.01. Vacuum's pressure 0 repeats the default; its name does not specify an implosion. Predict which body will settle sooner, replay, and watch both. Corner Strike changes the contact position instead, so it is not the matching case for this damping comparison.
```

### commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems/final.md

```diff
--- before/commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems/final.md
+++ commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems/final.md
@@ -5 +5 @@
-A small patch interrupts the pale field. Press STEP. Almost nothing seems to happen. Press a hundred steps. The boundary begins to matter. A name such as Spots or Maze may already have told you what to expect, but the field has not promised to become its label.
+A small patch interrupts the pale field. Press STEP. Almost nothing seems to happen. Advance in batches and watch the edge of the patch. What becomes visible depends on both the rates and the starting disturbance. A name such as Spots or Maze may already have told you what to expect, but the field has not promised to become its label.
```

