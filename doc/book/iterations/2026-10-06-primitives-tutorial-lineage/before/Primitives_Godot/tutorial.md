# Primitives Godot — the sphere in your hand

**Learning elements — selected focus**

*Teaching plan, 6 October 2026. The complete runnable lesson is still to be written and tested.*

- Extending the existing PointBody class
- SphereMesh rings and radial segments
- Held and released state
- Elapsed time and integer steps
- Bounded resource properties
- Independent mesh resources
- Visible mesh and collision shape

Continue with the sphere made in Point One, made pickable in Coordinates and packaged as `PointBody` in Lines. Hold it: its rings and radial segments gradually decrease, making its construction visible. Release it to pause; pick it up again to continue. Keep its size, material and spherical collider unchanged while its mesh becomes coarse. Compare changing the rings alone with changing the radial segments alone. Carry a familiar body whose construction you can now alter through an interaction, then use that distinction between resolution and shape in Columns.

## What the full lesson must supply

- Carry the [tested PointBody construction](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/lines/point_body.gd). In this later version, retain a named reference to its own `SphereMesh` so the new behaviour can change it. Each instance must own its mesh. Do not rewrite the earlier tested lesson.
- Use the existing pickup behaviour. Accumulate elapsed held time and change integer counts at a stated cadence; do not subtract once per rendered frame. Pause on release and provide an explicit reset to the starting counts.
- Stop at **4 radial segments and 1 ring**. Godot 4.6 clamps radial segments below four and rejects rings below one; zero is not a valid endpoint. See the [engine setters](https://github.com/godotengine/godot/blob/4.6-stable/scene/resources/3d/primitive_meshes.cpp#L1984).
- Keep the analytic sphere collider fixed and explain that the changing surface does not change contact geometry. A minimal readout must display the actual mesh properties; if used, create and initialize it in the printed code.
- Print and explain the complete small continuation and its declared helpers. Test hold, release, re-grab, reset, minimum counts, unchanged dimensions/collider, independent instances and equal held durations under different frame steps. Source inspection alone does not pass these tests.

The existing [mesh library](../../artifacts/ignorance_gallery/primitive_mesh_library.gd) and [seven-form choir](../../artifacts/seven_words_choir/seven_words_choir.gd) remain the wider encounter. This plan does not add controls to those installed specimens. The learner study host must be bound explicitly before implementation.

**Short AI brief:** CARRY PointBody. ADD owned SphereMesh reference + held-time resolution steps. HOLD reduces rings/segments; RELEASE pauses; RE-GRAB continues; RESET restores. MIN rings=1, radial_segments=4. KEEP radius/height/material/collider. TEST exact printed continuation. TRANSFER: isolate either setting. NEXT Columns; later sphere becomes catalyst/weapon through tested abilities.

[Read and edit the execution plan](http://localhost:3003/tutorial-plan?map=Primitives_Godot). The [object lineage](../../../doc/book/course/execution-plan/README.md#the-sphere-becomes-an-instrument) records the planned returns. Continue to [Columns](../Primitives_Columns/summary.md).
