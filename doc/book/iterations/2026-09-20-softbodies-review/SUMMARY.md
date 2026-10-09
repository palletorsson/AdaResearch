# Soft Bodies: reading, pressure, a skin that holds

20 September 2026. Targeted encounter repair after reading the nine current chapters and the frozen Soft Bodies review. Eight chapters and their maps are preserved byte for byte. Playground of Joy keeps its two existing primary works and three secondary comparisons; no artifact is removed.

## What the sequence already carries

| Hall | Contribution to the path | Decision in this pass |
|---|---|---|
| Soft Body Deformation | Yield while retaining relations; separate stiffness, damping and pressure | Preserve the developed chapter |
| Cloth Physics | Fixed boundaries permit different forms; release and rebuild | Preserve |
| Carusell | A driven support and a responding body are different processes | Preserve |
| Obsticals | Pressure-driven walls make the enclosure itself responsive | Preserve the breathing language and its stated limit |
| Obsticals Part 2 | Contact geometry, material and variation require a comparison | Preserve |
| Playground of Joy | Read a responding body, intervene through a measurement, keep a frozen result | Repair and stage the two specimens; revise only the affected passages |
| Affect Theory Visualization | The image of a living thing invites an inference its mechanism may not warrant | Preserve recognition, desire and resemblance |
| Reaction Diffusion Systems | Local exchanges maintain spatial differences; a field still needs a mapping to form | Preserve |
| Topology Entropy Morphogenesis | A named parameter can prescribe a family without measuring entropy | Preserve the distinction between parameter, sample, threshold, connectivity and passage |

This is a manuscript/source assessment. It is not a new runtime acceptance of the other eight halls.

## Findings and decisions

**Reading had quietly become intervention.** Selecting VOLUME enabled pressure correction. MEASURE now changes only the reading. FEEDBACK independently enables pressure correction, remains active across reading modes, and restores the selected manual pressure when switched off. It does not restore an earlier shape. Both local and hall controls expose the state. The seven hall buttons occupy two rows.

The quantity is the volume of a box aligned with the world's axes, not volume enclosed by the skin. The book makes that limitation an encounter: “A number that helped us look has become a number the body is asked to follow.” No assertion of exact volume conservation or feedback convergence is made.

**The live body was not live.** The first functional probe returned zero reference volume. A small isolated fixture reproduced it. The SoftBody3D entered the world before receiving its mesh, leaving its solver/render connection uninitialised. Creating the mesh before insertion restores that connection. This agrees with [Godot 4.6's SoftBody3D implementation](https://github.com/godotengine/godot/blob/4.6/scene/3d/physics/soft_body_3d.cpp), specifically the enter-world preparation path. The next check exposed inconsistent face winding and initial expansion passing through the 6 cm deck shell. All faces now wind outward; deck collision extends through the visible apron. World-space overlays no longer receive the bench transform twice, and desktop squeeze follows the simulated body instead of the engine node's reset world origin. These repairs affect the shared rounded-body implementation; the lowered harness placement is enabled only by this hall's `lesson:true` token.

**The apparent vessel had no collision and was mostly underground.** Its frozen mesh now rests above its floor datum. A two-sided trimesh collision follows that exact geometry and is replaced with it on reconstruction. The source topology remains a closed sphere: no mouth or traversable interior is claimed. The book's unsupported “walkable surface” becomes an invitation to approach, meet the skin and look for an opening. Making a vessel one can enter remains an artifact-development opportunity.

**Curation was inconsistent.** The vessel was already primary in the role assignment and book but duplicated in the ordered secondary list; the core record named only the rounded body. Both are now ordered primaries in the book, chapter anchors, roles and core record. Existing branching, field and grid-agent comparisons stay. The hall console is supporting equipment.

## Evidence

- `before/` and `before-sha256.json`: frozen inputs for all nine chapters/maps plus changed supporting files.
- `before-console.png` / `after-console.png`, `before-vessel.png` / `after-vessel.png`: actual museum captures from matched map-relative cameras. Live bodies and ambient agents are not synchronised across captures.
- `after-volume-reading.png` / `after-volume-feedback.png`: two states of the revised controller, not before/after versions.
- `after-vessel-40.png` / `after-vessel-400.png`: same force and camera, different integration counts.
- `after-specimen.png`: current live body at the lowered bench; no matched before close-up is claimed.
- `review-report.json`: **65 controlled runtime checks passed**. Checks cover nonzero simulated reference and placed position, display/feedback separation, a controlled error's pressure response, local/root/hall state, desktop squeeze location, seven-button layout, duration/gravity rebuilds, exact collision triangles, rays and actual CharacterBody support. Six-button desks and unconfigured harness heights are checked for preservation.
- `runtime-inputs.json`: tested source fingerprints and private museum inputs.
- `content-checks.json`: **36 content/preservation checks passed**. Only the active hall's lesson token changes in map data and both museum plans. Its other layers, placements and the other eight maps remain intact.
- `long-museum-check.log`, `necklace-check.log`: derived files match their inputs. Existing Random Space Geometry / Noise Inside Noise layer warnings remain separate work.

Run the scoped checks with `python -X utf8 doc/book/iterations/2026-09-20-softbodies-review/run_review.py` and `python -X utf8 doc/book/iterations/2026-09-20-softbodies-review/check_content.py`. The runtime driver reuses the private museum fixture in `ada_run/encounter_pilot/SoftBodies_Playground_of_Joy`; its recorded inputs must be refreshed if the museum loader or room plan changes.

## Limits and later work

No headset reach, hand-controller interaction, comfort or learner acceptance is claimed. The controlled pressure-error test proves the feedback action, not convergence for every deformation. The unpinned body remains free to move; extended sessions and stronger settings need a recovery/retention decision. The late wide console captures are not evidence of stable bench occupancy. The vessel is a collidable shell, not a solid body or accessible interior.

The run still reports the existing audio UID, certificate-store and shader-cache write warnings, plus costly ornamental builds. No new script/parse errors remain. These are not presented as a globally clean engine log.

The review bundle omitted `soft_workshop.gd`, which exists in the project. Future source exports should include that shared controller and helper closure. Historical artifact descriptions elsewhere still need a separate pass against implementation; their rhetoric is not a reason to flatten this sequence's writing.

## Next

Continue into **Isosurfaces**: a continuous field becomes a selected boundary. Read its current review and chapters, then choose the smallest encounter gap that matters. Carry forward the distinction established here between a visible skin, its numerical construction, and what the player's body can actually cross.

## Web review access

Use [the live comparison](http://localhost:3003/book-review#softbodies) instead of a filesystem link in chat. The encyclopedia handler `src/app/book-review/[[...path]]/route.ts` reads the review, linked evidence and current final.md files directly, with no copied image bundle. The handler installed on 20 September is recorded in `encyclopedia-review-route.ts`. HTTP checks passed for the page, image, summary and manuscript, and rejected unrelated/traversal paths. Browser verification confirmed the Soft Bodies text and paired images load.
