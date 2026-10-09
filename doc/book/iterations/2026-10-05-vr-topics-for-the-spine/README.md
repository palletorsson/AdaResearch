# VR topics through the Ada spine

5 October 2026. Research proposal.

27 researched candidates for the existing Endless Museum. Eight deserve the first editorial pass. The placements and exercises are proposals: they do not assert that a hall already implements or teaches the feature.

Keep the museum usable from Day Zero. Introduce a selected connection when the student can act on it, then return to it with greater depth. A supplied player, an authored operation and a critical reflection have different teaching responsibilities. The geometry and algorithm lineage remains central.

## How to read this list

- **Foundation:** Available from arrival; inspect selected principles later.
- **Core:** Strong candidate for a small authored operation in an existing tutorial.
- **Return:** Deepens an earlier capability after its prerequisites.
- **Optional:** Later branch or capstone; may require new implementation or hardware.

The eight first-pass choices are pickup/release, grip alignment, named actions, interaction state, targeting, snapping, feedback and surface painting. Spread them across their named halls; do not add them all to Coordinates.

## Source and implementation boundaries

- Godot's 3.1 VR starter is a historical teaching reference; implementation should use Ada's installed 4.6 code and plugins.
- Unity supplies interaction exercises, not directly usable Godot code.
- W3C XAUR is a Working Group Note about user needs, not a compliance standard.
- Official capability documentation is not proof that Ada currently delivers the proposed interaction.
- Hardware-dependent features require a supported runtime. Persistent anchors do not automatically save exhibit content or provide shared co-location.
- Recommendations do not change the spine, saved author choices, tutorial bodies, final.md or museum logic.

## Topics

### 01. Tracking space and local/world frames

**Foundation.** Proposed placement: Point_Coordinates → Trans_Translation.

**Builds on:** Vectors and parent/child transforms.

**Proposed activity:** Compare the carried sphere relative to its exhibit frame and to the world. Later distinguish physical walking from moving the origin.

**Source evidence:** The XR origin locates tracking space; the tracked head can move away from it. [Godot: room scale in XR](https://docs.godotengine.org/en/stable/tutorials/xr/xr_room_scale.html)

**Teaching boundary:** Keep distance calculation in Lines. The supplied player does not become a reconstruction exercise.

### 02. Scale, reach and accessible placement

**Foundation.** Proposed placement: Trans_Scale → Trans_Body.

**Builds on:** Position and scale.

**Proposed activity:** Change a pedestal height and keep the same operation reachable from a fixed seat. Offer an equivalent input when reaching is unsuitable.

**Source evidence:** XR guidance connects scale to the player; W3C identifies adjustable controls and alternatives to required physical movements. [Godot: setting up XR](https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html); [W3C: XR Accessibility User Requirements](https://www.w3.org/TR/xaur/)

**Teaching boundary:** Usable access belongs in the host from Day Zero. Teaching the geometry of reach can wait for Transformation.

### 03. Locomotion, teleportation and turning

**Foundation.** Proposed placement: Trans_Translation → Trans_Rotation → Trans_Body.

**Builds on:** Vectors, angles and conditions.

**Proposed activity:** Inspect one teleport acceptance rule or turn angle, then compare its effect on the route through a hall.

**Source evidence:** XR Tools provides teleport target checks and smooth or stepped turning. [XR Tools: teleport](https://godotvr.github.io/godot-xr-tools/docs/teleport/); [XR Tools: turning](https://godotvr.github.io/godot-xr-tools/docs/turn/)

**Teaching boundary:** Navigation is supplied on arrival. An optional return studies its rules without making lesson progress depend on smooth movement.

### 04. Picking up and releasing

**Core · First pass.** Proposed placement: Point_Coordinates.

**Builds on:** Named values; visible mesh versus collision.

**Proposed activity:** Carry the existing black sphere; inspect what enables pickup and what release restores.

**Source evidence:** XR Tools separates a pickable body's configuration from the controller's pickup function. [XR Tools: pickable objects](https://godotvr.github.io/godot-xr-tools/docs/pickable/); [XR Tools: pickup function](https://godotvr.github.io/godot-xr-tools/docs/pickup/)

**Teaching boundary:** Preserve the agreed Coordinates focus: pickable, 3D coordinates, local/world position.

### 05. Grip points, orientation and handedness

**Core · First pass.** Proposed placement: Point_Trace → Trans_Rotation.

**Builds on:** Pickup and local transforms.

**Proposed activity:** Inspect the existing pen's grip. Adjust one offset or angle so its tip remains useful in either hand.

**Source evidence:** Grab points define hand attachment and can distinguish left/right hands and hand poses. [XR Tools: grab points](https://godotvr.github.io/godot-xr-tools/docs/grab_point/)

**Teaching boundary:** A small return to Coordinates supports drawing. Keep pose authoring support supplied until rotation is understood.

### 06. Named actions and device bindings

**Core · First pass.** Proposed placement: Trans_Introduction → Color_Paint.

**Builds on:** Functions and named values.

**Proposed activity:** Have the prepared desktop and XR adapters call the same small artifact operation; inspect the action-to-function connection.

**Source evidence:** OpenXR actions give device inputs names and types; desktop input is a separate Godot input system. [Godot: XR action map](https://docs.godotengine.org/en/stable/tutorials/xr/xr_action_map.html)

**Teaching boundary:** Teach one binding. Do not imply one Godot InputMap automatically handles both systems or every controller.

### 07. Press, hold, release and interaction state

**Core · First pass.** Proposed placement: Trans_Introduction → Color_Paint.

**Builds on:** Boolean conditions; repeated updates.

**Proposed activity:** Trace idle → held → active → held for a spray can; identify the condition that allows a mark and the event that stops it.

**Source evidence:** XR actions can expose discrete buttons or analogue values; held-object activation is separate from pickup. [Godot: XR action map](https://docs.godotengine.org/en/stable/tutorials/xr/xr_action_map.html); [XR Tools: pickable objects](https://godotvr.github.io/godot-xr-tools/docs/pickable/)

**Teaching boundary:** Teach the small state transition before the whole spray system. Analogue pressure is a later return.

### 08. Near selection, distant pointing and ray hits

**Core · First pass.** Proposed placement: Color_Paint → ISO_Sculpting.

**Builds on:** Two positions, direction and conditions.

**Proposed activity:** Aim at two surfaces and show which one receives the operation. Move an occluder between tool and canvas.

**Source evidence:** XR Tools supports pointers; Godot ray queries return hit information and support filtering. [XR Tools: pointer](https://godotvr.github.io/godot-xr-tools/docs/pointer/); [Godot: ray casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)

**Teaching boundary:** Lines supplies direction and distance; ray-query implementation earns its place when the learner must target something.

### 09. Spatial drawing and sampling

**Core.** Proposed placement: Point_Trace → Point_Line_Grid.

**Builds on:** A position, a condition, then a list and loop.

**Proposed activity:** Record the learner's own path, vary sampling spacing, then reuse a derived grid version while keeping the original.

**Source evidence:** The Unity painting challenge distinguishes drawing activation and brush size; Ada supplies the trace/list learning opportunity. [Unity Learn: 3D painting challenge](https://learn.unity.com/pathway/vr-development/unit/events-and-interactions/tutorial/challenge-2-3d-painting-2)

**Teaching boundary:** Define units, frame, order and ownership before promising a cross-hall handoff. Add timestamps only when needed.

### 10. Two-hand manipulation

**Return.** Proposed placement: Trans_Rotation → Trans_Scale.

**Builds on:** Two points, distance, pivot and local transforms.

**Proposed activity:** Use two declared handles on one object; vary their separation or direction and compare the resulting scale or rotation.

**Source evidence:** XR Tools grab-point settings control how two hands contribute to position, angle and aim. [XR Tools: grab points](https://godotvr.github.io/godot-xr-tools/docs/grab_point/); [W3C: XR Accessibility User Requirements](https://www.w3.org/TR/xaur/)

**Teaching boundary:** Optional exercise requiring an equivalent one-hand control. Do not add full two-hand mathematics to the first grab lesson.

### 11. Snapping, docking and allowed fits

**Core · First pass.** Proposed placement: Array → Tutorial_Tiling_Floor → Color_Grid_Pallet.

**Builds on:** Addresses, object references and conditions.

**Proposed activity:** Place one known piece in a grid address; show a valid placement and an excluded placement, then alter the acceptance rule.

**Source evidence:** Snap zones can accept or reject object groups and define how objects enter a dock. [XR Tools: snap zones](https://godotvr.github.io/godot-xr-tools/docs/snap_zone/)

**Teaching boundary:** The array lesson leads with addressed storage. Snapping can make that decision tangible after the basics.

### 12. Collision bodies, masks and contact

**Core.** Proposed placement: Point_One → Vectors_Act4a_KineticForces → Boolean_Verbs.

**Builds on:** Visible form versus collision; conditions.

**Proposed activity:** Return to two similarly shaped bodies: change which pair can touch and observe the difference between visibility and contact.

**Source evidence:** XR Tools uses layers and masks to distinguish physical contact, pickup, pointers and other interactions. [XR Tools: physics layers](https://godotvr.github.io/godot-xr-tools/docs/physics_layers/)

**Teaching boundary:** Point One observes collider/no collider. Detailed filters return after conditions; confirm Boolean visual and collision geometry agree.

### 13. Throwing, release velocity and impulse

**Core.** Proposed placement: Change_Intro → VFM_05_Launch → VFM_03_Motion.

**Builds on:** Position differences, elapsed time and vectors.

**Proposed activity:** Release the same object with two motions; separate its starting velocity from the forces acting afterward.

**Source evidence:** The pickup system exposes velocity sampling and a factor affecting throws. [XR Tools: pickup function](https://godotvr.github.io/godot-xr-tools/docs/pickup/)

**Teaching boundary:** Pickup is already familiar. Forces explains its consequences; do not teach impulse and velocity as interchangeable quantities.

### 14. Feedback through sight, sound and touch

**Core · First pass.** Proposed placement: Trans_Introduction → Color_Grid_Pallet → WaveFunctions_AirMusic.

**Builds on:** An event and its receiver.

**Proposed activity:** Let one accepted action produce a label or outline plus a brief sound or optional vibration; allow channels to be disabled.

**Source evidence:** Godot exposes haptic output; W3C describes visual, auditory and tactile output needs. [Godot 4.6: XRController3D](https://docs.godotengine.org/en/4.6/classes/class_xrcontroller3d.html); [W3C: XR Accessibility User Requirements](https://www.w3.org/TR/xaur/)

**Teaching boundary:** One event can have several receivers. Vibration confirms an event; it does not reproduce the object's physical resistance.

### 15. Spatial audio and listening position

**Return.** Proposed placement: WaveFunctions_AirMusic → WaveFunctions_Effect_Sound.

**Builds on:** Signals, amplitude and distance.

**Proposed activity:** Walk around a sounding exhibit and alter one attenuation parameter while keeping the generated note unchanged.

**Source evidence:** AudioStreamPlayer3D supports positional sound, attenuation, directional emission and area-related audio effects. [Godot: AudioStreamPlayer3D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html)

**Teaching boundary:** Separate making a waveform from placing its sound. Retain visual or textual feedback for important state changes.

### 16. Painting: world hit to surface coordinates

**Core · First pass.** Proposed placement: Color_Paint.

**Builds on:** Local/world conversion; a function receiving values.

**Proposed activity:** Follow the existing nozzle hit into canvas coordinates. Change one brush property and verify that the hit still maps to the intended mark.

**Source evidence:** Godot ray queries identify hits; Unity's VR painting exercise distinguishes activation, size and feedback. [Godot: ray casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html); [Unity Learn: 3D painting challenge](https://learn.unity.com/pathway/vr-development/unit/events-and-interactions/tutorial/challenge-2-3d-painting-2)

**Teaching boundary:** The manual spray should lead. The automatic painter can return as another caller of the same paint operation.

### 17. Spatial controls and exhibit metadata

**Return.** Proposed placement: Color_Grid_Pallet → Flow_Field → QFEP_Sandbox.

**Builds on:** Signals, functions and named data.

**Proposed activity:** Connect one slider to an artifact parameter and expose the same value in an accessible label; identify the receiver.

**Source evidence:** XR Tools offers pointer-driven 2D-in-3D interfaces and fingertip poke interaction. [XR Tools: pointer](https://godotvr.github.io/godot-xr-tools/docs/pointer/); [XR Tools: poke](https://godotvr.github.io/godot-xr-tools/docs/poke/); [W3C: XR Accessibility User Requirements](https://www.w3.org/TR/xaur/)

**Teaching boundary:** A control belongs beside the phenomenon it changes. Keep the immersive artifact central and introduce structured metadata only when needed.

### 18. Frame budget and geometric resolution

**Return.** Proposed placement: Point_Zero → Primitives_Columns → Shader_12_PinkExtravaganza.

**Builds on:** Counters, resolution and controlled comparison.

**Proposed activity:** Return from the opening counter to the columns: measure frame time as resolution changes, then compare one shader setting.

**Source evidence:** XR rendering imposes timing constraints; variable rate shading trades shading density for work on supported hardware. [Godot: setting up XR](https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html); [Godot 4.6: variable rate shading](https://docs.godotengine.org/en/4.6/tutorials/3d/variable_rate_shading.html)

**Teaching boundary:** Keep performance observations device- and renderer-specific. A screenshot is not evidence of headset frame pacing.

### 19. Stereo rendering and view-dependent materials

**Return.** Proposed placement: Shader_01_Shaping → Shader_12_PinkExtravaganza.

**Builds on:** Coordinates, shaders and projection.

**Proposed activity:** Check the same material in both eyes and under head movement; compare a world-anchored pattern with a view-dependent one.

**Source evidence:** Godot's XR full-screen effects account for eye projections; screen-reading effects have rendering trade-offs. [Godot 4.6: XR full-screen effects](https://docs.godotengine.org/en/4.6/tutorials/xr/xr_full_screen_effects.html)

**Teaching boundary:** Later shader study. No promise that a desktop post effect works correctly or cheaply in stereo.

### 20. Deformable contact and simulation detail

**Return.** Proposed placement: SoftBodies_Cloth_Physics → SoftBodies_Soft_Body_Deformation.

**Builds on:** Meshes, forces, constraints and physics ticks.

**Proposed activity:** Compare two resolutions of a pinned cloth; inspect contact, deformation and frame time while changing one parameter.

**Source evidence:** Godot soft-body documentation connects mesh detail and simulation precision to behavior and performance. [Godot 4.6: soft bodies](https://docs.godotengine.org/en/4.6/tutorials/physics/soft_body.html)

**Teaching boundary:** Verify the museum's actual solver first; a custom cloth implementation is not automatically Godot SoftBody3D.

### 21. Tracked hands and gesture input

**Optional.** Proposed placement: ML_Perception → SoftBodies_Playground_of_Joy.

**Builds on:** Transforms, joints and input state.

**Proposed activity:** Where supported, let a pinch call a known object operation and compare it with the controller equivalent.

**Source evidence:** Godot hand tracking separates pose, skeleton data and tracking source; support differs across runtimes. [Godot 4.6: hand tracking](https://docs.godotengine.org/en/4.6/tutorials/xr/openxr_hand_tracking.html)

**Teaching boundary:** A tracking API estimate is not proof of intention. Keep this an optional branch, not a prerequisite for the spine.

### 22. Tracking loss and recovery

**Return.** Proposed placement: ML_Perception → QFEP_Sandbox.

**Builds on:** Conditions, state transitions and retained data.

**Proposed activity:** Simulate losing a tool pose; pause its action, preserve the learner's work and require a deliberate continuation.

**Source evidence:** XRNode3D exposes tracking availability and a tracking-changed signal. [Godot 4.6: XRNode3D](https://docs.godotengine.org/en/4.6/classes/class_xrnode3d.html)

**Teaching boundary:** Basic recovery belongs in the host. Its logic becomes a later lesson; missing data is different from a hand remaining still.

### 23. Passthrough and occlusion

**Optional.** Proposed placement: Boolean_Works → Color_Walls.

**Builds on:** Alpha, depth, surfaces and capability checks.

**Proposed activity:** Place one virtual form beside a real surface and compare the view with and without a declared occluding proxy.

**Source evidence:** Godot passthrough uses supported blend modes and platform configuration; passthrough alone is not a scene model. [Godot 4.6: AR / passthrough](https://docs.godotengine.org/en/4.6/tutorials/xr/ar_passthrough.html)

**Teaching boundary:** A later mixed-reality extension. Check the actual headset/plugin combination before promising the encounter.

### 24. Spatial anchors and place memory

**Optional.** Proposed placement: PostCrisis_Synthesis → SpeculativeComputation_Situated_Computation.

**Builds on:** Transforms, events, saved data and asynchronous results.

**Proposed activity:** Place one annotation, persist it if supported, then restore its content and position in a later session.

**Source evidence:** Supported spatial anchors track places; persistent anchors use identifiers that must be associated with application data. [Godot 4.6: spatial entities](https://docs.godotengine.org/en/4.6/tutorials/xr/openxr_spatial_entities.html)

**Teaching boundary:** Anchor tracking, persistence and content reconstruction are different responsibilities. Capability-check them separately.

### 25. Saving, restoring and undoing made work

**Return.** Proposed placement: Point_Line_Grid → Assemblage_Same_Desire → PostCrisis_Synthesis.

**Builds on:** Lists, identifiers, serialization and state.

**Proposed activity:** Carry the original trace through a supplied handoff early. Later save one authored arrangement, reopen it, and implement undo for one declared operation.

**Source evidence:** Godot's saving guide separates selecting persistent data, serialization and reconstruction. [Godot 4.6: saving games](https://docs.godotengine.org/en/4.6/tutorials/io/saving_games.html)

**Teaching boundary:** General programming in a spatial setting. A saved image, an ordered stroke record and an editable object are different outputs.

### 26. Shared objects and network authority

**Optional.** Proposed placement: GT_Connectivity → SpeculativeComputation_Collective_Knowledge.

**Builds on:** Object state, identifiers, serialization and messages.

**Proposed activity:** Have two visitors request a change to one sculpture and make conflict resolution visible.

**Source evidence:** Godot multiplayer distinguishes authority and delivery modes; its documented spatial-entities system does not provide anchor sharing. [Godot 4.6: high-level multiplayer](https://docs.godotengine.org/en/4.6/tutorials/networking/high_level_multiplayer.html); [Godot 4.6: spatial entities](https://docs.godotengine.org/en/4.6/tutorials/xr/openxr_spatial_entities.html)

**Teaching boundary:** Optional capstone requiring new integration. Shared state and physical co-location are separate problems; remote avatars are not a complete shared world.

### 27. Avatar correspondence and body representation

**Optional.** Proposed placement: Trans_Body → Color_Nails → ML_Perception.

**Builds on:** Transforms and correspondence; skeletons for implementation.

**Proposed activity:** Compare an aligned representation with an offset mannequin while preserving camera control; discuss how movement and appearance affect identification.

**Source evidence:** Slater and colleagues studied body ownership in VR and found first-person perspective influential in their experiment. [Slater et al. (2010): First Person Experience of Body Transfer in Virtual Reality](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0010564)

**Teaching boundary:** Early reflection can precede a later technical exercise. Do not promise universal ownership effects or equate appearance changes with lived identity.

## What this adds to Ada

The most useful questions are already inside these operations: which body can reach, which action is accepted, which surface counts as solid, which record survives, and who can alter a shared object. They can enter final.md as reflection while tutorial.md teaches the exact operation. Neither track needs to explain everything the room contains.

Next editorial step: choose a small interaction contribution for each relevant hall, preserving its primary lesson. Record what is introduced, practised, supplied or reflected on. Verify the selected artifact before writing a full tutorial.
