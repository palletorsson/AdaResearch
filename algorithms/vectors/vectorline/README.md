# Vector Line

A draggable 3D vector arrow connecting two grab spheres. The line body and arrowhead update every frame to follow the sphere positions, and a floating label displays the vector's name and magnitude. This is the foundational **vector visualization primitive** used across the Ada Research vector artifacts.

## Concept Taught

**Vectors as directed line segments** -- a vector has a start point, an end point, a direction, and a magnitude. By physically grabbing and moving the endpoints in VR, learners build intuition for how changing direction or length affects the vector. The floating label reinforces the connection between the spatial arrow and its numerical magnitude.

## How It Works

1. Two child nodes (`GrabSphere` and `GrabSphere2`) serve as the start and end points. These are VR-grabbable objects.
2. Each frame, `_refresh_geometry()` reads the global positions of both spheres, converts them to local space, and updates three visual elements:
   - **Line body**: A `CylinderMesh` stretched between the two points, oriented using a custom basis computation.
   - **Arrow tip**: A cone-shaped `CylinderMesh` (top radius = 0) placed at the end point, pointing in the vector's direction.
   - **Length label**: A billboard `Label3D` showing `"<name> |v| = X.XXm"`, positioned at the midpoint of the vector.
3. When a grab sphere is released, the script fires a `line_drop` event through the `TextManager` system with the current length, allowing maps to trigger narrative responses.
4. The material uses emission for visibility in dark environments, with configurable color.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `line_thickness` | float | `0.01` | Radius of the cylinder shaft |
| `line_color` | Color | White | Color of both the shaft and arrowhead |
| `arrow_tip_length` | float | `0.16` | Length of the conical arrowhead |
| `arrow_tip_radius` | float | `0.05` | Base radius of the arrowhead cone |
| `vector_name` | String | `"Vector"` | Name displayed on the floating label |

## Features

- Real-time updating cylinder shaft and cone arrowhead tracking two grab spheres.
- Billboard label showing vector name and magnitude, positioned at the midpoint.
- Custom basis computation for arbitrary 3D orientation (handles edge cases near vertical).
- Emissive material for high visibility in VR environments.
- `TextManager` integration: fires `line_drop` events on sphere release.
- Used as a building block by `vector_joint_playground`, `weather_vector_field`, and other vector artifacts.

## Files

- `vectorline.gd` -- Main script: geometry refresh, arrow tip, length label, material creation, basis computation.
- `vectorline.tscn` -- Scene file (contains lineContainer with GrabSphere and GrabSphere2).
