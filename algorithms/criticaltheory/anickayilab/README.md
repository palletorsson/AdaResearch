# Anicka Yi Lab -- Bio-Art Laboratory Installation

A procedural laboratory installation inspired by the bio-art practice of Anicka Yi. The artifact generates a complete lab environment with petri dishes, test tubes, Erlenmeyer flasks, and bioreactors populated by floating bacterial entities, fog particles, and color-shifting biological cultures.

## Concept Taught

**Bio-art and the intersection of science and aesthetics.** Anicka Yi is a contemporary artist whose work explores the boundaries between biological systems and artistic expression -- cultivating bacteria, engineering scents, and creating living installations. This artifact teaches how algorithmic thinking applies to artistic practice: procedural generation of lab equipment, particle systems for atmospheric effects, and parametric animation all parallel the systematic processes used in both scientific research and computational art.

## How It Works

1. A metal lab table with legs and a backdrop is constructed procedurally.
2. **Petri dishes** are created with glass bases, rims, culture medium, and randomized bacterial colonies. Each colony gets a unique shader material with hue-shifted colors.
3. **Test tubes** are placed in a procedural rack, each containing liquid at varying fill levels with distinct color palettes.
4. **Erlenmeyer flasks** are built using `SurfaceTool` to create the tapered conical body, with liquid meshes fitted to the interior geometry.
5. **Bioreactors** include glass vessels, metal caps, inlet tubes, valves, stirring rods with impeller blades, and bacterial particles floating in liquid.
6. **Floating bacteria** are spawned in three morphological types: rod-shaped (bacillus, CapsuleMesh), spherical (coccus, SphereMesh), and spiral (spirillum, stretched SphereMesh).
7. **Fog particles** use `GPUParticles3D` to create a subtle mist drifting across the lab.
8. All biological materials use custom shaders (`slime.gdshader`, `bitwisewater.gdshader`, `frosted_glass.gdshader`) with animated color shifting and pulsating emission.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `lab_scale` | float | 1.0 | Overall scale of the installation |
| `translucency_amount` | float | 0.7 | Glass transparency level |
| `pulsation_speed` | float | 0.5 | Speed of emission pulsation animations |
| `growth_amount` | float | 0.2 | Magnitude of growth animations |
| `color_shift_speed` | float | 0.3 | Speed of color cycling on biological materials |
| `primary_color` | Color | pale yellow-green | Base liquid color |
| `secondary_color` | Color | purple | Secondary blend color |
| `tertiary_color` | Color | orange | Tertiary blend color |
| `bacterial_color` | Color | cyan | Floating bacteria color |
| `petri_dish_count` | int | 8 | Number of petri dishes |
| `test_tube_count` | int | 12 | Number of test tubes |
| `flask_count` | int | 6 | Number of Erlenmeyer flasks |
| `bioreactor_count` | int | 3 | Number of bioreactors |
| `bacteria_count` | int | 40 | Floating bacterial entities |
| `enable_floating_bacteria` | bool | true | Toggle bacterial particle system |
| `enable_animation` | bool | true | Toggle all animations |
| `enable_interaction` | bool | true | Toggle mouse/VR interaction |

## Features

- Custom shader materials for glass, liquid, and biological matter
- Animated color shifting between primary, secondary, tertiary, and bacterial palettes
- Pulsating emission on bacterial colonies and liquid cultures
- Three bacterial morphology types with unique mesh shapes
- GPU particle fog system with drifting movement
- Erlenmeyer flask geometry built procedurally via SurfaceTool
- Bioreactor stirring rod rotation animation
- Interaction system with Area3D hover/click feedback
- Decorative pipe network with glass tubes and metal valve joints
- Equipment info display on interaction

## Files

- `anicka_yi_lab.gd` -- Full lab generation, animation, and interaction system
- `AnickaYiLab.tscn` -- Scene file
