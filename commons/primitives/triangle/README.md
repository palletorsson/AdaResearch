# Triangle Primitive

A simple interactive triangle primitive with three grabbable vertices.

## Features

- **Interactive Vertices**: Three grabbable spheres at each corner of the triangle
- **Real-time Updates**: Triangle mesh updates as you drag the vertices
- **Multiple Presets**: Reset to different triangle types (equilateral, right-angled, isosceles)
- **Visual Feedback**: Transparent green marble spheres with subtle glow effects
- **Shader Support**: Uses the SimpleGrid shader for wireframe rendering

## Controls

- **Mouse**: Drag the corner spheres to reshape the triangle
- **E**: Reset to equilateral triangle
- **R**: Reset to right-angled triangle  
- **I**: Reset to isosceles triangle

## Usage

Load the scene `triangle.tscn` or instantiate the `Triangle` node in your scene.

## Properties

- `sphere_size_multiplier`: Controls the size of the grab spheres
- `sphere_y_offset`: Vertical offset for the triangle
- `alter_freeze`: Controls freeze behavior for the vertices
- `vertex_color`: Color of the grab spheres

## Events

The triangle emits events when vertices are dropped, providing information about the triangle's area and vertex positions.
