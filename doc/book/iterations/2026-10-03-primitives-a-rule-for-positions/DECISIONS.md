# Primitives Ignorance: a rule for positions

3 October 2026. One tutorial pilot, continuing Cube.

The curriculum already proposes an octahedron generator as the first explicit parameter-and-return function. This pass makes that proposal executable. Three signed axis pairs generate six positions. Eight supplied face rows connect them. The function does not discover topology or prove that later edits preserve a regular solid.

The new teaching boundary is small: a positive radius enters; a fresh Array[Vector3] leaves. The function has no rendering side effects. _ready calls it once; _process updates faces from the handles. The numbered handles let a learner break the regularity without being snapped back by the generating rule. All lesson nodes are created in code, with direct references.

The short SphereMesh return follows Point One. Its radius and full height stay fixed while radial_segments and rings are edited separately. MeshEdges is a named, supplied reader of triangle geometry; its implementation remains outside the lesson's conceptual load. It exposes the actual non-degenerate source edges and merges duplicate guide strokes at seams and poles. It creates no alternative sphere or collision. The flat material isolates geometry from smooth lighting.

This is a selected path through a rich hall, not a replacement account of every artifact. The previous tutorial has been retained exactly as tutorial-museum.md. The critical text, map placements, capsule, courtyard and PrimitiveMesh library were not edited in this pass.

The learner keeps the same starter and face-list renderer. This lesson generates fresh geometry rather than pretending an arbitrary saved trace is an octahedron. No Trace file is touched. Imported XR Tools supplies pickup; no dollar-sign or get_node references are used in the lesson scripts.

Verification: 33 native checks passed after cold import of the ZIP in an independent temporary folder. These include the actual printed radius and sphere-setting edits, closed regular geometry, persistent deformation, guide/source agreement, desktop mouse and synthetic XR pickup, release and a fresh-instance reset. Import and native error logs are empty. Screenshots were inspected from the running student room. Physical headset use, Quest performance and beginner comprehension remain untested.

Local Godot 4.6 reference checked: SphereMesh radius, height, radial_segments and rings. No inferred triangle-count formula is taught. The numeric subject taxonomy remains a proposal; Coordinates still needs its earlier shared-starter writing pass. Next after author review: Primitives_Portals, finite approximation and its limits.
