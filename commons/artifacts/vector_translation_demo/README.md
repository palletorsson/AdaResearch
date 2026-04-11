# Vector Translation Demo

Demonstrates vector translation in 3D space by moving a cube along a direction controlled by VR sliders. Teaches how a vector encodes both direction and magnitude, and how translation displaces an object from the origin.

## How It Works

Four horizontal sliders control the translation vector: three direction sliders set the X, Y, and Z components (each ranging from -1 to +1), and a magnitude slider scales the resulting direction to set the vector's length (0 to max_magnitude). The cube is repositioned each frame to the tip of the computed vector, while an arrow mesh is oriented and scaled to visualize the vector from the origin. A MultiMesh-based trail of ghost cubes is drawn at evenly spaced intervals along the vector path, providing a visual trace of the translation. A 3D label displays the vector components and magnitude in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `max_magnitude` | float (0.1-20.0) | 3.0 |
| `show_trail` | bool | true |

## Features

- VR slider controls for direction (X, Y, Z) and magnitude
- Animated arrow visualization pointing from origin to translated position
- MultiMesh ghost trail showing intermediate positions along the translation path
- Real-time 3D label with vector components and magnitude
- Public API: `set_vector()`, `get_vector()`, `reset()`
- Signal `vector_changed` emitted on every update

## Files

- `vector_translation_demo.gd` -- Main script
- `vector_translation_demo.tscn` -- Scene file
