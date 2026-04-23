# Summary Audit — 2026-04-23

One session. One role. Every summary.md in the spine, from 83 passing to 179.

## The starting state

Blurbs were already clean from the previous session. The remaining text-audit mass sat in four files per map: intent, summary, critical, technical. A quick count of failures showed where the cheapest win was.

| Role | Fail | Missing |
|---|---|---|
| summary.md | 30 | 66 |
| intent.md | 26 | 5 |
| critical.md | 32 | 64 |
| technical.md | 104 | 46 |

Summary had the smallest word budget, the smallest code burden, and the largest ratio of placeholder text to prose. Starting there.

## What is a summary, exactly?

Before writing any, we spent a turn separating summary from its neighbours. The four files had drifted into the same voice over time — long, hedged, gesturing at theory. If summary is just a short critical.md, the category earns nothing and the writing task has no shape.

The sort that held up:

- **intent.md** — authorial cheat-sheet. Concept / sequence role / technical angle / critical angle / key artifacts. Terse metadata. Private.
- **blurb.md** — 40–260 words. Invitation read before entry. Present tense, sensory, no theory, no code.
- **summary.md** — 180–1500 words. Museum wall label. What is this map, what happens in it, where does it sit in the arc. No code. No theorist citations. No steps. Descriptive, not hortatory.
- **critical.md** — 500–3500 words. Theoretical reading. Argues a position.
- **technical.md** — 700–3500 words. Code, artifact file paths, complexity, failure modes.
- **tutorial.md** — 400–1500 words. Follow-along kit.

The anchor was the word "catalog". Blurb is a poster. Summary is the catalog entry. Critical is the essay. Technical is the spec sheet. Tutorial is the kit.

Point_One's old summary ran to 1879 words, used stanza breaks, invoked Heidegger, and read as a small essay — a perfect critical.md. Its rewrite at ~260 words was the test of whether the distinction was actually operable.

It was.

## The workflow

The prior session had built three tools for distributed text work: `bundle_sequence.py` to concatenate a sequence's files into one document, `split_sequence.py` to fan them back out with atomic backups, and `pack_for_worker.py` to wrap a bundle as a self-contained prompt for any other Claude Code session.

This session ran almost entirely on the first two, with the inline model doing the writing directly rather than spawning a subprocess:

```
bundle_sequence --sequence X --file summary.md --with-context --out X.md
# read bundle once
# write all N sections in one edited file
split_sequence --bundle X_edited.md
# verify with text_metrics
```

`--with-context` was the variable that mattered. It drops each map's intent and blurb as comment headers inside the bundle, so a single read gives you the authorial cheat-sheet, the poster, and the existing summary (or a `[empty — file does not yet exist]` marker) for every map in the sequence. One 10-kilobyte bundle replaces thirteen separate reads and writes.

## The cohorts

Nine bundle rounds, in order of headcount:

- wavefunctions — 13/13 (12 missing + 1 short)
- forces — 10/10 (all missing)
- noise — 9/9 (all missing; Random_Noise_Types skipped as already passing)
- cellularautomata — 9/9 (all missing)
- machinelearning — 9/9 (placeholder stubs)
- proceduralgeneration — 8/8 (placeholder stubs)
- graphtheory — 8/8 (placeholder stubs)
- array_tutorial — 7/8 (Array_Patterns skipped)
- postfoundationscrisis — 6/8 (Rhizome and Lab_Equipment skipped)

Plus individual writes and edits for the tail: Point_One, Trans_Introduction, LSystems_Living, SwarmIntelligence_Swarm_Intelligence_Algorithms, Random_Cubes, Random_Remove, Random_Game, Trans_Pit, and nine Chamber_* rooms that had not yet been written at all.

Ninety-six files passed when the round finished. ML_Synthesis caught a stray `navigating` on the forbidden-words list and needed a one-word edit to close it out.

## Shape of the voice

The texts converged on a few moves without being asked to. They name the spatial arrangement early ("a small control room", "a tall vertical amphitheatre", "three islands connected by jump pads"). They point at specific artifacts in the space rather than generic objects ("a frame_counter_display", "a paradox_stalker"). They close on the sequence-arc placement — where does this map sit relative to what came before and what comes after — because that is the question summary answers and none of the neighbouring files do.

The chambers needed a consistent structural move of their own. Each catalyst chamber has the same shape: creature, catalyst, science screen, return to Lab. Writing nine of them in a row exposed the risk of the category collapsing into boilerplate. The fix was to let each chamber lean into its specific creature and its specific catalyst mode, and to treat the shared structural shape as rhythm rather than as content. Chamber_Foundations does not hide that its lesson is the same lesson as Chamber_QFEP — "a limit, not a method" — because the lesson is load-bearing.

## What the count did

Before:  summary.md passing 83, total passing across the full 1074-file text audit 523.

After: summary.md passing 179, total passing 619. Failing dropped from 192 to 162; missing dropped from 359 to 293.

The audit is a third complete, measured in file count. The three remaining roles are the heavier ones — technical and critical each carry higher word budgets, and technical requires real code. The summary pass-through was the cheap cohort, and running it first cleared a category of failure modes that were leaking noise into everything else.

## Tools that earned their keep

`bundle_sequence --with-context` is the tool I would reach for again without thinking. It saves reads by at least a factor of ten, and the comment headers mean the editor does not have to hold the authorial cheat-sheet in a separate tab.

`split_sequence`'s `.before_bundle` backups are the safety net that makes the whole pattern usable. Nothing about the round-trip felt risky because every overwritten file left a copy behind.

`text_metrics --only-failing` let me verify each cohort in one command and catch the single forbidden-word slip without reading ninety-six diffs.

## What's next

Tomorrow's cohort decision is between intent (31 files, cheap), critical (96 files, medium), or technical (150 files, heavy). Intent is probably the next small cleanup. Critical is the next cohort where the inline model can earn its keep. Technical wants the direct-API script from the previous session, because each file is bigger and the code grounding matters.

Either way, the bundle tool is ready and the voice-separation holds. Summary is what the catalogue tells you. The rest of the audit gets to build on that.
