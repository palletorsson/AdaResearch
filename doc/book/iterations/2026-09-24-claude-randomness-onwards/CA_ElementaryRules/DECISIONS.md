# CA_ElementaryRules — decisions

**Verdict:** targeted revision. One sentence changed, none added. Everything else stays word for word.

## Preserved
- The title, the opening question and every other question, the paragraph order, and both `<!-- @structure_growth -->` / `<!-- @ -->` anchors.
- Both code excerpts. They are verbatim from `algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd:375-377` (the `== 1` count) and `:394-397` (the state-above-one branch).
- "The comparison is to `1`. A green neighbour holds `2`." Confirmed by Flexible.gd:376 and :390 (state 1 goes to 2 when `rule_states > 2`).
- The state-2 argument: state two goes to zero before any rebirth. Flexible.gd:380-397 checks birth only in the `state == 0` branch.
- The two buffers and no privileged first cell. Flexible.gd:399-402 swaps them once, after the whole pass.
- ACTIVE / FADING / DRAWN, and shell culling on six faces. Flexible.gd:425-447 hides any cell whose six face neighbours are all non-zero. The console counts are at structure_study.gd:85-92 and :130.
- The 20-step budget, `+20` without reseeding, the seeded REPLAY, and RUN toggling between RUN and HELD. See structure_study.gd:12, :29, :42-63, :94-104, :126-128.
- CHANGED as evidence of a fixed point. structure_study.gd:73-79 compares the two buffers after the swap.
- The empty edge, and its contrast with the previous board's wrap-around. structure_study.gd:51-60 clears the shell. Flexible.gd:365-369 never updates it. ca_rule_explorer.gd:378-380 wraps with modulo.
- The placement. `structure_growth#study:states` sits at (6,6), over a `0` floor cell. `dark_sphere` sits at (10,9) beside the route. Both are in `commons/maps/CA_ElementaryRules/map_data.json`.
- The restraint: no Turing-completeness claim, no claim that `M` selects among stencils, and the no-collision caveat.

## Changed
1. "Read CHANGED beside the generation count." became "Read CHANGED, beside DRAWN below the generation count, together with that count."
   - Reason: the auditor and the re-checker agree that the sentence names the wrong place. At structure_study.gd:129-130 the readout is a single Label3D. Line 2 holds `GEN g / b STATUS`. Line 6 holds `DRAWN d   CHANGED c`, with "NO STEP YET" in place of the CHANGED count before the first step. CHANGED therefore shares a line with DRAWN, four lines below GEN.
   - I used the re-checker's wording. It fixes the location and still says to read the two numbers together, which the next sentence ("A stopped clock alone ...") needs.

## Left alone
- The optional orb locator ("in the pocket to your left, past the far rim"). The auditor proposed it only as an option, the re-check did not confirm it, and no hall note reports a layout change. "Beside the route" is still true at (10,9).
- "Try RUN, then hold it." It is true because a second RUN press toggles to HELD (structure_study.gd:94-98, :126).
- "the rest of the museum keeps running." Unaudited, but the study only pauses its own parent (structure_study.gd:16-17).
- Sentences in the companion files (artifacts.md, walked.md, eye_shot.md, intent.md) that the audit flags as stale. They are outside this chapter and outside this task's write scope.

## Limits
- Godot was not run. The REPLAY/step performance concern in the audit is unmeasured and does not touch the prose.
- The commit state is a risk. The map rebuild, the Flexible.gd mount hook and the map_authored entry that build this console are uncommitted, while final.md is committed. The prose now matches the working tree, not HEAD. Forum thread 260924-s3yqc should land the whole set together. This revision did not touch those files.

## Installed

`after.md` was installed to `commons/maps/CA_ElementaryRules/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and no fixes were needed; the main agent reworded the one changed sentence into reading order (same facts). Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `2638c5ee9765…`, after `0ce19707a1be…`. No runtime or learner status changes.
