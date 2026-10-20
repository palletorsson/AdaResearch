## Polythedra: wedge labyrinth and standing joystick — 2026-10-17

The user clarified that "centre wedge" means the cheese's symmetric shape, not a central maze location. The yellow cheese now has a centred ridge over a 0.18 x 0.14 m base, height 0.17 m, at the far-end cell (4,1). Its model position is (0.82, TOP + 0.003, 0).

A 5 x 3 physical maze of 23 separate grabbable wedge walls replaces the miniature ramp/jump course. Walls stand broad-base down: four vertices on the plinth and two on the upper ridge. Base thickness 0.08 m, height 0.24 m, length 0.30 or 0.36 m. Branches and dead ends create an actual search by the player. The maze has no automatic pathfinding or learned route; Shannon's Theseus is the spatial reference.

The only control is a returning joystick standing upright behind the mouse, at (-1.24, TOP + 0.02, 0). Its original +Z axis is oriented +Y; local +Y goes forward +X and local +X goes right +Z. Both pointer and physical grip directions are verified. The large panel and jump/home/restore buttons are removed. The route lies on the floor. An off-table mouse returns after 0.7 s without resetting walls; re-enter the hall to restore the authored arrangement.

30/30 model checks and 11/11 native hall checks pass. These cover upright geometry, symmetry, waiting/input, physical obstruction, dead end/backtracking, complete route to the far cheese, moved-wall opening, pause while held, automatic recovery, pointer/grip release, player approach and platform crossing. No script errors found; existing renderer/registry warnings remain. Actual headset comfort remains open.

Final, tutorial, technical, summary, intent, inventory and registry description match the maze. Review: `iterations/2026-10-17-wedge-mouse-maze/index.html`, with native captures, before/current texts and test reports. The room's larger blocking -> climbing -> sculpture -> miniature sequence is unchanged. No commit or push requested.

## Polythedra: upright cheese, bare wedges, collected controls — 2026-10-17

The wedge-mouse model now uses a single bare brown PrismMesh and an upright yellow cheese wedge (0.18 x 0.18 m base, 0.24 m height). Ears, eyes, tail and cheese spots are removed. Seven grabbable construction wedges still make the blockers, incline, paired platform and paired landing. Four flush, non-colliding box strips mark the initial detour to the incline; their turns have non-overlapping joints.

Joystick, JUMP, HOME and RESTORE now share one 0.94 x 0.40 m panel at model x=-1.42, behind the starting mouse and facing along the course. Panel-relative input sends stick-up towards the cheese (+X), stick-right to +Z. HOME retains edits; RESTORE resets the arrangement. The panel uses an unshaded pale surface for readable dark text, with the instruction line below the joystick's face.

35/35 model checks and 100/100 native hall checks pass, including physical ascent/jump, altered support, reset, input direction/release, upright cheese, bare mesh counts, and walking to the new panel. Subsequent capture-only runs check the non-colliding strip and show the final arrangement with the test walker out of frame. No script errors were found in these runs; existing registry/renderer warnings remain. Headset reach and comfort remain a wearer trial.

Final/tutorial/technical/map summary and registry description are updated. Review: `iterations/2026-10-17-wedge-mouse-path/index.html`, with native captures, before/after final, tutorial and reports. Room order and placements stay blocking -> climbing -> sculpture -> miniature. No commit or push requested.

## Polythedra: wedge sculpture and player-steered mouse — 2026-10-17

On the Primitives_Polythedra platform, six copies of the original prism_block make a 1.95 m sculptural column: three paired diamond modules. Its joints remain fixed. The side ramps, three-metre passages and descending route are unchanged.

The second addition is a 2.8 × 1.0 m plinth with a brown wedge mouse and cheese. The player steers the mouse using a returning joystick, and presses JUMP to leap in the last steered direction. Seven identical right-triangular pieces are grabbable: two stoppers, an incline, two platform halves and two landing halves. Turning and placing pieces changes contact and support. The cheese is a gravity-enabled body and falls if unsupported.

HOME returns only the mouse. RESTORE resets all seven construction pieces, the mouse and the cheese. Construction pieces remain where released; there is no persistent layout save. Hand grabbing, pointer dragging and poke/ray buttons use existing interaction components. These controls leave avatar input alone.

Final, tutorial, technical, summary, intent, inventory and this map's curation/spine order follow blocking → climbing → sculpture → small model → descent. Existing notes are retained. Other maps and museum plan rows are unchanged.

98/98 native hall checks pass; 24/24 supplied-control model checks pass; 13 scoped data checks pass. The mouse is stationary without input, the central stoppers resist direct steering, a detour reaches the ramp, and a player-directed jump reaches the raised landing. Moving the ramp removes that ascent; removing the far support lowers the landing. HOME preserves edits and RESTORE returns the arrangement. Joystick pointer direction and release are checked. Native capture caught inward-facing button caps; they now face outwards and are checked explicitly.

The one-millimetre convex margin is important at this scale: the default four-centimetre rounding caused the small mouse to meet an artificially steep contact at the ramp foot. The miniature uses slowed gravity and is not a scaled model of real mouse mechanics. Fixed sculptural joints are not a balancing test.

Pathfinder: zero failures, with existing edge-teleporter and enclosed-rock-spawner warnings. Engine reports retain existing registry/renderer warnings. VR grip comfort, button reach and visitor interpretation still need a wearer. No commit or push requested.

Review: `iterations/2026-10-17-wedge-sculpture-model/index.html`. The user explicitly chose player steering; no autonomous route remains in production.

## Polythedra: central collection, then forward side ramps — 2026-10-17

Palle clarified the gap question: use grid principles, first a central collection of standing wedge blockers to walk around, then wp climbing wedges along the sides onto a platform. Implemented this corrected sequence. Five prism_block bodies at scale2 occupy an exact 10x2-cell central bank (columns5–14, rows24–25); half-cell offsets align their 2x2 footprints. Three full columns remain clear on each side (2–4,15–17). Six wp:0 units at row29 climb forward along the two sides; short inner walls at columns5/14 rows27–29 hold them. Structure2 platform is 16x3m (columns2–17 rows30–32), one metre above floor. Four wp:180 at row33 columns8–11 descend. The old central baffle and opposing-ramp layout are removed. STOP/double arrow precede the bank; ahead arrows precede the later ramps. Three metres now means clear side circulation, not the prior raised landing interpretation.

Review: `iterations/2026-10-17-wedge-grid-route/index.html`; saved summary, before/after texts and native captures. 78/78 native checks pass on first run, including true bank bounds, both 3m clear passages, central refusal, both detours/forward ascents, platform/descent and rock-room/exit access. Eight scoped data checks pass; only Polythedra plan row changed and no artifact runtime code changed. Pathfinder no failures; prior teleporter/rock-spawner warnings. Existing renderer/registry warnings but no engine errors. Final/tutorial/reference/summary/intent/inventory updated in encounter order. Headset comfort, Quest performance and unprompted understanding remain open. No commit or push requested.

## Polythedra: three-metre landing and standing stoppers — 2026-10-17

Palle requests “a gap of 3 meter between the wp:s” and standing wedge stoppers to walk around. Asked whether the gap means raised landing or flat passage; no answer before implementation. Stated assumption: three metres of raised landing between facing ramp upper ends. Current platform is 3 × 4 m (columns 8–10); east ramps move from x12 to x11. Seven native wp units form two 2m-wide approaches and a centred 3m-wide descent. Two existing prism_block instances, solid at uniform scale 2, stand at (5,24) and (13,24), without new runtime code. Signs remain, shifted to the narrower arrangement.

Review: `iterations/2026-10-17-wedge-spacing-stoppers/index.html`, short summary.md and native captures. 63/63 runtime checks pass; upper-edge spacing measured 3.0m; both stoppers block direct approach, both outside detours and ascents work, far descent/rock room/exit remain accessible. First right detour at x15.3 caught the existing monitor case (extends to15.34); x16.5 clears it. Eight scoped data checks pass; only this museum plan row changed. Pathfinder no failures, old teleporter and enclosed-rock-spawner warnings. Renderer/registry warnings but no engine errors. Current final/tutorial/technical/summary/intent/inventory updated. Headset comfort and visitor response untested; no commit/push requested. If Palle meant a floor-level gap rather than the shared raised landing, revise that geometry from the saved before snapshot, preserving the requested stoppers.

## Polythedra wedge corridors — 2026-10-17

Palle requests walls/corridors to hold the symmetric ramps, STOP and arrows, and wp ramps onto a structure-2 platform. Implemented in Primitives_Polythedra: front baffle, cross-hall divider, two 2 m-wide approaches, a 4 × 4 m landing (structure 2 gives 1 m rise), and the far descent. Six stock wp prisms supply the three ramps. Four street signs restored. The wedge_palace token remains as layout:map identity without duplicate geometry. Rock-room entrance moved beyond the crossing; former numeric-2 retaining walls converted to w before setting wall_height:3. First two alignment encounters, corner, basin and side-room contents retained.

Review: `iterations/2026-10-17-wedge-corridors/index.html`; short reading in summary.md, before sources and revised full text alongside. 47/47 native checks pass: six wp geometries, raised floor, signage, native CharacterBody ascents/descent, three blocked flat bypasses, rock-room access and exit approach. Ten scoped data checks pass; only this museum plan row changed. Pathfinder has zero failures; warnings for old edge teleporter convention and intentionally enclosed rock spawner. Runtime log has existing renderer/registry warnings and no engine errors. First probe had a mistaken rock-room return waypoint through a wall; corrected to doorway in v2, no architecture change. Native captures inspected. Headset comfort, unprompted route recognition, Quest performance and jumping/teleport bypasses untested. Final/tutorial/reference/summary/inventory revised. No commit or push requested.

## Primitive tools implemented — 2026-10-17

Palle's “go” authorizes the corrected four-map proposal. Point_Trace now has a 24 × 24-cell room, opt-in transparent glass painting with existing pens/eraser, then three held beads following their centres at 10/40/80 mm grain, and the ramp farther along. The monitor still discovers the tools; their released positions still reach Grid through TraceData. Grid selection preserves archive identity and source index through rounding collisions and page changes. Point_Animatedcube now opens with linked cubes using opposite front diagonals; one corner moves on both, followed by the net, prefab library and conveyor in a larger workshop. Melencolia's main seated figure is replaced by a labelled stylised skull; surrounding tools, stone and smaller figure remain.

Review and short reading: `iterations/2026-10-17-primitive-tools/index.html` and `summary.md`. Four before/current full-text comparisons and native screenshots are retained. Updated finals, tutorials, references and inventories; scoped Trace/Cube roles and generated reading order; only these four museum plan rows rederived. 77 supplied runtime checks pass, including desktop and XRTools pickup/release, transparent erasure and ordinary-board regression, exact trace transfer, source selection, paired deformation and walking routes. Four pathfinder checks pass with legacy edge-teleporter warnings. Melencolia reports a resource still in use at shutdown; scene operation passes, but do not claim a clean exit. Human headset comfort, Quest performance and unprompted visitor understanding remain untested. No commit/push requested.

## Primitive reverse design brief — 2026-10-17

Clarification: retain both glass painting with pens and three-dimensional spatial tracing. Palle objects to the pen metaphor in open air, not to air drawing itself. The first brief misunderstood this as replacing air drawing; that instruction is corrected. A held point/bead is only a candidate for a future spatial tool. Preserve its TraceData connection into Grid. `iterations/2026-10-17-primitive-reverse-brief/summary.md` saves the four-map proposal in a short reading, also shown at the top of the review page. Documentation only; no implementation in this clarification pass.

Palle asks the assistant to write improvement instructions: a spacious glass painting wall in Point_Trace, selected-point correspondence in Point_Line_Grid, a proposed improvement for Point_Animatedcube, and a skull replacing the main figure in Primitives_Melencolia. The source-grounded brief is in `iterations/2026-10-17-primitive-reverse-brief/brief.md` with a review page and a geometric sketch. Proposed cube pilot: identical corner displacement on paired cubes with opposite front-face diagonals, followed by rigid-face folding and prefab arrangements. Important dependencies: the current board does not export carried traces, Grid recentres/scales and deduplicates snapped samples, and the Melencolia final describes the figure being replaced. Instructions and observation criteria are prepared; no map/runtime/canonical prose edits or visitor results in this pass. The cube centre-depth calculation is not an engine test. No commit/push requested.

## Primitive encounter trial — 2026-10-17

Four requested maps revised locally: Point_One removes visible/solid-point podiums; Point_Lines has twelve pairing points, measurement monolith, ten-barrier queue, forced ordinary-walking ×/+ passage, then other examples; Point_Triangle_Context ends with a twelve-piece assembly table; Primitives_Polythedra begins with tetrahedron/wedge vertex alignment and physical completion, then corner tetrahedron, symmetric platform ramps and far descent, floored basin and rock side room. No cube exhibit.

Review: doc/book/iterations/2026-10-17-primitive-encounters/index.html. 102 supplied runtime checks pass, including desktop/XR pickup drivers and native walks. Four pathfinder checks pass with documented warnings. Broad sequence audit retains 14 existing missing title fields; Point One exit-support fallback remains. Human headset reach/comfort and pedagogical response are untested. Current summaries, inventories, tutorial extensions and affected final passages are updated. The scanner remains an animated plane, not an implemented section display. No commit/push requested.

# STATE — the book's re-entry point

## Min-entropy as chair pyramids · 17 October 2026

Palle clarified that “mini” meant **min-entropy**, then proposed pyramids of chairs. The [pyramid review](iterations/2026-10-17-physical-guess-chairs/index.html) installs four full-size physical stacks, each with 9 + 4 + 2 + 1 chairs. Counts remain 8/8, 8/4/4, 12/4 and all pink. All 64 chairs and the entrance reference chair are pickable; walking can disturb them. Separate leg/seat/back/arm colliders permit stacking. Labelled group IDs remain fixed wherever a chair moves, so spatial disorder does not change the declared category probabilities. RESET rebuilds a group; floor receipts preserve full pose/motion and generator state. The old miniature receipt format is deliberately not resized into the floor experiment.

122 installed-hall checks pass, with no engine errors: unfrozen pyramids stand, desktop and supplied XR Tools pickup/drop work, contact disturbs the stack, counts stay fixed, receipts replay subsequent IDs, held bodies resist reset, and the central route remains open. The first contact version scattered furniture too far; bounded horizontal/upward/angular speeds reduce the final measured maximum displacement to about 1.41 m in this supplied walking trial. These are interaction limits, not a calibrated chair-material model. Source snapshots and native before/after images are retained. Tutorial, final, writing wall, registry and plan follow the new encounter; room/final order and the first 48-value research pilot stay. Headset reach, grip feel, recognition, performance and independent reconstruction remain untested. No commit or push requested.

## Both operation and invitation · 16 October 2026

Palle confirmed **both** difficulties: physical operation and whether a visitor would naturally choose the button action. The [invitation comparison](iterations/2026-10-16-entropy-invitations/index.html) keeps the reach repairs, adds short local questions/input hints and steady primary-action colours, and revises five paragraphs in the two canonical finals. The gap and a possible exchange now precede the control names; guessing explicitly changes from identifying a hidden chair to predicting a new draw. KEEP/REPLAY remain capabilities when an exact arrangement matters. Corresponding magnet final notes follow; map, museum plan, order, magnet layout/tags and models stay. 34 Types and 13 Workshop checks verify loading, contact/ray operation and retained choice feedback; native views retained. These cues remain proposals awaiting an unprompted headset encounter, not evidence of discovered or desired action. The earlier complete finals are retained beside the revisions. First 48-value pilot unchanged.

## When the text says “we press” · 16 October 2026

Palle questions whether the narrated button actions are likely in VR. The [control audit](iterations/2026-10-16-entropy-button-reach/review.md) separates available, discoverable and desired actions. Reversed door/guess caps now face out; door caps move from 0.645 m to about 1.0 m, with the explanation above them. Guess controls move from 0.33 m to a horizontal front rail at 0.90 m; the first sloped repair hid chair parts at a lower eye position and was replaced. Both cabinet rows now face up, eliminating the front-row interception of rays aimed at SAME k. Models, save/replay behavior, chair materials, map order and finals stay. Both tutorials describe actual hand-contact and ray/trigger input.

300 Types and 30 Workshop checks pass using actual collision overlap on the hand layer and XR pointer dispatch after ray hits. Native standing/lower-eye views retained. No tracked-hand/headset comfort or discoverability claim. KEEP/REPLAY semantics were source-checked, not newly persistence-tested. Next: let a visitor choose an intended action before naming a button; record whether its target and consequence are found. The cabinet prompt's assumed button use is now an explicit weakness, not a successful reading result. The 48-value seed bench remains the first research pilot. No commit or push requested.

## Entropy transition and chair-image test · 16 October 2026

The [transition review](iterations/2026-10-16-entropy-transition-check/index.html) tests both current finals without replacing them or moving artifacts. Assistant judgement: doors → coffee now has a reset/return question but introduces heat before the encounter, then postpones its answer through milk imagery; cabinet → points remains the weakest join because viewpoint can already change at the cabinet. Entering the point field is its strongest additional affordance. Three small passage trials are retained separately. These are editorial hypotheses, not a new human reader result. A cabinet excerpt has been put to Palle; the requested next investigation remains pending.

New native views inspect five frosted panes, the black/pink chair types, coffee, cabinet and point enclosure. The same-pane test changes only blur 0.40 → 0.78 with chair identity, camera and colour record fixed; the form becomes more obscured while the declared record stays. The installed panes have different backgrounds/light, and dark armchair surfaces need headset-distance inspection. No production shader/material is changed. 27 load/capture/control checks pass; images are inspected separately, not algorithmically scored for recognition. A Types entry-frame fallback warning is retained as a separate unresolved route check. Next: test the local writing trials, then a consistent glass backdrop/neutral chair fill if the visual reading warrants it. Full finals remain 1,748/1,712 words, with the same seven/eight main encounters and optional stops. First 48-value pilot unchanged.

## Entropy encounters with room to breathe · 16 October 2026

The [new comparison edition](iterations/2026-10-16-entropy-room-to-breathe/index.html) retains the immediately preceding chapters beside both revised canonical finals: Types 1,360 → 1,748 words, Workshop 1,254 → 1,712, excluding notes. The seven/eight encounter orders stay, as do optional stops and magnet geometry/tags. Final notes and plans follow the revision. Doors → coffee now tests resetting a represented beginning against restoring a heat transfer; milk stages remain distinct from the thermal model. Cabinet → points tests exact saved positions against alignments dependent on viewpoint, then moves to load-bearing relations at the stones. These are proposed improvements, with no new reader response claimed.

The entrance reference chair now stands fully on the floor. Its shelf and one platform cell at (9,3) are removed; the divider behind remains. The first native view exposed the block intersecting the lowered chair, so the final probe checks that overlap as well as approaches and floor heights. 41 installed-museum checks pass; native images retained. Other full-size chairs are already floor-level; the guessing studies retain miniature chairs on 0.75 m tables. Both complete before/after pages and a separate revised reading are available. Next: read the two weak transitions, retain the reader's desired next investigation, then compare it with a headset walk. First 48-value research pilot unchanged. No commit or push requested.

## Entropy chapter length · 16 October 2026

Palle allows the entropy texts to be a little longer because they contain many artifacts. The usual 600–1,500 words is guidance rather than a ceiling. The shared encounter method and both entropy plans now prioritise situated observation, short explanations and earned transitions over compression to a fixed count. The latest review builder reports lengths outside that range for editorial consideration instead of rejecting them. This records a writing preference; it does not pad or rewrite the chapters automatically.

## Door histories and one guess · 16 October 2026

The [new Entropy Types review](iterations/2026-10-16-doors-and-one-guess/index.html) implements shared STEP/RESET/GAP for the two mathematical door pairs, with LOW/HIGH histories and a separate 1,024-start calculation. The centre stays open. The last encounter now has four tables of sixteen miniature chairs: 8/8, 8/4/4 types, 12/4 and all pink. Guess/DRAW, CHANGE ONE and RESET operate; the last chairs can be moved and turned. A/B share Hmin=1 but differ in Shannon entropy. Receipts preserve full generator state and poses through research APIs. 96 focused and 121 actual-hall checks pass; native views retained. Final, tutorial, magnets, registry and plan match; placements and seven-stop order stay. The reader's first unearned transitions—doors→coffee and Workshop cabinets→points—remain explicit open questions, not inferred removals. Workshop's final is unchanged. Headset comfort and independent learner reconstruction remain pending. First 48-value pilot unchanged; no commit or push requested.

## Two entropy finals in the encounter voice · 16 October 2026

The [paired reading](iterations/2026-10-16-entropy-two-voices/index.html) revises both canonical entropy finals using Random Definition's situated “we” voice. Entropy Types becomes *What remains uncertain*; Entropy Workshop becomes *What the gauge forgets*. The first ends with rearranging an all-pink tray; the second starts with SORT and unchanged colour entropy. The room orders remain, with seven Types encounters and eight Workshop encounters; hybrids and hardware stay optional. Writing-wall final notes and both plans follow the revision. Original chapters and the reference voice are retained with before/after pages. Source and numerical checks support the prose; no new runtime or reader result is claimed. Next: identify the first transition that fails to create a need for the next encounter. The first 48-value pilot is unchanged. No commit or push requested.

## A route for every Entropy Workshop artifact · 16 October 2026

The [hall-order review](iterations/2026-10-16-entropy-hall-order/index.html) widens the first bay to 25 m and gives all ten artifacts separate footprints. Shared room/final order: ledger → four jars → hand jar → four cubes → compartments → points → ruin → signal room. Hybrids with local butterflies and hardware wear remain side stops; the weathering wall stands beside the physical ruin. Museum arrival moves to sp=(8,2), before the ledger; the doorway at row 33 is three metres wide. All experimental configurations and the first 48-value pilot remain. 96 native layout, approach, route, portal and ghost-handoff checks pass; grid pathfinding has zero issues. Current text, writing wall and plan follow the placements. Next: walk it in VR and record the first missed encounter, tiring gap or transition without a reason to continue. No commit or push requested.

## Larger jars and a physical ruin · 16 October 2026

The [plinth and physical ruin review](iterations/2026-10-16-plinth-and-physical-ruin/index.html) enlarges the four slow lavender/coral jars to 1.04 m across and 2.30 m glass height, with rounded shoulders, pale lids and a shared 0.4 m plinth. The bank moves to clear viewing floor at (4,2); source paths and eight-second hold remain. The ruin's inward-facing fluted drums are corrected. Its installed scene now uses 116 rigid stones: 32 fixed foundations, 84 loose. ONE STONE draws out and releases a support; gravity/contact move the others. VR and desktop carry work directly, and RESTORE respects held stones. Selection can pause while gravity continues. The separate museum weathering wall keeps its authored dismantling model. 33 apparatus and 28 installed-room checks pass, plus 458 retained legacy checks. Final, tutorial, plan, writing wall and registry follow the working behavior. Next visitor question: which stones should move after one support leaves, and what actually happens? Physical headset comfort/performance remain untested. The first 48-value pilot is unchanged. No commit or push requested.

## Butterflies stay with the prefab installation · 16 October 2026

The [butterfly review](iterations/2026-10-16-prefab-butterflies/index.html) replaces Entropy Workshop’s separate aisle swarm with 16 smaller monarchs attached to `prefab_disorder`. The user-curated position at (8,12) is preserved. Upright local turning corrects the old local/world look-at mismatch; independent wing phases and shallow climbs animate a bounded 4.4 × 1.45 × 1.4 m habitat above the tables. Full wing geometry stays inside; moving/rotating the installation carries the habitat. GALLERY hides and pauses the flock. The private flight RNG does not affect hybrid seeds, recipe, save or replay. 18 focused checks and 14 installed-room checks pass; native exit is clean and map pathfinding passes. Writing wall now treats butterflies as part of the prefab encounter. Other prefab maps opt in through `#butterflies:16`. Physical headset comfort remains untested.

## Four cubes before the entropy dials · 16 October 2026

The [sorting-table review](iterations/2026-10-16-entropy-sorting-table/index.html) adds a tube and four fixed-site pickable cubes to Entropy Workshop at (13,9), beside the existing sixteen-site bench. DROP FOUR delivers one kept balanced batch; ADD DIVIDER changes one to four compartments and waits indefinitely for sorting. Every compatible colour pattern is pictured, with HERE marking the current one. The alternating example gives 6, 4, 2, 1; sorting separated halves gives one at two boxes. No replacement draws or automatic sorting occur. 47 model/interaction checks and 19 installed-room checks pass; map pathfinding passes and the web writing wall exposes the artifact. Tutorial, final, artifact list and plan connect this concrete encounter to the larger apparatus. The table has no persistent save; record colours and dividers for reconstruction. Existing bench KEEP/REPLAY and first 48-value pilot remain. Next human check: predict which pictures survive a divider, then produce WAYS one with two boxes and explain why. Physical headset comfort and learner understanding remain open.

## Slower lavender and coral columns · 16 October 2026

Palle found the mixing too fast and asked for a queer palette. The [revised column comparison](iterations/2026-10-16-slow-lavender-columns/index.html) runs the same seeded paths at one-quarter speed: the step interval is 0.48 rather than 0.12 seconds, and 180 seconds exactly reproduces the earlier 45-second positions. Lavender (#b49af7) and warm coral (#f58b91) replace red/blue in the full-size columns. Neutral glass and bases, eight-second inspection hold, PAUSE/RESUME and RESTART remain. Current texts and panel match the palette and timing. Existing apparatus and actual-room checks pass (49 + 43); native start/three-minute views were inspected. Headset colour legibility remains open. The original hand-sized jar keeps its original palette.

## Four column beginnings keep mixing · 16 October 2026

The [mixing review](iterations/2026-10-16-column-mixing/index.html) extends the full-size columns in Entropy Workshop. Approaching starts an eight-second inspection hold, then four separately seeded bounded walks continue indefinitely. PAUSE/RESUME and RESTART sit on the existing side panel. Starting coordinates match the previous still specimens; both readings now follow visible positions. No shared endpoint, bead collisions or heat model is imposed. At 45 seconds the retained run's height readings span 0.946–0.961 bits and later fluctuate. 49 apparatus and 43 installed-room checks pass. The review retains native frames and exact coordinates at 0, 15, 45, 90 and 180 mixing seconds. Final, tutorial, writing wall and plan follow the new behavior. Whether a person can still identify a column's beginning remains the next reading test. Hall placements, original shakeable jar, prefab investigation and first 48-value pilot remain unchanged.

## NEXT belongs to the table · 16 October 2026

Palle asks for the shelf controls to become a protruding appendix with one NEXT button. The installed version now has a joined tabletop extension and an upward-facing rectangular button. The standalone learner study keeps its research controls; the hall keeps its shared-seed behaviour and location. Native evidence: `iterations/2026-10-16-shelf-table-control/`.


## Entropy columns at body scale · 16 October 2026

The [column review](iterations/2026-10-16-entropy-columns/index.html) replaces the prepared tabletop jars with four two-metre glass columns in Entropy Workshop. Every original coordinate and both measurements remain unchanged; only display scale and materials change. Round non-emissive beads, neutral bases and thin collars keep the styling restrained. The bank faces the quieter entrance wall; a separate side panel carries readings. 43 apparatus checks and 30 actual-room checks pass, including front/rear standing space. The map pathfinder passes. The live shakeable jar and prefab investigation remain; headset legibility and comparative reading await a person. Two-hall roles and the first 48-value pilot are unchanged.

## Four assignments enter Random Definition · 16 October 2026

The tutorial shelf from 15 October is now registered as `randomness_tutorial_shelf`, beside the colour window at source cell (8, 13), facing 180 degrees. One retained value changes position, scale, radians and hue together. A museum adapter follows the shared hall seed and restores saved studies; the 26-line learner program remains unchanged. The writing wall tags the shelf Tutorial only. The final route, selected contour edition and first 48-value pilot are unchanged. Native integration verification is recorded in `iterations/2026-10-16-tutorial-shelf-in-hall/`.

## Contour print retained; blur study deferred · 16 October 2026

Palle chooses to keep the contour print for now. The [current chapter and PDF](iterations/2026-10-16-contour-selection/index.html) use the existing abacus contour capture. The tonal study remains archived for later; its reading question is deferred. RAND image comparison stays omitted. Prose, room order, arrival wall works and the first 48-value pilot are unchanged.


## Two entropy halls, two kinds of work · 16 October 2026

Keep `Random_Entropies` as **Entropy Types**, prepared comparisons of distinct questions, and `Random_Entropy` as **Entropy Workshop**, interventions into what those measures miss. The [review](iterations/2026-10-16-entropy-reading/index.html) includes the shared curation decision, revised texts and native views. Types gains a full-size wall chair and a simpler min-entropy comparison: one colour question, sixteen equal-sized balls, pink/teal counts 8/8, 12/4, 16/0. Workshop gains four prepared jar states beside its live jar; core/shell order is missed by height and revealed by radial regions. Prefab seed/gallery/replay remain there; Point is unchanged. 89 apparatus checks, 183 Types-room checks and 18 Workshop-placement checks pass; both pathfinders pass. These are technical observations, not learning evidence. The next trial asks whether the second hall produces a new question rather than repeats a definition. The first 48-value seed pilot remains unchanged.

## Keep the abacus tone; retire the RAND pair · 16 October 2026

Palle declines the RAND-number comparison and redirects attention to capturing blur. The [tone study](iterations/2026-10-16-tone-and-trace/index.html) finds the softness already present in the raw Godot capture; the contour filter discarded its gradients. A continuous-tone mode now preserves that accumulation without added blur or altered targets. Native raw and old contour captures reproduce exactly; 14 checks pass. The new seven-page chapter uses the tonal abacus and omits the RAND image pair, while retaining its prose and the 435 reference. Prose, hall order, wall arrival policy and first 48-value pilot remain. New tonal treatment awaits reading; the prior RAND-legibility question is closed.


## Baseline and consequence in Random Definition · 16 October 2026

The [before/after edition](iterations/2026-10-16-before-and-after/index.html) keeps the original wall/book captures and adds two scripted native continuations: 48 abacus segments per row, and 33442 kept while two rows descend. Both reconstructed baseline images match the originals pixel for pixel; 32 native checks pass. The eight-page PDF fills the former page-5 gap with the RGB transformation and enlarges the return schematic. The final clarifies Gaussian resemblance versus uniform targets, while retaining the opening and release ending. MOVE / KEEP remains restored; order and first 48-value pilot stay fixed. The next reading tests whether the kept number is visible before its caption explains it. This visual strategy is local to this hall, not a template for the spine.


## Coffee, glass and visible chances · 16 October 2026

Random Entropies now has five hollow cups on one shared table, with a donut and plate. The same prescribed milk fraction appears at different mixing stages; the swirls remain separate from the five thermal snapshots. Five panes progressively blur the same chair, with explicit identity/colour-plus-arms/colour/colour/no-detail records. The last example exposes min-entropy with numbered tickets: one winning ticket out of 16, fifteen out of 16, and fifteen out of 30. Three doorways now belong to one solid wall; the central route remains open. Tutorial, final, writing-wall notes and plan follow the installed comparisons. 179 apparatus checks and 181 room checks pass; headset appearance and understanding await a person. The seven-stop order, research wall and first 48-value pilot remain. [Current views, explanation and evidence](iterations/2026-10-16-entropy-coffee-glass/index.html).

## The book is another recorder · 16 October 2026

The [reader revision](iterations/2026-10-16-book-as-recorder/index.html) preserves the earlier critique and chapter, shortens the gesture passage, moves measurement detail into a note, and ends with release and return. Its reference groups three verified values into RGB; its small return diagram is explicitly schematic. Shared wall/book PNGs remain unchanged and the page still begins with ten seeded rows before filling.

Palle explicitly chose restoration of MOVE / KEEP. Its saved placement is active again; 28 actual-hall checks pass, including visibility, seed binding, floor approach and synthetic desktop release/return. The writing wall, final reading plan and idea bank retain the change. Full headset interaction and the literary effect still need a person. The five-stop order and first 48-value pilot remain. Compare the complete texts, then the ending with/without the diagram.



## A physical wall for explanation and visitor notes · 16 October 2026

Random Entropies has an independent research wall at (9,13): a solid partition with framed interpretation, a replaceable image, a usable whiteboard, two markers, an eraser and three movable handwritten notes. Ink and pinned positions autosave locally and return on a later visit. Three author-selected finishes preserve the notes. The smaller entropy captions also have frames and their own floor-to-top supports. The image is provisional; the frame is ready for the separately developed illustration. 25 native interaction/persistence and 131 actual-room checks pass; human writing and headset comfort remain open. Seven encounters stay in the same order, and the 48-value bench remains the first pilot. [Current wall, usage and evidence](iterations/2026-10-16-research-info-wall/index.html).

## Ten seeded rows; photograph the full page · 16 October 2026

The RAND-inspired page in Random Definition now starts with ten rows from 435 (100 draws), continues from draw 101 and restores those rows on reset. The wall/book camera waits until all 28 rows are filled and settled; the abacus and Geiger still keep arrival states. A waiting label makes the delay visible. Per-image timestamps distinguish the moments. The earlier invisible numerals were present but too faint for the print filter; that contrast comparison is retained, while the selected edition now waits for full ink. See [the wall/book edition](iterations/2026-10-16-arrival-wall/index.html).


## Arrival wall and book share their images · 16 October 2026

Random Definition now photographs the abacus, falling page and Geiger automatically on hall arrival. The author chose the actual arrival state: no touch, extra draw or staged trace is supplied. Three framed works use the saved PNGs; a selected visit supplies identical images to the new chapter and seven-page PDF. Cameras/crops/omissions are in book_images.json; later visits keep separate records. Geiger marks and needle now share a radial scale in radians. 47 native and 13 real-hall checks pass; headset performance and reading still need a human trial. [Comparison, edition and rebuild instructions](iterations/2026-10-16-arrival-wall/index.html). The earlier staged image study remains available.

## Entropy states are visible together · 16 October 2026

The seven ordinary-entropy encounters now use simultaneous versions and compact wall explanations. Interfaces and freestanding consoles are removed. Chair inventories/assignments, glass channels and pit rules can be compared together; three cups are timed snapshots; two door pairs repeat different rules while the central passage stays open. Tutorial, final, writing-wall notes and plan follow the installed arrangement. Native apparatus and actual-hall checks pass; human comparison and headset reading remain open. The 48-value bench is still the first pilot. [Current views and evidence](iterations/2026-10-16-entropy-visible-states/index.html).


## The window and falling page share the 435 sequence · 16 October 2026

The RAND-inspired page now truncates the same randf() sequence as the colour window into five-digit groups, retaining leading zeros. Its folio is an independent address and consumes no draw. The first group is 49811; the staged illustration holds 84288. The final adds one sentence connecting colour and digits; the tutorial describes the conversion, and the illustrated edition and PDF are rebuilt from new captures. Native tests compare actual RGB channels and page arrivals across four seeds, resets and folio changes. [Current edition and receipts](iterations/2026-10-16-book-image-study/README.md).


## Illustrated chapter available as PDF · 16 October 2026

[Eight-page PDF](iterations/2026-10-16-book-image-study/illustrated-chapter.pdf): the Random Definition chapter with its three selected illustrations, the verified first ten values from 435, and a separate generated illustration proposal. The proposal removes cabinet frames and retains paths, a held number and intervals; it is explicitly not an experimental data record. The editable PDF builder, image prompt and verification receipt are kept in the image-study folder. All pages were rendered and inspected; number values and captions were checked. The chapter and map remain unchanged.


## Smaller shared panels for the seven entropy encounters · 16 October 2026

The large boards and cabinets in Random_Entropies have become one 0.94 × 0.50 m panel beside each installation. Title, one question, current state and a short reading share the plate with PREVIOUS/NEXT and at most one extra action. Prepared comparisons replace visitor KEEP/REPLAY controls; the research capture/restore API and earlier receipts remain available. Four small floor numbers replace the description wall's separate plaques. The map stays directly after Random_Definition.

[Native before/after review](iterations/2026-10-16-entropy-quiet-panels/index.html) includes standing-eye views and panel close-ups. Tests check state cycles, returning to baseline, continuous cooling, text bounds, unchanged measurement models, side-panel standing clearance and centre sightlines. Current tutorial, writing-wall notes, registry and plan follow the new controls. The final changed only door/time control references. Headset reach and readability still need a human trial; the first 48-value pilot is unchanged.


## Selected illustrations placed in the chapter · 16 October 2026

The author accepted the Random Definition images. [The illustrated chapter](iterations/2026-10-16-book-image-study/illustrated.html) presents the full current final with three selected fragments: abacus outline, retained-number page in ink, Geiger outline. Captions are brief; the chapter view has no filter controls. The comparison and no-image trial remain linked. The curation manifest records acceptance; prose and room order are unchanged. The three assets, captions and exact prose preservation are verified. General book-pipeline integration remains separate from this chapter edition.


## Book images without fixing the whole room · 16 October 2026

[Random Definition image trial](iterations/2026-10-16-book-image-study/index.html) compares outline, hatching and solid ink from actual artifact captures. The [reading edition](iterations/2026-10-16-book-image-study/reading.html) places three fragments in the unchanged final, with a no-images comparison. The provisional selection uses outlines for the abacus and Geiger, ink for the retained number page. `commons/maps/Random_Definition/book_images.json` ties stable artifact IDs and exact passages to framing, treatment, omissions and reading questions; camera/state receipts and source hashes make the trial rebuildable. Filters render 18 variants; source text and local assets are verified. This is a separate image trial, not a reader-tested edition or a change to the room. Next: judge which relation each image makes available, and where it overdetermines the imagined world.


## Ordinary-object entropy room moved beside Random Definition · 16 October 2026

For immediate testing, the randomness route is now Random_Definition → Random_Entropies → Random_Entropy → Random_Remove. The game sequence, authored hall list, book order, museum plan and generated strip agree. The new room's explicit exit continues to Random_Entropy; existing relative exits follow the sequence. Restart the running museum to load the updated order. Seven encounters and their internal order are unchanged.


## Seven everyday-object entropies · 16 October 2026

Random_Entropies is a new map after Random_Entropy: normal-scale Shannon and Boltzmann chairs across a low divider, four chair descriptions beyond a wall, a driven doorway, cooling cup with steam, frosted chair and a large ball among small ones. Seven independent artifacts use rectangular controls and per-station KEEP/REPLAY. Room, final and tutorial have the same order; writing-wall magnets carry specific tutorial/final notes.

[Native room, texts and evidence](iterations/2026-10-16-ordinary-entropies/index.html): 110 apparatus and 62 actual-hall checks pass with native exit 0. Each gauge declares its variable, macrostate, channel, rule or thermal boundary. The description wall reveals a short recipe for a visually irregular arrangement. The door contrasts contraction with a driven expanding map; neither ordinary closing nor two diverging leaves alone establishes dynamical entropy. The ball pit separates perceptual size from explicit sampling weights.

Visual and room review corrected standing clearance, control/sign obstruction, frosted-pane opacity and the door magnet's floor footprint. Seven magnets and all six walking legs load in the web editor. The 968-word final is a situated draft, not evidence of a learner's response. Next trial: compare rearrangement with changed colour shares, then carry that distinction to the neighbouring count of arrangements. Headset comfort/performance and independent student reconstruction remain open. The original entropy hall, hybrid collection and first 48-value pilot remain in place.


## Following a part, then carrying a question onward · 16 October 2026

The prefab ghost now compares both tables at the unchanged midpoint and follows the CRT screen through a six-second joining action. FOLLOW PART adds a reversible identity frame and label. Eleven paired checkpoints retain actual head/outside images, source part transforms, seed/stage, complete replay state and source-checked tutorial/final excerpts with authored questions. Those words float above the moving head; they describe the proposed encounter, not a learner's inner experience. The eye view excludes the annotation layer.

After completion it restores the prefab baseline and walks about 5.86 metres to the Shannon ledger, the main route's first artifact. A twelfth pair records arrival. Floor support, body clearance and visitor cancellation are checked; a destination obstruction or missing artifact stops continuation. An initial stance too close to the entrance wall and false obstructions at tile seams were found and corrected. Arrival supplies a next question; a ledger-specific interaction adapter remains to build.

[Playtest, tutorial and paired hall views](iterations/2026-10-16-ghost-prefab-playtest/index.html): 48/48 apparatus/reconstruction, 35/35 existing rehearsal and 49/49 actual-hall checks pass, native exits 0. Eye-view inspection led to the identity cue, held comparison, slower joining, revised standing position and outside-camera framing. The tutorial and task plan now name that observation loop and its remaining uncertainty. Next human trial: interrupt, hide the marker, choose another part, and describe where a relation becomes unclear or worth revising. Headset comfort, physical hand interaction and human learning remain untested. The first 48-value pilot and six-stop room/final order remain in place.

## Seeing from the ghost's head · 16 October 2026

The prefab rehearsal now records an eye camera attached to its moving head and an outside camera in the same world. Four paired checkpoints retain PNGs, head/camera poses, seed, stage, complete artifact state and hashes. The desktop preview has COMPARE CAMERAS, SAVE BOTH VIEWS and OPEN CAPTURES; museum WATCH records the same checkpoints without taking the visitor's camera.

[Side-by-side actual-hall and preview captures](iterations/2026-10-16-ghost-head-camera/index.html): 47 camera/capture checks, 35 rehearsal checks and 18 hall checks pass. Tests include rendered pose alignment, fresh state reconstruction, failed writes, takeover and scene cleanup. An initial camera-notification lag was found visually and repaired; temporary reconstruction fixtures now finish their initial physics updates before disposal, resolving a test shutdown crash. The eye view exposes a choreography question: attention to the right-hand hybrids can leave the left-hand comparison outside the image. Change a gaze target or pause and compare before changing the writing. Monoscopic synthetic rehearsal is not evidence of headset comfort or comprehension. The six-stop room/final order and first 48-value research pilot remain in place.

## A visible ghost-student rehearsal · 16 October 2026

The optional prefab bench in Random_Entropy now hosts a holographic student with two articulated arms and fingered hands. WATCH, or six seconds watching from the front before using a control, begins a nine-action rehearsal: originals, separation, hybrids, another seed, an intermediate KEEP, changed conditions and REPLAY. Visitor input takes over; completion or WATCH-stop restores the starting arrangement. The ghost's save pointer and collection are separate from the visitor's.

[Recording, method and receipts](iterations/2026-10-16-ghost-student-pilot/index.html): 35 rehearsal checks, 16 actual-hall checks and the existing 104-check gallery suite pass. Current tutorial excerpts/hashes, before/after states and failed actions are recorded; missing text and a disconnected control fail visibly. Native rendered review led to three repairs: stale slider guidance, midpoint roundoff, and arm-segment scaling. A fresh instrument reconstructs the kept ghost form. The actor uses synthetic pointer events through real control handlers; no headset hand collision, haptics, Quest performance or learner understanding is claimed.

Next: let a person interrupt or continue the demonstration and record whether it invites an experiment or prescribes too much. Change one pause, gesture, control or passage, then compare. The reusable body can support other explicit adapters; full hall travel and autonomous exploration are not built. The 48-value bench remains the first research pilot, and the six-stop room/final order stays unchanged. The tutorial, research plan/card and artifact guide identify this as an encounter rehearsal rather than printed-code reconstruction.

## A gallery of kept hybrid arrangements · 16 October 2026

KEEP now adds each prefab experiment record to a persistent collection. GALLERY displays four saved sets at a time, each with its seed and slider stage; PREVIOUS/NEXT browse more, numbered REPLAY restores any entry at full size, and BACK preserves the live experiment. Each entry contains all four forms and fifty meshes. Earlier records remain usable; the previous latest KEEP is brought into the gallery.

[Native gallery and receipt](iterations/2026-10-16-hybrid-gallery/index.html): 104 apparatus checks and 32 actual-hall checks pass, covering exact previews, older/intermediate selection, fresh-instance persistence, paging, physical controls and safe rejection of unavailable records. Tutorial, wall, registry and research card/plan describe this loop. Next human question: compare two seeds at the same stage, follow a recognisable part, and describe what makes one relationship worth keeping. Headset comfort remains untested. The six-stop final route and first 48-value pilot remain in place.

## Seeds change the hybrid assemblies · 16 October 2026

The optional Random_Entropy prefab study now generates new hybrid memberships, joining order, attachment faces and turns from its seed. Four pads hold changing forms assembled from fifteen small bundles; every one of fifty meshes remains, and every hybrid has at least three donors. The original → separated → hybrid slider stays reversible. KEEP/REPLAY stores exact targets and memberships; yesterday's fixed-hybrid records and earlier separation records remain compatible. A new seed after legacy replay switches explicitly to the seeded generator.

[Seed comparison and receipt](iterations/2026-10-16-seeded-hybrids/index.html): 81 apparatus checks and 25 actual-hall checks pass. Thirty-nine sampled seeds produce thirty-nine distinct membership sets, ignoring pad permutations. Same-seed reconstruction, int64 boundary cases, old/new disk replay and the physical seed button are checked. Tutorial, wall entry, registry and research card/plan now describe the installed behavior. Next human trial: keep two variants at the same stage, follow a part changing roles, and ask whether a new use becomes imaginable. Headset testing remains open. The six-stop final route and first 48-value pilot stay in place.

## Prefab parts enter new relationships · 15 October 2026

The optional Random_Entropy prefab study now moves reversibly from originals (0), through separated parts (0.5), to four mixed-source hybrids (1). The left comparison scatters whole objects and returns them intact; the right reuses every one of fifty meshes once, retaining original materials and fitting each hybrid uniformly to its pad. Each new form has at least three donors, named on its label. Joining rules are authored; seed changes affect separation only.

[Native review and receipt](iterations/2026-10-15-prefab-hybrids/index.html): 69 apparatus checks and 23 actual-hall checks pass, including backward traversal, floor clearance, stored membership/target poses, fresh replay, physical presets, and version-one record compatibility. Tutorial, optional wall magnet and research card/plan follow the installed behavior. Human recognition, a changed-graft experiment and headset use remain open. The separate matched-base-motion refinement remains proposed. The six-stop final route and first 48-value pilot continue.

## Entropy becomes a recurring research thread · 15 October 2026

Palle supplies a proposal connecting information, dynamics, sustaining conditions and consequential difference across Ada. The [framework](research/entropy/README.md) distinguishes each quantity and its assumptions. An optional observation card fits the existing writing-wall Research loop; ER0–ER7 stages work across nine current maps. The [receipt](iterations/2026-10-15-entropy-across-maps/README.md) preserves the proposal, current source/plan audit and twelve exact calculation/source checks.

Key findings: the movement archive retains the full samples even though its seed channel is only 0–999; Noise REMAP reuses source values rather than recovering them from black pixels; Random Return permits release; the prefab comparison changes draw assignment as well as grouping. Its matched-motion follow-up remains proposed. Physical entropy production and KS entropy are not inferred from visual disorder or diverging finite traces. The 2023 proposal, current runtime, canonical hall texts, six-stop Entropy order and first 48-value pilot are preserved. Next: human Entropy encounter evidence, then the planned short-history signal witness, before expanding to record/seed and raw/clip/remap comparisons.

## Prefab disorder compares whole objects and mesh parts · 15 October 2026

Palle chooses both modes for the disorder slider. The [native comparison](iterations/2026-10-15-prefab-disorder/index.html) shows four actual gallery prefabs—box, monitor, stool and microscope—with the same fifty mesh parts on each side. One side preserves each assembly; the other moves its mesh parts independently. Zero restores the original forms, seed 435 supplies retained offsets, and KEEP/REPLAY reconstructs every mesh transform in a fresh scene. The control is geometric disorder, not an entropy reading.

Installed at Random_Entropy grid (13,3), facing the entrance, as an optional tutorial encounter. The writing wall and tutorial include it; the six-part main room/final order stays unchanged. Native apparatus checks pass 36/36 and actual-hall checks 17/17. Approaches and slider height are checked; headset comfort, Quest performance and human recognition still need observation. A productive next test is to find which relationship must remain for a displaced object to stay recognizable, then revise the movable grouping. The 48-value bench remains the first research pilot.

## Entropy adopts a laboratory form · 15 October 2026

Palle asks for the Shannon–Boltzmann setup to draw on the surreal-lab gallery. The [before/after review](iterations/2026-10-15-entropy-lab-form/index.html) shows glass-sided specimen trays, luminous A/B occupants and paired round gauges on a steel cabinet. The gauges follow the existing quantities; no ornamental randomness enters the experiment. The 25-line model and saved-state format are unchanged. Short tutorial/final descriptions now match the instrument, while the adopted hall/text sequence stays in place. Native apparatus and extracted-model reconstruction each pass 55 checks; the actual hall passes 16 checks. Headset and human-reading evidence remain open.

## Rhino structures become a Godot collection trial · 15 October 2026

Four separately registered studies translate Palle's Rhino scripts into cylinder height/radius, sphere height, layered pipe connectivity/displacement and branching trees. The [visual review](iterations/2026-10-15-rhino-random-structures/index.html) compares zero/full geometric range using retained draws. `commons/artifacts/random_structure_studies/preview.tscn` provides range, seed increment and KEEP/REPLAY controls. Records retain raw uint32 draws for exact reconstruction.

Native checks cover geometry, pipe endpoint transforms, boundary-safe neighbours, independent parameter changes and saved reconstruction. The source's overlaid rows, pipe indexing and traversal-dependent branch radii are corrected with the choices recorded. These are collection prototypes; no existing hall placement or canonical text is changed. Headset and learner trials remain open. The 48-value bench remains the first research pilot.

## Entropy: two compartments built and observed · 15 October 2026

The two-compartment experiment now stands at Random_Entropy grid (8,9), between the jar and displaced-point enclosure. Fixed 8 A/8 B counts hold Shannon colour entropy at one bit while S_B/k_B = ln Ω changes with the number of A on the left. Manual exchanges, same-k permutations, seeded swaps and exact KEEP/REPLAY make the distinction testable. The jar now names H(colour | six height bands), with a 0–1 bit range and no irreversible/absolute-maximum verdict.

The [trial receipt and facing texts](iterations/2026-10-15-entropy-compartments/index.html) retain the observed sweep, unchanged-reading comparison, seeded decreases, saved state and verification boundaries. Production and fresh printed-code scenes each pass 52 checks; the actual hall passes 16 placement/control/render checks. These are native scripted results, not headset or human-learning evidence. The tutorial isolates 25 model lines with declared display/control dependencies; the complete earlier lesson is preserved as counts-and-neighbours.md. The approximately 1,250-word final follows ledger → jar → compartments → displaced points → ruin → signal room, also stored in the writing wall. Other encounters remain optional.

E1 and the multiplicity part of E3 are implemented; E4/E5 have native evidence and revised texts. Editable jar partitions/radial shells, conditional history, a thermal model and independent human trials remain open. The 48-value seed bench remains the first research pilot. No cross-hall transfer or validation of QFEP is claimed. Next: let a visitor compare two different same-k arrangements, preserve the difference and decide whether an adjacency measure or another question is worth building.

## Entropy expanded as a foundational research hall · 15 October 2026

Palle clarifies that Random Entropy must explore Shannon and other forms of entropy because it is central to the research. The [research brief and E0–E6 task plan](course/text-plans/Random_Entropy/research-brief.md) expands the short counts lesson into a staged inquiry: marginal measurement, conditional prediction, spatial partitions, Boltzmann/Gibbs multiplicity and the choice of what to preserve or reopen. Min-entropy, compression and belief models are distinguished rather than merged into one entropy gauge. The preceding tutorial progression and research hall plan now point to this scope.

The two supplied texts and their provenance are retained in the [comparison receipt](iterations/2026-10-15-entropy-research-map/README.md). Their current QFEP direction keeps observations, inferences and methodological proposals distinct. Mathematical fixtures check two cyclic prediction examples and enumerate all 12,870 configurations of a sixteen-site occupancy model; these are not game observations. Source inspection finds the existing jar computes a weighted height-bin Shannon measure while its display/registry still overclaims irreversibility and maximum entropy. Repairing those labels is required work, not silently marked complete.

Next: correct the jar's account, build the small Entropy entrance and conditional witness, then add the required partition/multiplicity comparison with explicit physical-model limits. A new final and adopted spatial route should follow working apparatus and observation. Canonical tutorial/final, placements and runtime remain unchanged in this planning pass. The 48-value seed bench remains the first research pilot. Testing the declared inherited “ghost student” code can establish reconstruction completeness, while human learning and headset experience require separate evidence.

## Randomness tutorials compared with Nature of Code · 15 October 2026

Palle asks whether the randomness sequence can develop a cumulative tutorial progression. The [comparison and task plan](course/randomness-tutorial-progression.md) reviews all fourteen current tutorials and proposes eight small core builds, with six application or advanced workshops at their existing positions. The central continuity is a recognisable value, mapping and state that acquire new consequences. The [source audit](iterations/2026-10-15-randomness-progression/README.md) retains source hashes and listing sizes; thirteen chapters share identical PointBody code, while the step from Definition's 26-line listing to Entropy's 142 includes substantial display and control support.

Next proposed implementation: retain the shelf's values in a small Entropy study, classify and count them, then rearrange a copy before introducing the entropy measure. This is a proposed transfer; current Entropy still creates a separate categorical sample. Observe a learner across those two lessons before rewriting the rest. The room/final route, artifacts, canonical tutorials and particle branch are unchanged by this comparison. The 48-value seed bench remains the first research pilot. The plan distinguishes implementation checks, experiment-cycle evidence, specified transfers and physical VR trials; no new learner result is claimed.

## Randomness introduction reduced to a four-object shelf · 15 October 2026

Palle asks for a small part of the code to become the introductory tutorial: direct randomness into moving a point on a line, scaling a point, rotating a cube and changing a sphere's colour. Palle confirms all four should appear together, reading the same stored number. [Give a number somewhere to go](../../commons/maps/Random_Definition/tutorial.md) now prints one 26-line script and a concrete scene-assembly guide, with 770 prose words. The core is four property assignments. A local generator starts from 435 and retains eight draws; NEXT reads, REPLAY returns to the beginning. The first comparison changes only the X range.

The [runnable desktop preview](studies/randomness-shelf/preview.tscn), editable shelf, inherited rectangular controls and optional recording helper are supplied separately. KEEP/LOAD preserve exact values, index, X extent and observations without making the archive implementation the introductory lesson. All 39 checks pass using the exact printed script in fresh scenes; a Godot preview was rendered and inspected. [Revision and evidence](iterations/2026-10-15-randomness-tutorial-shelf/README.md) retains the prior tutorial and plan. The full [abacus reconstruction](../../commons/maps/Random_Definition/abacus-reconstruction.md) remains an extension; its builder and verifier now target that file. Entropy's incoming prose is updated; its code is unchanged.

The 48-value seed bench remains the first research pilot. The eight-value shelf is a learner study, not yet a placed museum artifact. Its eventual installation needs registry/shared-seed integration and a floor placement decision. Canonical final, abacus, room and magnets are unchanged. Next: observe a learner building the small program, collect the same-index comparison and independent reconstruction, then choose one further change from the evidence. Headset usability and whole-room performance remain separate checks. The [new text plan](course/text-plans/Random_Definition/tutorial.md) is the current teaching direction; the larger abacus loop below records the preceding revision.

## Definition's abacus tutorial now closes the experiment loop · 15 October 2026

At Palle's request, [Touch and be moved](../../commons/maps/Random_Definition/tutorial.md) now gives the complete baseline → one change → observation → save → reopen/replay → independent reconstruction → further proposal cycle. Row 2 at ten seconds and row 3 at five seconds traverse the same eight steps and leave the same 96 marks. All four printed apparatus files still match the current artifact. A fifth, reconstruction-only notebook supplies save/load/pause shortcuts and named recordings with questions, predictions and observations; the installed room retains its single REPLAY button.

The printed-code round trip found slight numeric changes in Godot's JSON parsing. Notebook files now carry a readable record and a packed copy for exact state restoration. Fresh-scene loading, phase continuation, replay and negative recipe checks pass among 25 workflow checks. Existing ink, hand and shared-hall-seed tests were rerun and pass. [Revision, source, logs and commands](iterations/2026-10-15-abacus-experiment-loop/README.md) preserve the evidence and before snapshots. Current chapter: 1,336 prose words, 528 nonblank code lines. The [text plan](course/text-plans/Random_Definition/tutorial.md) points to this iteration's builder; earlier builders are historical.

Stale MOVE / KEEP availability and optional-window RANDOM instructions are corrected; the latter also loses its obsolete fixed placement instruction. The 48-value bench remains the first research pilot, distinct from the abacus's 48 coordinate pairs. Canonical final, room, writing wall and literary candidates are unchanged. Next: observe the comparison in a headset and have another person reconstruct it from the chapter. Automated checks do not supply either result. Preserve a report of no meaningful difference, and let the observation justify the next apparatus or text change. The generated museum-plan lag and removed MOVE / KEEP placement remain separate work.

## Continue randomness with today's changed Definition · 15 October 2026

Palle returns the focus to the randomness maps and asks for the status of Random Definition's tutorial after today's artifact and final-text changes. The current local Definition is a changed research encounter: the five-row hand-following abacus and retained ink, falling RAND digits, a shared starting seed of 435, simulated Geiger gaps, and the distinction between changing a value and changing its permitted consequence. The current local final is *What chance is allowed to do*. The revised sixth literary trial remains a separate candidate; it has not silently replaced that file. Commit `a591c1128` preserves the local final as a draft, without adopting its unresolved room dependencies.

The current [tutorial](../../commons/maps/Random_Definition/tutorial.md), *Touch and be moved*, already reconstructs the five-row abacus. This status inspection confirmed that all four embedded student files match the current artifact sources. Using the existing builder's convention, it has 1,335 prose words and 457 nonblank code lines. Retained logs report ink, hand, reach and shared-seed checks passing; this inspection did not rerun them. Physical headset comfort and independent reconstruction remain unobserved. The next [Entropy tutorial](../../commons/maps/Random_Entropy/tutorial.md) already acknowledges the moving-sphere record and explicitly makes a new categorical sample.

Next tutorial work: make the baseline → one change → observation → preserve → reopen/replay → independent reconstruction → further change cycle executable for the learner. The installed abacus has only REPLAY; saving/loading and resuming a paused restored state need explicit reconstruction instructions, not implied room buttons. Correct the unqualified MOVE / KEEP instruction while its saved placement is removed. Repair the optional colour-grid extension's stale closing reference to RANDOM (the hall control is SEED +1). Keep the 48-value seed bench as the first research pilot and distinguish it from the abacus's 48 coordinate pairs. The tutorial need not reconstruct every encounter in the final. No tutorial prose, artifact, room placement or literary adoption is changed by this status entry.

## Voice sampled across three other maps · 15 October 2026

At Palle's request, [three side-by-side passage trials](iterations/2026-10-15-voice-across-maps/index.html) apply today's encounter-led, scientific and poetic voice to cloth, noise and cellular automata. The new passages are 270, 277 and 279 words. Full original snapshots and exact excerpts are retained. Each comparison includes a separate editorial judgement, a possible loss and a reading question; no reader preference is recorded.

The strongest provisional candidate is Noise One, where one discrepancy between relief and colour can carry the explanation without an immediate code block. Cloth gains a pause around the missing support; its omitted wall comparison remains valuable. The bridge trial is less certain: its original gold-frame passage is already strong and may be better left intact. Current map tokens, sequence neighbours, generated museum placements and active scripts were inspected. No runtime claim or canonical adoption follows. Original final texts, tutorials, room order and writing walls are unchanged. Next: read the paired passages before opening their notes, then decide which approach earns a whole-chapter trial.

## Voice strategy documented in the blog · 15 October 2026

At Palle's request, [The Paper Does Not Record the Hurry](../blog/2026-10-15-the-paper-does-not-record-the-hurry/post.md) records today's movement from narrator experiments to a local “we”, the Bachelard tension, attention supported by particular instruments, the limits of the first five walkthroughs, the returned form studies and the small sixth-trial revision. It is available locally at `/blog/2026-10-15-the-paper-does-not-record-the-hurry`. The post uses a retained scripted ink-wall preview and links to the complete comparison. It distinguishes chosen voice, editorial proposals and pending reader response. No chapter or room change follows from this blog publication.

## Sixth trial revised for comparison · 15 October 2026

Palle requested small corrections and a stronger RAND-to-Geiger transition while keeping the opening and ending. The [complete side-by-side reading](iterations/2026-10-15-sixth-randomness-trial/compare.html) pairs the intact 1,109-word original with the 1,181-word revision. The first paragraph and final three paragraphs remain exact, and the five-stop order is unchanged. [Revision notes](iterations/2026-10-15-sixth-randomness-trial/revision-notes.md) and exact before/after replacements retain the changes.

The held digits now leave their production out of view; Geiger introduces 435 as another kept number, used as a starting input. Short explanations cover uniform selection, seed, bits and the movement-record transformation. Withdrawal precedes REPLAY; holding Out / Back joins its existing cycle. Next: read the full revision and judge whether the transition earns the cabinet and the middle becomes easier to follow. MOVE / KEEP placement remains conditional. This comparison does not adopt a canonical chapter or change the room. The 48-value bench remains the first runtime pilot.

## Supplied sixth complete chapter · 15 October 2026

Palle returned [*What chance is allowed to do*](iterations/2026-10-15-sixth-randomness-trial/index.html), a 1,109-word complete trial whose subtitle reports composition after reading A–E. The original is retained byte for byte beside a separate [editorial and technical reading](iterations/2026-10-15-sixth-randomness-trial/assessment.md). It is distinct from the existing local F, *How long a result remains*, and the five short form studies. No adoption or independent reader result is recorded.

The candidate connects the opening bead's return and retained ink to the final sphere's return and unmarked release. The middle follows what different records retain and omit. Promising details include “The paper does not record the hurry” and the reversal from numbers giving a hand a journey to a journey giving instruments a number. Next: assess the whole chapter and make only warranted corrections. Out / Back already cycles before it is held; MOVE / KEEP remains removed from the saved room; uniform selection, seed, bit and hash need brief first-use help. The supplied prose is unchanged. The existing room/final order and 48-value first runtime pilot remain in force.

## Returned forms widen the experiment · 15 October 2026

Palle supplied five short works: performance, investigation, logical comedy, close observation and montage. The [complete return and reading collection](iterations/2026-10-15-returned-literary-forms/index.html), [office / ink comparison](iterations/2026-10-15-returned-literary-forms/contrast.html) and [editorial/technical assessment](iterations/2026-10-15-returned-literary-forms/assessment.md) preserve the originals. These are form studies, not five complete chapter responses. Their author's preference for 3 and 4 is not Palle's selection; our matching recommendation is editorial, not a new reader trial.

The [method](course/IDEAS_AND_DIVERGENT_READINGS.md) now separates form discovery from whole-chapter composition. The earlier five changed emphasis but retained a walkthrough; exploratory studies can vary coverage, narrator, sequence and scale while keeping apparatus claims accountable. The durable idea bank adds two candidates: accumulated ink loses arrival order, and a seed supplies a starting input rather than a full account of causes. Existing ideas link to the returned studies.

Next: read the office and ink studies separately before their method notes; record a concrete change of attention or a question worth taking to the apparatus, including no gain. Then conduct the technical reading and decide whether either form deserves a complete chapter. The 600–1,500-word range applies at that later stage. Canonical final, room order and tutorial remain unchanged. The MOVE / KEEP placement gap remains explicit. The 48-value bench remains the first runtime pilot.

## Ideas retained across five complete readings · 15 October 2026

Palle supplied a reading of the writer packet, then asked to save good ideas and prepare five very different complete Random Definition texts for handoff. The [five-reading collection](iterations/2026-10-15-five-randomness-readings/index.html), [two-text comparison](iterations/2026-10-15-five-randomness-readings/compare.html), [idea bank](iterations/2026-10-15-five-randomness-readings/ideas.html) and [handoff](iterations/2026-10-15-five-randomness-readings/handoff.md) are ready for reading. Five whole chapters share the selected route and current apparatus but develop through different forms. They are authored by the same situated assistant; no independent judgement or chapter adoption is claimed.

Eleven retained ideas live in `commons/maps/Random_Definition/composition/ideas.json`, with provenance, evidence, limits and next tests. The [method](course/IDEAS_AND_DIVERGENT_READINGS.md) keeps an idea available even when its draft fails. Portable notes save in the browser and export as unreviewed JSON; repository incorporation remains deliberate. The supplied reader provisionally prefers three calibration orientations, especially the abacus wall and CA support distinction; this remains separate from Palle's selection of exact passages.

The newest source check finds a public REPLAY-only abacus with uniform targets and persistent ink; Gaussian comparison is available in reconstruction code. Earlier packets remain versioned evidence. The five candidates all disclose the unresolved removed MOVE / KEEP part and require a placement decision before representing the complete walk as installed. Runtime, canonical texts and magnets remain unchanged by this literary trial. Next: collect complete-text responses before strategy notes, then a separate technical reading, and choose a coherent revision while preserving useful ideas. The 48-value bench remains the first runtime pilot.

## Evidence for a differently situated writer · 15 October 2026

The [prepared handoff](iterations/2026-10-15-independent-writer/README.md) and [reading packet](iterations/2026-10-15-independent-writer/index.html) record the supplied division of labour: situated researcher supplies encounter facts and limits; independent writer develops a complete chapter; Palle selects examples and adoption. Literary reading precedes technical critique. The [reusable protocol](course/INDEPENDENT_LITERARY_HANDOFF.md) keeps the writer's factual dossier separate from our internal orientation plan.

Palle chose **cellular automata** for the third calibration area. Three exact existing passages are nominated: five-row abacus, retained Geiger reference, and CA_ExpandingSpace's changing bridge. The captured abacus now includes the concurrently added recording wall; earlier tests are labelled as earlier evidence. Selection/refinement remains open. No independent chapter has been written, no packet sent and no canonical adoption made. Sources and a bridge render are retained. The existing MOVE / KEEP placement mismatch remains explicit: implemented code and Final tag, but removal in the saved room. Next: select/refine the calibration examples and resolve that placement before claiming the complete room encounter. The 48-value bench remains the first runtime pilot.

## Consequences can remain implicit · 15 October 2026

The latest [supplied passage reading](iterations/2026-10-15-composition-consequences/supplied-reading.txt) retains the reference, finds Geiger montage promising locally, and keeps recurrence for map development. Extended restart repetition is unadopted. The account explicitly did not finish the four chapters: record its RAND relation without calling the full-sequence test complete. The [review](iterations/2026-10-15-composition-consequences/review.json) keeps these findings tied to edition `ca4601b6324d2f76cd92`.

The [provisional orientation plan](../../commons/maps/Random_Definition/composition/orientation-plan.json) and Literary wall now carry five consequence questions for each proposed strategy, including **what can remain unspoken**. The proposed sequence is observation → selection/retention → montage → inversion → rule/consequence. A structural connection need not become an explanatory transition: leave the movement-to-number discovery for MOVE / KEEP. Keep the reference; no new literary candidate is adopted or rewritten in this pass. The [five-row abacus](iterations/2026-10-15-random-abacus/README.md) was completed separately in the **fixes** chat, with hand-interaction and hall-seed tests passing; its changed apparatus and current descriptions are distinct from this preserved three-line reading edition. The next literary comparison must account for that change.

## Writing orientations with consequences · 15 October 2026

The [supplied critical reading and follow-up](iterations/2026-10-15-composition-consequences/README.md) prefer the first composition pilot's reference to patient/inquiry. This preference is recorded against edition `3d57b4bf8da95a931c90`, without adopting a canonical chapter or claiming an independent participant trial. The next comparison changes the complete Geiger passage: repetition, montage and recurrence. Each appears inside the same five-stop chapter; the other four passages remain exact. Reference/new variants are 926/924/910/962 words in edition `ca4601b6324d2f76cd92`.

The reusable process now calls the artifact-to-text relation a **writing orientation** and tests both a local consequence and a changed significance elsewhere in the map. Intended effects, supplied feedback and observed outcomes are separate. The Literary wall links the new comparison; effects remain unassessed. Next: collect a reading response with a concrete detail and another encounter, or record no gain. The canonical final, tutorial, runtime and saved room order remain unchanged. The 48-value bench remains the first runtime pilot. The existing MOVE / KEEP placement/discovery mismatch remains unresolved.

## Composition pilot · 15 October 2026

The supplied compositional-system proposal is implemented as a [five-encounter pilot](iterations/2026-10-15-composition-pilot/README.md). Hall-scoped contracts separate implementation evidence from literary operations, counterpoints and refusals. A map score and directed graph keep meaningful relationships separate from walking order. The writing wall's Literary view follows draft Final tags/order, reports changed adjacency and source drift, and links to complete reference/patient/inquiry readings (926/950/967 words). Only the Geiger opening varies; the seed definition, receipt and other encounters stay fixed. A content-addressed edition retains exact inputs and can replay the assembly. Review is pending; no candidate is adopted. The canonical chapter, tutorial, saved wall and runtime remain unchanged. The 48-value bench is still the first runtime pilot.

## Situated voice and author strategies · 15 October 2026

Palle supplied a proposal linking orientation, apparatus, retention and the limits of records to literary strategies. The [expanded author library](course/writing-patterns/AUTHOR_STRATEGIES.md) adds nine authors and a further Haraway operation, with sources and limits. The [working note and short bridge trial](iterations/2026-10-15-situated-voice/README.md) propose keeping “we” while encounters change what its account can know. The bridge follows the actual virtual-hand motion into the retained RAND digits; it is unadopted. Keep the Geiger trial's locally preferred balance, the five-stop order and the 48-value first pilot. The canonical final, earlier complete trial, tutorial and runtime are unchanged. Next evidence is a local reading comparison, not a decision about the whole book's narrator.

## 435 witness-voice trial · 15 October 2026

Palle supplied feedback asking for a less explanatory middle, distinct documentary and bodily registers, and an earlier ending. The [complete reading trial](iterations/2026-10-15-435-witness-trial/index.html) and [comparison](iterations/2026-10-15-435-witness-trial/compare.html) preserve the current chapter alongside a 926-word alternative. The opening remains; the Geiger display, recorded clicks and receipt carry different information. A generator creates the 96 event times before playback; RESTART replays them. The trial keeps gesture collisions conditional and ends at the compulsory return. On the Geiger passage, Palle answered: “The balance is closer”. Preserve that local direction; the whole chapter, ending and newcomer comprehension remain open. See the [reading response and remaining questions](iterations/2026-10-15-435-witness-trial/README.md). No chapter adoption decision is recorded. The canonical final, tutorial, map and wall remain unchanged by this trial.

## Shared beginning 435 · 15 October 2026

Palle requested removal of the standalone lava passage and confirmed enforcement of 435 throughout Random Definition. The [current final](../../commons/maps/Random_Definition/final.md) now follows five Final-tagged encounters in room order: moving spheres, RAND book, Geiger, MOVE / KEEP, Out / Back. The lamps remain an optional Tutorial encounter and are mentioned with the window in the seed explanation. The approved “we” voice remains.

The hall shares one chosen seed across private instrument streams, starts at the saved 435, and permits deliberate selection or a retained gesture input. Fresh clock/system/online acquisition is disabled here. The frame trace still measures timing. Gesture-derived output remains pseudorandom. See the [implementation, task ledger and evidence](iterations/2026-10-15-seed-435-middle/README.md). The 48-value bench remains the first research pilot. Reader response, headset feel and independent reconstruction remain separate evidence to collect.

## Hand-only opening and integrated instruments · 15 October 2026

Palle revised the apparatus: Random Touch's bare lines are two metres apart and move only the contacting virtual hand. The RAND page has a small “select” stand. The Geiger runs continuously with controls in its cabinet; the lava controls sit within the wall; Out / Back loses its information board but retains body movement. See the [implementation and evidence](iterations/2026-10-15-hand-and-interfaces/README.md).

The current final retains the approved “we” voice with factual changes for these encounters. The tutorial includes all three hand-motion files, and writing-wall notes and both plans agree. Room order, tags and magnet positions are unchanged. Earlier opening variants describe their earlier apparatus and remain historical. Technical tests are separate from the still-unobserved headset feel and independent reconstruction.

## Bachelard opening trial · 15 October 2026

Latest decision: Palle responded to the “we” version, “ok I think that voice works.” The shared voice is now the chosen working reference for this opening, and the passage has been adopted into Random Definition's final. All earlier versions and the previous chapter are preserved beside it. This is a local editorial choice, not a participant report, a multiplayer claim or a compulsory voice for the whole book.

Palle requested a new scientific and poetic opening, close to the moving-sphere and RAND encounters. [Read the selected opening](iterations/2026-10-15-bachelard-opening/opening.md); its [record](iterations/2026-10-15-bachelard-opening/README.md) tracks the reading movement, factual anchors and voice decision. A measured line becomes a travelled distance; touch then changes from initiating motion to retaining a falling group. The canonical chapter now carries this opening; room order and tutorial are unchanged. Next evidence concerns the bridge into the remaining encounters and how the voice works across a longer reading.

## Scientific and poetic attention · 15 October 2026

The requested [collection of authors' strategies](course/writing-patterns/AUTHOR_STRATEGIES.md) is now available. It develops Bachelard's scientific questioning and poetic attention separately, then proposes concrete Ada uses for eleven authors. Each operation has a use and a limit; it is not a common voice or mandatory route. The sample is imagined narration anchored to the corrected waiting/carrying spheres. No chapter rewrite or A/B/C selection follows from this collection. Next: identify what an actual encounter brings forward and test one strategy against that detail.

## Moving-sphere opening comparison · 15 October 2026

[Three side-by-side openings](iterations/2026-10-15-sphere-openings/README.md) remain alternatives. Palle clarified that none was a clear winner; do not treat “the first I think” as approval. He wants scientific and poetic attention and a reusable collection of authors' strategies, including Bachelard, to revisit after fixing the artifact. The [touch-line revision](iterations/2026-10-15-touch-lines/README.md) replaces autonomous displays with three bare two-metre lines, one metre apart, whose waiting spheres carry the player on contact. The six-stop route remains; its prose voice and RAND handoff remain open.

## Writing and research loop · 15 October 2026

Resume hall-writing work with [From encounter to revision](course/ENCOUNTER_RESEARCH_LOOP.md), the [cycle record template](course/ENCOUNTER_CYCLE_TEMPLATE.md), and the [two writing roles](course/WRITING_ROLES_AND_DECISIONS.md). The process records Palle's direction: concrete encounter, short first-use explanations, a productive tension, controlled comparison, reader response and revision of either text or apparatus.

Random Definition's [current final](../../commons/maps/Random_Definition/final.md) and [plan](course/text-plans/Random_Definition/final.md) now select six main encounters in room order: moving spheres, RAND book, lamps, Geiger clock, MOVE / KEEP, Out / Back. Eight other encounters stay optional. The [six-encounter record](iterations/2026-10-15-six-encounters/README.md) distinguishes technical checks from comprehension and VR touch still to be observed. Length now follows the selected gems, normally 600–1,500 prose words per text. The 48-value bench remains the first research pilot. Do not treat the new prose or the method as a completed independent reconstruction trial.

## Current framing drafts · updated 24 September 2026

The requested preface and QFEP afterword now have developed working drafts: [preface](preface.md), [afterword](afterword-qfep.md), and [editorial scaffold](BOOK_FRAME.md). The [reading edition](iterations/2026-09-23-book-frame/index.html) places them before and after the complete active final.md spine. These are drafts for revision, not accepted final text. Rebuild with `python doc/book/iterations/2026-09-23-book-frame/build.py`.

The preface now opens with the author-approved late-arrival image: “We arrive after the light.” The first small gesture depends on accumulated work, and the beginning is a choice of attention within a world already running.

The older manuscript pipeline and coverage figures below are historical; they do not describe this final.md framing edition.

---

> Read this first, then the newest rulings in [RULINGS.md](RULINGS.md), then the current
> voice-bar chapter. Ten minutes and both of us are back in the loop — after weeks away,
> after a model upgrade, after context loss. Updated every session that touches the book.
> To FOLLOW the process as a feed: [LOG.md](LOG.md) (append-only, every tool writes to it
> via `tools/book_log.py`) — web face at **localhost:3003/book-log** (filterable timeline
> + the rulings panel).

**Last updated:** 2026-07-12 — **R-029: the Em-Square interlude.** The book's first
interlude, placed after Part I (Order) in `manuscript_frame.json` (`interludes[]`), plus a
computed **The Principal** beat per chapter — each names its hero and how the em-square seats
it (self/cube/frame/plinth/field), resolved principals → overrides → kin → measured-size
(Palle's rule 2: base ≥ 6 m = field). The interlude's checkable claim holds in the data:
field seating is absent in Order/Dynamics, arrives with Entropy (Noise 10 m, CA 7 m) and
returns in Emergence (mushroom 20 m, slime 50 m); Edge/Synthesis have none — so "field arrives
with entropy and returns in Emergence," not a clean monotonic loosening. Authored `principal`
field in any overlay overrides the computed beat. Rebuild: `python tools/build_manuscript.py`.

**Earlier:** 2026-07-04 — R-009 applied: fractals walk hand-cut (+mandelbrot_dive,
+box_counting_dimension; −fractal_scene, −recursive_tree_2 [ghost's cuts, pending friction]);
Hilbert blank declared (renders in chapter + as EMPTY PLINTH in the staging brief); field
journal carries its first real entries. R-010: blanks have a lifecycle (declared → candidates
→ filled | commissioned) — DEMONSTRATED: box_counting_dimension captured in Godot (shows
**D = 1.555** measured — undershooting the ideal 1.585, the debt photographed), copied to the
archive, chapter now 11/11 illustrated, journal recorded "capture appeared". The loop turns.

## Where we are

- **The book:** `ada_encyclopedia/public/manuscript.md` (+ `.json`), built by
  `tools/build_manuscript.py` from `doc/manuscript_frame.json` (six-part arc, 6 motifs,
  excavation note) + `ada_encyclopedia/public/tutorial/<seq>.json` chapters.
- **Coverage:** 21/22 chapters built (`boolean_surfaces` has no three-orders pearls — stratum
  unopened). Writing passes: **4/22** (primitives, randomness, noise, fractals).
- **Reader artifact:** https://claude.ai/code/artifact/0a58e039-f4df-4214-8a3a-8548559e76d5
- **Map artifact:** https://claude.ai/code/artifact/5050b8c6-3c07-4c7d-beb3-75e23d397fde
  (also `public/manuscript-map.html`, rebuild: `tools/build_manuscript_map.py`)

## Provenance of passes (honesty table)

| Chapter | Overlay | Provenance | Status |
|---|---|---|---|
| fractals | `tutorial_authored/fractals.json` | pre-protocol, **current voice-bar** | standing |
| randomness | `tutorial_authored/randomness.json` | ghost-only, zero rulings (see R-005) | **needs friction pass** |
| primitives | `tutorial_authored/primitives.json` | drafted from R-001 | needs friction pass |

## Open queue

0. **R-008 the deep dig** — `tools/dig_report.py` built; pilot reports in
   `doc/book/dig_reports/`. KEY FINDS: fractals' canon is at depth (mandelbrot_dive LB 6,
   box_counting_dimension LB 6 + uncaptured, Hilbert/space-filling = uncovered concept —
   "to the hilbert curve" literally missing); randomness: entropy_axiom LB 6 uncaptured,
   trng_vs_prng correctly buried (tension already staged), Gaussian family uncaptured.
   AWAITING RULINGS on promotions/burials. Tool refinements queued: filter counter-pairs
   to LB/promoted members, read authored-overlay prose (mislabels prose-rich walked
   artifacts "ornament?"), pull truth from tutorial JSON. Next: role overlays + builders
   consume roles.
1. **noise R-011+R-012 applied** — chapter authored; mc_sculpt_vr promoted cross-domain as
   the counter closing the walk (noise_space stepped down, ghost call); fractals' Hilbert
   plinth now POINTS ("the Hilbert curve stands in the next room"). PENDING: friction
   passes; Palle's wording for the two noise truth-sentences; noise staging note — the
   brief says 8 of 11 walked are LARGE (a chapter of giants; the hangar will need scale
   discipline). Still open → R-013: randomness staging forks (env_one, rhythm) +
   randomness dig (entropy_axiom?) + randompoints-vs-randompoint + Hangar v3.
2. R-003 landing: queerness definition into front matter + trace-motif sharpening (approved
   in principle, not applied).
3. Friction passes on randomness + primitives (Palle reads in the artifact, marks what isn't his).
4. `boolean_surfaces` three-orders pearls; captures for machinelearning + graphtheory
   (both walk 11 with 0 illustrated — the visibility apparatus hasn't reached them).
5. Next cold pass (voice-bar) due around chapter 4–5 of the protocol — Palle picks the sequence.
6. Later: `/manuscript` reader page in the encyclopedia; auto-indesign PDF
   (`/api/import-spine` → `/api/synthesize`) once enough passes exist.

## The pipeline (one chapter)

```
trench report (chat) → rulings → doc/tutorial_authored/<seq>.json
python tools/build_critical_tutorial.py <seq>
python tools/book_drift.py          # field journal — what the site changed under us
python tools/build_manuscript.py
python tools/build_manuscript_map.py
→ republish reader artifact → friction pass → update RULINGS.md + this file
```

## Spine-graph integration (tested 2026-07-03)

- **Book lens (read):** `tools/build_spine_graph_book.py` → `public/spine-graph-book.json`;
  the **Book** toggle on `/spine-graph` rings walked artifacts violet (title = chapter),
  dims the rest to depth, and prints "N of M excavated" under concept hubs. Rebuild the
  dataset after tutorial rebuilds. Verified: 194 lit / 578 dimmed / 772 total.
- **Walk curation (write):** arrange a sequence's ring on `/spine-graph` → Export →
  `python tools/import_walk_from_graph.py <export.json> --seq=<seq> --apply` → writes the
  `walk` override into the authored overlay; the tutorial builder honors the author's cut
  over the `[:11]` formula, marks `dig.curated`, and the manuscript's field note appends
  "The cut was made by hand." The field journal records the recut (`walked +x; −y`).
  Ring membership: artifact nodes with the sequence's seq or parented to its hub;
  order = reading order (row, then col). Tested end-to-end on noise and reverted.

## Staging briefs (the final game — chapter → hangar map)

`tools/chapter_stage.py <seq>` → `doc/book/staging_briefs/<seq>.md` — the bridge from a
finished chapter to its final map: roster w/ ladder tier + measured scale + staging-DNA
type + prose flag, rhythm score (scale melody, clashes/flats), alignment (no prose, no
plinth), grid from Σ footprints, floor plan from the 8-page grammar. First run 2026-07-03:
**fractals 70% contrast, melody holds, stage-ready; randomness 30% contrast, flat small
tail, and env_one (60 m base, 3,660 cells) blows the grid to 86×129 — fork: stage it AS
the room (terrain type = the map's shell) or hand-cut it from the walk.** fractal_scene +
cube_staircase unmeasured (run tools/measure_artifact_aabbs.py).

## The fold ladder (R-011 pending confirmation — dimensional unfolding)

Plan/elevation/itinerary as conjugate projections; the room is where they agree.
Fold 0 thread (walk, gaze_ride reads back) · Fold 1 plan (footprints) · Fold 2 elevation
(hangar walls) · **Fold 3 extrusion — `tools/wall_extrude.py` (built, piloted)** · Fold 4
3D grid (place.py) · Fold 5 fold-back (ride log → book). Pilot: **`Hangar_Fractals`**
(28×40, pathfinder 1120/1120 OK, captured) — 3 curated bays S→N in walk order
(fractal_recursion, proto_fractal_recursion, nk_fractals_mandelbrotset), hero
inverted_tree_cloud north zone, box_counting_dimension + cantor on the east lane,
**one empty plinth = the Hilbert blank, physically in the room**. Cluster sources:
`commons/data/curated_walls/clusters/`. Rebuild: `python tools/wall_extrude.py
--seq=<s> --write` → compact → pathfinder.

## Fold 5 — the ride log (built, folded back 2026-07-04)

`tools/fold_ride.py <Map> --seq=<s>` → runs gaze_ride, distills machine observations →
`doc/book/ride_logs/<seq>.json` (+ raw log `.log.md`) → tutorial world page `ride` field →
manuscript prints "The machine walked <Map> and filed this ride log" as the SECOND machine
register. First fold-back (Hangar_Fractals) generated the room's own revision list:
**the hero (inverted_tree_cloud) is neither visited nor seen** (ride path never reaches it);
8 of 11 exhibits visible only on arrival (blind bays — no long sightlines);
box_counting_dimension (11 m measured base!) holds 14 of 25 stations at up to 96° — one voice
too loud; 3 exhibit overlaps (box∩cantor on the lane; two inside the proto bay).
**v2 APPLIED (ruled):** root cause was a gaze_ride bug — spawn code "s" vs the documented
"sp" (fixed, accepts both) — plus the teleporter moved onto the hero's axis (wall_extrude
now voids the t cell itself). Result: hero seen at 32°/25.6 m mid-ride, then station 24 =
HUGE 66° CENTER 11.3 m before exit; ghost line gone from the ride log. Machine's honest
correction: from the south door the ENTRY hero by angular height is fibonacci_pagoda, not
the tree-cloud. Still queued (v3): blind bays (8/11 arrival-only — angle the bays or open
sightlines), tame/crown the 11 m box_counting, respace lane + proto bay interior overlaps.

## The encyclopedia API toolbox (harvested from /sitemap, 2026-07-04 — use before building)

- **`GET /api/find?q=&kind=content&format=markdown`** — corpus-wide search (registry +
  algorithms + maps + pages). USE BEFORE COMMISSIONING a blank — it found the
  anti-threshold candidates (mc_sculpt_vr et al.) that noise's pearls could not.
  Single terms work best; multi-word queries AND together.
- **`GET /api/game/analyze?name=<Map>`** — independent map validator (walkability %,
  reachability, longest shortest path, per-artifact distance from spawn). Second
  opinion to map_pathfinder; verified on Hangar_Fractals (100%, all reachable).
- **`POST /api/captures/generate` {map}** — runs the Godot map capture headlessly via
  the web. (Artifact captures stay CLI: capture_multi_angle --mode=artifact; then
  tools/sync_artifact_captures.py refreshes the manifest /api/artifact-captures reads.)
- **`POST /api/artifact-pairs` {ids}** — pairwise embedding cosine within a set —
  upgrade path for dig_report kin detection (token overlap is the current proxy).
- **`POST /api/fold-neighbors` {ids, topn}** / **`GET /api/concept-ladder?id=`** —
  semantic kin / tier ladders (chapter_stage currently reads doc files directly).
- **`POST /api/game/simulate`** — AI pathfinding walk; complement to gaze_ride.
- **`GET /api/final-lap?format=markdown`** — Part VI context for the last three passes.
- **`GET /api/scenes/footprint` / `/api/scenes/enriched`** — footprints for staging.

## The room is the map (R-015, 2026-07-05 — architectural pivot)

The room descends from the CHAPTER to the MAP. `tools/dollhouse.py` is the production
map-room composer: branches on hero:roster into MONUMENT (giant hero = the room) /
SPECIMEN (small = tight cluster) / CABINET (many = packed shelves); floating-diorama dais
(height-2 + void surround); non-destructive `Room_<Map>`. A chapter = a NECKLACE of these
rooms, chained by real maps' teleporters. `creator_walk`/`chapter_stage` keep value as the
SEQUENCE lens (necklace order, transitions), NOT the room; the dig/ledger/walk stay at
chapter grain. Piloted: `python tools/dollhouse.py --seq=randomness --write` → 13 valid
rooms, modes 11 monument / 1 specimen / 1 cabinet (randomness = the environment sequence).
Next: apply rigger glue per room; the rate-gallery + distil loop; run other sequences.

## The room is a hall of workstations (R-016, 2026-07-05 — the fused composer)

`tools/hall.py` fuses dollhouse (room=map) + workstation (hero=cluster) + rigger (glue).
A map's roster groups into workstations; each is a TIGHT lab bench — hero on a stage under a
`station_luminaire` task light, ladder children on flanking plinths/micropods, the lab cast
(`gas_canister`/`tech_crate`/`cardboard_box`/`lab_stool`/`station_multiscreen`/
`fire_extinguisher`) packed at the edges — flanking a walked central aisle. Floor height 1
(walkable, ZERO pathfinder warnings). `python tools/hall.py --seq=<s> --write`. The MODEL
(R-015→R-016): spine (1D index) → cluster (mindmap node = hero+children+props) → workstation
(the node staged) → hall (map-room) → necklace (sequence). This IS spine-graph's Clusters
layout built in 3D. Pilot: Hall_Random_Cubes (1 ws), Hall_Random_Definition (2 ws).
Tuning: hall size should hug workstations tighter; rigger needs `--roster` mode for map-halls
(currently walk-based); lighting/DNA polish toward the reference renders.

## Modkit + the meeting layer (R-017/R-018, 2026-07-05)

`commons/data/station_modules.json` is the modular spec: size classes S/M/L/XL with
footing contracts (micropod/plinth/stage normalize the seat), prop POOLS (instrument/
art/bench_tool/…), and named slot TEMPLATES. `tools/modkit.py --hero=X --template=T
--seeds=1,2 --write` fills a template deterministically — same slots, different cast →
`clusters/mk_*.json`, straight into the capture/review/place pipeline. R-018 adds the
JUNCTION layer: treatments applied wherever classes touch (reveal cap-inset on every
seat, skirting floorline under walls, zone-edge line where station meets aisle, seam
pillars between wall plates). The joint is the generator of form.

## The station-model library (/station-gallery, 2026-07-05)

Four templates: BENCH (reference wall bench), ISLAND (freestanding, read from all
sides), VITRINE (8-cell wall + micropod row — the miniatures cabinet), MONOLITH
(hero + two pillars + one light, Point_One energy). Fleet seeded across heroes,
captured via wall-hangar `--capture-clusters`, browsed at `localhost:3003/station-gallery`
(manifest: `python tools/station_gallery_manifest.py`). Learned: heroes that GROW over
time (fibonacci_pagoda, stochastic_tree) render empty at capture — monoliths need
instant-mesh heroes; shader/texture family members render as floating quads — modkit now
filters them from CHILD slots and prefers measured bodies. Place any station in a map
with `cluster:mk_<name>:<rot>`.

## The meeting audit (R-019, 2026-07-05)

Generalizes R-018 from declared junctions to an AUDIT QUESTION at every scale: for each
part of each object — how does it meet the object? For each object — how does it touch
its surroundings, and can the meet be improved? Standing rules from the first audit:
**body_on_cell** (artifacts seat by measured live-AABB centre, not code origin —
WallHangarEditor `_settle_loaded` centres horizontally before the vertical seat) and
**pole_on_floor** (the luminaire's flat foot became a stepped pedestal + collar; a foot
that cannot be SEEN has not met the floor). Declared in station_modules.json `junctions`.
Open audit queue: box_on_box crate stacks, screen→wall mounts, stool feet, grime as the
record of a long meeting.

## Ada and its ancestors (lineage, 2026-07-06)

The book names its parents in the front matter (doc/book/LINEAGE.md, rendered into
the manuscript): **Learning Processing** (Shiffman — Ch.1 "Pixels" = coordinate
system + point + primitives; the minimal runnable one-step progression we keep),
**The Nature of Code** (build-from-the-primitive-outward, our spine), and the
THIRD STRAND neither carried — the critical trajectory (thinking with Turing). All
re-staged from the flat VIEWED screen to inhabited, embodied 3D. The five shifts
that make 3D algorithm thinking its own: frame inhabited not viewed · atom inverts
(pixel->Vector3, discrete/continuous swap) · loop is presence not animation ·
input is the body not the mouse · reading is a walk not a glance. Keep Shiffman's
restraint; resist 3D's spectacle; add body, depth, critique.

## Standing constitution

- Rulings are the source; prose is compiled output. Unruled calls in drafts get marked, not hidden.
- Divergence is surfaced, never auto-collapsed. Disagreements logged both ways.
- The ledger is a voice, not a schema. The dig line is machine-only — never hand-written.
- VR walking is Palle's trench; text is the ghost's. A chapter needs both before it's done.

## Removal arena speed control · 17 October 2026

`random_removal_arena` now defaults to 3×, with SLOWER/FASTER steps from 0.5× to 8×. Warning time, walking distance threshold and seeded coil wait scale together; changing speed consumes no random draws. Current warnings finish at their original duration, pending waits rescale, and REPLAY retains speed while restoring support and generator state. Both installed variants were checked: 71 Random Remove and 70 Random Game native checks pass, including actual contact/ray controls, unchanged seeded order, cancellation and restoration. In the supplied stationary coil test, 1× removed one tile and 8× removed eight in three seconds. No script errors; the Game harness reports an object-cleanup warning at exit. Headset reach/comfort remain untested. Current tutorial and registry follow; map placements and student lesson remain unchanged. Evidence: [removal speed notes](iterations/2026-10-17-removal-speed/notes.md). No commit/push requested.


## 10 PRINT textile dressing studio · 17 October 2026

Completed the request to upgrade textile_comparison using the tiling/weaving work, wear its fabric as a dress, add a mirror/dressing room and make large 10 PRINT components visible. The Randomness_10_PRINT_Algorithm placement now loads ten_print_textile/textile_studio.gd; print_record.gd retains 252 integer draws with seed, marks, palette and repeat. Three swatches, three dress cuts, KEEP/REPLAY, WEAR/TAKE OFF, exact wardrobe restore and a walk-in planar-mirror alcove are installed. The production garment system accepts a version-2 printed record alongside unchanged version-1 woven records.

All three tall fields use mesh character glyphs and batched cell frames. The cross-room one starts at 3 m to preserve the studio sightline. The linked floor has low strokes and cell beds. Source map/registry/tutorial/final updated. Native evidence: 120/120 checks (43 data/wardrobe/mesh + 77 actual hall), including hand-layer contact, XR pointer events, active VR wearer and controllers, persisted clothing, mirror, alcove locomotion and screen/floor identity. No physical-headset test; fixed geometric garments and one head-centred reflection. Native cleanup warnings retained in evidence. No commit/push.

Review: /book-review/doc/book/iterations/2026-10-17-ten-print-dressing/index.html. Sources, before/after snapshots, changes.diff, tests.json, report.json and verification.json live in that folder. Native run: ada_run/encounter_pilot/Randomness_10_PRINT_Algorithm/textile-dressing/. Review open as an IAB deliverable.
