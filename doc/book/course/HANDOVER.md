# Handover: the course text — short-speak, functional text, and the compression tests

Written 2026-10-02, 15:45; corrected 16:20 after a cold-start test and a full fact-check (run wf_918dcd70-3b4).
Everything here was measured or read this day. Each number names its source.
Paths are relative to `C:/Users/palle/Documents/GitHub/AdaResearch_46/` unless they start with `ada_encyclopedia/` (`C:/Users/palle/Documents/GitHub/ada_encyclopedia/`) or `~/.claude/` (`C:/Users/palle/.claude/`).

---

## Scoreboard: one result at a time

Each result: one line of score, then what it means. Read these first.

**R1. The old lessons were too long.**
Score: the 29 study kits listed in `doc/book/course/kits.json` have a median of 4,300 words of prose and 2 images (the first eight have none), 114,000 words in all. These count every word outside code; with REPORT §0's stricter counter they are 4,145 and 110,221.
Meaning: Palle stopped the kit build that morning: "The text is too verbose, there are not enough images … intelligence is compression."

**R2. The course has a new order: one chapter per spine sequence.**
Score: 25 chapters, 197 sections, one picture per chapter, 13 open questions (`doc/book/course/sketch/sketch.json`). The checker reads the order: 34 errors (7 terms used before they are taught, 22 never taught, the rest small) and 570 warnings (`doc/book/course/functional_text/sketch_report.md`).
Meaning: the order is mostly right, not yet clean. Part I follows the Learning Processing ladder, Nature of Code follows, and case studies (Haeckel) come later as extensions.

**R3. The text is checked like code.**
Score: 170 tests pass in about 60 s, 13 of them running Godot (re-run by this session at 16:10: "Ran 170 tests in 61.231s / OK"). Chapters 1 and 18 pass with `--godot` at 0 errors (25 and 16 warnings). An attacker found 21 ways past the first checker, and each now has a test that fails it.
Meaning: "type-safe text" works as a gate. No term before it is taught, no synonyms. Every code block is parsed and run in Godot. Every number the text states must appear in its code, its printed output, or a claim that Godot verifies.

**R4. Compression round one (rebuild the lesson): what is kept returns, what is cut does not.**
Score: 480 of 484 kept claims returned; 2 of 117 cut claims returned. Halving short-speak cost 11–21 points of what returns. Force was lost first (24% at L1), connection next (45% at L2).
Meaning: a reader rebuilds facts and steps, but not the author's direction, force and connections. Source: `doc/book/course/functional_text/round_trip/REPORT.md`, sections 0–6.

**R5. Compression round two (understand the lesson): every reader understood everything.**
Score: all 336 judge scores were full, in both lessons and for every text: the original; texts at 54% (Point One) and 33% (cellular) of the prose; with and without the earlier chapters. Two blind judges agreed on all 168 pairs.
Meaning: for an AI reader, a lesson can be cut to a third with no loss this exam can see. But the exam sits at its ceiling and cannot rank the texts. The readers were Opus 5.5 agents with tools: they knew Godot, and one ran a scratch simulation. Source: REPORT.md, "Round two: understanding, not reconstruction"; data in `round_trip/round2/results.json`, sheet key in `round2/sheet_map.json`.

**R6. The eleven proposed changes did not earn their place.**
Score: they added 11% (Point One) and 36% (cellular) more prose, and 25% and 57% more characters. No score moved, and stuck points did not fall.
Meaning: do not adopt changes 1–11 as a set. Keep two of them: `Restore:` lines, and whole code where a file is first met (REPORT round two §5 and §8).

**R7. The only misunderstanding came from the original.**
Score: one misunderstanding in the whole round. It appeared on 2 of 14 sheets, both readers of the original cellular lesson (with and without the earlier content), and both judges flagged it independently. It concerns the paragraph comparing rules 30, 90 and 250. No compressed text drew one, and there were no confident wrong answers anywhere.
Meaning: a paragraph can carry a claim that no single line states. This is the case for "one claim per line".

**R8. The text's own markup must be introduced like any term.**
Score: the marker `enters:` stalled readers on 4 of 6 new-text sheets; `[read]` and `*(editor)*` on 2 of 3 in Point One.
Meaning: notation is vocabulary. Declare it once, before first use — the same rule as admin below.

**R9. Admin is described once, then called by name.**
Score: in the 31 old lessons (`doc/book/studies/*/TUTORIAL.md`), 339 lines in 30 lessons run something. 231 of them just say "Run it"; 27 spell out the steps (F5, the Play button, top right, F6). They use at least nine wordings and mix running the project (F5) with running the open scene (F6). The taxonomy now has four admin entries. Three are defined in the chapters: *run the project* (1.1), *add a node* (1.3), *save this script as* (18.1). The fourth, *run the scene* (F6), waits for its section. On the pages, every later call links to the first instance: chapter 1 has 5 links, chapter 18 has 10.
Meaning: this is Palle's rule, with his boundary: "not the teaching of that tutorial but admin". Teaching is never replaced by a link.

**R10. Most of the day's waiting was repeated work.**
Score: the understanding test itself (exam to judges) took about 27 minutes for cellular and 14–19 for Point One. The whole round took about two hours, of which about 55 minutes were repeated: cellular was compressed three times and Point One's readers ran twice, after a stop and a computer crash.
Meaning: a workflow resume reuses finished agents only while calls arrive in the same order, and parallel stages break that. Write expensive outputs (compressions) to files before the test, not inside it.

**R11. Chapters 2 to 5 are written, merged and checked (2 October, evening).**
Score: chapters 1–5 and 18 pass `--godot` at 0 errors, alone and all six in one run; 188 tests pass; the sketch report stays at 34 errors (619 warnings). `taxonomy.json` went from 606 to 625 entries through four chapter patches and one merge patch, all kept in `functional/patches/`.
Meaning: 50 writer operations applied as written, one found identical across two patches (the `cell_at()` stub), seven merge operations (the lamp's def, `uv_repeat` deleted, five notes). New admin *add a scene* (1.6); *make a new script* moved to 4.7, so 18.1 now calls it. A new code option, `keep=`, shows a member once and lets later sections keep it: chapter 5 fell from 639 to 502 lines with the same prose. The course walker must steer with WASD only, and Space must stay free (`base_scene` and `walker` notes): kit-base binds the arrows and Space.

**R12. Four student readings of chapters 2 to 5, acted on (2 October, late evening).**
Score: chapters 1–5 and 18 pass `--godot` at 0 errors, alone and in one run (122 warnings, 113 before); the sketch report stays at 34 errors (622 warnings, 619 before); 188 tests pass. `taxonomy.json` 625 → 629 entries through 22 operations (`functional/patches/students_ch02-ch05.taxonomy_patch.json`). Prose words: ch02 1,495 → 1,569, ch03 1,445 → 1,604, ch04 1,837 → 1,994, ch05 1,555 → 1,730.
Meaning: each stall a reader could act on now has a line, and the price is 5–11 % more prose. All four readers stalled first on the scene: old bodies stood on new ones. New admin *delete a node* (2.1) opens every chapter: "Delete every node you added: keep the base scene's own." New concept *action* (2.6). `ui_accept` moved 2.6 → 4.6, where code first uses it. 3.4 teaches that `*` and `/` come before `+` and `-`, 3.5 that `%` ranks with `*`; 2.2, 4.5 and 4.7 say what `.0` keeps. 3.8 times its beat with a clock, not frames. 5.6 builds the floor's material in `picture()`, which 5.8 keeps.

---

## 1 What we are doing

**The goal.** Ada Research teaches algorithms through a Godot VR/desktop world. Palle is writing a Godot course that follows the project's spine: a student learns programming by building the Ada examples. On 2 October he stopped the old lesson build (R1) and asked for:
- as little text as possible, but enough to understand;
- a picture for every concept;
- the voice of *The Nature of Code*;
- and, before anything else, a new order (R2).

**The form: three names for one discipline.**
- **Short-speak** (`doc/book/course/SHORT_SPEAK.md`).
  - Lines, not paragraphs. One claim per line, about seven words.
  - Do / see / why.
  - Code first, then the lines about it.
  - Parallel lines are the only ornament.
  - A section ends on its technical point.
  - Palle asked for "a bit less poetic but still".
- **Type-safe text.**
  - A term is declared once, where it is first needed, and keeps one meaning.
  - No synonyms, and no use before the declaration.
  - Code names appear exactly as the code spells them.
- **Functional text** (`doc/book/course/functional_text/FUNCTIONAL_TEXT.md`).
  - Palle: "Type safe means that we are not using unintroduced elements (hard taxonomy) and that the text is verified as code."
  - One hard taxonomy (`doc/book/course/taxonomy.json`, 604 entries) lists every element the book may use and the section that introduces it.
  - Each section is a function: it `needs` terms that earlier sections `gave`.
  - A checker fails the text when anything breaks this.

**Admin versus teaching (R9).** Palle first said: "how to run the project can be described once. after that we can just say run the project (maybe with a link to the first instance)". Then he drew the boundary: "not everything should be linked back I mean not the teaching of that tutorial but admin".
The test for a step: if it were done for the student, would they still learn what the section teaches? Then it is admin. Admin is defined once, called by name and linked. Everything else is teaching and stays written out.

**The research method.** Palle wants the compression itself studied: compress, unfold, compare, and let what fails to return change the next version. What he cares about losing are three "vectors":
- the *direction* of a thought;
- the *force* of a claim;
- the *connection* between a shortcut and the system it enters.

After round one he made two corrections:
1. The reader has the earlier chapters of the series.
2. "The decompressor should not be forced to recreate the original but to understand the content of the tutorial."

So round two measured understanding with an exam, not reconstruction.

**Why it matters to Palle.** His preface (Google Doc "preface", id `1z3Sk3YY3VYiNUau5F0IhxHQxusAG-e2sRmDvt3CQn7M`) ties short-speak to Dichtung, to intelligence as compression, and to entropy as situated: the same text has a different entropy for the maker, an AI and a future reader. R5 is a measured case of this. Point One holds almost no surprise for an AI reader and a great deal for a first-time student.

---

## 2 Where everything is

| What | Path | State |
|---|---|---|
| Short-speak spec | `doc/book/course/SHORT_SPEAK.md` | untracked; admin section added today |
| Functional-text spec | `doc/book/course/functional_text/FUNCTIONAL_TEXT.md` | untracked; §2a admin, §6 known gaps |
| Hard taxonomy | `doc/book/course/taxonomy.json` | untracked; 604 entries, kinds concept, godot, maths, gdscript, supplied, name, plain, admin |
| Checker | `doc/book/course/functional_text/check.py` | untracked; standard library only, about 186 KB |
| Tests | `doc/book/course/functional_text/test_check.py` | untracked; 170 tests |
| Course sketch | `doc/book/course/sketch/sketch.json`, `SKETCH.md`, `img/` | untracked |
| Order report | `doc/book/course/functional_text/sketch_report.md` | regenerated by the checker |
| Chapters 1 and 18 | `doc/book/course/functional/ch01.md`, `ch18.md` | untracked; the only chapters written in the form |
| Obsolete | `functional/ch18.context.json`, `functional_text/with_context.py` | superseded; moved out of the tree on 2 October before the first commit |
| Compression tests | `doc/book/course/functional_text/round_trip/`: `REPORT.md` (rounds one and two) · `point-one/` and `cellular/` (round one: `claims.json`, `L1–L3.md`, unfoldings, compares) · `round2/` (`L2v2.md` per lesson, context packs, `results.json`, `sheet_map.json`, `point-one/_stopped_reconstruction/` holding four unjudged unfoldings) · `T1_PLAN_DRAFT.md` | untracked |
| Original lessons used by the tests | Point One: `commons/maps/Point_One/tutorial.md` (793 words; it has uncommitted edits; `doc/book/studies/point-one/TUTORIAL.md` is a near-copy at 798, NOT used). Cellular: `doc/book/studies/cellular/TUTORIAL.md` (4,217) | as used by rounds one and two |
| Round scripts (prompt templates) | round one `~/.claude/projects/C--Users-palle-Documents-GitHub-AdaResearch-46/d4723a07-4784-4cb6-9b4e-fe916444119f/workflows/scripts/compression-round-trip-wf_4a9644a5-06c.js`; round two, same folder: `compression-round-two-wf_a7f0e640-19c.js`. Journals with every agent's full answer: `~/.claude/projects/C--Users-palle-Documents-GitHub-AdaResearch-46/d4723a07-4784-4cb6-9b4e-fe916444119f/subagents/workflows/<run id>/journal.jsonl` | read-only |
| Pages | `ada_encyclopedia/src/app/course/sketch/` (`page.tsx`, `[chapter]/page.tsx`, `order/page.tsx`), `src/lib/course-sketch.ts` | untracked |
| Shared renderer | `ada_encyclopedia/src/app/course/_components/markdown.tsx` | tracked, modified (passes `className` for admin links) |
| Course index | `ada_encyclopedia/src/app/course/page.tsx` | tracked, modified (one link to /course/sketch) |
| Live pages | http://localhost:3003/course/sketch · /course/sketch/1 · /course/sketch/18 · /course/sketch/order | dev server on port 3003; do not restart it |
| Docs site (MkDocs, ready for Read the Docs) | `doc/book/course/site/` (`build_site.py`, `mkdocs.yml`); preview "course-docs" on port 8008 in `.claude/launch.json` | untracked; built from the old course.json, not from the functional chapters |
| Blog posts | `ada_encyclopedia/src/content/blog/2026-10-02-text-that-compiles.md`, `2026-10-02-the-field-was-too-wide.md` | untracked. "text-that-compiles" says the taxonomy "holds chapter 1"; that is stale, it now covers 25 chapters |
| Old study kits | `doc/book/studies/<kit>/` | build STOPPED; do not relaunch the old script |

---

## 3 How to run things

From `doc/book/course/`:

```
python functional_text/test_check.py
python functional_text/check.py --taxonomy taxonomy.json --godot functional/ch01.md
python functional_text/check.py --taxonomy taxonomy.json --godot functional/ch18.md
python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json --report functional_text/sketch_report.md
```

- **Exit code** is the number of errors, capped at 255. Each finding prints as `file:line: rule: message`.
- **`FT_OFF=<rule>`** switches one rule off, to prove its test bites.
- **Godot** is `C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe`; the checker calls it itself.
- **Several Godot instances at once:** the sources disagree. Palle said they are fine (memory, 2026-09-17), but CLAUDE.md says never run two, because the second dies silently on the user:// lock. Until he settles it, run checker runs one at a time.
- **Word counts:** count words that contain a letter or digit, outside fenced code and HTML comments, with link URLs dropped. REPORT §0 states the rule; there is no script for it, but the rule alone reproduces every published count (793, 427, 184, 475 and 917 for Point One; 4217, 1398, 780, 1897 and 2731 for cellular).

---

## 4 State of each workstream

**A. Admin: built, attacked, fixed, verified.**
Runs: builder `wf_2d5b727b-99c`, then attacker, link check, student, fixer. Re-verified by this session at 16:10:
- 170 tests pass;
- ch01 and ch18 have 0 errors;
- the pages return 200.

The fixer closed every attack except three left on purpose:
- "Play it again": *it* may be a sound.
- "Press the green arrow": the y-axis arrow is also green.
- "Or press Ctrl+Shift+S" without the "Or".

It also made links stop wrapping, and narrowed the 1.4 link to the word before its slot ("Add", not "Add five"). That was a judgement call it made itself; it is item 6 in §5.

It added the missing steps:
- 1.1: where the base scene is, and "Choose Create.";
- 1.3: "Select the node it goes under.";
- 18.1: "Click Script, at the top."

Words now: ch01 1,504, ch18 1,545.

Copies of every file from before each run are in `C:/Users/palle/AppData/Local/Temp/claude/C--Users-palle-Documents-GitHub-AdaResearch-46/d4723a07-4784-4cb6-9b4e-fe916444119f/scratchpad/before/` and `before_fix/`.

**B. Compression tests: rounds one and two done.** REPORT.md holds both. Round two's recommendation (§8):
- amend both specs narrowly;
- do not adopt changes 1–11;
- write at about half the prose for a short lesson and 35–45% for a long one;
- before going lower, build an exam with headroom and use a reader without Godot.

**C. Faults the tests found, not yet fixed.**
- **MultiMesh.** The cellular lesson says "the `MultiMesh` of the pendulum chapter" (`doc/book/studies/cellular/TUTORIAL.md` lines 82 and 448), and round two's `L2v2.md` turned that into "from: ch 9". The sketch's chapter 9 never teaches MultiMesh, and the taxonomy already places it at 13.0 with a note. The fault is in the lesson text and its compressed versions, not in taxonomy.json. All 4 cellular readers who had the series caught it.
- **Two orders for *y* and *point*.** The taxonomy places them at 1.2, but the hall lessons (Day Zero, Point Zero) never teach them.
- **1.46 m against 1.35 m.** In cellular, row 8's top is 9 × 0.15 = 1.35 m, but the edge walk reports feet at 1.46 m (TUTORIAL.md line 399). Check it with a Godot run before the course quotes it.
- **Gaps in the source lessons that no version fixes:**
  - the feeler's height and kind (7 of 7 sheets);
  - whether a shape works without a body (7 of 7);
  - why the walker stops on the seed (5 of 7).

**D. Pages and site.** The chapter pages show one source line per page line, hide the signatures, render the Types box as a card, and link admin calls. The MkDocs site does not yet include the functional chapters. Unrelated, and not ours: the encyclopedia's header overflows on every page (936 px nav at 375 px).

**E. Nothing from today is committed.** The course files are untracked, and the two encyclopedia files above are modified. Commit only with Palle's word.

---

## 5 Open decisions for Palle — do not decide these for him

**The form and the specs**
1. Amend SHORT_SPEAK.md and FUNCTIONAL_TEXT.md as round two §8 recommends?
2. Approve the voice of `ch01.md` and `ch18.md`, and the order in `sketch.json`, before more chapters are written. Section 1.1 now opens with 12 prose lines before the first code. One student reader called lines 52–63, after the first code, "a 12-line definition list".
3. May an exercise explain a term in passing (accept-reject, Huber, topological sort)? Today that is an error.
4. "Evolution" in the sketch: teach it, or allow it as an everyday word?

**Admin**

5. Rename heading 1.1, "Press Play"? It is the definition of *run the project*.
6. The fixer narrowed the 1.4 link to "Add". Keep that, or reverse it?
7. Is the Inspector's "give it a mesh" teaching (the builder's view) or partly admin, where to click (the attacker's view)?
8. Chapter 18. **Settled 2 October, evening, on Palle's "go with what you think works best":** one convention for scripts. Every script extends `Node3D` (through `Field`) and goes on the top node; the marched body is a child `MeshInstance3D` made in code (`seen`). *Save this script as* is gone: *make a new script* (File, New Script, 18.1) and *put a script on a node* (a drop from the FileSystem, 1.3) replace it. Every section 18.1 to 18.8 now puts its script on the top node and runs the project. check.py's `top` rule fails a script the top node cannot hold.
9. **Settled the same evening:** 1.1 names the FileSystem; 1.3 defines *put a script on a node* for `contact_probe.gd`; 1.6 drops `counter_panel.tscn` in one inline line (used once; the walker of 2.5 would make it an admin).
10. Godot 4.6 labels no one has checked in a live editor: Create in the Attach dialog, FileSystem at the bottom left, the Script button at the top, Cmd+B and Cmd+R, Ctrl+A to add a node; and now File > New Script and Create, a script dropped from the FileSystem onto a node, and a scene dropped onto the top node.

**Round three (T1)**

11. Is a smaller-model reader, or a reader of an obfuscated text, an acceptable stand-in for a first-time student?
12. What agent and time budget may round three spend? The draft plan estimates about 80 agents and 60–75 minutes.

**Housekeeping**

13. Which blog posts and pages to commit, and when.

---

## 6 Next tasks, specified for handover

Each task has inputs, a done-test, and a baseline to beat. "Faster and better" is measured against these.

**T1. Round three: an understanding test that can tell texts apart.** *(The task to give a second agent: it is self-contained and writes only under `round_trip/round3/`.)*

A draft plan written by a cold-start agent is in `round_trip/T1_PLAN_DRAFT.md`. Use it, improve it, or replace it.

- **Texts** (files only; no compression inside the test). For each lesson:
  - the original (paths in §2);
  - round one's `L1.md` (Point One 917 words; cellular 2,731);
  - `L2.md` (427; 1,398);
  - `L3.md` (184; 780);
  - round two's `L2v2.md` (475; 1,897).
- **Earlier content:** the context packs in `round2/`. They carry confounds; keep them, and write them down:
  - Point One's pack is in the new form and teaches *y* and *point* early;
  - cellular's pack holds outlines, not lessons.
- **Readers that do not already know Godot.** Round two's readers were Opus 5.5 with Bash.
  - Give readers Read only.
  - Workflow subagents get CLAUDE.md injected, which carries Godot facts. A built-in agent type that omits it may help.
  - A smaller model (Haiku, via the workflow `model` option) is a hypothesis, not a fix: it also knows Godot.
  - Prove naivety before the test: a Godot pretest on what the lessons teach, and the exam taken with no lesson at all. Both should score low (the draft suggests 0.3 or less).
  - If the reader is not naive, the draft proposes an obfuscated arm: Godot identifiers renamed the same way in every text, context and exam.
- **An exam with headroom.**
  - Pilot it on the original first. Target: original-with-context readers average 0.6–0.9, with the no-lesson floor clearly below.
  - Keep the lesson's facts out of the questions. Round two's cellular Q8 and Q1 gave them away (REPORT round two §6); check this by script against `claims.json`.
  - Round two's exams and rubrics are in `round2/results.json` and can be reused or rewritten.
- **Readers and judges.**
  - At least 3 readers per cell: reader-to-reader noise was as large as any text effect (REPORT round two §9).
  - One judge per lesson, plus a second judge on a sample for agreement.
- **Measures.**
  - Size is the share of prose words.
  - L2v2 also changes form, and L3 is in notation; flag both on the curve.
  - Report the three vectors (direction, force, connection) as well as the total.
- **Output:** `round3/REPORT.md` and `round3/results.json`, including the sheet-to-cell key.
- **Crash safety:** run each phase as its own workflow and write its outputs to files.
- **Done when:** in at least one lesson, two texts differ by more than reader and judge noise, and the knee (the size below which understanding falls) is named or bounded.
- **Baseline to beat:** round two took about 27 minutes of test for cellular and 14–19 for Point One, and found no difference between any two texts. Its discrimination was zero.

**T2. Act on the admin result.** Admin is done (§4A). Next is Palle's decisions 5–10. Do not change those points without his word.

**T3. Fix §4C's faults.**
- MultiMesh: in the lesson text and its compressed versions, with Palle's word, since the kits are his.
- The *y*/*point* order.
- The 1.46 m check.
- `taxonomy.json` is shared state: edit it surgically and record each change in the entry's `note`.

**T4. Apply Palle's decisions from §5** when he gives them.

**T5. Chapter 2 in the form**, only after decision 2.

---

## 7 Working in parallel

Palle: "it it work you can work in parallel" (if it works, you can work in parallel).

- **Split by files, not by topic.** Proposed: a second agent takes T1 and writes only to `round_trip/round3/`. This session takes T2 and T3: the checker, taxonomy, chapters and pages.
- **Announce before touching shared files.** At the start, `python tools/forum.py open`. Before editing, `python tools/forum.py ask "title" "body" --tags=course --as=<name> --claims=<paths>`.
- **Git.** Never `git add -A`. Never `git stash`. Never leave work staged. Commit only explicit paths, and only with Palle's word. Never push without it.
- **Report in numbers,** so Palle can compare the agents: time from start to result, agents used, and the scores of the task's done-test.

---

## 8 Traps learned today

- **A workflow resume can redo hours.** It reuses finished agents only while calls arrive in the same order, and parallel stages change the order. Keep expensive outputs as files.
- **Python on Windows writes CRLF** with `open(p, 'w')`, and the Workflow tool then refuses the script ("control characters"). Write with `newline='\n'`.
- **Bash heredocs can mangle quotes and backslashes** in this shell. Write files with the Write tool or a Python file.
- **Subagents asked to write a report file may refuse** ("subagents should return findings as text"). Have them return text, and save it yourself.
- **Subagent reports are claims.** Re-run the checker and the tests before you repeat a number. A fact-checker made 15 corrections to this handover's first draft: some were errors, others were things that had changed while it was being written.
- **An exam at its ceiling ranks nothing.** And an exam that supplies the facts cannot see a text that lost them (R5).
- **AI readers are not first-time students.** They know Godot, do arithmetic and run simulations. A test of a beginner lesson with AI readers measures the reader as much as the text.
- **`taxonomy.json` is shared state.** Three agents overwrote each other's entries in one morning. Edit surgically, and re-read it before writing.
