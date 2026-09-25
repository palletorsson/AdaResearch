# Random_Remove: decisions

**Verdict:** targeted revision. The audit and its re-check agreed on four overstated claims. I fixed each one by editing the sentence in place. I added four sentences about placed works, each checked against the code. The structure, questions, code excerpts, anchors and closing are unchanged. The chapter went from 1264 to about 1480 words.

## Preserved
- All five code excerpts, including the `_removed.has(i)` loop. The excerpt stays; the sentence that introduces it now describes it correctly.
- The anchors `<!-- @remove_random -->`, `<!-- @random_removal_arena -->` and `<!-- @ -->`, the title, and the opening back-reference to Entropy.
- Every sentence on the audit's Preserve list.
- The closing paragraph, word for word. 10 PRINT relies on four things in this chapter: "draw was even among the cubes a rule had admitted", "as RESET did on the last room's board", "what chance may touch was settled before it ran", and "a contour becomes a passage". All four still hold.
- The RESET passage and the NEW SEED caveat.

## Changes (the audit and the re-check both confirmed each one)
1. **Location.** "in the middle of the hall" became "a few steps inside the entrance, on the hall's centre line". The token sits at column 8, row 5 of a hall 17 wide and 26 deep. The spawn is at row 0 and the arena fills the middle, at row 17. Evidence: map_data.json:1201 (bench token), :1429 (arena); the layer scan puts `s` at (8,0), `remove_random` at (8,5), the arena at (8,17) and `t` at (8,25).
2. **The `_removed` skip.** The old wording said a removed cube "is skipped before the question is even put". It now says the loop carries a guard that never fires on this bench, because every run empties `_removed` first. Evidence: `find_all_instances` has one caller, RemoveRandom.gd:186, and it runs right after `_removed.clear()` at :176. The only other clear is the unbound branch, :78, which returns without scanning. Grep over algorithms/ confirms the one caller. I kept the excerpt and used the re-checker's alternative wording rather than swapping in a different excerpt.
3. **ROW/COLUMN addresses.** "The addresses at those positions differ" became "differ, except once", followed by the mirrored pair and the shared cube at (3,3). Evidence:
   - Cubes are indexed as z*8+x (remove_random_fixture.gd:33), and the filter walks that index in ascending order (RemoveRandom.gd:123-128).
   - Both modes draw the same offset from lists of equal length (:144-145, :158).
   - The plate prints `index % SIDE` as the column and `index / SIDE` as the row (fixture:94).
   - The defaults are target_row = target_column = 3 (:11-12), and the map token does not override them (map_data.json:1201).
   - The review README records that seed 777 meets the shared cube (3,3) on the fourth draw.

   I kept "differ" as the general rule, so 10 PRINT's "the same draws landed on different cubes" still holds.
4. **`removal_log`.** "The full history remains in `removal_log`, available in the source and the review" now says the log holds only the current run and is cleared by RESET, NEW SEED or any mode button. The review's six histories come from its own runs, not the visitor's. Evidence: RemoveRandom.gd:161 (append), :180 (clear inside the reset), :170 and :204 (mode and new seed both call the reset), :213 (exposed through `get_state`); remove_random_fixture.gd:72, 74 and 75-77 (buttons); doc/space/remove-review-2026-09-12/README.md:35 ("Six full histories are exported") and :62 ("The in-game plate retains only the last removal").

## Added sentences (verified facts about placed works)
- **Bench, "Choosing" line.** While a cube is red, the plate line reads "Choosing column c, row r", which makes draw-before-delete visible. Evidence: `_removal_in_progress = true` and `state_changed` fire before the highlight wait (RemoveRandom.gd:142, 149-150); the fixture shows `last_selected` while busy, with the "Choosing" prefix (fixture:88, 94).
- **Bench, the list shrinks.** One sentence, `active_instances.remove_at(offset)`, gives the work that change 2 took from the guard back to the code that actually does it. Evidence: RemoveRandom.gd:158.
- **Arena, fixed first order.** Two sentences. The floor seeds 17031 on every build, so every visitor meets the same sequence of cells, since walking only triggers draws. The floor names no seed, so after NEW SEED you cannot say which order you are in. Evidence:
   - removal_arena.gd:44 seeds 17031, and :25 sets replay_on_reset.
   - The walk only calls `remove_one` (:68, :72-73), and a call made while a removal is busy returns before drawing (RemoveRandom.gd:138).
   - The readout text has no seed (:89), and NEW SEED is the unnamed `new_seed()` (:57; RemoveRandom.gd:201-204).

## Left alone
- "Its controls sit together on the console in front; a cased account … to the left." The audit did not flag it, and the status post is at local −x (fixture:49), which is the visitor's left once the token's 180° turn is applied.
- The arena mechanics (99 cells, 0.6 m, 0.8 s, entry removal, collider disabled). They match removal_arena.gd:6-7, 26, 67-73 and 78-79.
- The optional Entropy "exposed tops" link, and the apron read as grey cubes. Both are optional, and the second would drift into correcting the word "random".
- The sequence reader flags two repeats: the NEW SEED caveat (Remove is its first appearance) and "waiting does not advance the generator". The repeats are other halls' problem, not this one's.

## Limits
- I did not run Godot. The location comes from map_data.json and the plan and runtime data the re-checker cited, not from a fresh walk.
- These are outside the chapter and outside my write scope:
  - The arena readout is hidden inside its own backing plate. At removal_arena.gd:53 the plate's +0.016 offset is shallower than its 0.035 depth.
  - The colonnade piers stamp onto the arena's apron. The fix is `"piers": false` in map_info.museum.
  - tutorial.md and technical.md repeat the `_removed` skip error.
  - intent.md and other sibling docs still describe an older hall.

## Installed

`after.md` was installed to `commons/maps/Random_Remove/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `5156030db490…`, after `6c1dabdc09f8…`. No runtime or learner status changes, because the text changed and nothing new was walked.

## Encounter repairs (added at the end of the block)

- **The floor now answers a headset.** `removal_arena.is_player` compared each body against the museum's `_player`. The museum's headset branch never builds that walker, so in VR the floor removed nothing, and this chapter's floor paragraph was false for a headset visitor. The arena now recognises the XR Tools PlayerBody by its group, `player_body`. The desktop walker and the grid lane are unchanged. See `removal_arena.diff`; the shipped script is `removal_arena.gd.before.txt`. The gate is `commons/testing/probe_removal_arena_vr.gd`, with output in `probe_removal_arena_vr.out.txt`:
  - V: a headset body starts the removals; the shipped script ignores it.
  - D: the desktop walker still starts them.
  - S: with a walker present, another body does not.

  The arena is placed in this hall and in Random_Game only. Not walked in a headset.
- **Piers.** The museum plan stamps a 20-pier colonnade onto the arena's apron. `map_info.museum.piers` is now `false` (`map.diff`, one line). The museum reads piers from the plan row, not the map, so this takes effect only when `tools/em_map_halls.py --apply` is re-run. That writes the baked plan, which belongs to Astra (INTEGRATION.md, section 7).
