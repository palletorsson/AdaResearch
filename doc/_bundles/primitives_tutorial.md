<<<ADA_BUNDLE>>>
sequence: primitives
file: tutorial.md
maps: 12
skipped_passing: 0
created: 2026-04-24T08:15:30
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Point_One>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The first instantiated point — position without extension, existence before duration — and the infrastructure (coordinate systems, render loops, void) that must precede it. A point is not geometric but computational: a Vector3 bound to a frame that was already running when the learner arrived. | Sequence role: Opens the Primitives sequence and the whole curriculum. No predecessor. Establishes the zero-to-one act: the system was already live, the point is the learner's first mark within it. Sets the vocabulary that every later Primitives map extends, from Point_Lines through the meshes a | [... truncated ...]
# BLURB: Before the point, infrastructure. The origin is not a point but a prerequisite — coordinate systems, render loops, the void made addressable. Point_One is the first mark: position without extension, existence without dur…
[empty — file does not yet exist]

<<<MAP: Point_Line>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The line as captured trace — relation, direction, and the possibility of measurement emerging from the act of connecting two positions. Two points become a line only when a rule names them as endpoints and a renderer draws the segment between them. | Sequence role: Third map in Primitives, following Point_One (position) and Point_Lines (multiplicity). Formalises the link between discrete positions as directed geometry, and prepares Point_Triangle by introducing the binary relation that closure will later extend to three. | Technical angle: Line rendering between two Vector3 endpoints, dir | [... truncated ...]
# BLURB: Captures trace into a line. Here relational history becomes discipline: the trace is formalized into directed relation. This map stages the first formal link between discrete moments, converting duration into geometry. L…
[empty — file does not yet exist]

<<<MAP: Point_Lines>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Multiplication of lines into relational systems — parallels produce direction, crossings produce intersection, grids produce metric frameworks. Discrete relations begin behaving as networks. | Sequence role: Second map. Extends Point_One's single mark into connection and multiplicity. The point gains companions; relation replaces isolation. Prepares Point_Trace by establishing the static scaffolding that trace will temporalize. | Technical angle: Line drawing between two Vector3 positions, parametric line equations, grid construction from parallel/perpendicular sets, perspective projectio | [... truncated ...]
# BLURB: A line connects two points. Two lines cross — the X marks intersection. Parallel lines organize direction. Then: perspective, scale, the grid. Lines become measure. Measure becomes pleasure — the satisfaction of knowing …
[empty — file does not yet exist]

<<<MAP: Point_Trace>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The trace introduces duration and embodied residue — geometry as lived process. Movement accumulates as record; gesture, hesitation, error, and return become geometric data. | Sequence role: Third map. Breaks Point_Lines' static network by adding time. Lines were connections; traces are histories. The hand enters. Prepares Point_Line_Grid by generating the continuous movement that the grid will later quantize. | Technical angle: Recording position over time (frame-by-frame trail), storing Vector3 arrays as path data, rendering accumulated points/lines as trails, delta-time and update loop | [... truncated ...]
# BLURB: Now: duration. The trace records what the line forgets — your hand moved through space, hesitated, curved, returned. Time accumulates as visible residue. The line will compress this to two points. The trace resists.  Pic…
[empty — file does not yet exist]

<<<MAP: Point_Line_Grid>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The grid quantises continuous movement into discrete positions. Traces snap to cells; memory becomes finite, sampled, measured against a fixed frame. Structure meets recording, and the learner's fluid path is disciplined into a sequence of addresses. | Sequence role: Fourth map in Primitives. Synthesises Point_Lines' grid and Point_Trace's duration. The fluid trace is disciplined by spatial structure so that deviation becomes measurable rather than merely present. Prepares Point_Triangle by establishing the coordinate politics that closure will formalise. | Technical angle: Grid snapping  | [... truncated ...]
# BLURB: The grid quantizes. Continuous movement snaps to discrete positions. Your trace, once fluid, becomes a sequence of cells. This is how space becomes computable — and how the body's path becomes data.  `grid_lines` provide…
[empty — file does not yet exist]

<<<MAP: Point_Triangle>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Three points close a boundary for the first time — inside and outside emerge. The triangle is the minimal surface, the GPU's atom, the first figure that produces area and orientation (front/back). | Sequence role: Fifth map. Shifts from open networks and traces to closure. Points and lines were relational but unbounded; the triangle introduces containment. Prepares Point_Triangle_Context by establishing the surface that rigidity and measurement will formalize; follows Point_Line_Grid. | Technical angle: Triangle construction from three vertices, winding order and face normals, front-face  | [... truncated ...]
# BLURB: Three points close a boundary. For the first time: inside and outside. The triangle is the GPU's atom — all surfaces decompose here. Enclosure begins. Territory begins.  The `triangle_line_puzzle` lets you construct the …
[empty — file does not yet exist]

<<<MAP: Point_Triangle_Context>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The triangle as first rigid relational structure — three points mutually constrained produce invariant measurements. Where geometry becomes stable, the Pythagorean theorem first resides, and quads emerge by decomposition. | Sequence role: Sixth map. Deepens Point_Triangle's closure into structural rigidity. The triangle is no longer just a boundary but a constraint system. Introduces quad as paired triangles, bridging toward polyhedra. Prepares Primitives_Polythedra by establishing the rigid faces that will fold into volume. | Technical angle: Triangle rigidity vs quad flexibility, Pythag | [... truncated ...]
# BLURB: Three points close a boundary, and now: rigidity. The triangle does not flex without breaking. Three distances mutually constrain three angles; move one vertex, the others resist. This is where measurement stabilizes, wh…
[empty — file does not yet exist]

<<<MAP: Primitives_Polythedra>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The trihedron — three triangular faces meeting at a single vertex — as the elementary expression of volume beginning to form. Not a closed solid but a spatial junction, a corner of space. | Sequence role: Seventh map. Extends Point_Triangle_Context's rigid faces into three dimensions. Faces fold off the plane to meet at a vertex; volume is implied but not yet enclosed. Prepares Point_Animatedcube by establishing the spatial junction that full enclosure will complete. | Technical angle: Trihedron construction from three face-sharing triangles, vertex normals and face adjacency, tetrahedron | [... truncated ...]
# BLURB: A trihedron is a geometric configuration where three triangular faces meet at a single vertex, forming a corner of space. It is not a closed solid by itself, but a spatial junction - an elementary expression of volume be…
[empty — file does not yet exist]

<<<MAP: Point_Animatedcube>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The cube as manipulable quad-based enclosure — full volumetric closure achieved, but through flexible quads rather than rigid triangles. Drag corners to deform; agency operates within constraint. | Sequence role: Eighth map. Completes the closure arc from triangle to trihedron to full enclosure. The cube is over-determined (quads flex where triangles would not), introducing deformation as interactive possibility. Prepares Primitives_Ignorance by establishing mastery that the next map will deliberately unsettle; follows Primitives_Polythedra. | Technical angle: Cube construction from six q | [... truncated ...]
# BLURB: A manipulable quad-based object where you can drag cube corners. This map transitions from rigid relational closure to over-stabilization and manipulation. Quads relax the rigidity of triangles and introduce interactive …
[empty — file does not yet exist]

<<<MAP: Primitives_Ignorance>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Deliberate epistemic reset — "primitive" names not a lowest form but a stage of unknowing. Point, line, shape re-encountered as constructs rather than givens. Mastery is undermined; assumptions and blind spots surface. | Sequence role: Ninth map. Disrupts the cumulative confidence built across maps 1-8. After building from point to enclosed volume, the learner confronts what was assumed. The zoo of forms (platonic solids, capsules, tori, L-shapes) overwhelms tidy progression. Prepares Primitives_Portals by clearing ground for the infinite; follows Point_Animatedcube. | Technical angle: Pr | [... truncated ...]
# BLURB: Ignorance is not the absence of knowledge but a structural limit. Every geometric, computational, or philosophical system is bounded by the capacities that produce it. What cannot be formalized does not vanish; it persis…
[empty — file does not yet exist]

<<<MAP: Primitives_Portals>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Toroidal portal sequence where increasing rings approach pi — continuity staged as asymptotic relation rather than arrival. Discrete steps approximate the circle without reaching it. The tension between countable and infinite. | Sequence role: Tenth map. After Ignorance's epistemic reset, Portals confronts the infinite directly. The torus is the first topologically non-trivial form in the sequence — a surface with a hole. Discrete rings chase a limit they cannot reach. Prepares Primitives_Melencolia by establishing the incompleteness that melancholy will inhabit; follows Primitives_Igno | [... truncated ...]
# BLURB: A toroidal portal sequence guided by increasing rings approaching π, staging continuity as asymptotic relation rather than arrival. This map makes approximation and limit visible: discrete rings approximate the circle wi…
[empty — file does not yet exist]

<<<MAP: Primitives_Melencolia>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The limit point of geometric aspiration — geometry has mastered shapes and measures, yet meaning, orientation, and closure remain unsettled. Melancholy of finitude at the end of the Primitives sequence. | Sequence role: Eleventh and final map. Closes the Primitives sequence not with triumph but with reflective incompleteness. Everything buildable has been built; the question shifts from "how" to "so what." Leads outward to the Transformation sequence, where static primitives will finally move; follows Primitives_Portals. | Technical angle: Scene composition combining multiple primitive ty | [... truncated ...]
# BLURB: Inspired by the Herzog August Bibliothek and Melencolia I, this scene embodies the limit point of geometric aspiration and existential constraint. Geometry has mastered shapes and measures, yet meaning, orientation, and …
[empty — file does not yet exist]
