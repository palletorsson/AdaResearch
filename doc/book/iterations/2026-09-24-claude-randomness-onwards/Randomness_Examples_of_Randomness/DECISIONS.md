# Randomness_Examples_of_Randomness — decisions

**Verdict: Targeted revision.** The chapter's layout, the Pollock line rule, the Monte Carlo formula, the pipe's turn rule and the five particle procedures all match the code. I changed four passages (five sentences) where the audit and its re-check agreed. I added three sentences, each verified in code. `before.md` is byte-identical to `commons/maps/Randomness_Examples_of_Randomness/final.md`, and I did not edit `final.md`.

## Preserved

- The title, the section order and every `<!-- @token -->` anchor, including the closing `<!-- @ -->`.
- The formula block and every question.
- Every line on the audit's Preserve list, word for word. That includes "it is not a brush whose movement you are controlling, and the drops are not a simulation of falling paint", which is kept inside the rewritten Pollock sentence.
- The closing handover to Random_Pheromone. The audit rates it good, and the code bears it out.

## Changes (audit and re-check agree)

1. **Pollock cursor (the ¶ after the homage ¶).** Overstated. Each line is fully painted into the image before its path signal fires (`algorithms/randomness/proceduralrandomness/movementbased/scenes/pollock2d/paint_dripping_2d.gd:133-136`). The texture updates at the end of the batch (`:89`). The cursor tween starts on that signal (`pollock_painting_in_3d.gd:217`) and kills any running tween (`:207`), so it retraces one line that is already painted. I used the re-checker's rewording. The cursor is a `SphereMesh` (`:168`).
2. **AUTO/RESET instruction (the dartboard's first ¶).** Overstated. `auto_throw` defaults to true (`algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd:143`). `_process` stops at `max_darts` without clearing it (`:267-273`). `_reset` never touches `auto_throw` (`:1043-1055`). So a visitor who meets a full board and presses RESET restarts automatic throwing. The re-checker's order works whether the board is still filling or has stalled. AUTO is wired at `:1033` and RESET at `:1040`.
3. **"An outside point increases only the total" (the dartboard's second ¶).** False as the visitor reads it. The `works` rung, which is the map token at `map_data.json:1174`, prints separate `darts`, `inside` and `outside` counters (`monte_carlo_dartboard.gd:596-599`, where `outside` = total − inside). An outside throw therefore moves two counters. The first sentence, "An inside point increases both the inside count and the total", is true, and I left it.
4. **"The board keeps at most 500 darts…" (the THROW ¶).** False. The counters cap at 500 (`:142`, `:427-428`), but the board frees its oldest mark once it holds more than 300 (`:502-505`). I followed the re-checker's rewording and added the audit's memory clause ("the picture forgets points the numbers still include"), because the chapter's lead is about memory.

## Added sentences (verified by me)

- **Opening, handover repair:** "The estimation the last room promised is the dartboard's job." Random_Space_Geometry closes "The next room uses random samples for estimation". Before this, the chapter took up that thread only at the dartboard's last question.
- **Pipe, a placed work doing real work:** "The colour shifts gradually from one length to the next, swinging between cyan and magenta twice over the run, so two neighbouring passages in clearly different colours were laid at different times." Evidence in `algorithms/randomness/pipedream/PipeDream.gd`: each segment gets `_segment_color(segment_count)` (`:287`), set as its albedo and emission (`:313`, `:352-366`). The blend is `0.5 + 0.5·sin(t·TAU·2)` over the run (`:369-376`). The base colour (0.2, 0.8, 1.0) is cyan and the accent (1.0, 0.35, 0.9) is magenta (`:127-128`). With 180 lengths, neighbouring lengths differ only slightly. The sentence serves the ¶'s own task of finding "an earlier passage". It claims only one direction: a matching colour does not prove the same moment, because the cycle repeats.
- **Particle study, noise chapter, handover to the previous hall:** "No random draw enters that motion, and its caption says it is not Perlin noise: the last room's coherent heights changed with SEED, but this field has no seed to change." Evidence in `algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd`: `update_perlin_noise` moves particles by `noise3` and time only (`:337-364`). `noise3` is a fixed product of sines and cosines (`:587-588`). The chapter's opening positions are a deterministic grid (`:280-284`). The on-screen description reads "not a Perlin noise implementation" (`:122`), in a Label3D below the sphere (`:218`). The previous hall's Perlin side is seeded (`algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd:104`) and has a SEED slider (`:205`, `:230-233`).

## Left alone, and why

- **"explain the change from the counters before looking at the distance from pi."** The re-checker showed this is true: the counters sit above the `actual π` / `error` lines (`monte_carlo_dartboard.gd:586-615`). Its rewording was offered only as an optional tightening.
- **"If growth has finished by the time you arrive…" (pipe).** There was no re-check. The museum also suspends a body's `_process` until the visitor comes within the show ring (`commons/scenes/endless_museum.gd:16544`, `:16631-16651`), so the 14.4 s growth clock does not start at build. The "if" is defensible.
- **"last bay on the right" / "within its bay" (particle study).** There was no re-check. The map's structure layer has no interior walls, but the museum stamps its own hall architecture, and I did not measure what stands there.
- **"It chose … different kinds of variation within the particle study" (closing).** There was no re-check. The added noise-chapter sentence now tells the reader that one chapter has no draw, which removes most of the overstatement without touching this line.
- **"The noise chapter."** Not flagged sentence by sentence. The code's own chapter key is `noise` (`extrem_randomness.gd:40`), and the on-screen title is "Trigonometric Flow". The added sentence names the caption.
- **Line 7, "follow the brush cursor as it traces a path."** True. It traces a path, and the rewritten ¶ says which one.

## Limits

- This is a reading of the code only. I did not start Godot, and nothing was walked or captured.
- I did not act on the audit's proposed encounter fix: the dartboard's D/SPACE/R keys fire from the museum's walking keys on desktop, and SPACE toggles AUTO (`monte_carlo_dartboard.gd:276-284`). That fix is a code change outside the two files this pass may write. On desktop, it can still undo the chapter's AUTO step.
- I did not touch the stale companions the audit lists (blurb.md, technical.md, critical.md, summary.md, intent.md/tutorial.md, the map's documentation.layout, the book wall text for Pollock in `commons/data/book/randomness.json`).
- I did not check how visible the pipe's colour is under museum lighting. The claim rests on the material code.

## Installed

`after.md` was installed to `commons/maps/Randomness_Examples_of_Randomness/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `1664e9ad746a…`, after `2a5c95fbf29e…`. No runtime or learner status changes, because the text changed and nothing new was walked.
