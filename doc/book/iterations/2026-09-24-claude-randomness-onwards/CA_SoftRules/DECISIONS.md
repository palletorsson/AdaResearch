# CA_SoftRules: decisions

Cellular Automata, hall 6 of 8. 24 September 2026. Verdict: **Targeted revision (near-preserve)**: one added sentence. STATUS counts it as targeted because `final.md` changed. No sentence was changed. Text only. No code, map or repo file was touched, and Godot was not started.

## Preserved

Everything else is kept word for word: the title, the `<!-- @rd_artifact -->`, `<!-- @the_clockmaker_of_rules -->` and `<!-- @ -->` anchors, all three GDScript excerpts, every question, the COAT footnote, and the closing handover. That includes every line the audit listed under Preserve: the STEP-once comparison at W, the five-point Laplacian and why the repeated subtraction matters, the exchange-off argument, the "Soft is not a promise" paragraph, VIEW U/V, COAT, the clockmaker's still ring and ornamental crank, and the 2,400-update hold.

## Changes

No sentence was changed. The audit flagged two claims as overstated, and the re-check found the auditor wrong both times (see "Left alone" below). The brief says to change a sentence only when both agree, so both sentences stand.

## Added (one sentence)

At the end of the exchange-off paragraph, after "This difference is small enough to calculate and large enough to alter the wall.":

> Even the right-hand square's seeded cells cannot keep their V: at feed .037 and kill .060 the reaction alone has no resting state other than full U and no V, so by the end of the first hundred updates that square has nearly faded.

Why it is here: the chapter already explains why an unseeded site on the right never gets its first V. It does not say that B's own seeded square also disappears, although a visitor sees that happen during the first +100. The sentence names what the right-hand table does, and it makes the chapter's question sharper: without exchange, the seeded cells lose what they had, on top of never gaining anything. I put it in the mechanism paragraph rather than the encounter paragraph so that the one sentence carries both what is seen and why, and so that paragraph 3 still ends on its open question. It goes last so that "it" in "The left-hand field can receive it" still refers to the first V.

Evidence:
- The parameters are `FEED 0.037` and `KILL 0.06` (`commons/artifacts/rd_artifact/live_field.gd:5-6`). The readout prints them as "FEED .037 / KILL .060" (`exchange_study.gd:88`), so the visitor can read the same numbers.
- B has exchange off (`exchange_study.gd:25`). Then `coupling` is 0 and both Laplacians are 0 (`live_field.gd:35, 41-42`), so each cell runs only its local map (`:43-44`). The seed is a 6x6 square at U .5, V .25 (`:21-23`).
- "No resting state other than full U and no V": a fixed point of `x + f(x)` is a zero of the Gray–Scott reaction `f`, and a nonzero homogeneous state needs F >= 4(F+K)^2. Here 4(0.097)^2 = 0.0376 > 0.037, so none exists. I also checked the clamp edges by hand. U = 0 goes to F. U = 1 with V > 0 goes to 1 - V^2. On V = 1, U stays put only at F/(1+F), about 0.036, and there V falls to about 0.94. None of them is fixed, which leaves (1, 0).
- "Nearly faded by the end of the first hundred updates": I ran a float32 numpy copy of `live_field.gd`. It reproduces the runtime probe's W values (`doc/space/ca-soft-rules-review-2026-09-14/runtime-verification.json`: first_update, after100, after1000) to 4 decimals: 0.9200/0.0200, 0.2593/0.3790 and 0.8556/0.0143. In that copy, V in B's square goes 0.25 at tick 0, about 0.349 at its peak (tick 20), 0.030 at tick 100 (0.028 at 101, the count after the chapter's STEP then +100), 0.003 at 125, 0.0003 at 150, and 0 by 200. The initial view draws V x 2 (`exchange_study.gd:72`), so at tick 100 the square sits at about 6% of the colour ramp from the background, down from 50% at the start. That is "nearly faded". I did not claim a steady fade, because the square brightens a little before it declines.

## Left alone, and why

- **"Switch exchange off, replay, and look for the first place where they differ."** The auditor called this overstated because 44 cells differ after one update. The re-check showed that those 44 cells form one connected band at the edge of the seed, so there is a single first place in time. The interior differs only at tick 2. The re-check also found REPLAY redundant but harmless: `toggle_exchange` already calls `reset()` (`exchange_study.gd:52`), and the comment at `:50` expects REPLAY to be used this way. The auditor was wrong, so the sentence stays.
- **"The brass shapes make reading and writing almost look like trades we could perform with our hands."** The re-check found this true as a claim about how the bench looks. The drum and the crank are brass-toned steel (`the_clockmaker_of_rules.gd:131, 170`), and they sit beside the trays labelled read and write (`:162`). "Almost" already gives up any claim that they operate. The trays are matte (`:153`), and each tray draws its own random cells (`r.seed = seed + i`, `:157`), but the sentence claims neither of those things. The auditor was wrong, so the sentence stays. I did not take up the re-checker's optional tightening either, because the brief says not to rewrite true sentences.
- **Optional edits in the audit's handover** ("For each field" → "For each concentration", the timing of V saturation, the vertical flip between wall and table). None of them is a false claim, and none has a re-check. "For each field" reads correctly as the U field and the V field. The chapter never says the wall and the table have the same orientation, only that "each pair shares the same texture", which is true (`exchange_study.gd:101, 107, 118`).
- **The four placed works the chapter ignores:** lattice_gas_pump, ca_sphere:90, crack_propagation_ca and rule_30_110_gravity:90 (`commons/maps/CA_SoftRules/map_data.json:1424, 1475, 1548, 1550`). The audit did not read their code, and neither did I, so I added nothing about them. The possible echo between ca_sphere and the periodic-edge paragraph is still unchecked.

## Limits

- **Git state.** final.md is committed (9ffe105ea), but what it describes is not. That includes the study mount in `rd_artifact.gd` (+17 lines, uncommitted), the 17x26 map that places `rd_artifact:0:0#study:exchange#plinth:0` (`map_data.json:1194`) with `artifact_placement: "map"`, the clockmaker relabel and the registry flag. The chapter is true only once those land together, and the registry diff sits inside a whole-file reindent.
- **Python, not Godot.** The fade numbers come from a numpy copy that matches the probe at W. They are not a Godot readback of B's square, and the probe only reads W.
- **Reveal flow.** The probe (2026-09-14) is older than the 2026-09-19 change that hides the A/B exchange labels until EXCHANGE B is pressed. The arithmetic did not change. Nobody has probed the reveal in the museum or checked it in the headset.
- **Stale companions.** walked.md and eye_shot.md still describe 2 of the 6 works. field_notes.md names the wrong next hall. The comment at `the_clockmaker_of_rules.gd:155` claims the write tray holds successors. All of these are outside this brief.
- **Line endings.** after.md is before.md with one in-line insertion, written byte for byte with no newline translation.

## Installed

`after.md` was installed to `commons/maps/CA_SoftRules/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and no fixes were needed. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `32b4a5843bad…`, after `1da9b7e36817…`. No runtime or learner status changes.
