# The Marching Cubes Workflow: "Mathematical Sculpting"

> *"The goal is to create a seamless queer experience where identity and form are fluid, defined not by rigid polygons but by continuous fields of potential."*

## 🔮 Conceptual Overview

Unlike traditional 3D modeling (assembling polygons), this workflow uses **Signed Distance Functions (SDFs)**. You define an object by a mathematical formula that answers one question for every point in space: *"How far am I from the surface?"*

- **Negative value**: Inside the object.
- **Positive value**: Outside the object.
- **Zero**: On the surface.

This allows shapes to blend, morph, and exist seamlessly. A "chair" can become a "human" just by changing the formula, with no vertex tearing.

---

## 🛠️ The API: `mc:`

We have created an API to easily spawn these mathematical objects in code.

```gdscript
# Spawn a computer screen at (0,0,0) with scale 1.0
var screen = MarchingCubesAPI.create("mc:computerscreen")
add_child(screen)

# Spawn a human at specific coordinates
var human = MarchingCubesAPI.create("human", Vector3(10, 0, 10), 0.04)
add_child(human)
```

### Available Shapes
- `human`
- `chair`
- `house`
- `bottle`
- `cup`
- `computer` (or `mc:computerscreen`)

---

## ✍️ Workflow: How to Create a NEW Object

To add a completely new object (e.g., a "Tree"), follow these 3 steps:

### 1. Sculpting (GLSL)
Open `algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubesShapes.glsl`.

Write a function `float treeSDF(vec3 p)`. Use primitive SDFs (sphere, box, cylinder) and combiners (union, subtraction, smooth union).

```glsl
float treeSDF(vec3 p) {
    // 1. Trunk (Cylinder)
    float trunk = sdCappedCylinder(p - vec3(0, -10, 0), 4.0, 10.0);
    
    // 2. Leaves (Sphere)
    float leaves = sdSphere(p - vec3(0, 10, 0), 12.0);
    
    // 3. Smooth blend them (Organic connection)
    return opSmoothUnion(trunk, leaves, 2.0);
}
```

Then, update the main `evaluate()` function in the same file to include your new shape ID (e.g., case 6).

### 2. Registration (GDScript)
Open `algorithms/proceduralgeneration/marchingcave/Scripts/TerrainGeneratorShapes.gd`.

Add your new type to the Enum:
```gdscript
enum ShapeType { HUMAN, CHAIR, HOUSE, BOTTLE, CUP, COMPUTER, TREE }
```

### 3. API Update
Open `algorithms/proceduralgeneration/marchingcave/Scripts/MarchingCubesAPI.gd`.

Add the mapping:
```gdscript
const SHAPE_MAP = {
    # ...
    "tree": 6,
    "mc:tree": 6
}
```

---

## 🧠 Why this supports a "Seamless Queer Experience"

1.  **Fluidity**: Objects are not hollow shells; they are volumetric fields. A "cup" is mathematically solid.
2.  **Transformation**: All SDFs can be interpolated. You can mathematically `mix(humanSDF(p), treeSDF(p), 0.5)` to create a perfect hybrid being that is half-human, half-tree.
3.  **Infinity**: The resolution is infinite. You can zoom in forever (theoretically) and the curve remains perfect, unlike polygons which reveal their jagged edges.
