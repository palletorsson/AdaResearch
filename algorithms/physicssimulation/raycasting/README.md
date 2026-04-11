# Raycasting Points

A GPU particle system that teaches **raycasting interaction, force fields, and emergent particle behavior**. Thousands of glowing particles float in a dark, fog-filled space. Invisible ray-casting points orbit through the scene in complex patterns, and the particles react by being pushed away from nearby rays -- creating flowing voids and ripples in the particle cloud.

## How It Works

1. **GPU particle system** -- A `GPUParticles3D` node emits up to 3000 particles with a 60-second lifetime. A custom **particle process shader** handles all physics on the GPU:
   - Particles are initialized in a spherical distribution centered at Y=5.
   - Each frame, every particle checks its distance to 8 ray positions. If within `interaction_radius`, a repulsion force is applied inversely proportional to distance (squared falloff).
   - A gentle orbital force rotates particles around the center, preventing collapse.
   - Gravity provides a subtle downward drift.
   - Velocity is damped at 0.98 per frame.
   - Particles that drift beyond radius 30 are respawned at a random position.

2. **Ray casters** -- 8 invisible `Node3D` points are animated in four distinct movement patterns using tweens:
   - **Circular orbit** -- constant-radius rotation with vertical bobbing.
   - **Figure-8** -- Lissajous-like path in 3D.
   - **Vertical spiral** -- rising helix.
   - **Random walk** -- smooth interpolation through random waypoints.

   Each ray caster has a small glowing sphere (cyan, magenta, yellow, etc.) so the user can see where the forces originate.

3. **Ray strength modulation** -- Ray strengths oscillate sinusoidally over time, creating pulsing force fields that make the particle cloud breathe and shift.

4. **Visual shader** -- A spatial shader renders each particle as a glowing disc. Distance-to-camera scaling keeps particles visible at all ranges. Color interpolates between a calm blue (`base_color`) and an excited pink (`excited_color`) based on how strongly rays are influencing the particle. A pulsing effect modulates emission over time.

5. **Atmosphere** -- A dark procedural sky, volumetric fog, and dim directional lighting create a mysterious, deep-space aesthetic.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `particle_count` | int | 3000 | Number of GPU particles |
| `ray_count` | int | 8 | Number of ray-casting points |
| `interaction_radius` | float | 15.0 | Maximum influence distance per ray |
| `animation_speed` | float | 1.0 | Speed multiplier for ray movement patterns |
| `particle_response_strength` | float | 2.0 | Force magnitude when repelling particles |

### Shader Uniforms (Particle Process)
| Uniform | Default | Description |
|---------|---------|-------------|
| `time_scale` | 1.0 | Animation phase speed |
| `ray_positions[8]` | vec3 array | World positions of rays (updated per frame) |
| `ray_strengths[8]` | float array | Per-ray influence strength |
| `interaction_radius` | 10.0 | Cutoff distance |
| `response_strength` | 2.0 | Repulsion force scale |
| `gravity` | (0, -0.5, 0) | Background downward pull |

### Shader Uniforms (Visual)
| Uniform | Default | Description |
|---------|---------|-------------|
| `brightness` | 1.5 | Emission multiplier |
| `base_color` | cyan-blue | Calm particle color |
| `excited_color` | magenta-pink | Color when near a ray |
| `pulse_speed` | 1.5 | Glow oscillation speed |

## Features

- Fully GPU-driven particle physics -- 3000 particles with no CPU per-particle work.
- 8 ray casters with four distinct tween-based movement patterns.
- Inverse-square repulsion force fields with oscillating strength.
- Orbital background force prevents particle collapse.
- Custom visual shader with distance-based scaling, color interpolation, and pulsing glow.
- Volumetric fog and procedural sky for atmospheric depth.
- Particle respawning for unbounded simulation.

## Files

| File | Purpose |
|------|---------|
| `raycastingpoints.gd` | Main script -- GPU particles, ray casters, tween animations, shader setup |
