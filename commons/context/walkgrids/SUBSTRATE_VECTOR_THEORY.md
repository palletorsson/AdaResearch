# Substrate Vector Theory

## The Question

What IS an artifact? Not "what algorithm does it teach" but: what implementation primitives compose it? What substrate dimensions does it occupy?

A jelly cube, a Foucault pendulum, a boids aquarium, Schrödinger's box, a DNA specimen — they all look different. But when you decompose them into what the engine actually does to produce them, patterns emerge.

---

## The Substrate Dimensions

After scanning all ~65 artifacts, ~100 primitives, and 2 existing substrate systems (Grid2D, LivingPaper), these are the atomic implementation dimensions that every object in AdaResearch occupies:

### 1. GEOMETRY — How is shape made?

| Value | Examples |
|-------|---------|
| `primitive_mesh` | SphereMesh, BoxMesh, CylinderMesh (static_reference_cube, elliptic_surface) |
| `csg` | CSGSphere3D, CSGBox3D, boolean ops (schrodinger_box, penrose_triangle) |
| `procedural_mesh` | ArrayMesh built from vertices (all walkgrids, chladni_plate) |
| `multimesh` | MultiMeshInstance3D for particle swarms (boids_aquarium, flow_field_painter, chladni_plate, perlin_terrain_sculptor) |
| `immediate_mesh` | ImmediateMesh for lines/vectors (vector_addition_demo, knowledge_terrain) |
| `parametric_surface` | f(u,v) → (x,y,z) (dna_specimen, riemann_sphere, hyperbolic_surface) |
| `curve_extrusion` | Path3D + CSGPolygon3D (foucault_pendulum wire, spring_demo) |
| `voxel_grid` | 3D boolean array → geometry (perlin_terrain_sculptor) |
| `no_geometry` | Pure data/UI (distribution_sampler, bias_visualizer) |

### 2. MATERIAL — How does it look?

| Value | Examples |
|-------|---------|
| `opaque_standard` | StandardMaterial3D, albedo+roughness+metallic (most solids) |
| `transparent` | TRANSPARENCY_ALPHA (schrodinger_box glow, jelly_cube, glass jars) |
| `emissive` | emission_enabled, emission_energy (DNA strands, grid2d alive cells) |
| `shader_driven` | ShaderMaterial (mandelbrot_dive, walkgrid height shader) |
| `vertex_color` | vertex_color_use_as_albedo (terrain coloring) |
| `cull_disabled` | Double-sided rendering (mobius_space, single-sided surfaces) |

### 3. PHYSICS — How does it respond to force?

| Value | Examples |
|-------|---------|
| `none` | Static display only (penrose_triangle, euclid_postulates_plaque) |
| `rigid_body` | RigidBody3D (throw_ball_sphere, rock physics) |
| `soft_body` | SoftBody3D (jelly_cube, queer_morphology_specimen) |
| `custom_integration` | Manual Euler/Verlet in _process (foucault_pendulum, boids, spring_demo) |
| `particle_system` | GPUParticles3D or manual MultiMesh stepping (flow_field_painter, chladni_plate) |
| `collision_only` | StaticBody3D for walkability (all walkgrids, platforms) |

### 4. TIME — How does it evolve?

| Value | Examples |
|-------|---------|
| `static` | Doesn't change after _ready (elliptic_surface, static_reference_cube) |
| `continuous` | sin(time), smooth animation (dna_specimen rotation, pendulums) |
| `discrete_step` | Generation-based stepping (game_of_life_petri, ca_rule_explorer) |
| `event_driven` | Changes on interaction only (schrodinger_box: open → collapse) |
| `simulation` | Ongoing multi-agent simulation (boids_aquarium, flow_field_painter) |
| `accumulative` | Trail-based, growing over time (flow_field_painter, random_walk_terrarium) |

### 5. ALGORITHM — What computation drives it?

| Value | Examples |
|-------|---------|
| `trig_functions` | sin, cos, atan2 (sine_space, oscillation cubes, harmonic_motion_demo) |
| `noise_sampling` | FastNoiseLite (noise_space, flow_field_painter, perlin_terrain_sculptor) |
| `cellular_automata` | Grid stepping rules (game_of_life_petri, ca_rule_explorer) |
| `flocking_rules` | Separation/alignment/cohesion (boids_aquarium) |
| `fractal_iteration` | z = z² + c (mandelbrot_dive, julia_set_explorer) |
| `physics_equations` | F=ma, pendulum, spring (foucault_pendulum, spring_demo, orbital_mechanics) |
| `vector_arithmetic` | Addition, dot, cross, normalize (all vector_*_demo artifacts) |
| `reaction_diffusion` | Gray-Scott (turing_pattern_generator) |
| `lsystem_expansion` | String rewriting + turtle (lsystem_editor) |
| `probability` | Distributions, Monte Carlo (distribution_sampler, monte_carlo_estimator) |
| `topology` | Curvature, geodesics (curvature_slider, poincare_disk, riemann_sphere) |
| `state_machine` | Discrete states + transitions (schrodinger_box) |
| `none` | Pure geometry, no ongoing computation (penrose_triangle, static shapes) |

### 6. INTERACTION — How do humans engage?

| Value | Examples |
|-------|---------|
| `none` | Look only (dna_specimen, superposition_display) |
| `grab` | XR pickable (jelly_cube, vector handle spheres) |
| `slider` | Continuous parameter control (mandelbrot_dive zoom, boids weights) |
| `button` | Discrete actions (schrodinger_box open, preset buttons) |
| `touch_surface` | Draw/paint on surface (grid2d touch, flow_field_painter) |
| `spatial_presence` | Player position affects system (chladni_plate proximity) |

### 7. CONTAINMENT — What holds it?

| Value | Examples |
|-------|---------|
| `none` | Freestanding in space (vector demos, pendulums) |
| `glass_jar` | Transparent enclosure (dna_specimen, queer_morphology_specimen, random_walk_terrarium) |
| `glass_tank` | Open-top aquarium (boids_aquarium, wave_interference_tank) |
| `petri_dish` | Flat substrate plate (game_of_life_petri, chladni_plate) |
| `table` | Flat surface mount (mandelbrot_dive) |
| `pedestal` | Display stand (static_reference_cube, penrose_triangle) |
| `frame` | Border/mount (oscilloscope, flow_field_painter) |
| `box` | Opaque container (schrodinger_box) |

### 8. INFORMATION — How does it explain itself?

| Value | Examples |
|-------|---------|
| `label_3d` | Label3D floating text (most artifacts) |
| `formula_display` | Math notation rendered (vector demos: "A + B = C") |
| `data_visualization` | Charts, graphs (distribution_sampler, oscilloscope) |
| `color_encoding` | Data → color mapping (mandelbrot_dive palette, grid2d states) |
| `spatial_encoding` | Data → position/size (all walkgrids, vector arrows) |
| `none` | Self-evident form (jelly_cube, rock) |

---

## Every Artifact as a Vector

Each artifact is a point in this 8-dimensional substrate space. Here are some examples written as coordinate tuples:

```
jelly_cube = {
  geometry: soft_body_mesh,
  material: transparent + emissive,
  physics: soft_body,
  time: continuous,
  algorithm: physics_equations,
  interaction: grab + slider,
  containment: none,
  information: label_3d
}

foucault_pendulum = {
  geometry: primitive_mesh + curve_extrusion + immediate_mesh,
  material: opaque_standard + emissive,
  physics: custom_integration,
  time: continuous + accumulative,
  algorithm: physics_equations,
  interaction: grab(gravity_spheres) + spatial_presence,
  containment: none,
  information: label_3d + spatial_encoding(trail_rosette)
}

schrodinger_box = {
  geometry: csg,
  material: opaque_standard + transparent(glow),
  physics: none,
  time: event_driven,
  algorithm: state_machine + probability,
  interaction: button(open_lid),
  containment: box,
  information: label_3d + formula_display
}

boids_aquarium = {
  geometry: multimesh + csg(tank),
  material: transparent(glass) + emissive(fish),
  physics: custom_integration,
  time: simulation,
  algorithm: flocking_rules,
  interaction: slider(weights),
  containment: glass_tank,
  information: label_3d
}

mandelbrot_dive = {
  geometry: primitive_mesh(plane),
  material: shader_driven,
  physics: none,
  time: event_driven(param changes),
  algorithm: fractal_iteration,
  interaction: slider(zoom+pan+iterations),
  containment: table,
  information: color_encoding + label_3d
}
```

---

## Common Trajectories

When you plot artifacts in this space, clusters and paths emerge:

### Trajectory 1: "Specimen in a Jar"
```
dna_specimen → random_walk_terrarium → queer_morphology_specimen → boids_aquarium
```
The containment dimension moves from jar → jar → jar → tank.
The physics dimension moves from none → custom → soft_body → simulation.
The algorithm moves from trig → random → physics+QFEP → flocking.
**Pattern: increasing agency inside a container.**

### Trajectory 2: "The Computation Gets Visible"
```
static_reference_cube → rotating_cube → oscillation_cube → jelly_cube → queer_morphology_specimen
```
geometry: primitive → primitive → primitive → soft → soft+fluid
physics: none → continuous → continuous → soft_body → soft_body
algorithm: none → trig → trig → physics → physics+QFEP
**Pattern: a cube gaining degrees of freedom. Rigidity dissolving.**

### Trajectory 3: "Vector → Field → Terrain"
```
vector_addition_demo → flow_field_painter → wave_interference_tank → erosion_space (walkgrid)
```
geometry: immediate_mesh(arrows) → multimesh(particles) → procedural_mesh(surface) → procedural_mesh(terrain)
scale: 0.5m artifact → 0.6m canvas → 0.8m tank → 30m walkable landscape
**Pattern: point data → field data → surface data → world data. The visualization grows until you're inside it.**

### Trajectory 4: "Grid → World"
```
game_of_life_petri → ca_rule_explorer → cellular_automata_space (walkgrid) → knowledge_terrain (walkgrid)
```
geometry: multimesh(flat grid) → multimesh(flat grid) → procedural_mesh(terrain) → procedural_mesh(terrain+markers)
containment: petri_dish → pedestal → none(IS the ground) → none(IS the ground)
**Pattern: the algorithm escapes its container. First it's in a dish. Then it's under your feet.**

### Trajectory 5: "Math Object → Thing You Walk On"
```
poincare_disk(artifact) → hyperbolic_surface(artifact) → hyperbolic_space(walkgrid)
mandelbrot_dive(artifact) → julia_set_explorer(artifact) → mandelbrot_space(walkgrid)
lsystem_editor(artifact) → lsystem_space(walkgrid)
```
**Pattern: every artifact has a walkgrid shadow. The artifact is the object you look AT. The walkgrid is the world you walk IN. Same algorithm, different substrate dimensions.**

### Trajectory 6: "Observation Collapses Form"
```
superposition_display → schrodinger_box → queer_morphology_specimen → brouwer_choice_sequence
```
time: static → event_driven → continuous → event_driven
interaction: none → button → slider(QFEP) → button(choice)
**Pattern: the act of looking at it determines what it is. Substrate dimension "interaction" becomes causally entangled with "algorithm."**

---

## What This Means

### For Artifact Design
Every new artifact can be designed by choosing coordinates in substrate space:
- "I need a physics-equations + glass-jar + accumulative-time artifact" → Foucault pendulum
- "I need a cellular-automata + petri-dish + discrete-step + touch-surface artifact" → game_of_life_petri
- The gaps in substrate space are artifacts that don't exist yet

### For Map Design  
A map's character = the substrate region its artifacts cluster in. A "Physics" map lives in the {custom_integration, continuous, physics_equations} region. A "Fractals" map lives in the {shader_driven, fractal_iteration, slider} region.

### For the Walkgrid Connection
**The walkgrids ARE the limit case of an artifact where containment→none and geometry→terrain.** The algorithm dimension stays the same. A mandelbrot_dive and a MandelbrotSpace share the algorithm substrate — they differ in containment (table vs world) and scale.

Every walkgrid is an artifact that ate its container and became the ground.

### For QFEP
The trajectory from artifact → walkgrid IS a QFEP phase transition:
- **F_order**: The algorithm exists as a formula on a label
- **oscillation**: The algorithm runs inside an artifact (contained)  
- **E_entropy**: The algorithm breaks its container (multiple interacting artifacts)
- **lambda_edge**: The algorithm becomes the terrain (walkgrid)
- **synthesis**: The algorithm becomes the world and you can't separate yourself from it

---

## Next Steps

1. Add `substrate_vector` field to artifact registry JSON entries
2. Build a SubstrateSpace visualizer (artifacts plotted in reduced-dimension substrate space)
3. Use substrate similarity to suggest "related artifacts" in the catalog
4. Auto-generate walkgrid substrates from artifact substrate vectors
5. Let maps define a "substrate profile" that selects compatible artifacts
