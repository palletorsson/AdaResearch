# Iter 4 — hole_with_cones → WALL

**Verdict:** WALL.

The artifact's whole point IS Boolean subtraction. From its own `@identity`:

> *truth: a hole is not the absence of matter — it is a boundary condition imposed on surrounding matter*

The ground plane has a circular hole, which is a CSG difference operation (PlaneMesh minus a CylinderMesh shape). Godot's built-in primitives don't expose CSG; you'd need a `CSGMesh3D` node tree (which is a different mode entirely — runtime CSG in the engine, not a static mesh).

The 3 traffic cones around the hole would each promote cleanly as `CylinderMesh(top_radius=small, bottom_radius=larger)` — that part works. But promoting only the cones loses the artifact's defining feature.

**Filed as WALL.** This artifact's identity is a CSG operation. Without engine-level CSG support in compose mode, the genome can't reach it. The cones-only promotion is a 70% solution that drops the most pedagogically important 30%.
