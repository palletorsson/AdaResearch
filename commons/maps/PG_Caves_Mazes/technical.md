# A route needs room — implementation

Sources: caverandomwalk.gd::_carve_cave, _carve_ball; maze_generator_vr.gd::_generation_step, _remove_wall.

The opt-in `pg_workshop_console` binds the named artifacts within its own museum hall; controls are implemented in commons/artifacts/timing_machines/pg_workshop.gd. Six push buttons occupy one compact 3×2 desk with an inclined translucent readout. RULE reveals the implementation card. Actions are guarded while a rebuild is in progress.

Compare biased carving centres with explicit maze backtracking and interior dimensions.

A connected line has no width. Your shoulders do. Stand at the cave opening and look for the space that would have to remain empty if you entered. Then turn on TRACE. Small gold dots mark positions where the carving operation was applied. Some positions were visited more than once.

The walker does not leave a solid trail. It removes cells around its position. The array begins filled; `_set_air` changes selected entries to zero. In this program, zero has a job: it records absence inside the generated volume. The museum's floor beneath the experiment is another object with another responsibility.

At full display scale the cells are one metre wide. The stated two-cell headroom is a construction parameter, not a guarantee that every turn and climbing region admits the player. An interior can exist geometrically while refusing a particular body. That refusal becomes something we can locate and revise.

Across the court, another grid offers another way to make room. Press MAZE STEP. The program moves to an unvisited cell and removes the wall between it and the previous cell. It also keeps the previous position on a stack.

Continue until the current cell has no unvisited neighbour. Now the stored path matters: the program pops a position from the stack and tries again from there. Backtracking is not an error to disguise. It is how this construction keeps unfinished alternatives available.

FINISH completes the small nine-by-nine study. RESET restores its construction so that you can step through it again. Its cells are 1.5 metres across. Compare the deliberate openings at the boundary with the cave's carved mouths, then compare their internal turns. The maze stores walls and visitation; the cave stores solid and empty volume. Both have random choices and authored restrictions.

In Sculpted Forms, we will reverse the direction of this encounter. Instead of asking a rule to carve space for a body, we will let bodies fall and ask another rule what surface it can record from them.

Space: the inherited structure is retained in a larger surround; relocated objects have an independent museum aisle. Source zeros remain present and receive explicitly listed museum.floor_cells covers. The floor audit records offsets and covers. Raised historic cells are retained witnesses, not universally certified decks.

Validation: see doc/space/pg-sequence-2026-09-15 and ada_run/pg-review-2026-09-15. Report actual runtime checks separately from outstanding human headset/clearance review.
