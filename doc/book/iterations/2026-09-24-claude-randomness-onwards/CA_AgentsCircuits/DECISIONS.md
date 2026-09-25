# CA_AgentsCircuits: decisions

Sequence `cellularautomata`, hall 7 of 8. 24 September 2026. Verdict: **Targeted revision**. Three sentences changed and one sentence added. Nothing else was touched.

`after.md` is the full revised chapter. `before.md` is byte-identical to `commons/maps/CA_AgentsCircuits/final.md` as found, and that file was not edited. `map_data.json` is also byte-identical to `map_data.before.json`, so the layout has not changed since the packet was cut.

## Preserved

- The title, the opening question ("Can two constructions resemble one another without doing the same calculation?") and every other visitor question.
- The paragraph order and both `<!-- @token -->` sections (`@ca_rule_explorer`, `@sierpinski_pyramid`) plus the closing `<!-- @ -->`. Anchor count is 3 → 3.
- The footnote `[^ca-resemblance]`, unchanged. It declines to read an agent, a circuit or universality off an appearance, which is what this hall's brief asks. The chapter still makes no claim that every CA is Turing complete or that any apparent circuit computes.
- "No instruction tells the display to draw a large triangle…", which is true because `_update_display` only colours stored rows (`ca_rule_explorer.gd:393-402`). Also "Its procedure begins with a shape and a copying arrangement…", "A failed correspondence tells you where the analogy stops", the SEED procedure, and the handover to Fractals and to the paired volumes in CA_EdgeOfChaos. That handover checks out: `Fractal_KochSierpinski/map_data.json` places `sierpinski_pyramid…#lesson:true`, and `CA_EdgeOfChaos/map_data.json` places `self_organization_ca:0:0#study:difference`.
- The chapter has no code excerpts.

## Changes

The audit and its adversarial re-check agreed on all three. Each rewording is the re-checker's, or a narrower form of it. I recomputed every fact myself from the code (scratch simulations, not in the repo).

1. **Paragraph 1: "Add another row" was unbounded.**
   - Before: "Add another row when you need more to compare."
   - After: "Add rows, up to fifteen steps, when you need more to compare; at the sixteenth the two edges meet around the ring and every new row from then on is empty."
   - Evidence: in this hall the token is `ca_rule_explorer:180:1.04:1#study:neighbours#rule:90#plinth:0` (`map_data.json:708`). The study mode sets 32 cells and 24 rows (`ca_rule_explorer.gd:104-111`). The seed is at cell 16 (`:361`). The update is `(rule >> neighbourhood) & 1` (`:368-370`), and rule 90 makes that left XOR right. Both edges wrap (`:378-380`). My simulation of exactly this update gives live counts 1,2,2,4,2,4,4,8,2,4,4,8,4,8,8,16 for steps 0-15. Step 15 is every odd cell, so at step 16 every cell sees two equal neighbours and the row is empty. An empty row is a fixed point. I dropped the re-checker's "the pattern vanishes": rows already drawn stay on the board until the 24-row limit pushes them off (`:385-388`), so only the *new* rows are empty. "Ring" is already established for this desk in CA_Introduction ("What looks like a line on the desk is a ring to the calculation"). A reader who stops at fifteen steps has 16 rows, inside the 24-row board, so the row limit needs no mention.

2. **Paragraph 5 (pyramid): "at selected corners" named four of six placements.**
   - Before: "This construction makes smaller copies recursively at selected corners."
   - After: "This construction repeats its arrangement recursively at half the spacing: four copies at the lower corners, one at the apex and one more directly above it, which lifts the top into a spire."
   - Added: "The cubes do not shrink with the spacing, so neighbouring copies overlap."
   - Evidence: `SierpinskiPyramid.gd:66-73` makes six calls per non-leaf node. Four go to `(±offset, -offset, ±offset)`, one goes to `(0, +offset, 0)`, and one more, gated by `extra_crown`, goes to `(0, +half_size, 0)`. `extra_crown` defaults to `true` and is not exported (`:42`). Only the opt-in lesson changes it (`:84-87`, `:102-104`). This hall's token `sierpinski_pyramid:0:0:0.42#plinth:0.25` (`map_data.json:819`) passes no lesson, and `SierpinskiPyramid.tscn` overrides nothing, so the figure is depth 4 with contact packing. Every leaf is scaled `size * fill` at any depth (`:79-80`). The spacing halves (`:63, 68`) but the cubes do not. At the lowest level leaves sit 0.5 × size apart and are 1.0 × size wide, so neighbouring copies overlap. My recomputation gives 1296 leaves, 60 of them coincident, and bounds of 8.5 wide × 12.25 tall (y from −4.25 to +8.0). With the extra call disabled the bounds are 8.5 × 8.5 with 625 leaves, so the extra call alone raises the top. This matches the registry's `dna.default` ("six recursive calls per nonterminal node, 1296 leaf instances") and the script header ("four lower corners and two upper placements"). I added the overlap sentence because the chapter asks "At which scales do gaps correspond?", and the overlap is exactly where the pyramid's gaps close. It is the auditor's own wording, with "with the spacing" added.

3. **Paragraph 8 (pair seed): the question presumed an overlap that never happens.**
   - Before: "Where do the familiar triangular relations return, and where do they overlap?"
   - After: "Where do the familiar triangular relations return, and do they ever overlap?"
   - Evidence: SEED calls `toggle_seed` (`ca_rule_explorer.gd:469`), which seeds cells 16 and 17 (`:361-363`). Rule 90 is additive, and each single-seed history occupies one parity per step. I simulated seeds at 16 and 17 separately: they share 0 cells at every step. The pair history's counts are exactly double the single counts (2,4,4,8,…,32), then 0 from step 16. The question stays open. It now allows the true answer, which is no.

## Left alone, and why

- **"Set the rule explorer to Rule 90 and reset its central seed."** This is true. The 90 preset and RST are on the CA RULES panel (`ca_rule_explorer.gd:255-259, 299-313, 338-339`), and CA_Introduction has already named RST. The audit left naming RST optional.
- **Sending the visitor to CELL and the LEFT / SELF / RIGHT / NEXT plate** (audit optional fix 4). I did not add this. CA_Introduction already teaches that plate at length (its paragraphs on CELL, "left, self, right", and the ring), and the "still" in "Each new cell is still calculated from a local neighbourhood" points back to it. Repeating it here would be a second lesson, not a repair.
- **The rule plate's "Sierpiński" label** (`:94`) and **preset 110's "Turing Complete" label.** These are instrument text, not chapter claims. The footnote already declines universality. Correcting the label is a code or registry matter.
- **"The row's next state and the pyramid's smaller copies…"** (paragraph 7). Neither pass flagged it. The copies are smaller in extent even though their cubes are not, and the changed sentence now says which is which.
- **"Find a small pyramid and compare where its neighbours sit."** Not flagged. The arrangement does repeat at every scale.
- Every sentence on the audit's preserve list.

## Limits

- Godot was not run. The figures come from reading the code and from Python recomputations of the implemented update and recursion. They were not read back in the engine.
- **Commit state (audit handover 1, highest risk).** The chapter is committed (`9ffe105ea`), but the hall it describes exists only as uncommitted edits to `map_data.json`, `ca_rule_explorer.gd` and `SierpinskiPyramid.gd` (confirmed by `git status`). At HEAD the explorer has no study desk (no STEP / SEED / CELL), and the museum would take the bench stamp. The edits may belong to a live session. Ask on the forum before committing them. This revision does not change that risk.
- There is no build evidence for the current layout. `em_bake.json` has no row for this hall, and `em_pack_report.json` still records the older, mirrored bench layout (audit handover 2).
- These are stale and outside the write scope: `blurb.md`, `intent.md`, `summary.md`, `technical.md`, `critical.md` and `artifacts.md` still describe Wireworld, Langton's ant and CellularAutomata3DStacked, none of which is placed. They also claim "cellular automata literally compute" / "anything is computable". The `ca_rule_explorer` registry description also overclaims ("custom neighborhood and transition tables", Rule 110). `neighbour_study.gd:2` still says the desk is "for CA_Introduction".

## Installed

`after.md` was installed to `commons/maps/CA_AgentsCircuits/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and one fix applied: 'the pattern's two diagonal edges meet around the ring', so the edges are not read as the board's two ends. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `b192cbe9b731…`, after `b17878f9d565…`. No runtime or learner status changes.
