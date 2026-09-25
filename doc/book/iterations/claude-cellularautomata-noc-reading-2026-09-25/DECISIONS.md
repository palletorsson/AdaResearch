# Cellular automata — the Nature of Code reading, applied

Sequence `cellularautomata`, all eight halls. 25 September 2026. Palle: "apply" — installed, not candidates. `before/` and `after/` hold each chapter and `address_study.gd`; `<Hall>.diff` and `address_study.diff` are the deltas; `life_meet_trace_probe.txt` is the readback. Reading and rationale: `doc/book/readings/NOC_cellular_automata_2026-09-25.md`. Tasks: `doc/tasks/book_cellularautomata.json` `.026`–`.033`, folding `.002`, `.005`, `.009`, `.012`. No agents; two Godot boots (one parse failure of the probe itself, then the run).

## 1. What changed, hall by hall

| hall | words | change | task |
|---|---|---|---|
| Introduction | 1,364 → 1,574 | Wolfram footnote at the first "Rule 90" (numbering, 1983/2002, the RULE slider runs all 256; Ulam and von Neumann before him); the painters named as turmites, Langton's ants, with a footnote; the close carries **four** choices (hold / consult / when / settled by the rule or by a draw) and says every later hall changes one or two | .027 .030 (.009) |
| ElementaryRules | 783 → 805 | "Two of the four choices change at once: three states, twenty-six neighbours" | .030 |
| GameOfLife | 601 → 635 | "None of the four choices has changed in this hall … what has changed is where the past is kept" | .030 |
| BeyondBinary | 706 → 984 | still life / oscillator / spaceship named after they are watched; "the second choice, widened from two"; **TRACE** paragraph; MEET corrected to "empty within six generations; only A ever lights, and it was lit before the first step"; Conway's three design goals as the hall's edge, pointing at Edge of Chaos; the hexagonal field further in as "the second choice only: six neighbours, a birth on two"; Conway/Gardner 1970 footnote | .028 .029 .031 .030 .027 (.002) |
| ExpandingSpace | 758 → 791 | "Three of the four choices moved in this hall: a fraction, the visitor's position, the order of the loop" | .030 |
| SoftRules | 892 → 1,010 | "two fractions instead of one bit … not a count but a difference"; Gray–Scott footnote (1984; Pearson 1993 for the feed/kill range); Lenia footnote (Chan 2019, what a running one would be) | .030 .027 (.012) |
| AgentsCircuits | 546 → 777 | "the pyramid is not an automaton at all"; the **four classes beat** — turn RULE to 222, 190, press 30, 110, name the classes after (Wolfram 1984 footnote); the resemblance footnote rewritten to answer the plate's captions and to cite Cook 2004 as the theorem the caption points at | .030 .026 .027 (.005) |
| EdgeOfChaos | 734 → 944 | "this hall moves the first choice alone"; the name given its referent — Langton 1990, λ, the fourth class — and kept as a question; the averaging named as a blur, "an image filter is a cellular automaton run once"; the rear gallery's disease grid named as SIR (Kermack–McKendrick 1927) and as the fourth choice, settled by a draw | .030 .026 .032 .027 |

The four-classes beat stands in AgentsCircuits, not EdgeOfChaos: the explorer is placed in Introduction and AgentsCircuits, and both placements are the neighbours study, which builds the same "CA RULES" panel (RULE slider 0–255; buttons 30 / 90 / 110 / 184; `ca_rule_explorer.gd:249–259`). A 32-cell ring from a single seed was simulated for all four rules before the sentences were written: 222 fills to 31 cells by row 16 and every later row is identical; 190 is the `###.` stripe shifting with period 4; 30 has no repeated row in 24; 110 has none either and carries the structures. Rooms are not counted in the prose ("the hall called Edge of Chaos, ahead"), because the book's pearls put `Chamber_CA` between AgentsCircuits and EdgeOfChaos and the sequence file does not.

## 2. The code change: TRACE on the address study

`commons/artifacts/game_of_life_petri/address_study.gd` (the desk that dresses the dish in CA_BeyondBinary; the base `game_of_life_petri.gd` is untouched): a `trace` toggle and a third button row `TRACE`; after each step `born` and `died` are counted from the base solver's own two buffers (after its swap, `_next_grid` is the old present — the study already used that for CHANGED); with the trace on, a cell that just began is painted `7fb4ff` and one that just stopped `b5555f`, on the floor plane and on the dish, for one generation; a replay copies the present into the old-present buffer so it shows no births; the readout adds "BORN n DIED m" while tracing; `readback()` carries `born`, `died`, `trace`. Off by default, so the shipped look is unchanged until the button is pressed.

Readback (`commons/testing/probe_life_meet_trace.gd`, the museum's configure-before-`_ready` path):
- MEET: populations 9, 9, 9, 11, 6, 3, 0 — empty at generation 6; over the run only lamp A's address is ever occupied, and it is occupied at the replay (the block sits on (10,10)). Exactly task `.002`'s numbers; the chapter's "by generation 24" was wrong by eighteen.
- TRACE: at replay born 0 / died 0; after one glider step born 2, died 2, changed 4, population 5 (born + died == changed). Toggle off restores the readout line without the BORN/DIED field.

No script errors in the Godot log (a pre-existing UID warning on the petri scene aside).

## 3. Not applied

- `.033` (the hall names promise other rooms — ElementaryRules holds a three-state 3D automaton, GameOfLife holds Rule 30, BeyondBinary holds binary Life): a rename or a re-deal, for Palle/Astra. Left open.
- `.025` (companions and the registry claim CA "literally compute"): registry/companion text, not the chapter. Left open; the AgentsCircuits footnote now says where the proof actually is.
- `.015` (which CA_Introduction text stands — the block's checked chapter or the 14:20 rewrite): still Palle's call. These edits are on the working-tree (14:20) text, which is what the book serves; `before/CA_Introduction.final.md` is that text as found.

## 4. Shared-tree facts

- `CA_Introduction/final.md` was dirty (the 14:20 rewrite, forum 260924-zgl38); the other seven chapters were clean after commit `70bd571f1`, so their diffs here are only these edits. `address_study.gd` was clean; `game_of_life_petri.gd` is dirty with someone's study-mount work and is not touched.
- Line endings preserved per file (Introduction, EdgeOfChaos: CRLF; the rest LF).
