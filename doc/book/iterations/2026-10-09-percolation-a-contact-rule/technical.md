# Touching is not enough — implementation

Sources: percolationnetwork_ca.gd::update_percolation_automata, calculate_neighbor_flow, update_cube_collision.

The opt-in `pg_workshop_console` binds the named artifacts within its own museum hall; controls are implemented in commons/artifacts/timing_machines/pg_workshop.gd. Six push buttons occupy one compact 3×2 desk with an inclined translucent readout. RULE reveals the implementation card. Actions are guarded while a rebuild is in progress.

Compare face and corner contact before following flow through a finite lattice.

At a face contact the white site becomes flowing. Press CONTACT to start again with a different arrangement. The cubes now meet at a corner. STEP leaves the white one waiting. Their visual contact has not disappeared. The program simply does not consult that relation.

Its neighbourhood consists of six positions: one step in either direction along x, y and z. It does not include the diagonal positions. This is an explicit local definition, not a universal meaning of nearness.

The update reads the old grid while writing another. An occupied site becomes flowing when a permitted neighbour carries flow. One press advances one generation; it does not instantly colour every reachable site. The source remains supplied. Flow values and state transitions have their own rules beyond the simpler question of whether a path exists.

Press LATTICE. The comparison expands into an 18 by 18 by 18 field, supplied from one z face. STEP lets you follow its spread. DENSITY restarts from the same seeded sequence of occupation draws at a different cutoff: 0.2, 0.4 or 0.6. A larger cutoff admits more sites. The readout counts sites reached and those reached on the opposite face. The desk permits 64 generations before another reset.

There is another distinction already under your hands. White occupied sites have collision. Pink source and flowing sites do not. The signal travels through the occupied network; as it arrives, that particular obstacle to your body is removed. The same event is connection for one system and a change of resistance for another.

Space: the inherited structure is retained in a larger surround; relocated objects have an independent museum aisle. Source zeros remain present and receive explicitly listed museum.floor_cells covers. The floor audit records offsets and covers. Raised historic cells are retained witnesses, not universally certified decks.

Validation: see doc/space/pg-sequence-2026-09-15 and ada_run/pg-review-2026-09-15. Report actual runtime checks separately from outstanding human headset/clearance review.


## Reconstructed tutorial — 9 October 2026

Three printed files: reach.gd, lattice.gd, unchanged Branching Growth point_body.gd. Occupied/sources/reached are Dictionary sets with Vector3i keys and true values. SIZE6, six face offsets, synchronous reached->next copy, no boundary wrap. Generation cap64. Source set persists; R restarts wave only, unlike installed RESET to contact fixture. Local RNG seed1337, x/y/z draw order, cutoffs.2/.4/.6, whole +z face explicitly forced occupied/source. Museum desk does this at18-cubed; standalone source normally seeds only occupied boundary sites. Different dimensions remap RNG draws to addresses; not scaled copies.

Learner keeps Boolean reached projection, omits numerical flow/decay/random transfer amplitudes/CONNECTED threshold and collision. No conserved-fluid claim. Installed white cube collision disappears on becoming pink. Miniature EDGE.3 equals address spacing, no gaps, visual geometry only. Full edit adds only (+1,+1,+1),(-1,-1,-1); one diagonal orientation in both directions, not all26neighbours. Point held action advances; movement alone does not; releaseparks(0,1.1,1.5). Temporary host maplocal(8.5,0,18),yaw180, clear supported approach(8.5,0,16).

30 exact-printed checks PASS first run. Independent BFS distance oracle matches wave fronts across20generations on3density fixtures. Seventy-two production-kernel comparisons (six small fixtures embedded in18-cubed arrays,12steps each) match reached sites, not amplitudes. Source/old-buffer independence, one-step chain, gaps, six axes, boundary, restart, nested densities, all rendered cell addresses/sizes/colours, fullvariant, supplied XRTools poses under translated/rotatedhost verified. In-place avalanche, unrequested diagonal and flow-through-empty mutants rejected. At20steps six-cubed p.2:61occupied/3reached beyond36sources/0far; p.4:108/61/4; p.6:144/104/19. Those observations are finite seed-specific examples.

35 native museum checks PASS including9capture cameras,6actual desktop pointer buttons, real white collision removed after face transmission, retained collision at corner, sourceplane324sites, nested densities and full64step installed comparison. Printed propagation with supplied18-cubed occupancy agrees at eight checkpoints. Actual p.4 field:2483occupied,1673reached beyond324sources,81on oppositeface after64steps. Extra STEP respects64cap. Complete learner+editedmodel exercised insidehall; handmove/action/release via suppliedXRTools poses. No headset/Quest or independentstudent acceptance.

Side bypass beside dense lattice: 234 supportedclear capsule samples, from beside desk toexitapproach. Authoredentry(13.5,.05,1.5) remains invalid/floorblocked bydesk; fullentrance/portaltraversal notcertified. Existingrearraisedstructure notcertified aswalkabledeck. Before3/final9nativephotos retained. Firstcamera set passed35checks but projectionobscuredcorner andlargefieldintrudedintostudentview; retained first-cameras/. Revisedcamera viewsfromoppositeside andresetsinstalledfield forlearnercloseups, restoresdensefield forabove. No production placement/lightingchanged. Finalcamera exposure.45 differsfrombaseline; notlightingbefore/afterclaim. Physicalview andtexturetransparency remainindependentofnumericalconnectivity.

Canonicalfinal codeexcerpt removed, opposite-face wording corrected, one short reflection onpermittingcontact added. Productionalgorithm/scene/workshop/map/sequence andruntimeplan targetrowunchanged byhash/row checks. Engineacceptedlogs have noSCRIPT/Parseerrors; pre-existingdiagnostics retained. Report doc/book/iterations/2026-10-09-percolation-a-contact-rule/index.html. Tutorialprinted/extracted/renderedcode parity andZIP/staticHTMLchecked; browserlayoutunverified. FourthofsevenPGhalls. NextPG_Caves_Mazes.
