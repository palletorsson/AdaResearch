# Vector & Forces Museum — assessment + hall plan (2026-06-10)

Full audit of every vector/forces artifact (152 registry candidates, 3-agent fan-out reading
registry + source), feeding an 8-hall museum: `VFM_01..VFM_08`, chained by teleporters.
Layout rule: **S** (small interactive) artifacts sit on height-2 plinths in narrow rows/columns;
**L** (big) artifacts get open floor and clearance.

## Verdict summary
- **KEEP ~60** — each concept shown once, by its best artifact.
- **CHANGE 12** — keep-with-tweak (placed in the museum now; tweaks are follow-ups):
  - `ForceMagnitudeDemo` — reset/freeze are desktop keys; add VR buttons
  - `VectorForces`, `VectorMotion`, `VectorSubtraction`, `VectorTorque` — stub registry descriptions despite solid code
  - `coordinate_system_switcher` — add a grabbable point handle
  - `vector_field_visualizer` — watch-only; add a VR mode-switch button
  - `magnetic_simulation` — only magnetism piece but thin (131 lines); deepen
  - `three_body_problem` — desktop Control UI; swap for the VR rack panel
  - `normal_force_demo` — surface tilt is KEYBOARD-only; add a VR slider
  - `forcedirected3d` — shrink layout_bounds (50x30x50) to hall scale
  - `exercise_5_9_angle_between`, `noc_5_04_flow_field` — shipped map_ready:false (FIXED → true)
- **CUT ~45** — three kinds:
  - *Superseded duplicates*: the compact bases of the XL family (VectorAddition/DotProduct/CrossProduct/ProjectionReflection), most of the NOC example_1_x row, laser_turret/ball_dropper, nbody_simulation, spring_system, SpringSuspension, PendulumPin, viscosity_layers, particle_systems, vector_field_grid, particle_flow_swarm, force_directed_layout, vector_addition_demo/walk, cross/dot/projection/reflection _demo compacts, vectorline/vectorpoint/coordinates, throw_ball/vector_drone (components), CharacterRagdoll, DrawbridgeHinge, GimbalStabilizer.
  - *Test scenes / stubs*: gravity_gun_test_scene, destructibles_test_scene, destructible_marching_cube, tscn_joint (registry description is fiction), and **4 EMPTY stub scenes with fictional registry entries**: `centripetal_force_demo`, `drag_coefficient_wind_tunnel`, `impulse_collision_demo`, `spring_chain` (bare Node3D, no script). Centripetal force is currently untaught — gap worth filling someday.
  - *Off-topic grep matches*: nlp, svm_visualization, reinforcement_learning, joint_learn_walk, smart rockets, catalyst family, dark_sphere, chaos_attractor, bias_from_inside, HUD displays, graphspace (it's a map, not a piece), force_field (hazard system), sphere_splitting_showcase.

## Registry fixes applied
- `exercise_5_9_angle_between`, `noc_5_04_flow_field`: map_ready → true
- `queer_cylinder_target`: footprint 8x8x8 → [1,2,1] (real ~1m)
- `VectorForces`: footprint 20x20 → [2,2,2]

## The 8 halls
1. **VFM_01_Foundations** — what a vector is. CoordinateSystem3M (entry), vector_addition_xl,
   vector_subtraction_demo + plinth rows: VectorBasics, basis_vectors_rig, magnitude, normalize,
   translation, example_1_4 (scalar mult), coordinate_system_switcher, the Vector Bench
   (adder_board, length_lantern, stretch_bench), newtons_laws, example_2_1 (F=ma), wall boards.
2. **VFM_02_Operations** — dot/cross/projection. VectorWorkbench + the three XL walk-ins +
   plinths: agreement_gauge, work_energy_demo, torque_demo, normal_force_demo, exercise_5_9.
3. **VFM_03_Motion** — velocity/acceleration/collision. bouncing_ball chamber, trajectory_artifact,
   collision_crasher (warning sign) + plinths: VectorMotion, ForceMagnitudeDemo, VectorForces,
   exercise_1_3/1_5, example_2_5/3_2/3_3, friction_ramp, newton_cradle, combined_forces_demo,
   flocking_controls.
4. **VFM_04_Fields** — vector fields. vector_field (14m centerpiece), weather_vector_field (Storm
   Chamber), force_vortex, force_fields, VectorFieldFlow, magnetic_simulation + plinths:
   force_field_visualizer, flow_field_painter, interactive_point_origin_force,
   vector_field_visualizer, noc_5_04_flow_field.
5. **VFM_05_Launch** — ballistics, firing lanes. catapult, human_catapult (landing run),
   mortar_vector_siege (9m bay), VectorThrowing, hl_turret_vectors + turret_boll_infoboard,
   slingshot_launcher (27m lane), firework_launcher, force_pad (flight path).
6. **VFM_06_Springs** — oscillation + joints. surreal_kinetic_sculpture (centerpiece),
   mass_spring_damper, harmonic_motion_demo, ChainSwing, ConeTwistBag, HingeCrank, SliderPress,
   vector_joint_playground + plinths: spring_demo, spring_network, coupled_pendulums.
7. **VFM_07_Gravity** — attraction + orbits. three_body_problem, forcedirected3d + plinths:
   exercise_1_8, example_2_8 (two-body), example_2_9 (n-body), gravity_well,
   orbital_mechanics_demo, grid3d_force_directed.
8. **VFM_08_Arena** — games. vector_arena, reflection_hall (own bay), sentry_turret dodge zone,
   turret_targeting, queer_cylinder_target.

Chain: 01→02→…→08→01. Sequence file: `commons/maps/sequences/vectorforcesmuseum.json`.
