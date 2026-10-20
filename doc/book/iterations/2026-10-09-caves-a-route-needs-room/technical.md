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


## Reconstructed tutorial — 9 October 2026

Full printed carver.gd/cave.gd/unchanged Percolation point_body.gd. SIZE=(7,4,7), PackedByteArray196 entries, 1=solid/0=air. Index=(y*7+z)*7+x. Radius1 clears five-cell x/z cross; headroom2, non-wrapping clipped bounds. Nine fixed route centres include one repeated entry. Route/history/volume/display kept distinct. Full route clears44cells; whole HEADROOM3 variation clears66, same history and roofy3 intact. Interior single carve10/15 cells, front-edge8/12. This is reconstruction of production _carve_ball, not another random-walk lesson. Its name does not imply a spherical footprint.

Renderer .28m cubes, basey.75, floating miniature without collision/support; nominal headroom.56m/.84m. Installed cave cells1m. Cutaway hides solid y>=2 only; data/history unchanged. Gold dots retain repeated records. Point action advances one entry; movement does not. Physics parking reused from Percolation, release returnslocal(0,1.1,1.45). Temporary host maplocal(10.5,0,10),yaw180; approach(10.5,0,8). Production cube size, walks, room and collisions untouched.

29 exact-printed assertions PASS. Eighteen production-kernel comparisons including repeats and clipped/outside centres, independent every-cell union-of-footprints oracle, index uniqueness/strides, bounds, cursor cap, display data parity, cutaway nonmutation, restart, complete headroom variation, keyboard finish and actual XRTools pick/action/drop with supplied poses under translatedrotatedhost. Three complete faulty models rejected: square footprint, extra cleared layer, deduplicated history. First run retained under first-code-check: early probe type check loaded XRTools before its autoload; probe now dynamically inspects method. One-shot deferred release park lost to physics update; tutorial host now uses the established physics parking. Point class unchanged.

31 native checks PASS: six actual pointer buttons/effects; installed seed1338 cave has262centres/183distinct/533air cells; replaying its entire record with source kernel reproduces volume. Five supported clear standing capsules at front mouth only, not whole cave traversal. Maze9x9 contains16 logical rooms; all visited, array entrance-to-exit reachable, open-cell wall colliders removed. Wholelearner and editedprogram agree44/66cells in actualmuseum; supplied hand action and release passed. Eight native captures. Side bypass 298 supported clear capsules using x36 starts beside desk; first x35 path hit maze boundarywall and is retained under first-room-check. Authored entry(19.5,.05,1.5) still blocked bydesk; valid exitrecord. No fullportal/interior traversal, headset, Questperformance or independentghoststudent claim.

Before3 andfinal8 images. Finalcameraexposure.45, productionlightingunchanged. Miniature opening and cutaway inspected; fullcave andmaze remainlarger comparisons. Originalrearstructure retained. Canonical final two code blocks removed, short same-route/different-height reflection added; argument preserved. Onlytargetexecutionplan row updated, draftretained. Productionalgorithm/scene/workshop/map/sequence protected byhash; runtime targetrowunchanged. Final logs noSCRIPT/Parseerrors; preexistingUID/renderer/resource diagnostics retained. Report doc/book/iterations/2026-10-09-caves-a-route-needs-room/index.html. NextPG_Sculpted_Forms.
