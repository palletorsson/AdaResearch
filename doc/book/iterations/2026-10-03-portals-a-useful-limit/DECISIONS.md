# Portals: how close is useful?

3 October 2026. One tutorial pilot, continuing Primitives Ignorance.

This hall is a reflective application of existing skills. The selected making task is the planar polygon comparison already placed beside combine_portals. It reuses distance, an ordered list, neighbour traversal, accumulation and a function with a returned result. The learner adds the closing edge and compares boundary lengths under a stated absolute tolerance.

CircleSamples is supplied, with source. It accepts 3..256 divisions and a positive radius, returning distinct ordered points in XY without repeating the first point. The trigonometric construction is available to inspect, but not claimed as taught. PolygonDisplay creates the segment drawing, the fixed 256-segment grey guide and readouts; it makes a copy when closing the drawing and does not mutate the learner's data.

The numerical circle reference is TAU × radius, not the length of the grey guide. The shortfall compares total boundary lengths, not the visible normal distance between chord and arc. 48 is the first adequate member of the four chosen trials at tolerance 0.01 m, not a claimed globally minimal count. Tightening tolerance to 0.001 m changes the decision with identical positions. These counts do not test floating-point saturation, and a finite display cannot establish a claim about arbitrary precision.

The old tutorial ranged from polygon approximation through halving saturation, torus topology and a portal-velocity transform. The placed rings do not implement teleportation. Preserve that earlier text exactly in tutorial-previous.md as an archive, not current museum instructions. The more accurate technical.md, final.md and live map were not changed by this pass. We have not removed their richer encounters or asked the critical text to become a tutorial.

The student study contains no new interaction system: change the settings, run again and approach the diagram. Geometry is created in code with direct references. The prepared scene supplies the room and places the study. The script also runs on a bare Node3D. No saved Trace is read or changed, and no collider is added across the polygon.

35 native checks passed from a cold-extracted starter in Godot 4.6. They cover the actual printed settings, the independent chord formula, a separate 3–4–5 triangle that catches a missing closing edge, non-mutating calculation, translation and scale, unchanged geometry under a tolerance edit, bounded redraw, drawing/measurement agreement and standalone construction. A harness-only script-replacement leak was fixed by freeing the unused default display before installing the edited script. The final cold-import and native error logs are empty. Native screenshots were inspected. No physical headset, performance or beginner-comprehension claim is made.

Next after author review: Primitives_Melencolia. It can compose known forms and let the critical encounter carry the transition, rather than introduce another unrelated code system. Coordinates still needs its earlier shared-starter writing pass. Numeric taxonomy locations remain provisional.
