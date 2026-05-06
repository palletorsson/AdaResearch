# Science Desk -- Laboratory Workstation

A procedural laboratory workstation built entirely from CSG primitives. The artifact generates a complete science desk with cabinets, countertop, sink with faucet, beakers with colored liquids, a reagent bottle, and a microscope.

## Concept Taught

**Constructive Solid Geometry (CSG) for rapid prototyping.** CSG is a modeling technique where complex shapes are created through boolean operations (union, subtraction, intersection) on primitive solids. This artifact demonstrates how a detailed, functional lab environment can be built entirely from CSG boxes, cylinders, and spheres -- with the sink basin carved out using CSG subtraction. The approach teaches how boolean geometry operations work and when they are useful for quick environmental prototyping versus mesh-based modeling.

## How It Works

1. A **desk base** is created as a large CSG box with four cylindrical legs positioned at the corners.
2. **Cabinets** are generated side by side beneath the countertop, alternating between drawer-style (with two pull handles) and door-style (with a single side handle) using CSG subtraction for visual detail.
3. A **countertop** surface sits on top with a backsplash along the rear edge.
4. A **sink** is created by placing a CSG box and then subtracting a smaller basin box from it (CSG `OPERATION_SUBTRACTION`). A multi-part faucet is assembled from cylinders (base, neck, spout).
5. **Beakers** are built from transparent cylinders with inner liquid cylinders at varying fill levels and colors (clear, green, amber).
6. A **reagent bottle** is assembled from a body cylinder, narrow neck, and dark cap.
7. A **microscope** is constructed from CSG boxes (base, arm, head) and a cylinder eyepiece.
8. An omni light illuminates the scene from above.

## Features

- Complete lab environment from CSG primitives only -- no imported meshes
- CSG boolean subtraction for sink basin carving
- Transparent glass materials for beakers and bottles
- Three colored liquid fills (clear, green, amber)
- Alternating cabinet styles: drawers with pull handles, doors with side handles
- Multi-part microscope assembly (base, arm, head, eyepiece)
- Multi-segment faucet (base, neck, spout)
- Cool white overhead lighting

## Files

- `science_desk.gd` -- Procedural lab desk generator using CSG primitives
- `science_desk.tscn` -- Scene file
