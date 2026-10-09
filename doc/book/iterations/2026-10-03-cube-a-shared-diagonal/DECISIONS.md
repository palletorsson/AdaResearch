# Cube: follow the shared diagonal

Continue one lesson from Polyhedra. Its position list and face list are already enough to build the cube; this pass gives them eight explicit positions and twelve triangle triples. A cube requires a chosen arrangement, so no saved gesture is silently converted into a regular cube. Trace's original record remains untouched and available to other studies.

The numbering and connections match the museum builder, with a vertical placement offset and the front pair listed first. `[4,5,7]` and `[5,6,7]` share diagonal 5–7. Moving vertex 6 out of the original plane changes the second front patch while leaving the first unchanged. Other incident top/right patches move too. The learner can make the edit with a handle or set a 0.35-metre startup displacement for a repeatable comparison.

The alternate pair `[4,5,6]`, `[4,6,7]` changes only the triangulation and the guide endpoints. Both pairs cover the initial flat square. With the same displaced four corners, the two diagonals produce different piecewise planar surfaces. This is the new investigation; no new mesh factory or required animation state machine is introduced.

Each patch has a separate ImmediateMesh surface so the second front patch can use a distinct supplied pink material. The others are off-white, the boundary edges dark, and the shared diagonal amber. Materials are two-sided and unshaded, reusing the prior separation between visibility and geometry. The numbered labels stay readable through faces. These are declared display aids; changing or hiding the guide does not alter the mesh.

The original museum tutorial remains as tutorial-museum.md, including replay, restoration, nets, prefabs and architecture. The live hall, final.md, intent and critical writing are unchanged. A tutorial can select one useful construction without consuming every work in a room.

The next tutorial can examine the engine's generated primitives and a small rule that produces vertex positions. Coordinates still needs its earlier starter-based pass. The local teaching contract does not promote the older numeric taxonomy.
