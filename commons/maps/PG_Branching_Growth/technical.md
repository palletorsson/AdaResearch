# One nearest invitation — implementation

Sources: branching_growth_algorithm.gd::grow_step, update_mesh_immediate; organic_space.gd.

The opt-in `pg_workshop_console` binds the named artifacts within its own museum hall; controls are implemented in commons/artifacts/timing_machines/pg_workshop.gd. Six push buttons occupy one compact 3×2 desk with an inclined translucent readout. RULE reveals the implementation card. Actions are guarded while a rebuild is in progress.

Nearest-target growth; compare stored children with distinct positions, then restore variation.

The first segment leans left. In local coordinates the nearest target is (-2, 1.5, 0), two and a half metres away. Normalizing its direction and taking a half-metre step gives (-0.4, 0.3, 0). We can predict this small displacement before we have a tree to admire.

The running program searches unreached attractors inside `attraction_distance`. Each active branch site chooses the nearest one. Its construction begins with:

Now compare the readout's records with its distinct positions. They need not agree. Older active sites can produce another child; with no variation, an old site can choose the same target and put that child where it put the last one. Several records may occupy one place. A count of parents with multiple children therefore tells us about the stored tree, not necessarily about visibly separate branches.

The museum study caps the record count at 192. The counter includes coincident children. That limit tells us something about what this program spends, not how mature its tree has become. RULE reveals the operation after you have had a chance to follow it.

Space: the inherited structure is retained in a larger surround; relocated objects have an independent museum aisle. Source zeros remain present and receive explicitly listed museum.floor_cells covers. The floor audit records offsets and covers. Raised historic cells are retained witnesses, not universally certified decks.

Validation: see doc/space/pg-sequence-2026-09-15 and ada_run/pg-review-2026-09-15. Report actual runtime checks separately from outstanding human headset/clearance review.
