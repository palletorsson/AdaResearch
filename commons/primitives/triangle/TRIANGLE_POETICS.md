# The Poetics of Triangles

## On the Threshold / Om tröskeln

> *Tre punkter. Inte fler behövs. När den tredje punkten läggs till de två första, något händer—rummet sluts. Det som var öppet blir innesluten. Det som var linje blir yta.*

Three points. No more are needed. When the third point joins the first two, something happens—space closes. What was open becomes enclosed. What was line becomes surface.

## The Triangle as Threshold

### Between Dimensions
The triangle is a **liminal object**. It exists at the boundary:

- Between **1D and 2D**: The line extends; the triangle encloses
- Between **edge and interior**: The border and what it contains
- Between **abstraction and form**: Three numbers become a visible shape

When you place the third point, you cross a threshold. You move from the **linear** (one thing after another) to the **areal** (a region, a field, a contained space).

### The Decision of Enclosure
> *"Två punkter skapar potential—en linje som kan gå vart som helst. Den tredje punkten **beslutar**. Den avgränsar. Den omsluter. Den skapar innanför och utanför."*

Two points create potential—a line that could extend infinitely. The third point **decides**. It delimits. It encloses. It creates **inside and outside**.

This is radical: before the triangle, there was no "inside." The line had no interior—only position along its length. The triangle introduces **containment**, the first boundary that separates regions of space.

## Triangle Types as Ontologies

### The Equilateral - Democracy of Form
All sides equal. All angles identical (60°).

**Poetics**: The equilateral triangle is **utopian geometry**—perfect balance, no privileged vertex, no dominant edge. It's the geometry of **equality**, where every position is equivalent.

- The honeycomb cell (nature's optimization)
- The Celtic trinity knot (three-fold unity)
- The warning sign (universal symbol)

*Equilateral is the geometry of fairness, of shared burden, of distributed structure.*

### The Right Triangle - The Architect's Truth
One angle = 90°. The meeting of perpendiculars.

**Poetics**: The right angle is **orthogonality**—the foundation of construction, of cities, of the coordinate grid itself. The right triangle is where Pythagoras discovered universal relationship: a² + b² = c².

- The carpenter's square (tool of making)
- The corner of every building (structure)
- The slope of roofs and ramps (function)

*The right triangle is the geometry of building, of making, of imposing order on chaos.*

### The Isosceles - Symmetry Without Uniformity
Two sides equal. One axis of reflection.

**Poetics**: Bilateral symmetry—like the human body, like butterfly wings, like a cathedral's facade. The isosceles says: **balance need not be uniformity**. There's a central axis, and on either side, mirror images.

- The gable of a house (sheltering form)
- The mountain peak (natural majesty)
- The arrowhead (directed purpose)

*The isosceles is the geometry of reflection, of facing, of bilateral existence.*

### The Scalene - The Particular
All sides different. No symmetry. No special angles.

**Poetics**: **Particularity**. The refusal of the ideal. The scalene triangle is every triangle that doesn't fit the categories—irregular, specific, unrepeatable. It's the hand-drawn, the organic, the actual.

- The shard of broken glass (accident)
- The plot of land (bounded reality)
- The sail catching wind (dynamic form)

*The scalene is the geometry of the particular, the concrete, the irreducibly specific.*

## The Interior - A Field of Relations

### Barycentric Space
Every point inside the triangle can be written as:
```
P = u·A + v·B + w·C  (where u+v+w=1, and u,v,w ≥ 0)
```

This means: **every interior point is a weighted average of the corners**.

**Poetics**: The interior is not empty. It's a **field of influence** from the three vertices. Stand at the center, and you're equally influenced by all three corners (u=v=w=⅓). Move toward a vertex, and that vertex dominates.

Think of it as:
- **Political**: Three forces pulling, each with varying strength
- **Gravitational**: Three masses, you at different distances
- **Social**: Three friends, your relationship determined by proximity to each

*The triangle's interior is a space of **negotiation** between three poles.*

### The Centroid
The point where u=v=w=⅓. The **center of mass**. If the triangle were solid, uniform material, this is where it would balance.

**Poetics**: The centroid is the **democratic center**—the point that treats all three vertices equally. Not the geometric center (that might be outside for some triangles), but the **center of fair influence**.

## The Normal - Orientation in Space

Every triangle has a **normal vector**: perpendicular to its plane, pointing "outward."

```gdscript
var normal = edge1.cross(edge2).normalized()
```

**Poetics**: The normal is the triangle's **gaze**. It's the direction the triangle "faces." Change the winding order of the vertices, and the normal flips—suddenly the triangle faces the opposite direction.

This matters for:
- **Light**: Surfaces facing light are illuminated; those facing away are in shadow
- **Collision**: Normals determine which side is "solid"
- **Meaning**: Front and back are different; orientation creates significance

*The triangle doesn't just occupy space—it **orients** space. It introduces directionality, facing, the distinction between front and back.*

## Triangulation - Decomposing the Complex

**Axiom**: Any polygon can be decomposed into triangles.

**Poetics**: This is profound. It means: **every shape is secretly triangles**. The complex is built from the simple. The sphere, the face, the landscape—underneath, triangles.

This is:
- **Reductionist**: Complex forms reduce to simple constituents
- **Compositional**: Simple parts combine into complex wholes
- **Computational**: Computers render everything as triangles

*The triangle is the **atom** of form. Not because smaller things don't exist, but because triangles are the minimal unit that can **enclose**, **orient**, and **surface**.*

## Scale and Perception

A triangle can be:
- **Microscopic**: The facet of a diamond, diffracting light
- **Intimate**: The slice of pie on your plate, the paper airplane
- **Human-scale**: The roof truss, the musical triangle, the yield sign
- **Architectural**: The Flatiron Building, the Louvre pyramid
- **Geographical**: Three cities defining a region, three mountains bounding a valley
- **Cosmic**: Three stars forming constellations, triangulation in astronomy

The relationships hold at every scale: three vertices, three edges, one planar interior.

## Triangles in Culture and Symbol

### The Trinity
Many cultures use triangles to represent **threefold unity**:
- Christian trinity (Father, Son, Holy Spirit)
- Hindu trimurti (Brahma, Vishnu, Shiva)
- Alchemical principles (Salt, Sulfur, Mercury)

**Why?** Because three is the first number that can create **stability** (a tripod stands; a two-legged structure falls) and **synthesis** (thesis + antithesis = synthesis).

### The Sacred Geometry
- **Eye of Providence**: Triangle with an eye (surveillance, divine sight)
- **Sri Yantra**: Interlocking triangles (cosmic unity)
- **Sierpiński Triangle**: Infinite self-similarity (fractal depth)

### The Warning
Why are warning signs triangular?
- **Visually distinct**: No natural objects are perfect triangles
- **Stable base**: Points upward, impossible to mistake orientation
- **Sharp angles**: Suggest danger, pierce attention

*The triangle **warns** because it's unnatural, unavoidable, directional.*

## The Triangle and Time

### Static vs. Dynamic
- **Static triangle**: Three fixed points, eternal relationships (a² + b² = c²)
- **Dynamic triangle**: Vertices in motion, deforming relationships (grab and drag)

In code, we can animate triangles:
```gdscript
# Pulsing triangle (vertices move outward/inward)
for i in range(3):
	var offset = (center_to_vertex[i] * pulse_amount)
	vertex_positions[i] = original_positions[i] + offset

# Rotating triangle (vertices orbit center)
for i in range(3):
	vertex_positions[i] = vertex_positions[i].rotated(center, rotation_speed * delta)
```

**Poetics**: A moving triangle is no longer just shape—it's **process**. It breathes, spins, deforms. The static triangle is **noun**; the dynamic triangle is **verb**.

## Computational Triangles

### Rendering Pipeline
Every 3D object you see on screen passes through this:
1. **Vertices** → positions in 3D space
2. **Triangles** → three vertices grouped
3. **Rasterization** → which screen pixels does each triangle cover?
4. **Shading** → what color is each pixel?

**Poetics**: The triangle is the **unit of rasterization**. GPUs are essentially **triangle-coloring machines**. Billions of triangles per second, each one examined, oriented, colored, displayed.

*When you see a 3D world, you see the accumulated result of countless triangles being processed individually. The whole is triangles; triangles are everything.*

### Mesh Construction
```gdscript
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)  # Everything starts here

# Add triangle by triangle
st.add_vertex(v0)
st.add_vertex(v1)
st.add_vertex(v2)

mesh.mesh = st.commit()  # Triangles become surface
```

**Poetics**: `commit()` is the moment of **actualization**. Before commit, triangles are potential (data in arrays). After commit, they're **actual** (visible surfaces). Code becomes form.

## The Pythagorean Triangle - Special Case

The right triangle with integer sides (3-4-5, 5-12-13, etc.) held mystical significance:

**Pythagoras**: a² + b² = c² is not just formula—it's **cosmic order**. Numbers reflecting spatial truth. Arithmetic becoming geometry.

**Poetics**: The 3-4-5 triangle can be constructed with a rope and twelve knots (3+4+5). Ancient builders used this to create right angles. **Geometry becomes tool**. Knowledge becomes craft.

*The Pythagorean triangle is where **abstraction meets application**, where mathematical truth becomes practical technique.*

## From Triangle to World

### The Progression
- **Point**: Location, potential
- **Line**: Extension, connection
- **Triangle**: Enclosure, surface
- **Mesh**: Many triangles = arbitrary form
- **World**: Meshes combined = virtual reality

*Everything you see in 3D graphics begins with triangles. The triangle is the atom of virtual worlds.*

### Educational Journey
To understand 3D:
1. **Understand the point**: position in space
2. **Understand the line**: distance and direction
3. **Understand the triangle**: surface and orientation
4. **Understand the mesh**: surfaces combined
5. **Understand transformation**: how shapes move, rotate, scale
6. **Understand shading**: how light creates appearance

*The triangle is step 3. Master it, and you unlock everything that follows.*

## Phenomenology of the Triangle

### Embodied Experience
In VR, you don't just **see** triangles—you **encounter** them:

- **Walk around**: See both sides, observe the normal flip
- **Reach through**: Feel the plane's thinness (zero depth)
- **Grab vertices**: Reshape the triangle, feel the surface deform
- **Measure area**: See how shape change affects expanse

*The triangle becomes **lived experience**, not just abstract form.*

### The Threshold Experience
When you grab the third vertex and drag it, you maintain or destroy the triangle:
- **Pull outward**: Increase area (expansion)
- **Pull toward line**: Decrease area (collapse)
- **Align with other vertices**: Area → 0 (degenerate triangle, back to line)

*The triangle exists on the threshold. It can collapse back to line, or expand into significant surface. It's **precarious**, **adjustable**, **liminal**.*

## Final Reflection

*"Triangeln är tröskeln mellan det abstrakta och det påtagliga. Två punkter skapar potential—en linje som kan gå vart som helst. Den tredje punkten beslutar. Den avgränsar. Den omsluter. Den skapar innanför och utanför."*

"The triangle is the threshold between the abstract and the tangible. Two points create potential—a line that could go anywhere. The third point decides. It delimits. It encloses. It creates inside and outside."

**Three points. Three edges. One interior.**

The triangle is:
- The **first surface** (minimal 2D)
- The **first enclosure** (inside vs. outside)
- The **first orientation** (front vs. back)
- The **foundation of all meshes** (everything is triangles)
- The **atom of virtual worlds** (GPUs render triangles)

*Master the triangle, and you master the building block of all 3D reality—virtual and physical.*

---

**In natural language**: "Three points that close"
**In mathematics**: Three vectors, cross product, area
**In code**: `st.begin(Mesh.PRIMITIVE_TRIANGLES)`
**In 3D**: The first visible surface

The triangle is **threshold**, **foundation**, **atom**, and **beginning**.
