# Cube review: keep the crease — 2026-09-16

Applied Palle's supplied review selectively. The five-step experiment stays outline → reveal → deform → expose the diagonal → compare rigid-face folding. Kept the museum floor and wall recognition in the main walk, as Palle explicitly requested in the preceding turn. Shortened the crate and collision discussion; moved the crossing/collapse caution into the connectivity note. Replay/restore, the carton admission, and the exit carrying the crease remain.

Three technical notes now accompany the walk: triangulation, connectivity versus geometric placement, and Euler's count. Existing note identifiers animatedcube-boundary and animatedcube-counts are retained and extended. The opening question stays in plain language; the main text does not substitute "invariant" or assume that a self-intersecting result remains a valid embedding.

## Sources checked

- Godot Engine 4.6, [Using the ArrayMesh](https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/arraymesh.html), rectangle example: four vertex positions and two triangle triples. Used alongside the existing builder's SurfaceTool triangle submission. No claim that every GPU operation renders triangles.
- Botsch, Sieger, Moeller and Fabri, [CGAL Surface Mesh manual](https://doc.cgal.org/latest/Surface_mesh/index.html), displaying version 6.2.1 on access, sections Connectivity and Properties. Point and connectivity properties provide the technical comparison. The builder does not use CGAL. The version-specific URL could not be opened by the web tool, so the footnote links to the verified manual URL and names the inspected version.
- [Euler Archive, E230](https://scholarlycommons.pacific.edu/euler-works/230/) verifies Elementa doctrinae solidorum, published 1758, Novi Commentarii academiae scientiarum Petropolitanae 4, pp. 109–140. The Latin download returned HTTP 403. Its web abstract appears to invert the relation between edges and the sum of vertices and faces; that wording was not adopted. No page-specific claim about the inaccessible original is made.
- Heinz Hopf, [Selected Chapters of Geometry](https://pi.math.cornell.edu/~hatcher/Other/hopf-samelson.pdf), 1940 ETH lectures reconstructed and translated by Hans Samelson. Section I.3, printed pp. 4–5 (PDF indices 5–6), derives v - e + f = 2 for a triangulation of the sphere and discusses extension to polygonal cells. This supplies the accessible proof reference. Cube and triangulated-cube arithmetic is checked against the artifact's separate lists; reverse rendering copies are not extra combinatorial faces.

## Validation and scope

The main walk decreased from 832 to 792 whitespace-delimited words, including its annotation tags and code. The three notes are optional. Nine content checks pass, including exact archives, preserved placement/role/manifest/source hashes, primary tags, footnotes and live text. Four Markdown rendering checks pass for targets, backlinks, unique IDs and source links. The final live API content matches disk.

Only final.md and intent.md changed in this amendment. Tutorial, technical text, physical placements, role ordering and runtime source remain unchanged. No runtime test rerun was needed for this editorial change. Earlier checks and headset limitations remain documented in the parent iteration.
