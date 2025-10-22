# Triangle Primitive - The First Surface

## Overview

The triangle is the threshold between line and surface, between one-dimensional extension and two-dimensional area. It is the **first bounded space**, the **minimal polygon**, and the **atomic unit of all 3D geometry**. Where the point was location and the line was distance, the triangle introduces **interior**, **orientation**, and **area**.

## The Triangle in Three Modalities

### Natural Language
"Three points not in a line define a plane. Between them, bounded by their edges, emerges the first interior—a region that is neither here nor there at any single point, but **enclosed**. The triangle is the threshold, the minimal surface, the first shape that can contain."

### Mathematics
- Three vertices: **A**, **B**, **C** as Vector3 positions
- Three edges: line segments AB, BC, CA
- One face: the planar region bounded by the edges
- **Axiom**: Three non-collinear points uniquely determine a plane
- Area = ½ |(**B** - **A**) × (**C** - **A**)|

### Code (Godot 4)
```gdscript
# Three vertices define the triangle
var vertex_positions: Array[Vector3] = [
    Vector3(-0.25, 0.0, 0.0),  # A: Bottom-left
    Vector3(0.25, 0.0, 0.0),   # B: Bottom-right
    Vector3(0.0, 0.5, 0.0)     # C: Top-center
]

# The triangle exists in the mesh
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)

# Calculate the face normal (orientation)
var edge1 = vertex_positions[1] - vertex_positions[0]
var edge2 = vertex_positions[2] - vertex_positions[0]
var normal = edge1.cross(edge2).normalized()

# Add the three vertices to create the surface
st.set_normal(normal)
st.add_vertex(vertex_positions[0])
st.add_vertex(vertex_positions[1])
st.add_vertex(vertex_positions[2])

# Commit creates the visible surface
mesh_instance.mesh = st.commit()
```

## Conceptual Progression

### 1. From Line to Surface
The line extended infinitely. The triangle **closes**.

- **Point**: Location (0D)
- **Line**: Extension between two points (1D)
- **Triangle**: Area bounded by three points (2D)

The triangle is the **minimal closure**—you cannot create a bounded 2D region with fewer than three points. Two points create only a line. Three points create the first **interior**.

### 2. The Plane Axiom
**Axiom 1**: Three non-collinear points uniquely determine a plane.

This is foundational to all 3D geometry:
- Three points = one plane (unique)
- Four or more points = potentially non-planar
- The triangle is **always planar** by definition

In code, this means: when you have three vertices, you **know** they lie on a plane. You can calculate that plane's normal vector through the cross product.

### 3. Orientation and the Normal
**Axiom 2**: A triangle has two sides, determined by vertex winding order.

```gdscript
# Counter-clockwise winding (when viewed from normal direction)
var edge1 = B - A
var edge2 = C - A
var normal = edge1.cross(edge2).normalized()  # Points "out"

# The normal defines:
# - Which side is "front" (normal direction)
# - Which side is "back" (opposite direction)
# - How light interacts with the surface
```

The normal is not just a technicality—it's the triangle's **orientation in space**, its facing direction, its relationship to light and viewer.

### 4. Interior and Barycentric Coordinates
**Axiom 3**: Any point inside a triangle can be expressed as a weighted combination of its vertices.

```gdscript
# A point P inside triangle ABC can be written as:
# P = u*A + v*B + w*C
# where u + v + w = 1 and u,v,w >= 0

# This means:
# - Every interior point is "between" the vertices
# - The weights (u,v,w) are the barycentric coordinates
# - They're used for texture mapping, interpolation, collision detection
```

The interior is not empty—it's a **field of positions**, each with a unique relationship to the three corners.

### 5. Area - The First Measurable Region
**Axiom 4**: The triangle has area = ½ |edge1 × edge2|

```gdscript
func get_triangle_area(v0: Vector3, v1: Vector3, v2: Vector3) -> float:
    var edge1 = v1 - v0
    var edge2 = v2 - v0
    var cross = edge1.cross(edge2)
    return cross.length() * 0.5
```

Area is the first **2D measure**. Not distance (1D), but **expanse**—the amount of surface enclosed.

## Triangle Types - Modes of Being

Different triangles express different relationships between their vertices. These are not mere categories—they're **geometric personalities**, different ways of organizing space.

### Equilateral Triangle
```gdscript
# All sides equal, all angles 60°
vertex_positions = [
    Vector3(-0.25, -0.25, 0.0),
    Vector3(0.25, -0.25, 0.0),
    Vector3(0.0, 0.25, 0.0)
]
```
**Poetics**: Perfect symmetry. The Platonic ideal. No edge dominates, no angle privileged. The equilateral triangle is **democracy in geometry**—equal distribution of distance, equal division of space.

### Right Triangle (90° angle)
```gdscript
# One angle = 90°, Pythagorean relationship: a² + b² = c²
vertex_positions = [
    Vector3(0.0, 0.0, 0.0),   # Right angle here
    Vector3(1.0, 0.0, 0.0),   # Along X (base)
    Vector3(0.0, 1.0, 0.0)    # Along Y (height)
]
```
**Poetics**: Orthogonality. The meeting of perpendiculars. The right angle is the **architect's angle**, the angle of construction, of grids, of Cartesian space itself.

The Pythagorean theorem emerges here: `a² + b² = c²`—a relationship so fundamental it's been proven hundreds of ways across cultures and millennia.

### Isosceles Triangle
```gdscript
# Two sides equal
vertex_positions = [
    Vector3(-0.3, -0.2, 0.0),
    Vector3(0.3, -0.2, 0.0),
    Vector3(0.0, 0.4, 0.0)
]
```
**Poetics**: Bilateral symmetry. The human face, the butterfly, the doorway. One axis of reflection creates a sense of **balance without uniformity**—variation within structure.

### Scalene Triangle
```gdscript
# All sides different
vertex_positions = [
    Vector3(-0.2, -0.3, 0.0),
    Vector3(0.4, -0.1, 0.0),
    Vector3(0.1, 0.3, 0.0)
]
```
**Poetics**: Asymmetry. The organic, the irregular, the hand-drawn. Every angle different, every edge its own length. The scalene is **particularity**, the resistance to abstraction.

## The Triangle Mesh - Foundation of All 3D Surfaces

**Axiom 5**: Every 3D mesh is composed of triangles.

Whether you see a sphere, a character, a terrain, or a building—underneath, it's triangles all the way down:

```gdscript
# A "smooth" sphere is actually many small triangles
var sphere_mesh = SphereMesh.new()
sphere_mesh.radial_segments = 32  # 32 triangles around equator
sphere_mesh.rings = 16            # 16 rings of triangles top to bottom
# Total triangles: approximately 32 × 16 × 2 = 1024 triangles

# When you create any mesh, you create triangles:
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)  # The fundamental primitive
# Everything else is built from this
```

### Why Triangles?

1. **Always Planar**: Three points always lie on a plane (four+ may not)
2. **Convex**: No interior angles > 180° (simplifies rendering)
3. **Simple Rasterization**: GPUs are optimized for triangle rendering
4. **Minimal**: Fewest vertices to enclose 2D area
5. **Universal**: Any polygon can be decomposed into triangles

The triangle is the **lowest common denominator** of all 3D surfaces. Master the triangle, and you master mesh geometry.

## Interactive Triangle Features

### Basic Triangle (`triangle.tscn`)
- **Three grabbable vertices**: Drag each corner to reshape
- **Real-time mesh updates**: Surface recomputes as you move vertices
- **Preset shapes**: Reset to equilateral (E), right-angled (R), isosceles (I)
- **Area calculation**: Displays area as you reshape
- **Material with shader**: Wireframe + fill color visualization

```gdscript
# Instance and manipulate
var triangle = preload("res://commons/primitives/triangle/triangle.tscn").instantiate()
add_child(triangle)

# Access information
var info = triangle.get_triangle_info()
print("Area: ", info["area"])
print("Vertices: ", info["vertices"])
```

### Pythagorean Triangle (`pythagorean_triangle.tscn`)
- **Right triangle with labeled sides**: a, b, c
- **Live Pythagorean calculation**: Shows a² + b² = c² in real-time
- **Educational visualization**: Drag vertices and watch the relationship update
- **Horizontal orientation**: Lies flat on the ground plane

```gdscript
# Instance Pythagorean demonstration
var pyth = preload("res://commons/primitives/triangle/pythagorean_triangle.tscn").instantiate()
add_child(pyth)

# Get mathematical relationships
var info = pyth.get_pythagorean_info()
print("a² + b² = ", info["sum_squares"])
print("c² = ", info["c_squared"])
print("Difference (should be ~0): ", info["difference"])
```

## Technical Implementation Details

### Double-Sided Rendering
Triangles are rendered on both sides for VR visibility:

```gdscript
# Front face (normal direction)
st.set_normal(normal)
st.add_vertex(v0)
st.add_vertex(v1)
st.add_vertex(v2)

# Back face (reversed winding, negated normal)
st.set_normal(-normal)
st.add_vertex(v0)
st.add_vertex(v2)  # Reversed order
st.add_vertex(v1)
```

### Normal Calculation
The cross product determines surface orientation:

```gdscript
var edge1 = v1 - v0
var edge2 = v2 - v0
var normal = edge1.cross(edge2).normalized()

# Normal properties:
# - Perpendicular to both edge1 and edge2
# - Perpendicular to the triangle plane
# - Length = area of parallelogram formed by edge1, edge2
# - Direction determined by right-hand rule (winding order)
```

### Material and Visualization
Uses `SimpleGrid.gdshader` for wireframe + fill rendering:

```gdscript
material.set_shader_parameter("wireframe_color", Color.DARK_VIOLET)
material.set_shader_parameter("fill_color", Color.DEEP_PINK)
```

## Educational Progression

### For Beginners
1. **Recognize triangles** in everyday 3D geometry
2. **Manipulate vertices** to understand how shape emerges
3. **Observe area changes** as triangles deform
4. **Explore presets** to understand different triangle types

### For Intermediate Learners
1. **Understand normals** and their role in lighting/orientation
2. **Calculate area** using cross product
3. **Work with barycentric coordinates** for point-in-triangle tests
4. **Decompose polygons** into triangles

### For Advanced Study
1. **Triangle mesh optimization** (reducing triangle count)
2. **Delaunay triangulation** (optimal triangle arrangements)
3. **Triangle strips and fans** (efficient rendering)
4. **Subdivision surfaces** (triangles → smooth surfaces)

## Philosophical Notes

### The Threshold
*"The triangle is the threshold between the abstract and the tangible. Two points create potential—a line that could go anywhere. The third point **decides**. It bounds. It encloses. It creates inside and outside."*

### The Minimal Surface
*"Why is the triangle fundamental? Because it is the **least** that can be called a surface. It is the economy of geometry—no wasted points, no redundant edges. Three vertices, three edges, one face. Nothing more, nothing less."*

### The Foundation of the Virtual
*"When you look at any 3D world—a game, a simulation, a virtual reality—you are looking at triangles. Millions of them. The triangle is the **pixel of 3D space**, the atomic unit of virtual form. Master the triangle, and you hold the building block of digital reality."*

### Scale and Perception
Drawing from the line's poetics: a triangle can be:
- **Microscopic**: The facet of a distant polygon, invisible to the eye
- **Intimate**: A hand-held paper folded into thirds
- **Architectural**: The pediment of a Greek temple
- **Vast**: Three mountain peaks bounding a valley

The triangle scales. It is scale-invariant. From nanometers to kilometers, the relationships hold: three points, three edges, one bounded interior.

## Integration and Usage

### In VR Experiences
```gdscript
# Interactive geometry education
var triangle = preload("res://commons/primitives/triangle/triangle.tscn").instantiate()
add_child(triangle)

# Listen for interaction events
# (Triangle emits events through TextManager on vertex drop)
```

### In Map Systems
```json
{
  "utilities": [
    ["triangle", " ", " "],
    [" ", "pythagorean_triangle", " "]
  ]
}
```

### Customization
```gdscript
# Change vertex visualization
triangle.sphere_size_multiplier = 0.5  # Larger grab spheres
triangle.vertex_color = Color(1.0, 0.0, 0.0, 0.5)  # Red transparent

# Adjust behavior
triangle.alter_freeze = true  # Keep triangle fixed while moving vertices

# Programmatically reshape
triangle.vertex_positions[0] = Vector3(1.0, 0.0, 0.0)
triangle.update_sphere_positions()
```

## File Structure

```
commons/primitives/triangle/
├── triangle.gd                    # Main interactive triangle
├── triangle.tscn                  # Scene with three grab spheres
├── pythagorean_triangle.gd        # Educational right triangle
├── pythagorean_triangle.tscn      # Pythagorean demonstration scene
└── README.md                      # This file
```

## Keyboard Controls

### Standard Triangle
- **E**: Reset to equilateral triangle
- **R**: Reset to right-angled triangle
- **I**: Reset to isosceles triangle
- **Mouse/VR**: Drag corner spheres to reshape

### Pythagorean Triangle
- **R**: Reset to 1m × 1m right triangle
- **Mouse/VR**: Drag corners to see Pythagorean relationship change

## Events and TextManager Integration

When vertices are dropped, triangles emit events:

```gdscript
# Event: "triangle_drop"
{
    "vertex": 2,              # Which vertex was dropped (0-2)
    "area": "0.15"           # Current triangle area in m²
}
```

Map authors can create contextual messages responding to triangle manipulation.

## Future Explorations

### Potential Extensions
- **Tessellation**: Split one triangle into four smaller triangles
- **Extrusion**: Pull the triangle into 3D to create a prism
- **Revolution**: Rotate triangle around an axis to create a surface
- **Deformation**: Bend the triangle (non-planar) to introduce curvature
- **Triangle fans**: Multiple triangles sharing a central vertex
- **Triangle strips**: Efficient chains of connected triangles
- **Voronoi/Delaunay**: Optimal triangle arrangements in space

### Educational Sequences
- **Triangle → Quadrilateral**: Two triangles = four-sided polygon
- **Triangle → Mesh**: Many triangles = complex surface
- **Triangle → Subdivision**: Smooth surfaces from triangular base
- **Triangle → Collision**: Using triangles for physics detection

## Connections to the Progression

- **From Point**: Three points instantiated
- **From Line**: Three lines connected and closed
- **To Mesh**: Many triangles combined into surfaces
- **To Primitives**: Triangle → Quad → Cube → Sphere (all built from triangles)
- **To Shaders**: Triangles are the unit that shaders operate on
- **To Transformation**: Rotate, scale, translate entire triangular surfaces

---

*"The point was potential. The line was extension. The triangle is **enclosure**—the first space that knows inside from outside, the first surface that can hold meaning, the first shape that is truly a shape."*

**Three points. Three edges. One interior. The triangle is the threshold of surface, the foundation of form, the atom of all virtual geometry.**
