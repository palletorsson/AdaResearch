# Random_Definition — decisions

Sequence `randomness`, hall 1 of 14. 24 September 2026. Verdict: **Targeted revision.** Prose only. No code or map was touched. `commons/maps/Random_Definition/final.md` is unchanged, and the revision is in `after.md`.

## Preserved

The voice, title, structure, every question, both gdscript excerpts (still verbatim at `algorithms/randomness/seed_replay/seed_replay_demo.gd:313-315` and `:319-323`), the `<!-- @seed_replay_demo -->` and `<!-- @ -->` anchors, and every sentence in the audit's Preserve list. Both handovers are kept word for word. The opening picks up Synthesis Lab's "BASELINE restores", and the closing ("one small patch", "what a number can retain") is the sequence's best seam into Random_Entropy.

## Changes (the audit and its re-check both agree on each one)

1. **"The patch is back." → "The patch is still there. REPLAY recoloured every cube from the seed and got the same colours, so nothing on the grid moved."**
   The old sentence implied the patch had gone. `replay()` only calls `_regenerate()` (seed_replay_demo.gd:583-585). `_regenerate()` sets the seed back and writes the same albedo values over the existing materials (302-323). The slider (471-479), RANDOM (491-495) and +1 DRAW (499-502) already regenerate as soon as they are used, and the script has no `_process` or Timer. The grids therefore already show whatever REPLAY would rebuild. The wording is the re-checker's, unchanged.

2. **"Then use REPLAY to recover it." → "Then press REPLAY: it rebuilds that cell from the seed, and the cell keeps the colour it had."**
   The evidence is the same as for change 1: nothing is lost between RANDOM and REPLAY. I started from the re-checker's wording but did not keep its ending, "the same colour comes back", because that phrase repeats the "lost and returned" overstatement. The ending is the auditor's fix instead ("stay what it was").

3. **"The handle can move a little without choosing another seed." → "The handle moves smoothly, but each seed holds for less than a quarter of a millimetre of its travel, so almost any movement you can feel picks another seed."**
   Seed = `roundi(norm * 999.0)` (seed_replay_demo.gd:477). The native travel is 0.14 (commons/interactables/slider_horizontal.tscn:75). The slider is scaled 0.7 (commons/audio/rack_templates/RackTemplates.gd:180). There are no detents: `slider_steps` stays 0.0 (addons/godot-xr-tools/interactables/interactable_slider.gd:29, 109-110). The panel is 0.236 m wide (RackTemplates.gd:28-32, 46, 50, 86-89).
   - In the museum, the compact console scales the panel by min(2.2, 0.80/0.236) = 2.2 (commons/artifacts/randomness_space/museum_exhibit_stage.gd:103, 111). That gives about 0.216 m of travel, or 0.22 mm per seed.
   - In the plain grid map, the panel keeps its own 1.5 (seed_replay_demo.gd:436), which gives about 0.15 mm per seed.
   - Only endless_museum.gd:13271 installs the console.
   
   Both stagings are under a quarter of a millimetre. That is why I used the re-checker's wording and not the auditor's "twenty-two centimetres", which is true of the museum only.

4. **"The crank across the room makes a generator advance by hand, one state at a time." → "The crank machine near the entrance, a few steps to one side of the replay console, makes a generator advance by hand: one press of its CRANK button, one state."**
   - The crank is at cell (3,4) and the seed demo at (6,6), yaw 180, with its console pulled 1.0 m toward the entrance. The spawn is at (6,0). Sources: commons/maps/Random_Definition/map_data.json (interactables layer, lines 780 and 813) and ada_run/em_plan.json plans[62].
   - The control is a push-button labelled CRANK (algorithms/randomness/prng_crank_machine/prng_crank_machine.gd:880-884, 892-897). Each press runs exactly one LCG step (295-349) and is refused during the animation (296-297).
   - I kept the re-checker's structure but wrote "to one side of" in place of "beside" and left out left/right. The visitor's handedness depends on facing conventions that I did not verify at runtime.

5. **Anchors.** I added `<!-- @textile_comparison -->` before the textile paragraph and `<!-- @prng_crank_machine -->` before the crank paragraph. Both works are placed (map_data.json:888, 780) and discussed, but they had no tag. The textile paragraph was parsed into the seed demo's region, and the crank sat in the untagged region. The existing `<!-- @ -->` now stands before the closing handover paragraph, so the handover is still untagged ("prose about no work") and is not attributed to the crank. I checked the regions with `tools/final_tags.parse` on after.md. It gives six regions: untagged header, seed_replay_demo, textile_comparison, random_number_book_page_1955, prng_crank_machine, untagged close.

## Added (one placed work the chapter ignored)

**A new paragraph under `<!-- @random_number_book_page_1955 -->`, placed before the crank. It has three sentences.** The audit names this work as the direct counterpoint to the hall's replay: a table made to be read again, standing here as a stream that never returns. Every fact in it was checked:
- It takes its look from the RAND 1955 book of random digits (algorithms/randomness/randomnumbergeneration/scripts/random_number_book_page_1995.gd:3-4, the scene's script).
- It shows five-digit numbers (Helpers/NumberHelper.gd:5-6).
- It moves one row per second: `cascade_speed` is 1.0 (script:82, 276-282).
- Each column inserts a new value at the top and drops the lowest flowing one (411-441).
- The numbers come from the global `randi()` (NumberHelper.gd:6) because `page_seed` stays -1 (script:102, 262-264). Neither the map token (`random_number_book_page_1955:0:2.7:0.8`, which gives rotation, height and scale) nor em_plan plans[62] sets a seed.
- No history is kept, only `_cells` and `_frozen`.
- It stands at (9,16) in a 13x20 hall whose spawn is at (6,0), which is the far end.

I did not mention the touch-to-freeze gesture (script:387-398), because the page is raised 2.7 m and I did not verify that it can be reached.

## Left alone, and why

- "A result can surprise us and still know the way back to itself" and the title "A pattern that returns". Neither was flagged. Both are true of reconstruction from the seed.
- "waiting does not advance the generator that colours these grids". The re-checker confirmed it: `_pick` and `raw_prefix` use their own generators.
- The textile paragraph's claims (seed 41, NEXT SEED, RESET). The auditor marked them true.
- **slot_machine** (10,4) and **trng_vs_prng** (3,16) are also ignored by the chapter. I did not add them. The slot machine's lesson is eligibility (6^3 admitted outcomes), and that belongs to Random_Remove and later halls. The sequence notes already flag the idea as re-taught without its name. trng_vs_prng's TRUE RANDOM label claims physical entropy that its code does not use (TrngVsPrng.gd:229-252, 395 per the audit). Naming it would mean correcting its label, and that is a larger decision than this pass should make.
- The crank's SPACE and R keys also fire from `_input` on desktop (prng_crank_machine.gd:282-288), and project.godot binds Space to jump. That is a code issue, not a prose one, and the chapter does not depend on it.

## Limits

- Nothing was checked at runtime, and Godot was not started. The positions come from map_data.json and em_plan.json. No runtime capture exists of the current staging (see the audit).
- The ActionLine is probably hidden behind the compact console. The chapter never relies on it, before or after.
- The 1955 book's purpose is described from general history ("open at the same line and read the same digits again") and not from a repo source.

## Installed

`after.md` was installed to `commons/maps/Random_Definition/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `449ee9880e76…`, after `a38185f6b49a…`. No runtime or learner status changes, because the text changed and nothing new was walked.
