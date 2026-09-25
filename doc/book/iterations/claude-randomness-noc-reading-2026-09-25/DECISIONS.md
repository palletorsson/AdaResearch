# Randomness — the Nature of Code reading, applied

Sequence `randomness`, nine of fourteen halls. 25 September 2026. Palle: "apply" — installed, not candidates. `before/` and `after/` hold each touched chapter and `distribution_sampler.gd`; `<Hall>.diff` and `distribution_sampler.diff` are the deltas; `sampler_width_probe.txt` is the readback. Reading and rationale: `doc/book/readings/NOC_randomness_2026-09-25.md`. Tasks: `doc/tasks/book_randomness.json` `.035`–`.044`, folding `.013`. No agents; one Godot boot.

## 1. What changed, hall by hall

| hall | words | change | task |
|---|---|---|---|
| Random_Definition | 999 → 1,083 | footnote at the 1955 page: *A Million Random Digits with 100,000 Normal Deviates* (RAND 1955, the roulette wheel of 1947, why the tables ended, a line as a seed) and Coveyou's sentence | .035 (.013) |
| Random_Cubes | 1,381 → 1,423 | at the coin ribbon: read it as steps, heads forward and tails back; "the simplest random walk is a coin on a beam; two rooms on, a block on a rail takes it" | .036 |
| Random_Walk | 1,707 → 1,863 | LONG STEP named as the code's Lévy flight with a footnote (Lévy; Mandelbrot's phrase, 1982; Viswanathan 1996 and the argument since); the long step as the way out of a worn patch; the rail's pink block as "the coin you tossed two rooms ago"; the 128 field's high places as *oversampling*, counted | .036 .037 |
| Random_Gaussian | 1,123 → 1,204 | "two draws in three within 0.15, nineteen in twenty within 0.30"; the WIDTH button and what it shows; the splatter's two-in-five as the same rule on a plane (a disc, not an interval); the panel list gains WIDTH | .038 .044 |
| Random_Mushrooms | 1,497 → 1,620 | the `* 2` and the field's frequency ½ named as the knob that sets a clearing's width, "in Random Space Geometry that number is a slider"; the rejected candidates named as the accept–reject method, with a footnote; the sampler's beads as the other road | .039 .041 |
| Randomness_Examples | 1,205 → 1,282 | "Estimating by sampling is what the name on this bench, Monte Carlo, has meant since 1949" with a footnote (Metropolis and Ulam 1949; the casino; Ulam's uncle; accept–reject as the other classic form) | .039 |
| Random_Game | 2,076 → 2,121 | the equivalence: a clock every half-second, or one every tenth with a one-in-five chance — the same cubes an hour, a different room; the podium's drawn delays as the second kind | .040 |
| Random_Space_Geometry | 625 → 688 | Perlin footnote (1983 *Tron*, the 1985 paper, the 1997 Academy Award, simplex 2001; this bench is FastNoiseLite's gradient Perlin; the mixer in Random Space is sines and says so) | .042 |
| Random_Remove | 1,734 → 1,771 | the hoppers' arithmetic: one in eight on the left, none on the right; after seven pulls one answer left vs eight | .043 |

Not touched: Random_Entropy, 10 PRINT, Random_Rotate, Random_Pheromone, Random_Space — the reading found nothing NOC adds to them.

## 2. The code change: WIDTH on the sampler's cabinet

`commons/artifacts/distribution_sampler/distribution_sampler.gd`: `WIDTH_CHOICES = [0.08, 0.15, 0.25]`; a third row on the cabinet's second panel (BATCH · PAUSE / NEW SEED · BINS / **WIDTH**) wired as `Btn_4 → cycle_width()`; `set_width()` clamps into the export's range, runs the same `_clear_samples()` CLEAR runs (the named seed restarts, the orange curve and the readout are recomputed), rebuilds the pale expected bars when the cabinet has them, and refreshes the readout. `bin_probabilities()`, `_theoretical_pdf()` and `_law_line()` already read `gaussian_std`, so nothing else had to learn about the button. 0.15 is what shipped and is the value the cycle returns to.

Readback (`commons/testing/probe_sampler_width.gd`, cabinet stood through `apply_grid_config` before `_ready`, seed 20260925, GAUSS, 600 draws by BATCH at each width):

| press | σ | cleared first | within 1σ | within 2σ | law line | tallest expected bar | clipped |
|---|---|---|---|---|---|---|---|
| 0 | 0.15 | yes | 0.707 | 0.945 | GAUSS · μ 0.50 σ 0.15 | 52.8 | 0 |
| 1 | 0.25 | yes | 0.705 | 1.000 | … σ 0.25 | 31.8 | 32 |
| 2 | 0.08 | yes | 0.705 | 0.947 | … σ 0.08 | 96.9 | 0 |
| 3 | 0.15 | yes | 0.705 | 0.947 | … σ 0.15 | 52.8 | 0 |

So the chapter's "two draws in three, nineteen in twenty" holds on the hall's own generator (0.683 and 0.954 in the model; 600 draws land within sampling error), the cycle returns to the shipped width, and two things worth knowing came out of the numbers: the within-1σ fraction is identical at every width because the seed replays the same standard draws and WIDTH only scales them; and at σ 0.25 the within-2σ fraction is 1.000 with 32 draws clipped — the tails are folded onto the edges, exactly as the chapter's clipping paragraph says. No script errors in the Godot log.

The sampler was already dirty with another session's uncommitted work (+32/−16: signage text, in-flight reservation with `_drawn`, marker clearing); the WIDTH hunks sit on top of it and the commit lands both, as the message says.

## 3. Not applied, and cautions

- Nothing from the ten tasks is left out. `.015`/`.016` (which text stands for 10 PRINT and Random_Cubes — the block's checked chapter or the 14:19 rewrite) remain Palle's; these edits are on the working-tree text, which the book serves.
- Five of the nine chapters were dirty before these edits (Random_Cubes, Random_Walk, Random_Gaussian, Random_Game, Random_Remove: the rewrites of 24 Sept 14:19, forum 260924-zgl38); the commit lands those rewrites with the edits. The other four were clean after `70bd571f1`.
- Line endings preserved per file (eight CRLF, Random_Space_Geometry LF).
- The mushrooms sentence says "about a metre": FastNoiseLite Perlin at frequency ½ sampled at `pos * 2` has a feature scale of order 1 m; it is an order-of-magnitude statement, not a measurement.
