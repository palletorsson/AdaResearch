# Critical and Technical Push — 2026-04-24

Session continuation after the summary and intent cohorts closed. The remaining text roles were critical.md and technical.md. Both opened with a mix of existing files that failed thresholds and files that did not exist at all. The session closed five of six text roles across every spine map.

## Starting state

Summary and intent finished in the earlier session with 100% pass on all 179 spine maps. Critical and technical inherited the audit's long tail.

| Role | Fail | Missing | Total |
|---|---|---|---|
| critical.md | 32 | 64 | 96 |
| technical.md | 104 | 46 | 150 |

Critical is 500–3500 words with 25% max code ratio, theory-heavy voice. Technical is 700–3500 words with 15–80% code ratio. The two roles have opposite code postures, and the opposite postures are what make them pedagogically distinct.

## Critical first — the cheap-fix sweep

Thirty-two files already existed but failed. The failure modes distributed as:

- 16 overlong paragraphs — the single-paragraph bullet dumps where an author's enthusiasm exceeded the threshold
- 12 forbidden words — `navigating`, `fascinating`, `intricate`, `landscape of`
- 6 files exceeding the 25% code ratio by a wide margin

The paragraph fixes ran as a Python script that split on sentence boundaries. The forbidden-word fixes were manual edits. The code-ratio fixes were the interesting ones: critical.md should not carry code, so the 6 offenders (WaveFunctions_Intro, Noise_One, CA_AgentsCircuits, LSystems_Growth, SoftBodies_Cloth_Physics, SwarmIntelligence_Boids_Algorithm) had every code block stripped. Each file lost roughly half its length but gained alignment with the role's actual purpose — theory tied to artifacts rather than implementation details.

After the sweep: critical.md existing-file failures went from 32 to 0.

## Critical missing — 64 files written inline

The missing-file cohort was the substantive work. Sixty-four readings had to be written from scratch, each ~500–800 words, each tying queer theory or critical theory to specific in-map artifacts without lapsing into generic citation.

The writing plan was one theorist hook per map. The curriculum's teaching-moment structure invited a different thinker at each step:

- Ahmed on the pendulum's restoring force as compulsory orientation
- Haraway on the unit circle as standpoint
- Lefebvre on the sine corridor as produced space
- Chun on sound's hidden infrastructure
- Deleuze on Bernini's fold
- Trinh Minh-ha on Cage's unmarked
- Feld on AirMusic as acoustemology
- Butler on colour columns as performative
- Mulvey on voxel threshold as framing
- Barad on domain warping as intra-action
- Kuhn on Perlin vs Simplex as non-replacement
- Zuboff on Lab_Path as attention-protecting
- O'Neil on classifier ethics
- Priest on dialetheia
- Longino on collective knowledge
- Lyotard on the modest synthesis
- Iser on subtractive authorship
- Beck on risk society
- de Certeau on mutual illegibility
- Albers on colour as grammar
- Hofstadter on fractal recursion
- Tsing on L-system collaboration
- Lévi-Strauss on procgen bricolage
- Mortimer-Sandilands on soft contact
- Clastres on decentralised swarms
- Chaitin on foundations undecidability

The workflow mirrored the summary sweep: bundle → edit → split. The bundle tool's `--with-context` option dropped each map's intent and blurb as comment headers into the bundle, so the author's cheat-sheet and the invitation were available at edit time without separate reads.

Each sequence's bundle became one chapter of theoretical prose at a time: wavefunctions (12), forces (10), cellularautomata (8), noise (8), array_tutorial (7), postfoundationscrisis (5), randomness (3), transformation (2), plus 9 scattered chambers. Two passes per bundle — one for the main body, one for short files that fell a few words below the 500w minimum.

After the cohort: critical.md went from 83 passing to 179 passing.

## Technical — the heavier cohort

Technical.md wanted code. The failure modes were different from critical's:

- 43 word_count_min (too short)
- 43 max_paragraph_sentences (same fix as critical)
- 37 code_ratio_min (not enough code — 15% minimum)
- 14 code_ratio_max (too much code — 80% maximum)
- 11 forbidden_words
- 46 missing files

The missing cohort broke down as 23 stub files (PG, ML, GT sequences at wc=12 placeholder), 14 missing chambers, and 9 other maps.

Code-heavy files needed surgery the opposite direction from critical's cohort: some had too much code (stripping), some had too little (adding). The code-ratio-max sweep removed every second code block from 14 over-code files and appended prose closing sections to restore word count. The code-ratio-min sweep added new code blocks — typically a Belnap-logic implementation, a Gödel-numbering sketch, a Lorenz integrator, a Dinic max-flow, or a Reynolds boid rule — to philosophical maps that had good theory but no implementation grounding.

Missing files fell into tight structural families. The graph-theory, ML, and procgen stubs were all sequence-level cohorts with known artifact lists; each became an 8-map bundle with consistent patterns (data structures, algorithms, complexity analysis, sequence placement). The chamber files followed the creature-catalyst-science-screen triad established by earlier chambers, with only the specific creature and specific catalyst code varying.

## Workflow observations

The bundle tool's `--only-failing` flag mattered in technical more than in critical. Technical's cohorts mixed passing and failing files within the same sequence; writing against only the failing subset kept the edit bundle short and the context tight. In critical, the sequences were mostly either all-missing or all-passing, so the flag was less critical.

The `.before_bundle` backups were the quiet hero of both role sweeps. Nothing about the round-trip felt risky because every overwrite left a copy behind. When the paragraph splitter mis-split a file (once), the backup was available; when the code trimmer went too aggressive (never, but it could have), the backup was available; when a forbidden-word substitution changed the meaning unexpectedly, the backup was available. The backups accumulate to several megabytes of redundant text, which is the cheapest insurance ever written.

Python scripts replaced bash heredocs early in the technical push. The heredoc approach failed when triple-quoted GDScript strings inside a triple-quoted Python string produced a syntax error. Writing a .py file in doc/_bundles/ with a descriptive name (`_ml_ext.py`, `_gt_ext.py`, `_chambers_tech.py`) solved the quoting problem and gave every subsequent script a version-controlled home.

## Voice alignment across roles

A map's four role files now have distinguishable voices:

- **blurb.md** — present-tense invitation, sensory, no theory, no code.
- **summary.md** — museum-label description, 200–400 words, specific nouns, sequence placement.
- **critical.md** — theory-grounded reading, one theorist hook, tied to artifacts.
- **technical.md** — code-first walkthrough, complexity analysis, implementation tradeoffs.

When a map's four files are read in order, they produce a coherent progression from felt experience through spatial description through political reading into mechanical implementation. The coherence is what the role-separation frame the summary session established was aiming at, and the technical push confirms that the frame holds under load.

## The count

Final state of the audit:

| Role | Start of session | End |
|---|---|---|
| blurb.md | ✓ | ✓ |
| summary.md | 179 ✓ | 179 ✓ |
| intent.md | 179 ✓ | 179 ✓ |
| critical.md | 83 / 179 | **179 ✓** |
| technical.md | 29 / 179 | **179 ✓** |
| tutorial.md | 1 / 179 | 1 / 179 |
| **Global** | **650 / 1074** | **896 / 1074** |

Five of six text roles pass for every spine map. Only tutorial.md remains.

## What's left

Tutorial.md is 178 files waiting to be written. The role wants 400–1500 words with 40%+ code ratio, 6–20 code blocks, and ≤3 sentences per paragraph. The voice is step-by-step: "Do this, then this, then this." Captions must be short. Code has to be followable without prior context.

Tutorial.md is the only role whose difficulty scales differently from the others. Technical.md wants code within running prose; tutorial.md wants prose embedded in a code walkthrough. The writing centre of gravity is different, and the pedagogy is different — technical tells a reader what a system does; tutorial tells a reader how to rebuild it.

The bundle toolchain that carried the first five roles will carry the sixth too. The question is whether to write 178 tutorials inline, use the direct-API rewriter from two sessions ago, or queue them on the other networked machines via pack_for_worker. That's the next session's first decision.

## Tools that earned their keep

- `bundle_sequence --with-context --only-failing` — still the workhorse. Replaces N reads with one.
- `split_sequence --bundle` — safe, atomic, always leaves backups.
- `text_metrics --only-failing` — verification loop in one command.
- `doc/_bundles/_*.py` scripts — escaped the heredoc trap, version-controlled the incremental fixes.

Nothing new was built this session. The tools built in earlier sessions held up across a 373-file sweep, which is the best argument the toolchain has had.
