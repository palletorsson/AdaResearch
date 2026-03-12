# Vector Projection Demo

An interactive visualization of vector projection and reflection, showing how a vector decomposes into components parallel and perpendicular to a plane. The projection strips the normal component (proj_plane(A) = A - (A dot n-hat) n-hat), and the reflection mirrors the vector through the plane (reflect(A) = A - 2(A dot n-hat) n-hat).

## How It Works

Given a source vector A and a surface normal n, the artifact computes the scalar projection of A onto the unit normal, yielding the normal component. Subtracting this from A gives the plane projection (the shadow of A on the surface). Subtracting twice the normal component gives the specular reflection. All five vectors (A, normal, plane projection, reflection, and normal component) are rendered as cylinder-and-cone arrows. A semi-transparent plane mesh orients perpendicular to the normal, and a dashed drop line connects A's tip to its projection, making the right-angle relationship visible.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `max_vector_length` | float | 1.2 |
| `arrow_thickness` | float | 0.025 |
| `vector_a` | Vector3 | (0.6, 0.7, 0.2) |
| `normal` | Vector3 | (0.0, 1.0, 0.0) |
| `color_a` | Color | (1.0, 0.3, 0.3) |
| `color_normal` | Color | (0.3, 0.8, 1.0) |
| `color_projection` | Color | (0.3, 1.0, 0.4) |
| `color_reflection` | Color | (1.0, 0.6, 0.8) |
| `color_proj_normal` | Color | (1.0, 0.8, 0.3, 0.6) |
| `panel_color` | Color | (0.06, 0.06, 0.08, 0.9) |

## Features

- 5 vector arrows: source A, normal n, plane projection, reflection, and normal component
- Semi-transparent reflection plane that orients dynamically to the normal
- Perpendicular drop line between A and its projection
- Grabbable VR handles for both the source vector and the normal
- Live formula panel showing component values and angle to normal
- 5 preset configurations: Floor, Wall, 45-degree, Glancing, and Reset
- Framed info panels with metallic borders using MultiMesh

## Files

- `vector_projection_demo.gd` -- Main script
- `vector_projection_demo.tscn` -- Scene file
