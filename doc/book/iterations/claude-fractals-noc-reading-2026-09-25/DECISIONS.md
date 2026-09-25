# Fractals — the Nature of Code reading, applied

Sequence `fractals`, all seven halls. 25 September 2026. Palle: "can you add these improvements to fractal sequence?" — so these are **installed**, not candidates. `before/` and `after/` hold each chapter and the editor; `<Hall>.diff` and `lsystem_editor.diff` are the deltas; `cantor_preset_probe.txt` is the readback. Reading and rationale: `doc/book/readings/NOC_fractals_2026-09-25.md`. Tasks: `doc/tasks/book_fractals.json` `.015`–`.023` plus `.003`, `.004`, `.014`. No agents; one Godot boot (the probe).

## 1. What changed, hall by hall

| hall | words | change | task |
|---|---|---|---|
| Recursion | 861 → 998 | `#` on the title; after "Seven levels produce seven squares": what *fractal* names (parts are reduced copies of the whole) and the edge (a straight line passes the copy test and is not one); footnote: Mandelbrot 1975/1982, the desks are NOC Examples 8.2 and 8.3 | .014 .015 .020 .003 |
| RecursiveTrees | 691 → 900 | GROW beat: say which branch comes next — every tip at once (a queue, `recursive_tree.gd:3,120`), where a self-call would take one branch to its last twig first, and the drawing would not show which; three-trees paragraph: a number (`recursive_tree_2`), a seed (`recursive_tree`), a sentence (`fractal_lsystem_tree` at (11,11), NOC 8.9: four rewrites, one every 1.5 s, angle control 10–45) | .016 .017 |
| CantorSet | 783 → 956 | the three stochastic trees at z 18 get their paragraph (recursive `_grow_tree`, three children near the trunk and two beyond, chance at every fork, separation level by level, `randomize()` so never the same tree — every desk's RESET returns the same object, these never do); footnote: Cantor 1883 / Smith 1874, the pagoda is NOC 8.4 | .023 .020 .004 |
| KochSierpinski | 1,261 → 1,389 | after "The next call receives these segments as its beginning": the CA halls' separate-next-array swap, and the sentence to come; the 256 pieces are separate objects nothing has asked to move; footnotes von Koch 1904 (+ NOC 8.5), Sierpiński 1915 | .018 .021(b) .020 .004 |
| MengerSponge | 825 → 855 | footnote Menger 1926, the universal curve | .020 |
| GoldenSpiral | 1,076 → 1,129 | footnote Liber abaci 1202, Virahanka/Hemachandra, Euclid's extreme and mean ratio, "golden" as a nineteenth-century word | .020 |
| Synthesis | 786 → 1,005 | the makers-before-the-name paragraph (dates; the Ba-ila settlements as a ring of rings — Eglash 1999 footnote; Islamic ornament); handover rewritten through Cantor as a grammar, naming the lab's new "Cantor" preset, with the quadratic-Koch caveat kept | .020 .019 |

Voice and structure of the shipped chapters are untouched: every edit is an added paragraph, an added clause or a footnote, and the handovers keep their last sentences.

## 2. The code change: a Cantor preset in the grammar lab

`commons/artifacts/lsystem_editor/lsystem_editor.gd`: `PRESETS[7] = ["F", {"F": "FfF", "f": "fff"}, 0.0, 5, "Cantor"]` (the turtle already draws `F` and walks `f`, `:311–322`); `"Cantor"` in the `preset` enum before `"Custom"` (clamp 0..8); `"cantor"` on the `grammar` DNA enum and in `GRAMMAR_INDEX` (7); the PRESET slider maps `/ 7.0` and `* 7.99` instead of `/ 6.0` and `* 6.99`; the header's seven becomes eight. Registry: `"cantor"` appended to `dna.axes.grammar` in `commons/artifacts/registry/commons_artifacts.json` (one line, line 8637; the file was already a 32,610-line reindent in the working tree).

Readback (`commons/testing/probe_lsystem_cantor_preset.gd`, the museum's configure-before-`_ready` path): `grammar:cantor` → preset 7 "Cantor", 32 `F` in 243 symbols, 64 line vertices = 32 drawn pieces, label "Cantor"; `cantor#depth:3` → 8 in 27; `grammar:koch` unchanged (preset 0, 4 generations, 625 `F`, 1,250 vertices). `check_dna_declarations.py`: `lsystem_editor.grammar ok`, `.depth ok`. No script errors in the Godot log. The angle clamps to 5° (the setter's floor) and is idle — the sentence has no turns.

Found on the way, not mine: the gate's one broken axis is `fibonacci_sequences.evidence` — declared `['result', 'trace', 'longhand', 'axiom']` with no `@export var evidence` on the fractals' own Fibonacci desk.

## 3. What was NOT applied

- `.022` (the biome ring's flora): the endless museum does not stand the biome ring — `BiomeRingComponent` is a `GridSystem` component and `endless_museum.gd` never mentions it — so a museum visitor never walks past the flora that `soft_stages.json` promises for the fractals stage. The nature tree is recursive (`TreeGrowthComponent._grow_branch`, depth from `dna.segments`), so the paragraph would be true in the grid lane and false in VR's venue. Left open with that note; it is a decision about the museum, not the chapter.
- `.021(a)`, a Koch whose segments the hand can pull: a design decision, still open.
- The tide and the diver are not named in the RecursiveTrees beat: graphtheory is spine index 20, fractals 12, so the reader has not met them.

## 4. Shared-tree facts

- `Fractal_Recursion/final.md` and `Fractal_KochSierpinski/final.md` were already dirty (an uncommitted rewrite; last commit 2026-09-03). The edits sit on top of the working-tree text, which is what `/api/book-text` serves. `lsystem_editor.gd` (+112 lines: lesson mode, batching, Custom) and the registry were dirty too. Forum 260925-q44xl (heads-up, settled with the outcome).
- Line endings preserved per file (Recursion, GoldenSpiral, Synthesis, the editor: CRLF; the other four: LF) — the Edit tool keeps a file's endings.
- Nothing committed; no map, sequence file, plan or bake touched. Two new probe files in `commons/testing/` (this one and `probe_gt_foundations_bodies.gd` from the graphtheory pilot) are uncommitted.
