# The face operation behind the family

Source: `commons/artifacts/form_grammar_family/form_grammar_family.gd`. Reuses production `MeshData.create_cube`, `MeshSelector`, `InsetFaceOp` and `ExtrudeFaceOp`; no substitute geometry algorithm.

The cube has half extent 0.5 m: one metre across, with 12 triangular faces. Select two upward triangles (5° normal tolerance) or all twelve initial faces, tagging them growing. Inset reads only that tag, returns it on the smaller inner triangle and marks the surrounding ring shoulder. Extrusion reads the same tag, returns it only on the raised cap and marks the sides wall. Thus later rounds act only on the descendant tips, not every upward border.

Inset is a fraction towards each face centroid, 0.28 or 0.08. Extrusion distance is 0.4 m with scale 1 and minimum area 0.001. Three rounds are bounded and deterministic. Colours expose construction roles. Each specimen retains a 1:1 metre scale; only its vertical placement changes to seat its lowest vertex 0.01 m above a 0.55 m plinth.

The exact rendered triangle mesh supplies static collision. The hall floor supplies continuous walking support. Open `commons/artifacts/form_grammar_family/study.tscn` for the F6 desktop preview: WASD, mouse, Escape. The preview reconstructs the map’s floor and boundary independently of the museum loader. Native evidence and limits are in `doc/book/iterations/2026-09-24-form-grammar-spine/`.
