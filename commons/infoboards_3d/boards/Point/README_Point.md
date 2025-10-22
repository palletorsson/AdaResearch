# Point Info Board

## Overview
The Point Info Board teaches the fundamental concept of a point in 3D space - the atomic building block of all 3D graphics and simulations.

## Concept
Starting from the most basic element, a point is introduced as:
- A mathematical abstraction (position vector)
- A visual representation (small sphere)
- A labeled entity (with coordinate display)
- A dynamic object (updating in real-time)

## Content Pages

### Page 1: The Point - The Atom of Space
- **Concept**: Introduction to points as vectors in 3D space
- **Axiom 1**: A point in 3D is a Vector3(x, y, z)
- **Visualization**: Origin point with coordinate system
- **Code**: Basic Vector3 declaration

### Page 2: Visualizing the Point
- **Concept**: Making abstract points visible
- **Axiom 2**: Points represented as small spheres
- **Visualization**: Comparison of different point sizes (5mm, 1cm, 2cm, 3cm)
- **Code**: Creating SphereMesh with appropriate size
- **Discussion**: What size should a point be?

### Page 3: Instantiating the Point
- **Concept**: Turning mesh data into scene objects
- **Axiom 2.5**: Meshes must be instantiated to exist in the world
- **Visualization**: Multiple points instantiated in a pattern
- **Code**: MeshInstance3D creation and scene tree integration

### Page 4: Labeling the Point
- **Concept**: Identifying points with text labels
- **Axiom 3**: Labels convey point identity and coordinates
- **Visualization**: Points with billboard labels showing coordinates
- **Code**: Label3D creation with billboard mode

### Page 5: Dynamic Updates
- **Concept**: Points that move require updating labels
- **Axiom 4**: Labels must update when positions change
- **Visualization**: Moving points with real-time label updates
- **Code**: _process() loop for dynamic updates
- **Best Practices**: Null checks, parent relationships, performance

## Visualizations

### 1. Origin
- Pulsing point at (0,0,0)
- Coordinate axes (X: red, Y: green)
- Grid background
- Demonstrates the root of all vectors

### 2. Point Sizes
- Four points of different sizes side by side
- Labels showing real-world measurements
- Helps understand scale in 3D space

### 3. Instantiation
- Eight points arranged in a circle
- Connection lines to center
- Coordinate labels for each
- Shows multiple instantiated objects

### 4. Labels
- Four named points (A, B, C, D)
- Labels with coordinates in styled boxes
- Billboard effect demonstrated
- Pulsing animation for emphasis

### 5. Dynamic
- Four moving points with trails
- Velocity vectors shown
- Real-time updating coordinates
- Demonstrates animation and _process() loop

## Usage in Maps

```json
{
  "utilities": [
	["ib:point", " ", " "],
	[" ", "ib:point:1.5", " "]
  ]
}
```

## File Structure

```
commons/infoboards_3d/boards/Point/
├── PointInfoBoard.gd           # Main logic and content
├── PointInfoBoard.tscn          # UI layout (40/60 split)
├── PointVisualizationControl.gd # Drawing logic
├── PointVisualizationControl.tscn # Visualization container
└── README_Point.md              # This file
```

## Key Features

- **Educational Progression**: Builds from abstract to concrete
- **Code Examples**: Shows real GDScript for each concept
- **Interactive Visualizations**: Animated demonstrations of each axiom
- **Axiom-Based Learning**: Clear numbered principles
- **Performance Discussion**: Addresses best practices

## Technical Details

- **Font**: Roboto Variable Font (14px for text, 20px for title)
- **Layout**: 40% text panel, 60% visualization
- **Animation**: Speed control slider (0.5x - 3.0x)
- **Colors**: 
  - Background: Dark blue-gray
  - Points: Golden yellow
  - Axes: Red (X), Green (Y), Blue (Z)
  - Labels: Light blue-white

## Educational Goals

1. Understand points as the foundation of 3D graphics
2. Learn the relationship between abstract vectors and visual representations
3. Grasp the importance of scale and units in 3D space
4. See how scene tree hierarchy works
5. Understand dynamic updates and the _process() loop

## Integration with Grid System

The Point info board can be placed in maps using:
- `ib:point` - Default height
- `ib:point:1.5` - Raised 1.5 units

It integrates seamlessly with the grid system's utility layer and VR interaction.
