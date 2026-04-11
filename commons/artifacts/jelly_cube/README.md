# Jelly Cube

A soft, deformable cube built on Godot's SoftBody3D physics that jiggles and deforms when touched. This teaches soft-body dynamics concepts including spring stiffness, damping, and internal pressure.

## How It Works

A subdivided BoxMesh is attached to a SoftBody3D node, which simulates the mesh vertices as a mass-spring system. Spring stiffness controls resistance to deformation, damping controls how quickly oscillations settle, and pressure inflates the body from the inside. VR hand collisions deform the mesh in real time. The cube sits on a pedestal with a static collision body, and a control panel provides sliders and buttons for adjusting physics parameters and cycling through colors.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | 0.3 |
| `subdivisions` | int | 4 |
| `jelly_color` | Color | (0.2, 0.9, 0.5, 0.8) |
| `stiffness` | float | 0.5 |
| `damping` | float | 0.01 |
| `pressure` | float | 1.0 |
| `mass` | float | 1.0 |
| `emission_strength` | float | 0.2 |
| `use_transparency` | bool | true |

## Features

- Real-time soft-body deformation via SoftBody3D physics
- VR-interactive: touch to deform, grab sliders to adjust parameters
- Three physics sliders: stiffness, damping, pressure
- Color cycle button with five preset jelly colors
- Reset button to restore default physics parameters
- Translucent material with configurable emission glow
- Pedestal with static collision for the cube to rest on

## Files

- `jelly_cube.gd` -- Main script
- `jelly_cube.tscn` -- Scene file
- `jelly_variants.tscn` -- Variant scene file
