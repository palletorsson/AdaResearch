# T1 plan draft: round three

Written 2026-10-02 by a cold-start agent that had only `doc/book/course/HANDOVER.md` (run wf_918dcd70-3b4), as a test of the handover.
Its file sizes were checked by that agent; nothing here has been run. Palle has not approved it. Treat it as a starting point, not a decision.

**2. Concrete plan for T1 (round three)**

*Inputs.* I checked that each file exists. Prose words are counted with REPORT §0's rule; I re-implemented that rule and it reproduced all ten published figures.

Point One:
- Original: `commons/maps/Point_One/tutorial.md`. 113 lines, 793 words. It has uncommitted changes against HEAD. Round two's reader prompts used this file.
- `round_trip/point-one/L1.md`: 258 lines, 917 words (116% of the original).
- `L2.md`: 119 lines, 427 words (54%).
- `L3.md`: 59 lines, 184 words (23%).
- `round2/point-one/L2v2.md`: 167 lines, 475 words (60%).
- Context pack: `round2/point-one/context_lessons.md` (189 lines, 1,087 words) plus `context_types.md` (35 lines, 343 words). Round two gave readers both files.

Cellular:
- Original: `doc/book/studies/cellular/TUTORIAL.md`. 460 lines, 4,217 words, clean against HEAD.
- `round_trip/cellular/L1.md`: 734 lines, 2,731 words (65%).
- `L2.md`: 382 lines, 1,398 words (33%).
- `L3.md`: 136 lines, 780 words (18%).
- `round2/cellular/L2v2.md`: 633 lines, 1,897 words (45%).
- Context pack: `round2/cellular/context.md`, 498 lines, 6,795 words.

Exam material:
- `point-one/claims.json` (118 claims) and `cellular/claims.json` (175 claims).
- The fragile set, recomputed from the `L*.compare.json` files: 29 claims for Point One and 78 for cellular. These match the REPORT.
- `round2/results.json` (4,422 lines, about 428 KB) holds round two's 12 questions per lesson with their rubrics, all answers and the judge sheets.

The cells are 5 texts × 2 conditions (with and without the earlier chapters) × 2 lessons, which makes 20.

*Reader, and how I would prove it is naive.* Round two's readers were Opus 5.5 with Bash. One cellular reader wrote a scratch automaton simulator; I read that in the transcript. So:
- **Reader:** Haiku, through the workflow `agent()` option `model`.
- **No tools beyond Read of the given files.** I would audit every reader's transcript and throw out any sheet that ran Bash or opened another path.
- **Pretest:** before any lesson, each lesson gets 8 to 10 Godot questions that the lesson answers. Examples: does a CollisionShape3D under a plain Node3D collide; what `-> void` means; what `%` does at the row ends; what a MultiMesh draws.
- **No-lesson baseline:** the full exam is also taken with no text at all. That score is the floor made of prior knowledge plus anything the questions leak.
- **Naive means:** the pretest scores at most about 0.3, the no-lesson baseline is at most about 0.3, and reading the original raises the score by a clear margin.
- **If Haiku fails this (likely, since it also knows Godot):** fall back to an obfuscated arm. One Python mapping renames the Godot identifiers (StaticBody3D, add_child, MultiMesh, _ready, Vector3 and so on) the same way in every text, context pack and the exam. The pretest is then re-run under the renaming and must fall to chance. Because all texts get the same change, the comparisons between them stay fair.

*Exam and pilot for headroom.*
- **Writing:** one writer and one critic agent per lesson write about 14 questions aimed at the fragile set (direction, force, connection, measured facts, hall facts, decisions). Round two's rubric format and question kinds are reused.
- **Leak rule:** no number or claim text from the lesson may appear in a question stem. Round two's leaky questions are cellular Q8 and Q1. This is checked by script: every stem is grepped against claims.json numbers and key phrases.
- **Pilot:** per lesson, 3 readers with the original plus context, 1 with the original alone, 2 with no lesson. One judge scores them.
- **Pass condition:** the readers with the original and context average 0.6–0.9, and the no-lesson floor sits at least 0.3 below them. Questions that everyone or no one gets right are rewritten. I would freeze the exam before any compressed text is read.

*Judging.*
- **Scale:** FULL / HALF / NONE, as in round two.
- **Primary judge:** one per lesson, the default model, blind. Sheets are shuffled and the mapping is kept in the orchestrator, then written to `round3/` afterwards. results.json does not store a mapping today.
- **Second judge:** about a third of the sheets (about 10 per lesson), in a different shuffle. Judge noise is defined as the mean absolute difference per sheet, with the spread of those differences reported too.
- **Readers per cell: 3.** REPORT §9 shows reader-to-reader noise (D1 against D2) is as large as any text effect, and the done-test ignores this.
- **When two texts count as different:** the bootstrap 95% interval of their difference, resampling readers and questions, excludes zero and is larger than judge noise.
- **The knee:** take score against prose-word share for the original, L1, L2 and L3. L2v2 is plotted off the curve because it changes form as well as size, and L3 is flagged because it is also in notation. The knee is the largest step down beyond noise, named or bounded between two sizes.

*Time and agent budget.*
- **Agents (about 80):** 6 for the Haiku pretest, 4 for exam writing and critique, 12 Haiku and 2 judges for the pilot, 52 Haiku for the main reads (60 minus the 8 pilot sheets reused if the exam is unchanged), and 4 judges.
- **Wall time:** about 60–75 minutes. The test proper (main reads plus judging) is about 30 minutes for both lessons, which beats round two's 26 minutes for one lesson.
- **Crash safety:** each phase is its own Workflow run, and the orchestrator writes each phase's outputs to `round3/` files. A crash then redoes one phase, not hours.

*First three steps.*
1. Run `python tools/forum.py open`, then `python tools/forum.py ask "round three understanding test" "..." --tags=course --as=<name> --claims=doc/book/course/functional_text/round_trip/round3/`. Pull round two's reader and judge prompts from run `wf_a7f0e640-19c` to use as templates.
2. Freeze the inputs. A python script writes `round3/inputs.json` with the sha256, prose words (§0 rule), characters and lines of the 10 texts and 3 context files, plus the fragile-set claim ids (29 and 78).
3. Run Workflow "r3-naive": the Haiku pretest plus the no-lesson baseline, with schema output, saved to `round3/pilot/naive.json`. Then apply the rule: naive goes ahead as planned; not naive switches to the obfuscated arm before writing the exam.

*Where the handover left me to guess:*
- Which file is "the original" for Point One.
- How to call Haiku, and what to do if it is not naive.
- What tools readers may use.
- Whether to reuse or replace round two's exam, and where its prompts and script are.
- Exam length and scoring scale.
- Readers per cell.
- How "judge noise" is defined and how big the second-judge sample is.
- The size measure for the knee (prose words, characters or lines).
- How to treat L2v2 and L3 on the size ladder.
- The agent and token budget.
- The output format and location (REPORT.md section or `round3/REPORT.md`).
- Whether to report the three vectors.
- That workflow subagents get the project CLAUDE.md injected, which may make readers less naive.
