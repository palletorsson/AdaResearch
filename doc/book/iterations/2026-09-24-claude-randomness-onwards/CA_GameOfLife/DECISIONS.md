# CA_GameOfLife: decisions

Cellular Automata, hall 3 of 8. 24 September 2026. Verdict: **Targeted revision (near-preserve)**: one small error fixed in two places. STATUS counts it as targeted because `final.md` changed. Text only. No code, map or repo file was touched.

## Preserved

Everything else is kept word for word: the title, the `<!-- @ca_bridge -->` / `<!-- @ -->` anchors, both code excerpts, every question, and the closing handover to the two-dimensional present. That includes every line the audit listed under Preserve. The chapter still centres the Rule 30 history study and keeps Conway's Life out of it. It never calls the frame load-bearing, and it keeps collision (tiles only) apart from ornament (lattice infill).

## Changes

**1. The desk marks are bars, not squares.** The audit and the re-check both found this false. I used the re-checker's wording.
- Before: "Its small coloured squares have relatives ahead: tiles laid across the recess, and a lattice standing along its side."
- After: "Its small coloured bars have relatives ahead: tiles laid across the recess, and a lattice standing along its side."
- Evidence: each FlatRecord mark is a `BoxMesh` of 0.092 x 0.04 x 0.012 m, about 2.3:1 in the plane of the desk face (`algorithms/cellularautomata/ca_bridge/history_study.gd:199`). The mark pitch is 0.10 by 0.048 (`:204`). The console is tilted (-60, 180, 0) (`:195`), which makes the marks look even less square from standing height. Every cell is drawn: a one gets the 78d9bd-to-e2a4de gradient, and a zero is dark (30494d, or 17292e for rows not written yet) (`:120`, `:127`). So "coloured bars" singles out the ones among dark bars. The desk is this study because the map places `ca_bridge:0:0#study:history#plinth:0` (`commons/maps/CA_GameOfLife/map_data.json:1451`), and `ca_bridge.gd:90-91` and `:250-252` mount `history_study.gd` (`:97-112`).

**2. The same error again in the three-dressings paragraph.** The auditor's fix names this sentence ("and later 'a one becomes a coloured mark'"). The re-check confirms it: "The same mistake appears again ... 'On the desk, a one becomes a coloured square'". I used "bar" so it matches change 1.
- Before: "On the desk, a one becomes a coloured square."
- After: "On the desk, a one becomes a coloured bar."
- Evidence: as above (`history_study.gd:199`, `:127-128`). The basin tile stays a "tile": it is `CELL` 0.4 x 0.22 x 0.4, square from above (`:158`, `:6`).

No sentences were added.

## Left alone, and why

- **"Press ROW. The line moves into an earlier part of the pattern."** In its summary line the audit notes that ROW wraps at generation 0, but it does not list this as a false claim, and there is no re-check of it. The sentence is true where the chapter puts it. `_ready` calls `replay()` and then `_advance()` eleven times (`history_study.gd:35-38`). Each call sets `selected = history.size() - 1` (`:76`), so the visitor starts on generation 11 of 12. `previous_row` is `posmod(selected - 1, history.size())` (`:97`), so the first press goes to generation 10, which is earlier. It only wraps to the newest row after the visitor has stepped back to GEN 0. It only moves the cursor and readout (`:95-99`), so "Nothing has been recalculated" also holds. Adding a sentence about the wrap would fall outside the brief, which allows additions only for handovers or ignored works.
- **"one occupied square" / "that square" / "Which squares will appear"** (paragraphs 3 and 4). Neither the audit nor the re-check flagged these. They read as the record's cells, and the basin's tiles really are square from above. A later pass might want one vocabulary, now that the desk is described in bars.
- **`100` and `001`.** The auditor offered `110`/`011` as an optional edit. The sentence claims only that they "ask different questions of the rule". That is true: the indices are 4 and 1 (`ca_bridge.gd:230`). It does not claim that Rule 30 answers them differently (it answers 1 to both).
- **The four rear-gallery works** (lab_room with turing_apparatus, ca_columns, mirrored_cellular_automata, dark_sphere). The audit did not read their code, and this hall's brief was "change only the confirmed sentence(s)". Nothing was added. lab_room's signage ("Rule 110 → universal computation", "Game of Life is Turing complete") is about other rules. The chapter rightly does not lean on it.

## Limits

- **Git state.** final.md is committed, but its map (15x37, `study:history`) and the `ca_bridge.gd` study hook are still uncommitted, per the audit. At HEAD the museum would build the legacy growing bridge. This chapter is only true once those files land together.
- **Stale companions.** walked.md, eye_shot.md and the `ca_bridge.gd` @identity comment still carry the old "walking on computation" claims. They are outside this brief.
- **Nothing was walked or booted.** Whether a lone 0.4 m empty site lets a body fall through is still unmeasured.
- **Line endings.** after.md was produced from before.md by two in-line substitutions. Both files use LF.

## Installed

`after.md` was installed to `commons/maps/CA_GameOfLife/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and no fixes were needed. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `780fca9f4f67…`, after `5dfbd9069735…`. No runtime or learner status changes.
