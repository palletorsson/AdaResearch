# Primitives — review decisions, 24 September 2026

41 comments checked. 36 resolved (including repeated comments and author decisions), 3 proposals declined, 2 follow-ups left open. Original review claims and author notes are retained in the live queue.

## Verification limits

The production-code probe completed 20 passing assertions: triangle loader regression, quad mesh updates, and portal-panel overlap before/after relocation. Godot then exited abnormally during teardown (3221225477). This is not a clean process-exit result or a full museum/headset walkthrough. `runtime.json`, `runtime.log`, and `verification.json` preserve the evidence. The running museum bake was not replaced.

## Decisions

### book_primitives.001 — Shorten the overture before 'Somewhere to count from'

**cancelled / skip**

Preserve the author-developed arrival: borrowed time, inherited construction, giants in fog and the 1968 room have specific work here. Word count alone does not justify removing them. The concrete counter and its code already precede this overture. This pass clarifies local references without shortening the author’s argument; see also .035.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.001)

### book_primitives.002 — Introduce Alice before 'Alice's rabbit is already ahead'

**done / fix**

Introduced the first allusion as “Like Alice after the White Rabbit …”, preserving the rabbit and the later return to Alice. No new preface or explanatory digression.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.002)

### book_primitives.003 — Say what the format-cycling label teaches, or cut the instruction

**done / fix**

Added what the label change makes available: a position can be written differently without moving it. Checked the executable match in interactive_point_origin.gd: plain coordinates, X/Y/Z labels, Vector3 spelling, and hidden label. The reviewer relied on an outdated source-header description of integer/scientific/word formats; those are not the current modes. Exact modes recorded in technical.md.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.003)

### book_primitives.004 — Rework 'An earlier version confined the point to the arrows' span'

**done / fix**

Removed version history from the main reading while preserving the distinction between a finite drawn axis and positions beyond it. Earlier confinement is recorded in technical.md. Same correction resolves .033.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.004)

### book_primitives.005 — Attribute 'var p := Vector3(1.0, 0.5, 0.0)' to the screen's example

**done / fix**

Attributed the example explicitly to the screen and restored its displayed identifier, point_position. The illustrative code is no longer presented as an unexplained var p source excerpt.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.005)

### book_primitives.006 — @folding_past names no placed token; the frames are the lobby's window

**done / comment**

Author’s original note: keep it like this since it read as one room

Kept as requested: entrance frames and Point One read as one arrival. Verified folding_past in endless_museum.gd LOBBY_PIECES and the existing technical companion. Added the explicit museum/grid scope there. The anchor and physical placement remain; no duplicate frame artifact was placed.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.006)

### book_primitives.007 — Name the Fontana puncture, or remove the second point embedded in it

**done / comment**

Author’s original note: maybe we could use the fontana pucture as move this point there, or leave outof the text

Chose your “leave out of the text” option. Fontana and its embedded point stay as a secondary encounter. The named point_one_main continues to drive the cards/frame; the target still accepts eligible points, including the embedded one. Recorded this distinction in technical.md. No artifact was deleted, no invented single-point restriction was added, and a dedicated puncture/arrival encounter remains only an optional idea.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.007)

### book_primitives.008 — Introduce the falling balls before 'Watch for the falling balls'

**done / fix**

Changed the invitation to “Carry the point towards it without letting go, and watch what falls.” The existing following paragraph then introduces the falling balls through their arrival condition.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.008)

### book_primitives.009 — 'Lines on monitors seem to meet': the monitor draws parallel scan lines

**done / fix**

Author’s original note: there is a monitor with lines

Your note is correct. Point_Lines places line_space_workshop at (16,16), with four live private-world camera studies (camera_study.gd and workshop source). They include crossings and displaced joins; sketch_monitor is a different secondary work. Replaced the ambiguous clause with “On the workshop’s four monitors, lines turn, cross and pull apart”. Preserved the monitors and documented the distinction in technical.md.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Lines#book_primitives.009)

### book_primitives.010 — Cut the desktop aside in the walking-recorder paragraph

**done / fix**

The walking paragraph now stays with the headset reader and retains the lean consequence. The desktop fallback remains described in technical.md. Also resolves .030; no implementation or platform capability removed.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Lines#book_primitives.010)

### book_primitives.011 — Cut the two desktop asides

**done / fix**

Removed the desktop clauses from the main walking/plan encounters; the companion explicitly preserves desktop walker behavior and the plan without controller pens. See .031 and .032.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Line_Grid#book_primitives.011)

### book_primitives.012 — Say that the table shows only the last ten kept positions

**done / fix**

The table now explicitly shows the last ten kept positions. Verified the size-minus-ten window in grab_sphere_point_snap.gd; the retained record can be longer.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Line_Grid#book_primitives.012)

### book_primitives.013 — Move the troubleshooting sentence into a footnote

**done / fix**

Moved the empty-field/release instructions into a linked carry footnote. The reading stays with the received drawing; how to supply one remains available.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Line_Grid#book_primitives.013)

### book_primitives.014 — 'green corners': the carried corners render white at rest

**done / fix**

Changed green to pale corners. draw_triangle_faces creates editable grab_sphere_point handles without setting a green resting material; the source scene supplies an uncoloured sphere at rest. No claim of measured headset colour.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context#book_primitives.014)

### book_primitives.015 — 'filled loops' is not what the panel prints

**done / fix**

The passage now says the instrument counts loops and triangles separately, matching the actual panel wording. It no longer presents the internal filled_loops state key as the printed caption.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context#book_primitives.015)

### book_primitives.016 — The overspill is not guaranteed for every concave loop

**done / fix**

Changed guaranteed overspill to “may” and asks the visitor to look beyond the boundary. The deliberately constructed L and SHIFT START comparison retain their stronger, specific claim.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context#book_primitives.016)

### book_primitives.017 — The grid lane misreads #discovery:1 as a rotation and builds no panel

**done / fix**

Added discovery to GridInteractablesComponent.CONFIG_PARAM_NAMES. A production-path regression probe loads both current Triangle tokens: before the fix it reproduces bool/yaw=1 and missing panels; after it retains authored yaw and creates both ExperimentPanels. Discovery-off parsing, other numeric config and tutorial shorthand also checked. This is loader/configuration plus artifact runtime verification, not a whole-room or headset test. All runtime assertions passed; the Godot process exits abnormally during shutdown (3221225477), recorded separately in runtime.log.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context#book_primitives.017)

### book_primitives.018 — Name or anchor the wall plate the figure is captured from

**done / fix**

Named the wall plate immediately before the figure and added its existing primary token marker. Restored the triangle puzzle marker afterward so the puzzle’s two-sided-face discussion stays associated with the puzzle. The plate already was primary; no role change.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context#book_primitives.018)

### book_primitives.019 — 'the tetrahedron beside it' stands 3.6 m away; the cube is nearer

**done / fix**

Changed “beside it” to “a few steps on”, matching the separate tetrahedron placement while preserving the comparison with the open trihedron.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Polythedra#book_primitives.019)

### book_primitives.020 — 'one blue arrow': the arrow is white on a blue disc

**done / fix**

Changed the direction cue to “one arrow on its blue disc”, distinguishing the sign backing from the pale glyph.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Polythedra#book_primitives.020)

### book_primitives.021 — The pink corners exist only in the museum build

**done / comment**

The chapter follows the endless museum build. Verified the simplex_corners construction path in endless_museum.gd; recorded explicitly in technical.md that these are museum architecture and do not appear in a grid-only load. Kept the bodily encounter and the architecture.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Polythedra#book_primitives.021)

### book_primitives.022 — 'the game's movement controls' is manual voice

**done / fix**

Changed “Approach it through the game’s movement controls” to “Walk up to it.” The following sentence still makes the loss of walking space explicit.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Polythedra#book_primitives.022)

### book_primitives.023 — The Achilles rail runs through the combine_portals instrument

**done / fix**

Confirmed the old source-map placement puts the six-metre rail through the real ring-panel rectangle. Moved only Achilles from (5,5) to (8,8), retaining yaw, height and length. New rail runs X=8, Z=8 to 2 over authored floor cells; the real panel intersection check is now clear and NEXT STEP still advances. Updated map note, artifacts.md and technical.md. Source-map/runtime geometry verified; no full-room/headset walkthrough and no active museum restart/bake replacement.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Portals#book_primitives.023)

### book_primitives.024 — Say why the hall is called Portals, or rename the family

**done / fix**

Added a short naming cue: “These are portals for looking through: rings that frame the space beyond.” The existing companion retains the separate teleportation distinction.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Portals#book_primitives.024)

### book_primitives.025 — 'Ten rooms ago' in the tenth room

**done / fix**

Changed “Ten rooms ago” to “In the first room”, preserving the counter return without an incorrect inter-room count. Also resolves .037.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Melencolia#book_primitives.025)

### book_primitives.026 — Thin the closing cadence 'It does not tell us...'

**done / fix**

Varied two repeated closures in Grid: a return now leaves its reason with the visitor, and the chapter asks which use to take further. Kept the stronger geometry/use and limit/stopping distinctions in Polyhedra and Portals. Selective pacing change, not a sequence-wide formula.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives#book_primitives.026)

### book_primitives.027 — Hedge the references once, not in every note

**done / fix**

Lightened three repeated disclaimers in Point One, Trace and Grid while retaining each reference and its specific question. Kept technical qualifications where they matter (e.g. Shannon’s uniform-time assumptions, collider scope and mathematical conditions). No blanket preface that erases differences between claims.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives#book_primitives.027)

### book_primitives.028 — Headings: 0 to 7 per chapter

**cancelled / skip**

Retain varied chapter structures. Headings help a reader revisit Trace’s several distinct recorders; the continuous Line and Cube encounters read without the same subdivisions. No demonstrated navigation problem requires uniform counts or a mechanical station threshold. Preserve the mature sequence’s pacing.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives#book_primitives.028)

### book_primitives.029 — Move the six figures out of review folders

**done / fix**

Copied the six native figures to stable doc/book/figures/<hall>/ paths and updated canonical final.md references. Historical review copies remain so old pages keep working. SHA-256 provenance confirms byte-identical copies; publication commit remains tracked separately by .034.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives#book_primitives.029)

### book_primitives.030 — Cut the desktop aside from the walking recorder

**done / fix**

Same implemented correction as .010: headset-led main reading, desktop fallback in technical.md.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Lines#book_primitives.030)

### book_primitives.031 — Cut the desktop aside from the second walking recorder

**done / fix**

Same implemented correction as .011: the lean leads, and the precise headset/rig-origin distinction and desktop fallback are retained in technical.md.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Line_Grid#book_primitives.031)

### book_primitives.032 — Drop both desktop clauses from the plan vitrine

**done / fix**

Same implemented correction as .011: the main reading follows the tracked-controller pen pair; the desktop plan behavior is preserved in technical.md.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Line_Grid#book_primitives.032)

### book_primitives.033 — Remove the version history from the coordinate frame

**done / fix**

Same implemented correction as .004: present encounter in final.md, confinement history in technical.md.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.033)

### book_primitives.034 — Commit the six chapter figures

**open / comment**

Stable canonical figure copies and a provenance manifest are now prepared under doc/book/figures; .029 fixes the links. A publication commit remains outstanding. This shared working tree contains substantial earlier/concurrent work, and the reviewer’s proposed sweep of untracked iteration folders is not an appropriate scoped commit. Commit the reviewed manuscript/figure/source bundle together in the publication pass; no files staged or committed here.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context (also Polythedra, Animatedcube, Ignorance, Portals, Melencolia)#book_primitives.034)

### book_primitives.035 — Reach the first point sooner

**cancelled / skip**

Same decision as .001: retain the author’s developed arrival, including the historical room and borrowed time. The rabbit is now introduced more clearly under .002. No word-count target imposed on the opening.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One#book_primitives.035)

### book_primitives.036 — Give the quad one paragraph as the bridge to the cube

**done / fix**

Added a brief comparison using the already placed four-edge puzzle and quad before leaving Triangle. It distinguishes closing an outline from a face, then moves an off-diagonal corner and an end of the shared diagonal. The production quad mesh probe confirms one triangle changes in the first case and both in the second. This prepares the later cube crease without removing the fan experiment or promoting every secondary work.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Triangle_Context#book_primitives.036)

### book_primitives.037 — Nine rooms ago, not ten

**done / fix**

Same implemented correction as .025: “In the first room”.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Primitives_Melencolia#book_primitives.037)

### book_primitives.038 — Keep the second person at the barrier

**done / fix**

Changed “the player” to “you” at the barrier, maintaining the reader’s embodied perspective.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Lines#book_primitives.038)

### book_primitives.039 — Make the sequence's content list match its ten halls

**done / fix**

The sequence content list now matches its ten dealt maps, in order, and describes Triangle as “Closing a boundary, adding a face”. Removed only the two non-dealt content entries, not their maps or artifacts. The older Point_Triangle artifact-group metadata remains available as legacy curation material; it is not the maps[] routing list.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=primitives.json (sequence file)#book_primitives.039)

### book_primitives.040 — One gesture through three recorders

**open / comment**

Worth developing, not evidence that this prose is false. Keep as a separate native Godot illustration task: send the same measured gesture through the production plain, 80 mm and 32-position recorders; capture their resulting geometry and retained counts, with input/provenance recorded. Do not substitute an invented static drawing or assume the three counts. No new figure is claimed in this pass.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Trace#book_primitives.040)

### book_primitives.041 — Count the shelf: four pens and an eraser

**done / fix**

Changed the shelf inventory to “Four pens and an eraser”, matching the five pickables built by whiteboard_drawing.gd. The following red-pen action stays unchanged.

[Review comment](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_Trace#book_primitives.041)

## Serving the canonical figures

The encyclopedia route at `src/app/book-review/[[...path]]/route.ts` now accepts `doc/book/figures/` with its existing file-type and realpath checks. Without that addition the stable links returned 404. Six current PNGs serve byte-identically; unrelated map JSON and directory traversal remain unavailable. The small external-repository diff and route checks are saved alongside this report.
