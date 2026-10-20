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


## Reconstructed tutorial — 9 October 2026

Three complete files: faces.gd, family.gd and the byte-unchanged Living point_body.gd. The builder exposes the production cube's eight positions/twelve index triples, selects seed indices, then propagates a growing tag. Inset replaces each selected triangle with a smaller triangle and six shoulder triangles; extrusion adds a raised triangle and six wall triangles. The selection is captured before each operation and processed in descending index order. Extrusion uses the source's 0.4m offset, 0.001 minimum area and 0.05 aspect threshold. The study accepts distinct seed indices 0..11 and zero to three rounds; inset amounts clamp to0.01..0.99. It is a bounded reconstruction of this cube family, not a general mesh-editing API.

The point cycles six independent recipes by held trigger; Space does the same and R returns to the seed. Moving the point alone changes nothing. Release parks it at host-local(0,1.15,2.2). Each display reconstructs from the original seed. It retains metre scale and aligns its lowest vertex to0.56m. No study surface collider or additional plinth is supplied. A checked host is hall-local(10.5,0,21.5), yaw180, unit scale; its approach is(10.5,0,18.4). The program appears temporarily in this bay for tests/captures and is not a permanent new museum artifact.

25 native exact-printed checks pass, including31 complete source-mesh comparisons across six gallery recipes,24 further bounded settings and a tiny-tip guard case. Faces, positions and roles agree; counts are12/24/36/84/84/444. Six standard constructions have two indexed faces per edge and Euler characteristic2; this does not prove arbitrary self-intersection freedom. The complete student change RECIPE04.faces=[8] makes48 faces, one tip and leaves the other top triangle untouched. Two deliberate faults (ascending index removal and growing border tags) are rejected. Keyboard and supplied XRTools poses under translated/rotated hosts pass.

The first native hall launch revealed a missing em_plan/map_authored entry and fell back to Grammar Lab. Restored only this hall using the existing scoped sequence refresh; seven previous L-systems rows retain their content except indices/counts. Shape Grammars is index6, Assemblage index7, total8. Canonical map_data and sequence are unchanged. The refresh warns that the authored21m width exceeds its13–19m preference; that existing room width is preserved. Four baseline captures were made AFTER this route repair, before the learner study, and are labelled accordingly.

30 final native museum checks pass, including ten camera checks, six family/three canopy specimens, exact triangle collision, two-sided open-strip collision, fourfold canopy mesh reuse, identical printed/source rendered triangles, 439 supported side-route samples, valid entry/exit records, clear learner bay, supplied XRTools pickup/move/action/release and the full edited program. The first room probe expected exactly two edit records, incorrectly counting shared lobby/showing/clock fixtures as extra lesson artifacts; corrected to require each primary once. That rejected receipt is preserved. No production artifact logic was altered.

Final native views were inspected. The two-row comparison and the larger canopy have space between them; the temporary learner reconstruction fits that bay. The first-three camera clips the outer plaque edges, and fine edge overlays show some shimmer; the oblique whole-family and close study views give the complementary evidence. Existing environment UID/renderer diagnostics remain; accepted logs contain no SCRIPT ERROR or Parse Error. These are author-led native assertions and supplied input, not independent ghost-student, headset, Quest-performance or full portal-traversal acceptance. HTML/code/link/ZIP checks do not claim browser layout validation.

Reflection preserved except one sentence distinguishing changing face-list addresses from descendant tags. Its four existing images remain with portable report copies. Review: doc/book/iterations/2026-10-09-shape-grammar-a-face-continues/index.html. Seven of eight L-systems halls reconstructed; Assemblage next.
