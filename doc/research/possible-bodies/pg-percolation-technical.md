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
