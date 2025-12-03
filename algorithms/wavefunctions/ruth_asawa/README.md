# Ruth Asawa Sculpture Generator

This directory contains a procedural generator for sculptures inspired by Ruth Asawa.
The generator uses a parametric surface approach where the radius of the sculpture along the vertical axis is defined by a `Curve` resource.

## Files

- `ruth_asawa_sculpture.gd`: The main script generating the mesh.
- `ruth_asawa_sculpture.tscn`: A scene with the sculpture and a camera.

## Usage

1. Instance `ruth_asawa_sculpture.tscn` in your scene.
2. Select the `RuthAsawaSculpture` node.
3. In the Inspector, you can adjust:
    - `U Resolution`, `V Resolution`: Density of the mesh.
    - `Radius Curve`: The profile of the sculpture.
    - `Height`: Total height.
    - `Max Radius`: Maximum width.
    - `Wireframe`: Toggle between wireframe (lines) and solid (triangles) mesh.
    - `Auto Rotate`: Enable/disable rotation.

## Inspiration

Inspired by the looped wire sculptures of Ruth Asawa, which often feature nested, bulbous shapes and organic symmetry.
