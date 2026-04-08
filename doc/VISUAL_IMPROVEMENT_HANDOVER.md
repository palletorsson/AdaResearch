# Visual Improvement Handover — Physics Simulation

> Learn what makes a good scene by improving every artifact in `physics_simulation.json`.

## The Question

What makes a good VR algorithm visualization? By improving 90 physics artifacts one by one, we develop a pattern language for visual quality.

## Visual Quality Checklist

From the improvements we already made, a pattern emerged:

### 1. VISIBILITY — Can you see it?
- **Scale**: Objects must be visible at arm's length in VR (~0.05m minimum radius for spheres)
- **Bad**: exercise_1_3 had 0.03m ball → nearly invisible
- **Good**: exercise_1_3 now has 0.06m ball + wireframe box

### 2. CONTAINMENT — Can you see the boundaries?
- **Bad**: bouncing_ball had invisible collision walls → ball seemed to float in nothing
- **Good**: bouncing_ball now has wireframe cube showing the containment box
- **Pattern**: Use thin cylinder edges with `Basis(right, direction, up)` orientation (see `line_static.gd`)

### 3. TRAILS — Can you see the history?
- **Bad**: exercise_1_5 had no trail → just two dots, no sense of motion
- **Good**: exercise_1_5 now has chase trail + connection line to target
- **Pattern**: `ImmediateMesh` with `PRIMITIVE_LINE_STRIP`, 200-300 points, transparent material

### 4. CONNECTIONS — Can you see the relationships?
- **Bad**: exercise_1_8 had no orbit trail → just a ball near a sphere
- **Good**: exercise_1_8 now draws the orbit path + force line to attractor
- **Pattern**: Connection lines between related objects (force vectors, springs, attraction)

### 5. GLOW — Does it feel alive?
- **Bad**: flat `StandardMaterial3D` with no emission → looks like gray plastic
- **Good**: `emission_enabled = true`, `emission = color * 0.4`, `emission_energy_multiplier = 1.5`
- **Pattern**: Every interactive object should glow slightly. Bright emission for targets/attractors.

### 6. COLOR — Does it communicate?
- **Bad**: all objects same color → can't distinguish roles
- **Good**: Different colors for different roles (ball=cyan, target=pink, force=yellow, trail=faded)
- **Pattern**: Use the queer_colors palette for variety. Attractor=accent, mover=primary, trail=faded.

### 7. INFORMATION — Can you read the state?
- **Good**: exercise_1_8 has `Label3D` showing "dist: 0.123, force: 0.045"
- **Pattern**: Billboard `Label3D` for state readouts. Small, positioned above the scene.

### 8. CAMERA — Does the screenshot show the artifact well?
- **Bad**: scene fills screen but you can't tell what it is
- **Good**: 3/4 angle, object centered, ground plane gives depth reference
- **Pattern**: `--yaw=0.4 --pitch=0.35` for most. No ground for self-contained artifacts. Longer wait for procedural builders.

## The 90 Artifacts

Browse at: `http://localhost:3003/artifacts?registry=physics_simulation`

### Group 1: Joint Demos (10 artifacts)
```
ChainSwing, CharacterRagdoll, ConeTwistBag, DrawbridgeHinge,
GimbalStabilizer, HingeCrank, PendulumPin, SpringSuspension,
tscn_joint, IKArm
```
**Common issues**: Most are `.tscn`-only with minimal procedural code. They rely on Godot's built-in physics joints. Visually they're often just gray boxes connected by invisible constraints.
**Visual improvements**: Add edge highlighting to show joint connections. Add glow to contact points. Add axis indicators showing constrained vs free axes.

### Group 2: Nature of Code Chapter 2 — Forces (8 artifacts)
```
example_2_2 through example_2_9, bouncing_ball
```
**Common issues**: Tiny spheres, no trails, no force visualization.
**Visual improvements**: Bigger objects, trails, force arrows, emissive materials. We already fixed bouncing_ball, exercise_1_3, exercise_1_5, exercise_1_8.

### Group 3: Nature of Code Chapter 3 — Oscillation (14 artifacts)
```
example_3_1 through example_3_11, exercise_3_*
```
**Common issues**: Many are sinusoidal motion demos with small objects. No wave visualization.
**Visual improvements**: Trail lines showing oscillation patterns. Phase indicators. Amplitude/frequency labels.

### Group 4: Nature of Code Chapter 4 — Particles (7 artifacts)
```
example_4_1 through example_4_6, example_particle_body
```
**Common issues**: Particle systems may look good dynamically but capture as a single frame → unclear.
**Visual improvements**: Longer wait time for captures. Multiple particle colors. Emission trails.

### Group 5: Nature of Code Chapter 6 — Physics (8 artifacts)
```
example_6_1 through example_6_8
```
**Common issues**: Rigid body demos using Godot's built-in physics. Often just falling boxes.
**Visual improvements**: Edge outlines on rigid bodies. Velocity arrows. Collision flash effects.

### Group 6: Core Physics Sims (20+ artifacts)
```
mass_spring_damper, spring_system, three_body_problem, nbody_simulation,
force_fields, vector_fields, particle_systems, verlet_integration,
firework_launcher, friction_ramp, gravity_well, newton_cradle,
cloth_simulation, fluid_simulation, magnetic_simulation, fem_simulation,
soft_bodies, slingshot_launcher, rigid_body, numerical_integration
```
**These are the showcase artifacts** — each represents a major physics concept. They should look stunning.
**Visual improvements per artifact**: Varies. Focus on what tells the story of the physics.

### Group 7: Artistic/Synthesis (5 artifacts)
```
waterflowers, waterone, surreal_kinetic_sculpture, softmill, softstopscene
```
**Already visually rich** — these are art pieces. Focus on camera angle and lighting.

## Workflow Per Artifact

```
1. LOOK at the screenshot: /scenes/detail?path={scene_path}
2. READ the code: what does it build?
3. IDENTIFY visual problems: tiny? no containment? no trail? flat color?
4. EDIT the GDScript: apply the patterns above
5. CAPTURE new screenshot: godot --scene={path} --yaw=0.4 --pitch=0.35
6. COMPARE: does the new shot tell the story better?
```

## Commands

```bash
# View artifact in encyclopedia
http://localhost:3003/artifact/{lookup_name}

# View scene detail with screenshot
http://localhost:3003/scenes/detail?path=res://algorithms/physicssimulation/{folder}/{file}.tscn

# Capture new screenshot
godot --path . --xr-mode off --no-window \
  --script res://commons/testing/capture_tscn_shot.gd \
  -- --scene=res://{path}.tscn \
  --out=C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/scene-catalog/{lookup_name}.png \
  --ground=true --yaw=0.4 --pitch=0.35 --distance=0 --wait=3.0

# Run full improvement (docs + code + screenshot)
/ada-artifact-improver {lookup_name}
```

## What We Learned So Far

| Artifact | Problem | Fix | Lesson |
|----------|---------|-----|--------|
| bouncing_ball | Cylinder edges rotated wrong | `Basis(right, dir, up)` instead of `look_at` | Always use cross-product basis for cylinder orientation |
| exercise_1_3 | Ball invisible (0.03m), no box | Larger ball (0.06m), wireframe box, @export vars | Minimum visible size ~0.05m. Always show containment. |
| exercise_1_5 | Just two dots, no motion sense | Trail + connection line + emissive materials | Trails are essential — they show the algorithm's history |
| exercise_1_8 | No orbit path visible | Added 300-point orbit trail | Orbits only make sense when you can see the path |
| bulging_tunnel | Code fine, just needed identity | class_name + @identity | Not all improvements are visual — some are structural |

## Start Here

Pick the first artifact in Group 1 (ChainSwing) and run:
```
/ada-artifact-improver ChainSwing
```

Look at the proposal. Look at the screenshot. Ask: what would make this scene tell its story?
