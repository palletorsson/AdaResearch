# Particle Systems

Birth, life, death. Many simple objects creating complex effects.

## QFEP Connection

Particle systems are **entropy engines** — they create order (emitter structure) that immediately dissolves into entropy (particle death/dispersal). Fire, smoke, explosions: all are φΔE in action, systems actively increasing entropy while maintaining localized pattern.

## Contents

Based on **Nature of Code Chapter 4: Particle Systems**.

### Core Examples

| File | Description |
|------|-------------|
| `example_4_1_single_particle_vr.gd` | One particle with lifespan, gravity, fade |
| `example_4_2_array_particles_vr.gd` | Managing multiple particles in array |
| `example_4_3_particle_emitter_vr.gd` | Continuous particle emission |
| `example_4_4_multiple_emitters_vr.gd` | Multiple emission points |
| `example_4_5_inheritance_polymorphism_vr.gd` | Different particle types (OOP) |
| `example_4_6_particle_repeller_vr.gd` | Particles avoiding/attracted to points |
| `example_particle_body.gd` | Physical particle with collision |

### Optimization

| File | Description |
|------|-------------|
| `test_phase1_optimizations.gd` | Basic optimization techniques |
| `test_phase2_multimesh.gd` | GPU instancing via MultiMesh (thousands of particles) |

## Key Concepts

1. **Particle lifecycle** — Born → live → die (lifespan)
2. **Emitter** — Source point + emission rate + initial velocity variance
3. **Forces** — Gravity, wind, attraction/repulsion
4. **Rendering** — Instancing, billboards, GPU particles
5. **Object pooling** — Reuse dead particles instead of allocating

## Particle Properties

Each particle typically has:
- Position, velocity, acceleration
- Lifespan (countdown to death)
- Size (often shrinks with age)
- Color/alpha (often fades with age)
- Mass (for force calculations)

## VR Experience

- Walk through particle fields
- Interact with emitters (hand tracking)
- Feel the flow of smoke/fire
- Create particle art

## Files

- 9 GDScript files
- 7 scene files
- 10 documentation files
