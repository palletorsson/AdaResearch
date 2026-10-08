# The face operation behind the family

Source: `commons/artifacts/form_grammar_family/form_grammar_family.gd`. Reuses production `MeshData.create_cube`, `MeshSelector`, `InsetFaceOp` and `ExtrudeFaceOp`; no substitute geometry algorithm.

The cube has half extent 0.5 m: one metre across, with 12 triangular faces. Select two upward triangles (5° normal tolerance) or all twelve initial faces, tagging them growing. Inset reads only that tag, returns it on the smaller inner triangle and marks the surrounding ring shoulder. Extrusion reads the same tag, returns it only on the raised cap and marks the sides wall. Thus later rounds act only on the descendant tips, not every upward border.

Inset is a fraction towards each face centroid, 0.28 or 0.08. Extrusion distance is 0.4 m with scale 1 and minimum area 0.001. Three rounds are bounded and deterministic. Colours expose construction roles. Each specimen retains a 1:1 metre scale; only its vertical placement changes to seat its lowest vertex 0.01 m above a 0.55 m plinth.

The exact rendered triangle mesh supplies static collision. The hall floor supplies continuous walking support. Open `commons/artifacts/form_grammar_family/study.tscn` for the F6 desktop preview: WASD, mouse, Escape. The preview reconstructs the map’s floor and boundary independently of the museum loader. Native evidence and limits are in `doc/book/iterations/2026-09-24-form-grammar-spine/`.

## A new operation and the same surface at another scale

`form_grammar_canopy.gd` retains face 8 from MeshData.create_cube(0.5), moving that triangle's centroid to the origin. PetalSplayOp is applied once to this single face, using count 6, length 1.25, width 0.52, curl 0.38, tilt 0.45, segments 16 and twist 0. The source face remains. Each strip is sampled along its length; its width tapers with sine, while a quadratic curl argument changes the direction. No randomness or noise participates.

The operation adds open strips. Its zero-width endpoints can produce degenerate triangle records; MeshData.to_array_mesh omits degenerate faces. Generated-face count and rendered-triangle count are therefore logged separately. No thickness or manifold closure is inferred from the two-sided material. Concave mesh collision explicitly enables backface collision so each open strip is present to rays from above and below.

One generated MeshData supplies both the small and enlarged version. A parent transform multiplies all three axes by 4, including the same support geometry: surface origin 0.9 m becomes 3.6 m. The supports are additional cylinders; they are not products of PetalSplayOp. Low non-colliding plaques annotate the specimens. The museum floor provides walking support.

The expanded F6 preview reads dimensions, wall height and both artifact placements from the production map. Its 66 native checks and five images are recorded in `doc/book/iterations/2026-09-24-form-grammar-canopy/`. Full loader, tracked-headset, Quest and learner acceptance are separate.
