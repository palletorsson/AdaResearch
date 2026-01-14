# Point Triangle - Critical Reflection

## The First Enclosure

From triangle_axioms: "Three positions connected by three relations produce something new: an inside and an outside."

This is the decisive moment: **Space becomes enclosed**.

Before the triangle:
- Point (position, singular)
- Line (connection, open)
- Grid (indexing, but still open fields)

With the triangle:
- **Closure** appears
- **Containment** becomes possible
- **Boundaries** are established

The triangle doesn't just measure or organize space - it **captures** it.

## Inside and Outside: The Decisive Binary

The triangle produces a binary distinction: A position is either **inside** the boundary or **outside** it.

```gdscript
var is_inside = point_in_triangle(test_point, a, b, c)
// Returns: true or false
```

No third state. No "partially inside." No "near the boundary." The algorithm returns a **boolean**.

This is **computational violence** - the reduction of continuous gradients to discrete categories:
- Inside vs. Outside
- Citizen vs. Alien
- Legal vs. Illegal
- Included vs. Excluded

The triangle's boundary has **no thickness**. It cannot express:
- Thresholds (gradual transitions)
- Porous edges (semi-permeable boundaries)
- Ambiguous belonging (partially inside)
- Contested zones (disputed boundaries)

The triangle insists: **You are either in or out.**

## What the Triangle Cannot Hold

From triangle_axioms: "The boundary has no thickness."

What the triangle excludes:
- **Gradients** - Smoothly varying inclusion
- **Porosity** - Boundaries that allow passage
- **Negotiation** - Boundaries that shift based on context
- **Multiple membership** - Being inside several overlapping territories
- **Liminality** - The space of the threshold itself

The triangle is **pure enclosure** - absolute, instantaneous, non-negotiable.

## The Triangle as Governance

From triangle_axioms: "To draw a triangle is to declare territory."

Every triangle is an act of **spatial governance**:
- What was continuous becomes bounded
- What was open becomes enclosed
- What was shared becomes exclusive

Consider what triangular boundaries represent:

**Property boundaries**
- Lot lines on cadastral maps
- "This parcel belongs to X"
- Triangular survey plots

**Borders**
- National boundaries (polygons made of triangles)
- Immigration zones
- "You may not cross this line"

**Exclusion zones**
- Military no-fly areas
- Restricted access regions
- "You are not permitted here"

**Computational spaces**
- Collision boundaries (this object cannot pass through)
- Trigger zones (events fire when you enter)
- Render frustums (only what's inside is drawn)

To draw a triangle is to **partition space into included and excluded**.

## Triangulation as Surveillance

Modern surveillance often involves **triangulation** - using three or more reference points to locate a target:

- **Cell tower triangulation** - Your phone's position calculated from signal strength to multiple towers
- **GPS triangulation** - Position determined from multiple satellites
- **Acoustic triangulation** - Gunshot location from microphone array
- **WiFi triangulation** - Device location from multiple access points

Triangulation transforms continuous space into **precise coordinates** that can be logged, tracked, and analyzed.

The triangle enables **localization** - fixing position within a bounded region.

## The Atomic Surface: Every Mesh is Triangles

From triangle_axioms: "All polygonal surfaces reduce to triangles."

Every 3D object you see in VR is composed of triangular faces:
- Your avatar: thousands of triangles
- The room: hundreds of triangles
- The platform: dozens of triangles
- Each interactable object: triangles

The GPU renders **only triangles**. Complex curves, organic shapes, smooth surfaces - all are **triangular approximations**.

This means:
- **All rendered boundaries are discrete** (made of flat triangular facets)
- **Smoothness is an illusion** (enough small triangles appear curved)
- **Everything has edges** (triangle boundaries, even if subpixel)

The continuous world is **triangulated** before it can be rendered. Reality is approximated by countless small enclosures.

## Orientation: Front and Back

The triangle has **orientation** - a front face and a back face.

```gdscript
material.cull_mode = BaseMaterial3D.CULL_BACK
// Only the front face is rendered
```

This produces asymmetry: The triangle **sees in one direction only**.

Consider the politics of orientation:
- Architecture faces a "street side" and hides a "back alley"
- Surveillance cameras point toward public space, away from operator
- Borders are crossed in one direction easily, the other with difficulty
- Interfaces show a "public face" while hiding backend systems

The triangle's orientation establishes **directionality** - who sees and who is seen.

## The Editable Triangle: Closure Persists

In Point_Triangle, you can **grab and move vertices**. But the triangle persists as long as vertices remain non-collinear.

This reveals: **Closure is a relation, not a fixed form**.

The triangle is not "these specific three positions." It is "whatever three positions maintain connection."

This has political implications:
- Boundaries can shift while remaining boundaries
- Territory can be redefined while remaining exclusive
- The category of "inside/outside" persists even as the shape changes

Enclosure is **flexible** - it adapts to maintain closure even as its form transforms.

## The Triangle Inequality: Geometric Constraint

Not any three edge lengths can form a triangle:

```gdscript
a + b > c  // Sum of two sides must exceed third
```

This is **geometric constraint** - the triangle has requirements. You cannot arbitrarily define edges and expect closure.

This constraint appears benign (just geometry), but it reveals how **formal systems impose requirements** for inclusion:
- Immigration systems: "You must have X qualifications to enter"
- Property systems: "You must have Y documentation to own"
- Citizenship: "You must meet Z criteria to belong"

The triangle inequality says: **Not everything can be enclosed this way.** Some configurations are excluded by the rules themselves.

## Triangulation of Terrain: Making Ground Calculable

3D terrain is represented as a **triangle mesh** - a surface made of connected triangular faces.

This process:
- **Samples** elevation at discrete points (the vertices)
- **Interpolates** between samples (the faces)
- **Discards** sub-triangle detail (variations within faces)

The result: Smooth, continuous terrain becomes a **faceted approximation**.

What's lost:
- Texture below triangle resolution
- Micro-topography (pebbles, grass, irregularities)
- Non-planar surface details within each triangle

The terrain is made **calculable** by becoming triangular, but actual ground is **more complex** than any triangle mesh can represent.

## Queer Triangles

What would a queer triangle look like?

Perhaps:
- **Porous boundaries** that allow passage and leakage
- **Thick edges** that acknowledge the threshold as a space
- **Ambiguous interiors** where inside/outside is uncertain
- **Shifting vertices** that drift over time
- **Overlapping triangles** that share contested space

A queer triangle would refuse the **absolute binary** of inclusion/exclusion. It would insist that boundaries are:
- **Negotiated** (not predetermined)
- **Permeable** (not impermeable)
- **Contested** (not settled)
- **Gradual** (not instant)

## The Workshop Architecture

Point_Triangle's architecture creates a "workshop" space - elevated platforms at varied heights, focused lighting from dark_sphere, central manipulation area.

This staging says: **Triangles are made, not discovered**.

The editable triangle makes this explicit - you **construct** the closure by positioning vertices. The boundary appears as a result of your choices.

This is crucial: The triangle is not natural geometry. It is **geometric technology** - a tool for producing enclosure.

## Every Complex Surface is Countless Small Enclosures

A sphere rendered at 32×16 resolution contains **1,024 triangles**.

Every rendered object is:
- Thousands of small boundaries
- Thousands of inside/outside decisions
- Thousands of discrete facets approximating continuity

The smooth world you see in VR is actually **countless tiny enclosures** rendered so quickly they appear unified.

This is the computational condition: Continuity is **simulated through dense discretization**. The world is not actually smooth - it's made of millions of small, hard boundaries.

## The Pythagorean Theorem: Geometric Certainty

For right triangles: a² + b² = c²

This theorem establishes **geometric certainty** - given two sides, the third is **determined**.

This certainty enables:
- **Predictability** (outcomes can be calculated)
- **Constraint** (not all configurations are possible)
- **Control** (systems behave according to rules)

The Pythagorean theorem appears neutral (just mathematics), but it reveals how **formal systems reduce uncertainty** through constraint.

In right triangles, there is no freedom - the relationship is deterministic.

## Triangles and Rigidity

Triangles are **structurally rigid** - three edges form a stable configuration that resists deformation.

Contrast with quadrilaterals (four sides), which can "squash" unless braced. Triangles need no bracing - they are inherently stable.

This is why bridges, towers, and trusses use **triangular supports** - the triangle is geometry of **structural enforcement**.

The triangle literally **holds things in place**.

## Conclusion: Enclosure as Foundational Geometry

Point_Triangle teaches that the triangle is the **first geometry that contains**.

The triangle introduces:
- **Boundaries** that divide space
- **Binaries** that categorize positions
- **Orientation** that establishes front/back
- **Area** that quantifies capture
- **Rigidity** that resists change

These are not innocent geometric properties. They are **technologies of enclosure** that enable:
- Property (bounded, owned space)
- Territory (exclusive regions)
- Surveillance (triangulated positions)
- Rendering (discretized surfaces)
- Control (rigid structures)

Every rendered surface in VR is composed of triangular faces. This means:

**You navigate a world of countless small enclosures**.

Every object, every surface, every boundary is a **repetition of the triangle's logic**: inside or outside, included or excluded, visible or culled.

The question is not whether to use triangles (we must - they're foundational to rendering). The question is whether we can remain **aware** that triangles are not neutral:

The triangle is **geometric governance** - the tool that makes space containable, boundaries absolute, and inclusion binary.

When you grab the triangle's vertices and watch the boundary reform, you are witnessing **the making of enclosure** - the act of drawing a line that says: "This space is separate. There is an inside. There is an outside."

This is power disguised as geometry.
