# Random_Remove — implementation and review

The room's one primary is `remove_random:90#local_grid:true` at (6,7). The scene `algorithms/randomness/remove_random.tscn` uses `RemoveRandom.gd`; the owned bench is built by `remove_random_fixture.gd`. The continuation preserves both production scripts and the current placement.

## Selection, state and ownership

Range uses inclusive x/z bounds 2–5 and y bounds −1–1. Row and Column use index 3; All admits every instance. `find_all_instances` tests each original local transform, skips `_removed`, and collects indices in ascending instance order. It colours eligible instances amber and excluded instances grey. An empty set remains empty. The candidate count therefore describes this configured grid, not arbitrary geometry in the museum.

`_bind_owned_grid` accepts an explicitly named descendant MultiMesh and creates a private resource copy before editing it. It never searches the hall for replacement targets. The bench has 64 instance slots; `_original` keeps their transforms. Removal draws a uniform integer offset from the remaining candidate list using a private RandomNumberGenerator, highlights the selected instance for 0.3 seconds, then zero-scales its original basis, records the index and removes it from the candidates. Instance count stays 64. The board and museum colliders remain.

The pending operation records `_generation`. RESET and mode changes increment it, clear the busy flag and restore transforms. A delayed callback from the previous generation returns without modifying the new run. Rapid presses during the highlight do not queue extra removals. The timer API exists but is not connected to START/STOP buttons here.

## Seed and comparison

The fixture enables `replay_on_reset` and chooses a five-digit seed. Both its arrival selection and NEW SEED use the shared `randi_range(10000, 99999)` function to choose the seed; the subsequent removal draws use the remover's private generator. Do not describe the whole fixture as isolated from global random state. RESET reseeds that private generator with the named run seed and restores the same list order.

The fixture's NEW SEED button calls `set_random_seed` and resets; it does not call the remover's separate unrestricted `new_seed()` API. Five-digit seed selection can repeat, and distinct seeds can produce the same permutation. There is no visitor seed-entry field. Rebuilding the hall constructs a fresh bench and selects a seed again; the visitor's last seed is not saved.

ROW and COLUMN begin with eight candidates, use identical successive bounds under the same seed, and select equal offsets in different lists. Comparing a range with a row changes both eligibility and the draw bounds. A seed alone is not a specification of the complete procedure.

## The visible bench

The pedestal is 0.8 × 0.96 × 0.8 m. The board is 1.4 m square with its top at 1.02 m. Cubes have local size 0.82 scaled by pitch 0.14, giving a visible width of 0.1148 m. Sixty-four permanent slot plates and sixteen edge numerals retain the addresses. Row/column coordinates are local to the grid.

The seven-button panel stands to the right at fixture position (0.95, 0.82, 0.70), scaled three times and tilted/yawed (−35°, −35°, 0). A cased status plate stands to the left around x = −1.12 m, y = 1.08 m, yawed 30° toward the visitor. It names the set, seed, initial eligible count, remaining count and number removed. Its second label names a pending/last removed address or exhaustion. The complete `removal_log` is available through `get_state`; the plate shows only the last event.

The actual layers are 13 × 18. Museum wall height is 3 and the clear rectangles are [[3,4,10,11]] (the far edges are exclusive). All three placements remain declared: the remover, dark_sphere at (5,8), and hazards_demo at (5,9). Two instantiate; hazards_demo has no living scene. The dark sphere's body constrains one adjacent lane; the route around the bench must be checked separately from the small removal model.

## Evidence

The independent continuation exports six complete removal histories, compares equal-sized masks, checks cancellation during the highlight and rapid presses, and retains the existing button, mask, replay, ownership, route and streaming checks. Its run receipt, captures, diagnostics and results are in `doc/space/remove-review-2026-09-12/`; the illustrated review is `/research/possible-bodies/random-remove.html`.

Desktop pointer operation is distinct from tracked-hand reach. Headset reading, approach and Quest performance remain for a later visit. Preserve the raw run diagnostics alongside assertion results.
