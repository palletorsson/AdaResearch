# Primitive Ontology — What Each Artifact Opens

> Every primitive is a lens on the world. Not "how does it work" but
> "what does it reveal about the nature of things?"
>
> This is a living document. Each entry should be discussed, challenged,
> and deepened through building the 2D editors and testing in VR.

---

## Point — The Act of Choosing

**Lens:** Location — *What system am I in?*

A point is not a dot. A point is a **decision**: *here, not there*.
But "here" only means something inside a system:

- **Euclidean** space: (x, y, z) — flat, measurable, familiar
- **Hyperbolic** space: position on a saddle — distances stretch outward
- **Spherical** space: lat/long — no edge, every direction curves back
- **Spacetime**: an event — not just where, but when
- **Topology**: a member of a set — no coordinates at all, just belonging

The most important thing about a point is that **it doesn't exist without
a space to exist in**. Choosing a coordinate system is an ontological
commitment — you're declaring what dimensions matter.

**QFEP connection:** The point is where formalism meets identity.
"Where am I?" is always followed by "in what system?"

**Open questions:**
- What does a point mean in a space with no metric?
- Is the origin special, or is that a choice too?
- When Ada places a spawn point on a map — what ontological claim is that?

---

## Line — Length and Measure

**Lens:** Connection + Measurement — *What defines "between"? And what is the unit?*

A line is not a shape. A line is the claim that **two things are connected**.
But the line is also **the instrument of measurement itself**. It is both
the distance and the ruler. Length and measure are the same object.

This duality is fundamental:
- The line IS the shortest path (the thing)
- The line IS how we measure that path (the tool)
- You cannot separate the measured from the measurement

The nature of the connection depends on the space:

- **Euclidean**: straight, shortest path, measurable with itself
- **Hyperbolic**: geodesic — curved, diverging, distances grow exponentially
- **Spherical**: great circle — go far enough and you return to start
- **Graph theory**: an edge — no geometry, just "these two are linked"
- **Social**: a connection between people — shortest ≠ strongest

The line teaches: **the shortest path between two points depends on the
world you're in.** And: **you cannot measure without first choosing what
measuring means** — the line is both the question and the answer.

**QFEP connection:** The line as measure is the formalism making itself
visible. The ruler is part of the system it measures.

**Open questions:**
- If the line is both length and measure, what happens when the ruler curves?
- In non-Euclidean geometry, the "straight line" is curved — is it still a line?
- What does it mean that we measure the world with a piece of the world?
- Is a border a line? What does a line exclude?

---

## Triangle — The Minimum Enclosure

**Lens:** Surface — *What is the smallest thing that contains area?*

Three points. The first shape that **encloses area**. Two points make a
line (1D). Three make a surface (2D). This is a dimensional jump — the
smallest possible one.

But the triangle is also:
- The **rendering primitive** — every 3D model is triangles. The GPU knows nothing else.
- The **normal vector** — orientation tells light where to bounce. *Visibility depends on facing.*
- **Winding order** — CCW = front, CW = back. Same triangle, different traversal = visible or invisible.
  *Identity depends on the order you tell your story.*

The triangle teaches: **complexity is decomposed into the simplest possible
surfaces.** And: the same surface can be visible or invisible depending on
which side you're looking from.

**QFEP connection:** Winding order as identity — the same shape, read
differently, shows or hides itself. Coming out is a winding order reversal.

**Open questions:**
- Why triangles and not quads? (Because triangles are always planar — 3 points define a plane)
- What does it mean that all visual complexity reduces to the simplest polygon?
- Is the normal vector an identity? It points outward — toward the viewer or away.

---

## Grid — The Commitment to Discretize

**Lens:** Discretization — *What resolution reveals? What hides?*

A grid is an **ontological act** — it takes continuous space and cuts it
into cells. What was fluid becomes countable. Every cell gets an address.

But *which* grid?
- **Square**: Manhattan distance, 4 neighbors. Roads, spreadsheets, pixels.
- **Hexagonal**: 6 equidistant neighbors. Bees, game boards, organic tiling.
- **Triangular**: densest packing. Crystallography.
- **Irregular mesh**: adapts to content. Finite elements, terrain LOD.

Ada's 3-layer grid (structure / utilities / interactables) is itself an
ontological claim: **space has geometry, function, and meaning** — and
they're separable layers on the same coordinates.

The grid teaches: **how you divide space determines what you can say about
it.** Discretization is not neutral. The resolution you choose hides
everything below it.

**QFEP connection:** The grid is governance. Who decides the cell size
decides what counts. Ada's 3-layer separation is a political architecture.

**Open questions:**
- What is lost between the grid lines?
- Is a pixel a point or an area?
- Does the grid create the space, or does the space create the grid?
- What would a queer grid look like? (Non-uniform? Adaptive? Self-modifying?)

---

## Vectors — The Duality of Meaning

**Lens:** Interpretation — *Same data, different meaning*

Same numbers: (120, 80). But is it:
- A **position**: "I am here"
- A **direction**: "I am going this way"
- A **force**: "I am being pushed"
- A **color**: RGB — "I look like this"

The vector teaches: **data has no inherent meaning. Meaning comes from
interpretation.** The same numbers, in different contexts, are location,
velocity, force, color, sound.

- **Dot product** measures alignment: are we facing the same way?
- **Cross product** measures perpendicularity: what axis don't we share?
- **Normalization** strips magnitude: pure direction, no intensity

These are geometric operations, but they're also questions about
relationship. How aligned are we? What do we not share?

**QFEP connection:** Profoundly queer — identity is not in the data,
it's in the reading. The same person, in different contexts, is different
things. The vector is the mathematical proof of contextual identity.

**Open questions:**
- If the same data means different things in different bases, is there a "true" meaning?
- The basis vectors are a choice. Changing basis changes everything but the vector itself.
- What is the "identity" of a vector — its components, or its invariant properties?

---

## Wave — The Circle Unrolled

**Lens:** Decomposition — *What is the hidden spectrum?*

A sine wave is not a function. It's a **circle seen from the side**.
Rotate the viewing angle and the wave becomes a circle. The wave IS
the circle, projected into time.

Fourier's theorem: **every signal is a sum of simple waves.** Sound,
light, heat, stock prices, brain activity — all decomposable into
frequencies. This means:
- Complexity is **composed**, not irreducible
- Any periodic phenomenon has a **spectrum** (hidden structure)
- The tangent goes to infinity at cos=0 — discontinuity is a boundary, not a bug

The wave teaches: **everything that repeats can be decomposed.** What
looks complex in time-domain may be simple in frequency-domain. The right
lens simplifies.

**QFEP connection:** Fourier decomposition is analysis — finding the
hidden components of identity. The "complex signal" of a person is a
sum of simpler frequencies. None of them alone is the whole.

**Open questions:**
- If every signal is a sum of sines, are sines "atoms" of periodicity?
- What does a non-periodic signal look like? (Noise — no decomposition)
- The uncertainty principle: precise in time = spread in frequency. You can't have both.
- Is identity a wave or a particle?

---

## Random Walk — Freedom and Fate

**Lens:** Dimensionality — *Does the space allow return or escape?*

A drunk man in 2D **always returns home** (Polya, 1921).
A drunk bird in 3D **probably never returns**.
The dimension of your space determines your destiny.

- Expected distance: **sqrt(N)**, not N — freedom grows slower than time
- Individual steps: **chaotic**. Ensemble behavior: **Gaussian** — order from chaos
- 100 walkers from one origin **diffuse like heat** — this IS how temperature works

The random walk teaches: **the dimensionality of your freedom determines
whether you can return to where you started.** In constrained space (1D, 2D),
you're bound to revisit. In open space (3D+), you escape.

**QFEP connection:** Liberation and constraint. Which spaces allow return?
Which allow escape? The closet is 1D — you always return. Coming out is
adding a dimension.

**Open questions:**
- Is free will a random walk? (Agency as biased step distribution)
- Levy flights: occasionally taking huge leaps. Is that how breakthroughs work?
- The boundary between recurrent (2D) and transient (3D) — what happens at the edge?
- Is society 2D or 3D? Do marginalized people random-walk in lower dimensions?

---

## Arrays — The Politics of Order

**Lens:** Order — *Who controls the index?*

An array is a **shelf**. A 2D array is a **bookcase**. A 3D array is a
**library**. But who decides what goes where?

- **Index** is power — whoever assigns the index controls retrieval
- **Iteration order** matters — row-major vs column-major affects speed,
  which affects access, which affects who gets served
- **Bounds** are borders — accessing outside crashes. The edge of the
  array is a hard wall.
- **Sorting** is hierarchy — the sort key determines what's "first"

The array teaches: **organization is not neutral.** How you order data
determines who can find what, how fast, and what's hidden at the bottom.
A spreadsheet is a 2D array. A database is arrays of arrays.
The index is the key to the kingdom.

**QFEP connection:** The array is canon formation — who gets indexed,
who gets iterated over first, who falls off the end of the bounds.

**Open questions:**
- What's at index 0? Is it special or arbitrary?
- Hash maps vs arrays: associative vs positional. Name vs number.
- What would a non-hierarchical data structure look like?
- Does the iteration order create a narrative? (First to last = beginning to end)

---

## Forces — The Invisible Hand

**Lens:** Invisibility — *What unseen pressures shape trajectories?*

F = ma. Three letters for every motion. But force is invisible — you only
see its effects (acceleration). You infer force from motion.

- **Gravity**: inverse-square, reaches everywhere, never stops. Background hum.
- **Springs**: F = -kx. Proportional to displacement. Pull away, it pulls back.
  Equilibrium is the rest state everything seeks.
- **Vector fields**: assign a force to every point. Particles follow like rivers.
  **The field is the territory.**

Forces teach: **the invisible shapes the visible.** You can't see gravity,
but you see orbits. The forces acting on a system are its hidden politics —
unseen pressures that determine trajectories.

**QFEP connection:** Systemic forces — racism, heteronormativity, capitalism —
are invisible like gravity. You only see their effects: trajectories bent,
orbits constrained. The vector field of society.

**Open questions:**
- Can you map social forces as vector fields?
- Equilibrium: is it peace or stasis?
- What is the spring constant of an institution? How much force does it take to displace?
- When does a perturbation become a phase transition?

---

## Coordinate System — The Frame of Reference

**Lens:** Perspective — *Whose zero? Whose axes?*

**Status:** Ontology pending — needs discussion

The coordinate system is not the space. It's a **lens placed on the space**.
The same point exists regardless of coordinates. But the coordinates
determine what's easy to say and what's hard.

**Open questions:**
- Right-hand vs left-hand rule — a convention, but conventions are power
- Y-up (Godot) vs Z-up (Blender) — same world, different stories
- What does it mean to change basis? Translation of worldview?

---

## Randomness — The Source of Novelty

**Lens:** Determinism vs Freedom — *Is anything truly new?*

**Status:** Ontology pending — needs discussion

Pseudorandom numbers are deterministic. Same seed = same universe.
True randomness may not exist at all (or may be quantum).

**Open questions:**
- If seeds are deterministic, is free will an illusion?
- Noise as texture: Perlin noise looks "natural" — why?
- Gaussian distribution: the bell curve of normal. What is "normal"?

---

## Procedural Generation — Creation from Rules

**Lens:** Emergence — *Can a handful of rules create a world?*

**Status:** Ontology pending — needs discussion

L-systems: `F→FF+[+F-F-F]-[-F+F+F]` grows a tree. BSP splits make dungeons.
Noise makes terrain. A few rules, iterated, produce infinite complexity.

**Open questions:**
- Is the universe procedurally generated? (Physics as rules, reality as output)
- Authorship: who is the creator — the rule writer or the rule?
- What can procedural generation NOT make? (Meaning? Intent? Love?)

---

## The Filter Screen — Projection as Primitive

**Lens:** Dimensionality collapse — *What is lost when 3D becomes 2D?*

**Status:** Ontology pending — needs discussion

Every screen you've ever looked at performs 3D→2D projection. Your eye
does it. A camera does it. The Filter Screen makes this operation visible
as an object you can walk around in VR.

**Open questions:**
- What information is destroyed in projection? (Depth)
- Can you reconstruct the 3D from the 2D? (Only with multiple views — stereoscopy)
- Is understanding itself a projection? (Reducing complexity to a viewable surface)

---

## The Science Screen — Abstraction as Mirror

**Lens:** Representation — *How does a grid of pixels represent a world?*

**Status:** Ontology pending — needs discussion

The Science Screen reads a 3D artifact's grid data and renders it as
colored pixels. It's not projection (that's the Filter Screen). It's
**abstraction** — reducing a complex 3D object to its data structure.

**Open questions:**
- The map is not the territory. But what if the map IS all we have?
- CRT scanlines as aesthetic: why does abstraction look "scientific"?
- Split consciousness: experiencing the 3D with your body while reading the 2D with your eyes

---

## Summary Table

| Primitive | Lens | Core Question |
|-----------|------|---------------|
| Point | Location | What system am I in? |
| Line | Connection + Measure | What defines "between"? What is the unit? |
| Triangle | Surface | What's the minimum enclosure? |
| Grid | Discretization | What resolution reveals? What hides? |
| Vectors | Interpretation | Same data — what does it mean? |
| Wave | Decomposition | What's the hidden spectrum? |
| Random Walk | Dimensionality | Return or escape? |
| Arrays | Order | Who controls the index? |
| Forces | Invisibility | What unseen pressures shape trajectories? |
| Coordinate System | Perspective | Whose zero? Whose axes? |
| Randomness | Determinism | Is anything truly new? |
| Procedural Gen | Emergence | Can rules create worlds? |
| Filter Screen | Projection | What is lost in flattening? |
| Science Screen | Abstraction | How do pixels represent reality? |

---

*This document is the ontological foundation for every primitive editor
in Ada Research. Each entry should inform the 2D web editor design, the
VR infoboard content, and the Science Screen / Filter Screen presentation.
The primitive is not the visualization — the primitive is the question.*
