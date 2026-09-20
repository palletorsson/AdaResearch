# A route needs room

<!-- @caverandomwalk -->

A connected line has no width. Your shoulders do. Stand at the cave opening and look for the space that would have to remain empty if you entered. Then turn on TRACE. Small gold dots mark positions where the carving operation was applied. Some positions were visited more than once.

The walker does not leave a solid trail. It removes cells around its position. The array begins filled; `_set_air` changes selected entries to zero. In this program, zero has a job: it records absence inside the generated volume. The museum's floor beneath the experiment is another object with another responsibility.

The cave is guided more deliberately than its name might suggest. Walkers begin at four sides and are biased towards the centre. They then wander at a prescribed low level and climb through further levels. Around each carving centre, the operation clears a small lateral footprint and two cells of headroom. This is not an unconstrained random walk discovering a cave without prior decisions.

```gdscript
_carve_ball(p)
p = _biased_step_towards(p, to_center, 0.7)
```

CAVE SEED makes another run while retaining that construction. Find an opening that moved and one restriction that did not. TRACE marks carving centres; it does not join separate walkers into a fictitious continuous trajectory. The dots help us read where the work occurred, including work that the final void no longer distinguishes.

At full display scale the cells are one metre wide. The stated two-cell headroom is a construction parameter, not a guarantee that every turn and climbing region admits the player. An interior can exist geometrically while refusing a particular body. That refusal becomes something we can locate and revise.

<!-- @ -->

<!-- @maze_generation -->

Across the court, another grid offers another way to make room. Press MAZE STEP. The program moves to an unvisited cell and removes the wall between it and the previous cell. It also keeps the previous position on a stack.

```gdscript
generation_stack.push_back(current_cell)
current_cell = next_cell
```

Continue until the current cell has no unvisited neighbour. Now the stored path matters: the program pops a position from the stack and tries again from there. Backtracking is not an error to disguise. It is how this construction keeps unfinished alternatives available.

FINISH completes the small nine-by-nine study. RESET restores its construction so that you can step through it again. Its cells are 1.5 metres across. Compare the deliberate openings at the boundary with the cave's carved mouths, then compare their internal turns. The maze stores walls and visitation; the cave stores solid and empty volume. Both have random choices and authored restrictions.

The nearby binary-space-partitioning work remains another comparison: divide a region before deciding how its parts communicate. We need not erase it because today's first argument concerns two generators.

The desktop check follows open maze cells from entrance to exit. That proves a route in its array. Human VR clearance through every generated interior remains a separate review. The independent museum aisle lets us continue while keeping that distinction honest.

In Sculpted Forms, we will reverse the direction of this encounter. Instead of asking a rule to carve space for a body, we will let bodies fall and ask another rule what surface it can record from them.

<!-- @ -->
