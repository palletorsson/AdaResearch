# Point One — Summary

## The Minimum Viable Existence

A point has no width, no height, no depth. Euclid called it "that which has no part." Two thousand years later, the definition holds — but the implementation betrays it. In code, a point is `Vector3(x, y, z)`: three floating-point numbers bound to a coordinate system, stored in memory, rendered through a pipeline. The point is not geometric. It is computational. It exists because something allocated it.

Point_One isolates this act of allocation. The map asks the simplest possible question in 3D space: what does it mean for a single thing to *be here*? Not two things, not a line between them, not a surface or a volume. One point. Position without extension. The atom of space — except atoms have radius, have mass, have parts. A point has none of these. It is pure address.

## Infrastructure Precedes Entity

The map opens inside a dark sphere — an ambient enclosure pulsing with slow purple emission, rotating at the edge of perception. This is not decoration. The sphere establishes that environment exists before the point does. Render loops are cycling. The coordinate system is live. Light is already propagating. The void is not empty; it is *addressable*. The point arrives into a world that was already running.

This is the first lesson, delivered spatially rather than verbally: individuation requires infrastructure. A point cannot place itself. It needs axes, it needs a number line on each axis, it needs a system that can receive the instruction "put something at (1, 3, 0)" and execute it. The origin — `(0, 0, 0)` — is not a point but a convention. A decision about where counting starts. The grid is not the territory; it is the condition of possibility for territory.

The 7×10 grid layout makes this concrete. A continuous platform spans the western columns — stable ground, the infrastructure you stand on. At position `(4, 0)`, a single isolated cube floats apart from the platform, holding a static point. Fixed. Ungrabbable. A reference mark that says: *here is a location, and it is occupied*. The gap between platform and cube is pedagogical. It spatializes the difference between the system (grid, platform, ground) and the entity (point, mark, instance).

## Two Points, Two Ontologies

The map places two points in dialogue. The `static_point` at `(4, 0)` is fixed — a fact about space, immovable, declarative. It exists the way a coordinate exists: by fiat. The `interactive_point_origin` at `(1, 3)` is grabbable. It can be moved, repositioned, dragged through the coordinate field. Same data type. Same `Vector3`. Radically different ontological status.

The fixed point demonstrates that position can be assigned. The interactive point demonstrates that position can be *changed* — and that changing position does not change identity. Move the point from `(1, 3)` to `(5, 7)` and it is still the same point. Its address changed; it did not. This is the paradox of computational individuation: the point is not its coordinates. The coordinates are a description of where the point currently is. The point is whatever persists when the numbers update.

The annotation `la:point` marks the interactive point's home location. An annotation is metadata about a position — a label applied to a cell in the grid. The point sits on its annotation the way a name sits on a thing. Remove the name and the thing remains. Remove the thing and the name points at nothing. Point_One lets you test this relationship with your hands.

## The Script Runner and the Code Behind the Curtain

At `(0, 1)`, a script runner executes a live code demonstration. It shows `Vector3` as point — the raw syntax, the constructor call, the three numbers that conjure location from void. This is where the map breaks the fourth wall. The point you see floating in space is not a geometric primitive. It is a function call. It is an instruction to a graphics pipeline that converts numerical triples into pixel clusters on a display surface.

The script runner reveals that between the mathematical idea of a point (dimensionless, ideal, Euclidean) and the rendered point (a lit pixel, a small sphere, a visible mark) lies an entire apparatus of translation. The GPU does not draw points. It draws fragments. The point is a convenient fiction maintained by layers of abstraction — from `Vector3` to vertex buffer to rasterizer to framebuffer to photon.

## F Without λ

In the QFEP framework, Point_One is pure F — free energy, order, prediction, structure. No entropy has entered the system. No randomness, no variation, no stochastic wobble. The point is where it is because it was placed there. The grid is regular. The coordinate system is Cartesian. Everything is deterministic, stable, and fully specified.

This matters because later maps will introduce λ — the entropy drive that loosens structure into possibility. Noise will blur edges. Probability will replace certainty. Agents will drift. But none of that can land without this foundation. You cannot appreciate disorder until you have experienced pure order. You cannot feel the edge of chaos until you know what the interior of stability feels like. Point_One is the interior. The F term at rest. The system before perturbation.

The sequence truth states it plainly: "A point is position without extension. Everything is built from nothing." The nothing here is not absence. It is the zero-dimensional seed — the minimum information required to say *something is somewhere*. Three numbers. One location. No size.

## What Comes Next

Point_One is map 1 of 11 in the Primitives sequence. The next map, Point_Lines, multiplies lines into context — parallels, crossings, grids. Two points will define a line. Three points will define a plane. The dimensionless will acquire dimension. But that escalation only works because this map established what a single point is and what it costs.

The floating text reads: *that which has no part*. Euclid's definition. Still true. Still incomplete. A point has no geometric part — but it has computational parts: an x, a y, a z, a memory address, a render call, a place in a scene tree. The definition describes what a point *lacks*. The map demonstrates what a point *requires*. Between the lack and the requirement — in that gap — individuation happens. Something that has no part becomes something that has a place. The first mark in an empty coordinate system. Not born. Instantiated.