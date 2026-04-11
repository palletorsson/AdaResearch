---
title: "Triangle — The Minimum Enclosure"
primitive: triangle
sequence: primitives
phase: F_order
lens: Surface
question: "What is the smallest thing that contains area?"
insight: "The minimum surface. Every 3D model reduces to this. Winding order determines visibility."
qfep: "Winding order as identity — the same shape, read differently, shows or hides itself. Coming out is a winding order reversal."
web_editor: /primitives/triangle
tags: [geometry, rendering, normals, winding]
connections: [point, line, quad]
---

# Triangle — The Minimum Enclosure

**Lens:** Surface — *What is the smallest thing that contains area?*

## Discussion

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

## QFEP Connection

Winding order as identity — the same shape, read
differently, shows or hides itself. Coming out is a winding order reversal.

## Open Questions

- Why triangles and not quads? (Because triangles are always planar — 3 points define a plane)
- What does it mean that all visual complexity reduces to the simplest polygon?
- Is the normal vector an identity? It points outward — toward the viewer or away.

## Connections

- **Point** — three points define the triangle's vertices
- **Line** — three edges form the boundary
- **Quad** — two triangles compose the next polygon up
