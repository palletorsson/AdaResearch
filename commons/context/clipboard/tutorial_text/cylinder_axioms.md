**The Cylinder**
Circular Extrusion

The cylinder as a hybrid of planar and curved surfaces

---

## Two Circles, One Curve
AXIOM 1: Two parallel circles + curved surface.
Code

```
var cyl = CylinderMesh.new()
cyl.top_radius = 0.5
cyl.bottom_radius = 0.5
cyl.height = 2.0
```

Extruded circle along axis
Concepts: circles, extrusion, axis, curved surface

---

## Caps and Sides
AXIOM 2: Cylinder = 2 caps + 1 side surface.
Code

```
cyl.top_radius = 0.5
cyl.bottom_radius = 0.3  # Cone
cyl.cap_top = true
cyl.cap_bottom = true
```

Varying radii creates cones Caps can be toggled
Concepts: caps, side surface, cone, radii

---

## Radial Segments
AXIOM 3: Circular sections tessellate to triangles.
Code

```
cyl.radial_segments = 32
cyl.rings = 8

More segments = smoother circles
```

Rings add horizontal subdivisions
Concepts: radial segments, rings, tessellation, smoothness