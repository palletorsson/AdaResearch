# Using Marching Cubes and AI to Create Low Poly Game Objects

**Exploring a workflow for "Mathematical Sculpting" in Game Development**

In traditional game development, creating 3D assets usually involves a modeling software (like Blender), moving vertices, managing UV maps, and exporting fbx/obj files. This process is rigid. A chair is a chair; to make it a table, you delete it and start over.

But what if objects were defined not by fixed shells, but by **mathematical fields**?

This article explores a workflow we implemented in the *Ada Research* project: generating game objects procedurally using the **Marching Cubes algorithm**, driven by **Signed Distance Functions (SDFs)**, and assisted by **AI** to bridge the gap between creative intent and complex mathematics.

---

## 1. The Core Concept: Mathematical Sculpting

Instead of storing a list of triangles, we store a **function**. This function, called an **SDF (Signed Distance Function)**, takes any point $(x,y,z)$ in space and answers one simple question:

> *"How far is this point from the surface?"*

- **Negative Distance**: Inside the object.
- **Positive Distance**: Outside the object.
- **Zero**: On the surface.

To "render" this into a game object, we use the **Marching Cubes** algorithm. It divides space into a 3D grid of voxels. For each voxel, it checks the values at the corners and "marches" through, building triangles where the value crosses from positive to negative (the surface).

### Why is this powerful?
1.  **Fluidity**: You can smooth-blend shapes.
    *   `min(d1, d2)` creates a **hard union**—like two clay balls stuck together with a sharp crease.
    *   `smin(d1, d2, k)` (smooth minimum) acts like **liquid mercury**, merging the shapes organically with a smooth fillet, where $k$ controls the "goopiness" of the blend.
2.  **Resolution Independence**: You can generate the mesh at low resolution for a "low poly" aesthetic or high resolution for smooth organic forms, just by changing a single variable (`grid_size`).
3.  **Code-Driven**: The object exists as code (`.glsl`), meaning it can be version-controlled, parametrized, and tweaked instantly.

*(Imagine a diagram here: On the left, a sharp V-shape where two spheres meet. On the right, a smooth U-curve bridging them, illustrating the `smin` function.)*

---

## 2. The Interaction: AI as the Translator

The challenge with SDFs is that writing them is hard. Math is abstract. Telling a computer "draw a human" requires composing spheres, capsules, and ellipsoids with precise coordinate transformations.

This is where **AI** becomes the perfect pair-programmer.

### The Workflow
1.  **Intent**: "I want a low-poly computer screen."
2.  **AI Translation**: The AI converts this intent into GLSL code using primitive SDFs:
    *   *Monitor*: A rounded box (`sdBoxRound`).
    *   *Stand*: A vertical box unioned with a base box (`opUnion`).
    *   *Placement*: Coordinate offsets (`p - vec3(0, 10, 0)`).
3.  **Generation**: The game engine compiles this shader at runtime, runs the Marching Cubes compute shader, and produces a physical mesh in the scene.

**Example Prompt:**
> "Create a chair using SDFs."

**AI Output (GLSL):**
```glsl
float chairSDF(vec3 p) {
    float seat = sdBox(p, vec3(15, 2, 15));
    float back = sdBox(p - vec3(0, 15, -13), vec3(15, 12, 2));
    float leg1 = sdBox(p - vec3(12, -10, 12), vec3(2, 8, 2));
    // ... union them together ...
    return opUnion(seat, opUnion(back, legs));
}
```

---

## 3. Achieving the "Low Poly" Aesthetic

While Marching Cubes is often used for high-res terrain, it is surprisingly excellent for stylized, low-poly art.

By adjusting the **Grid Resolution** (or `chunk_scale`), we force the algorithm to approximate the smooth mathematical curve with fewer, larger triangles.
- **High Res**: Smooth, indistinguishable from a sculpted mesh.
- **Low Res**: Chunky, distinct geometry that catches light in interesting ways.

*(Visualizing Resolution: A sphere at 64 resolution looks like a ball. At 8 resolution, it looks like a faceted icosahedron-style gem.)*

We further simplified the pipeline for game performance:
- **Static Generation**: The mesh generates *once* on load. We disable the update loop (`set_process(false)`), making it as cheap as a standard static mesh.
- **Collision optimization**: We generate physics bodies only if the triangle count is manageable, allowing player interaction.

---

## 4. Seamless Implementation (The `mc:` API)

Theoretical power means nothing if you can't use it in a level. We built a system to bridge the gap between our JSON map definitions and the compute shader.

Instead of manually placing nodes, a level designer or architect simply requests an object by string ID.

### The Definition (JSON)
In our map data, we can invoke a computer screen, rotate it, and scale it down to human size with a single string:
```json
"interactables": [
    [" ", " ", " ", "mc:computerscreen:0:0:0.04", " "]
]
```
*Format: `prefix:id:rotation_y:y_offset:scale`*
*Example Breakdown: `mc` prefix, `computerscreen` ID, `0` degrees Y-rotation, `0` units vertical offset, `0.04` uniform scale.*

### The Backend (GDScript)
The system parses the `mc:` prefix and delegates the creation to our API, which sets up the compute pipeline on the fly.

```gdscript
# GridInteractablesComponent.gd
if lookup_name.begins_with("mc:"):
    # Parse "computerscreen", scale 0.04
    var mc_object = MarchingCubesAPI.create(lookup_name, position)
    parent_node.add_child(mc_object)
```

This abstraction allows for the definitions of objects to be incredibly lightweight—mere bytes in a text file—while the engine manifests them as fully volumetric, interactable geometry at runtime.

---

## 5. Conclusion: A Fluid Future

This technique offers a glimpse into a future of "Semantic Rendering." We aren't just placing pre-baked assets; we are describing objects and letting the engine manifest them.

For the *Ada Research* project, this serves a thematic purpose beyond just tech: it represents a **"seamless queer experience"** where identity and form are not rigid binaries (vertex vs. empty space) but continuous fields of potential, capable of shifting, blending, and reforming new identities on the fly.
