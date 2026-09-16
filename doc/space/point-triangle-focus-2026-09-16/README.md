# Point_Triangle_Context — a boundary and the face we give it

16 September 2026. Palle asked to continue from Grid to Point_Triangle_Context. This pass focuses the book on two existing primary artifacts: `triangle_line_puzzle` and `draw_triangle_faces`. It carries Grid's repeatable positions into a closed boundary, a visible face and a filling method whose reach can be tested. The exit prepares Primitives_Polythedra: faces meeting at a corner do not yet enclose a volume.

The preceding chapter already contained a useful primary encounter and a specific L-shaped comparison. Those are retained and tightened. The long further-encounters passage becomes a separate route back into the room's other works. No artifact is removed, moved or reconfigured. The role file already has the correct two primary cards and remains byte-for-byte unchanged. All fifteen placements remain: two primary, twelve secondary and one text marker. Only the map's stale count changes, from 17 to 15.

## What the revision clarifies

- Closing three edges, creating a triangle mesh and displaying its fill are separate operations. The puzzle's fill button waits for completion.
- The drawing tool records timed samples while held, can record on release, and commits an edited corner's snapped position when that corner is released. The text follows these actual controls.
- NEW OUTLINE preserves completed work. Each L adds one loop and four logical triangles. An earlier practice triangle still contributes to the readout; the previous chapter's fixed total of two loops and eight triangles overlooked it.
- The two Ls reuse the same six corner positions and traversal direction. Changing the starting corner changes the fan, not the boundary or its intended interior. The second fill overspills the notch.
- Using that excess for another work would change its purpose. It would not repair the polygon fill or change the implemented algorithm. The critical passage leaves room for both repair and desire without assigning virtue to convexity or concavity.

The tutorial, intent, technical reference, critical text, blurb, summary and inventory now describe the same route. The technical reference also corrects older claims about arbitrary fan triangulation, fixed-length rigidity, normals versus culling, universal triangle rendering, and a trihedron being a closed volume. The drawing's generated faces have no collider; appearance does not itself grant bodily support.

## Keep the work available

[Detours](../../../commons/maps/Point_Triangle_Context/detours.md) gives each secondary artifact a return question, source link and relevant limits. It retains the developed hinge study, editable surfaces, quad, measurement, symbolic history, coarse ring, screen and gates. The pink triangle's historical references are checked against the US Holocaust Memorial Museum and Wellcome's original-poster catalogue; geometry alone does not supply that history.

All eleven preceding map documents and the original map JSON are archived byte for byte under `previous/`, with hashes in `previous-sha256.json`. The prior resolved room cards are saved alongside them. `field_notes.md` and `walked.md` gain historical notices while preserving their original bodies; `eye_shot.md` is untouched. The old copied-example test gains a comment identifying its historical source, so it does not claim to validate the current tutorial.

## Checks and their limits

Two existing probes were run against Godot 4.6 with XR off in this pass:

- [probe_triangle_primary.gd](../../../commons/testing/probe_triangle_primary.gd): 23 checks pass, using actual endpoint and pointer events, supplied held positions, rotated and translated scenes, corner-release updates and panel checks. Compact output: [primary-checks.json](primary-checks.json).
- [museum_triangle_fan.gd](../../../tools/probes/museum_triangle_fan.gd): the actual drawing scene and NEW OUTLINE callback preserve and reuse six points across the two Ls. Four logical triangles arise from each start. From A their summed area is approximately 0.8 square metres; from B approximately 1.44, with two centroids in the excluded notch. The boundary area is 0.8 in both cases. Summed triangle area includes overlaps and is not union area. Output: [fan-checks.json](fan-checks.json).

The fan probe begins with a fresh drawing and checks the two Ls; the primary probe separately checks a practice triangle. The book's optional total of three loops and nine triangles follows the panel's accumulation rule, not a claim that a human completed that whole gesture sequence in a headset.

The startup logs retain the existing unresolved `uid://rwex60pqapc` and certificate-store messages. The isolated primary probe also reports ObjectDB instances at exit; these checks do not establish leak-free teardown. Both probes finish successfully with no failed assertions. No headset or visitor-learning validation is claimed. Secondary interactions are source-inspected return opportunities, not newly tested experiences.

[validation.json](validation.json) records book/primary agreement, unchanged layers and roles, archive hashes, retained historical bodies, placement counts, return visits and local document links. [source-checksums.json](source-checksums.json) identifies the checked primary scripts and probes. This revision changes prose and count metadata, not the runtime implementation.

## The next useful iteration

Use the [encounter reference](../../../commons/maps/Point_Triangle_Context/encounter-reference.md) to observe whether a visitor can separate closure from fill and reproduce the comparison. Exact timed hand placement may be the difficulty. If it obscures the question, a future selector for the same stored L and its starting corner could isolate input order while keeping free drawing available. It is a proposal, not an installed feature.

The chapter is 1,001 whitespace-delimited words, down from 1,648. All 24 editorial checks pass, including 60 resolved local links; the current book markers match the two primary cards in order.

The focused [book chapter](../../../commons/maps/Point_Triangle_Context/final.md) is ready for review. Grid and this Triangle revision remain working changes; no commit or push is performed in this turn.
