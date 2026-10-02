# Handover: the Godot course, written in functional text

Written 2026-10-02, 21:30, by the session that did this work (Claude, session d4723a07), for the next model; checked by hand against the files and git at 21:50 (every link, path and commit exists; the counts re-measured).
Palle is switching models because this session kept re-writing his text in its own words. Read section 1 before you touch anything.

Paths are relative to `C:/Users/palle/Documents/GitHub/AdaResearch_46/`.
`ada_encyclopedia/` means `C:/Users/palle/Documents/GitHub/ada_encyclopedia/` (branch `spatial-iterations-gallery`).
The Ada repo's trunk is `palm-scanner-door-entry` (`main` is stale).

---

## 1. The one thing that went wrong, and how to avoid it

Palle gives short, exact corrections. The agents (and this session) answered each correction by re-writing whole chapters in their own voice, so every fix brought new drift, and he had to catch it again. His words, at the end: "you're not letting me win. please make it work."

What the drift looked like, all found by Palle, all fixed in `3083866fe`:

| what the agents wrote | what Palle wanted | why |
|---|---|---|
| "`StandardMaterial3D` is a class: Godot wrote it." | "`StandardMaterial3D` is a Godot built-in class." | the documentation's term, said simply |
| "Alpha is how much a colour covers." | the standard definition: alpha is the colour's opacity, 0 fully transparent, 1 fully opaque | use the technical term and its standard definition |
| "A function answers." | "A function returns a value." | the code says `return`; "answer" turns a function into a speaker in a dialogue and hides that control and a value go back to the caller |

**How to work with Palle on this text:**
1. Do exactly what he asks. Change only the lines his request needs. Every other line stays byte-identical.
2. Show him the before/after of the exact lines (a small table), then commit.
3. Use established terms with standard definitions, close to the Godot documentation (docs.godotengine.org class reference and GDScript reference). Never paraphrase a term that has a standard name.
4. For a change of style across chapters, do one chapter, show him, and roll out only after his yes.
5. Work by hand. Palle asked, at the end of this session: "do this by hand not by multi agents". Many agents meant many voices, and each correction met new drift. If an agent is ever unavoidable, brief it for minimal change and ask for a table of every changed line (old, new, why), and check the diff against that table yourself.
6. Turn each correction into a checker rule where you can (a forbidden synonym in `taxonomy.json`, a test), so it cannot come back.

**The reference for the voice:** [test_tutorial.md](test_tutorial.md), "A sphere in code": the simple test tutorial Palle asked for, written by hand at the end of this session, its code run in Godot 4.6. Palle has not reviewed it yet. Start by showing it to him.

**The research frame:** Palle's preface (his Google Doc, https://docs.google.com/document/d/1z3Sk3YY3VYiNUau5F0IhxHQxusAG-e2sRmDvt3CQn7M/edit) explains why the text is compressed: Dichtung, intelligence as compression and unfolding, the subtle vectors (direction, force, connection), cribs and Good–Turing, entropy as situated and layered. Read it to understand what the course text is for.

---

## 1b. The two anchors (added at the end of the session, after the mistakes above were traced)

Every drift today came from structure or words invented by a model and then copied. Two things outside the model now fix both:

- **Structure: the scaffold, read from the spine.** [scaffold/SCAFFOLD.md](scaffold/SCAFFOLD.md) (data: `scaffold/scaffold.json`, regenerate with `python doc/book/course/scaffold/build_scaffold.py`, dev server needed). One chapter per spine sequence, one hall per map in the sequence's order, and in each hall the works in Palle's own arrangement: his primary works, his named boxes with their works, his notes. 25 chapters, 204 halls, 419 primary works. Palle: "we should have used scaffold from the spine sequence." A chapter is written hall by hall from this, and each primary work is something the student builds, in code. The sketch (`sketch/sketch.json`) did not do this: it took the Learning Processing ladder as its skeleton and pulled works from across halls; treat the sketch as background, the scaffold as the skeleton. The ladder still decides which programming idea arrives when a work first needs it.
- **Words: Godot's own documentation and editor labels.** The 4.6-stable class reference and the 4.6 editor UI strings are downloaded (with Palle's permission) at `C:/Users/palle/Documents/GitHub/godot_reference_4.6/` (outside the repo). A derived vocabulary (classes, member names, 5,485 UI strings) is `godot_vocabulary_4.6.json` there. Not yet wired into the checker: that is the next mechanical job (every Godot name and every quoted editor label must exist there; Godot entries' definitions derived from the docs).
- **Bodies are made in code**, from chapter 1 (Palle: "it is all wrong to use the dollar mesh tscn approach"). The `$Name` pattern came from an agent-written chapter-1 seed and the checker's `nodes=` runner, not from Palle or the sketch.

## 2. What the project is

A Godot 4 course for first-time programmers, inside Ada Research (the VR museum of algorithms). One chapter per spine sequence: 25 chapters. Part I follows the Learning Processing ladder; The Nature of Code follows; case studies (Haeckel's radiolaria and others) come later as extensions.

The text is written in **functional text**:
- **short-speak**: lines, not paragraphs; one claim per line, about seven words; do / see / why.
- **type safety**: every term the course uses is an entry in one hard taxonomy; a term is used only after the section that introduces it; synonyms are forbidden; names from the code appear exactly as the code spells them.
- **verified as code**: a checker reads the chapters like a compiler and runs every code block in Godot 4.6.

---

## 3. Palle's rules, in his words, and where each one lives

| date (2026-10-02) | Palle | became | lives in |
|---|---|---|---|
| morning | "The text is too verbose, there are not enough images ... the language should be like The Nature of Code. You must lead the student with as little text as possible but still enough to understand. Intelligence is compression." | short-speak | [SHORT_SPEAK.md](SHORT_SPEAK.md) |
| morning | "Before we commit to writing ... sketch the whole sequence ... one image per tutorial. Chapters: one chapter per spine sequence. Part I: the Learning Processing is the right ladder. Case studies: later." | the sketch | [sketch/sketch.json](sketch/sketch.json), [sketch/SKETCH.md](sketch/SKETCH.md) |
| midday | "Type safe means that we are not using unintroduced elements (hard taxonomy) and that the text is verified as code. Maybe we can call it Functional text." | taxonomy + checker | [taxonomy.json](taxonomy.json), [functional_text/FUNCTIONAL_TEXT.md](functional_text/FUNCTIONAL_TEXT.md), [functional_text/check.py](functional_text/check.py) |
| afternoon | "the decompressor should not be forced to recreate the original but to understand the content of the tutorial" | the compression test measures understanding | [functional_text/round_trip/REPORT.md](functional_text/round_trip/REPORT.md) |
| afternoon | "how to run the project can be described once. after that we can just say run the project" + "not everything should be linked back, not the teaching of that tutorial but admin" | admin procedures: defined once, then called by name and linked; teaching is never linked | SHORT_SPEAK "Admin is said once", FUNCTIONAL_TEXT 2a, kind `admin` in the taxonomy |
| evening | "make images later" | images deferred; figure lines stay | — |
| evening | "can we make it even more readable by indented point list that we can group related hierarchical meaning?" | lines in a tree: numbered steps for doing, a bullet tree for understanding, plain lead and point | SHORT_SPEAK "Lines in a tree", FUNCTIONAL_TEXT 2b |
| evening | "highlight the word type like in code?" | NOT BUILT yet (see 6.2) | — |
| evening | "the usual word is return ... explain the concept of function returning a var ... use illustration whenever you can along the code" | return, not answer; 4.2 explains the return value and `void`; one diagram figure line so far | ch04 4.2; `answer` is a forbidden synonym of `return` |
| evening | "`StandardMaterial3D` is a godot basic class ... use the technical term the standard definition ... stay close to the documentation and opt for clarity ... these seem to be unnecessary rewrites" | standard words, standard definitions; built-in class explained in 1.1 | ch01 1.1, ch04 4.7 and 4.8 |

---

## 4. The files

### The course text (Ada repo, `doc/book/course/`)

| file | what it is | state |
|---|---|---|
| [SHORT_SPEAK.md](SHORT_SPEAK.md) | the voice: short-speak, type-safe text, admin said once, what compression keeps, lines in a tree | committed |
| [functional_text/FUNCTIONAL_TEXT.md](functional_text/FUNCTIONAL_TEXT.md) | the form: taxonomy, sections as functions (needs / gives / admin / borrows), the page's devices (2b), the chapter file format, what the checker verifies and cannot see | committed |
| [taxonomy.json](taxonomy.json) | the hard taxonomy: 631 entries (concept 201, godot 157, maths 106, gdscript 69, supplied 43, name 30, plain 18, admin 7), each with forms, def, introduced_at, synonyms, depends_on | committed |
| [functional/ch01.md](functional/ch01.md) | 1 Points Build Bodies | written, 0 errors |
| [functional/ch02.md](functional/ch02.md) | 2 Bodies That Change | written, 0 errors |
| [functional/ch03.md](functional/ch03.md) | 3 Many From One | written, 0 errors |
| [functional/ch04.md](functional/ch04.md) | 4 Colour by Function | written, 0 errors |
| [functional/ch05.md](functional/ch05.md) | 5 A Source, Many Repeats | written, 0 errors |
| [functional/ch18.md](functional/ch18.md) | 18 Bodies From Fields (written early as the hard case) | written, 0 errors |
| [functional/patches/](functional/patches/) | the taxonomy changes each chapter writer proposed, kept as the record | committed |
| [functional_text/check.py](functional_text/check.py) | the checker (standard library only) | committed |
| [functional_text/test_check.py](functional_text/test_check.py) | 207 tests, each rule with a passing case and a planted fault | committed |
| [functional_text/sketch_report.md](functional_text/sketch_report.md) | the order check of the whole sketch: 34 errors, 641 warnings | committed |
| [sketch/sketch.json](sketch/sketch.json) | 25 chapters, 197 sections, each with idea, picture, hall, code; 13 open questions | committed |
| [functional_text/round_trip/REPORT.md](functional_text/round_trip/REPORT.md) | the compression research, rounds one and two | committed |
| [site/](site/) | a MkDocs Material docs site (Read the Docs ready); it builds the OLD kit lessons, not the functional chapters yet | committed |

Chapters 6 to 17 and 19 to 25 are not written. Each exists only as its sketch entry.

### The pages (`ada_encyclopedia/`, dev server `npm run dev`, port 3003)

| URL | source |
|---|---|
| http://localhost:3003/course/sketch | `src/app/course/sketch/page.tsx` |
| http://localhost:3003/course/sketch/1 (and /2 /3 /4 /5 /18) | `src/app/course/sketch/[chapter]/page.tsx`, `functional-text.css`, `src/lib/course-sketch.ts` |
| http://localhost:3003/course/sketch/order | `src/app/course/sketch/order/page.tsx` |

The chapter page hides the signature comments, keeps one source line per page line, renders numbered steps and the bullet tree, shows the Types box as a card, and links every admin call to its first instance. A new `chNN.md` appears on its own.

### Memory (for Claude sessions)
`~/.claude/projects/C--Users-palle-Documents-GitHub-AdaResearch-46/memory/feedback_course_text_compression.md` (the whole day's decisions) and `feedback_minimal_change_pilot_first.md` (section 1 of this file).

---

## 5. How it works, and the commands

### A chapter file
Each section starts with a signature in an HTML comment, then plain Markdown:

```markdown
<!-- section 2.1
needs: extends, Node3D, func, _process, var, :=, +=, $, position, y, frame, MeshInstance3D, BoxMesh, Inspector, metre, base_scene, add_a_node, run_the_project
gives: *, delta, frame_rate
admin: delete_a_node
-->
## 2.1 A little every frame

*[the cube in three stills a second apart, each half a metre higher than the last]*

**Delete a node**: select it, then press Delete.

1. Delete every node you added: keep the base scene's own.
2. Add a `MeshInstance3D` named `Cube` with a `BoxMesh`.
   - Its `position` is in the Inspector, under `Node3D`.
3. Set it to (0, 0.5, 0).

**Example 2.1: a rising cube**

(gdscript block)

Run the project: the cube rises.

- `delta` is the seconds since the last frame.
  - It has no underscore here: the code uses it.
- ...

Times `delta`: per second, at any frame rate.
```

- `needs`: entries the section uses (all introduced earlier). `gives`: entries it introduces (each needs a defining line in the text). `admin`: admin procedures it defines. `borrows`: supplied parts it hands out.
- The form: plain lead line, numbered steps (doing), code, a bullet tree (understanding: a child explains, qualifies, follows from or restores its parent; at most two levels), plain point line.
- The page's devices are listed in FUNCTIONAL_TEXT 2b. Nothing else (no arrows, no `enters:`, no `from:`, no provenance tags: the checker refuses them).
- Every chapter script `extends Node3D` and sits on the root node of the base scene (the checker's `top` rule).

### Commands (run from `doc/book/course/`)

```bash
python functional_text/check.py --taxonomy taxonomy.json --godot functional/ch04.md
```
Checks one chapter, runs its code in Godot. The exit code is the number of errors. Without `--godot` it is fast and skips Godot. `--quiet-warnings` hides warnings.

```bash
python functional_text/test_check.py
```
All 207 tests, about 100 s; some run Godot.

```bash
python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json --report functional_text/sketch_report.md
```
The order check of the whole course sketch.

Godot is `C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe`; the checker finds it itself.

### State at handover (measured 21:20)
- ch01, ch02, ch03, ch04, ch05, ch18: 0 errors with `--godot`.
- 207 tests: OK.
- Sketch order check: 34 errors, 641 warnings. The 7 real order breaks: wallpaper group, rate, Mover (in 8.x), damping, reaction-diffusion, genome, queue. The other errors are terms the sketch never teaches.
- Uncommitted in `doc/book/course/`: only `kits_checked.json`, which is not part of this work (leave it).

---

## 6. What is open, in order

### 6.1 A decision Palle has not made: bodies in code, or bodies in the editor
Palle asked: "we use variables for meshes in the .tscn; we could also create these meshes to keep it all in code. we need to choose; if we go with the .tscn approach we need to say something about that in the tutorial?"

Today the chapters do both:

| chapter | bodies made in the editor (Add a node, Inspector) | bodies made in code (`.new()`) | scene files (`preload`, `instantiate`, `.tscn`) |
|---|---|---|---|
| 1 | 6 | 0 | 2 |
| 2 | 5 | 0 | 2 |
| 3 | 1 | 0 | 24 |
| 4 | 4 | 28 | 0 |
| 5 | 0 | 21 | 1 |
| 18 | 0 | 7 | 1 |

This session recommended **code**: it is a coding course; the checker can run code but cannot click the editor; loops (chapter 3 on) need code; Ada's own artifacts are built in code in `_ready()`. The editor would keep opening the base scene, putting the script on the root node, running, and looking. Chapter 1 would say it once: "In this course, code makes the bodies. The editor runs them and shows you what code made."
**Palle did not answer.** Ask him before changing anything. If he says code: chapters 1 to 3 change (`.new()` and `add_child` move into chapter 1 in the taxonomy; chapter 3's scene files become bodies made in a loop; chapter 4 may name the repeated making as a function that returns a body). If he says editor: write the rule into chapter 1 and leave chapters 4, 5 and 18 as code with one sentence on why.

### 6.2 Type highlighting (asked, not built)
"highlight the word type like in code?" Plan, already agreed in principle:
- The checker, as it checks a chapter, writes a sidecar `functional/chNN.types.json` with every prose use of a taxonomy term it resolved (line, span, entry id, kind, declaring or not, def, introduced_at, a hash of the chapter text). One implementation: spans come from the checker's own matching, never from a second matcher in TypeScript.
- The chapter page colours those spans by kind (concept, maths; code names keep their code style), the declaring use in bold, with a tooltip "N.M · def". A tooltip, not a link: Palle's rule is that teaching is never linked back.

### 6.3 Illustrations beside the code
"use illustration whenever you can along the code". Every section has a figure line `*[...]*` saying what its picture shows; only one diagram line exists so far (ch04 4.2: `*[diagram: ...]*`, the flow of a return value). Add a figure line beside each code block where a picture helps. The images themselves come later ("make images later"): renders from each example's own code for bodies, drawn diagrams for ideas. Note: the checker does not yet know the `diagram:` prefix as a kind; it reads it as an ordinary figure line, which works.

### 6.4 Standard vocabulary, the rest of it
The three words Palle named are fixed. Other homemade definitions are likely still in the chapters and in `taxonomy.json` defs. Do this as a list for Palle first, not as a rewrite: for each term, the current def, the Godot documentation's wording (URL), a proposed short def. Change only what he approves. Course-coined terms that he agreed (mesh = what is seen, shape = what is touched) stay.

### 6.5 Part II, chapters 6 to 9 (Motion: change, forces, formfinding, wavefunctions)
Write them the way chapters 2 to 5 were written, but with the method of section 1: one chapter first, show Palle, then the rest. Each writer proposes taxonomy changes in a patch file (`functional/chNN.taxonomy_patch.json`, a list of `{op, id, fields, why}`) instead of editing `taxonomy.json`, because parallel writers overwrite each other; one agent merges the patches in chapter order. A student reading of each chapter, with the earlier chapters in hand, found the real stalls last time.

### 6.6 Smaller open points
- Two editor procedures are not confirmed in a live Godot editor (the checker cannot click): "Make a new script" (Script, File, New Script, name, Create) and dropping a `.gd` or `.tscn` from the FileSystem onto a node to attach it.
- Two choices for Palle from the order check: may an exercise explain a term in passing (accept-reject, Huber, topological sort)? Is "evolution" taught or an everyday word?
- "basic class" (Palle's word) against "built-in class" (the Godot documentation's word): the text uses "built-in class". Ask if he prefers his.

---

## 7. The compression research (background for Palle's research method)

Palle's method: compress, unfold, compare, and let what fails to return change the next version. He wants to study the "subtle vectors" lost in compression: the direction of a thought, the force of a claim, the connection between a shortcut and the system it enters.

- Round one (rebuild the lesson): of claims kept in the compressed text, 480 of 484 returned; of claims cut, 2 of 117. Force was lost first, connection next.
- Round two (understand the lesson, with the earlier chapters available, open book, two blind judges): every one of 336 scores was full, for the original and for texts at 54% (Point One) and 33% (cellular) of its prose. This is a ceiling: agent readers already know Godot. The eleven extra devices round one proposed cost 11 to 36% more words and moved no score, so they were dropped. The only misunderstanding came from a paragraph of the original.
- A sharper round three would need a reader without Godot knowledge and an exam with headroom. A draft plan exists: [functional_text/round_trip/T1_PLAN_DRAFT.md](functional_text/round_trip/T1_PLAN_DRAFT.md) (not approved by Palle).
- All sheets: `functional_text/round_trip/round2/results.json`.

---

## 8. Traps that cost time today

- **Stale `.git/index.lock`.** A crashed git left an empty lock five times today. If git refuses and no `git.exe` is running (`tasklist | grep -i git`), delete `.git/index.lock`.
- **Shared tree.** Other sessions edit this repo. Commit by explicit paths only (`git add -- <paths>`), never `git add -A`, never `git stash`. `doc/book/course/kits_checked.json` and the encyclopedia's `src/app/globals.css` belong to others.
- **Agents commit if they see "commit" in Palle's messages**, even when the brief says not to. Say it explicitly in every brief, and check `git log` after a run.
- **Workflow resume re-runs work.** A resumed workflow reused results only while its calls came in the same order; after the crash it re-ran a 27-minute compression. Keep expensive outputs as files.
- **Windows file locks.** A write to `taxonomy.json` once failed with `OSError: [Errno 22]` while another process read it; retry after a second.
- **Python on Windows writes CRLF** in text mode unless you pass `newline="\n"`; a workflow script with CR characters is refused.
- **The shell's working directory** follows your last `cd`; a folder you `cd` into cannot be deleted until you leave it.
- **A twin session.** After the computer crashed, session 0f212078 received the same messages as this one; it wrote an earlier version of this file. Forum thread `261002-xga26` claims these paths (`python tools/forum.py read 261002-xga26`).
- **`godot --doctool`** dumps only the API skeleton, without descriptions. For definitions, read docs.godotengine.org.

---

## 9. Today's commits

Ada repo (`palm-scanner-door-entry`):

| commit | what |
|---|---|
| `243394c16` | the course sketch, 25 chapters |
| `faeac2b6d` | functional text: spec, taxonomy, checker, tests, chapters 1 and 18, admin |
| `5dcdc23de` | compression rounds one and two; the first handover |
| `2161e5ab7` | the docs site |
| `9f7cddf35` | cellular kit: the edge walker hangs on row 9's edge, it does not stand on row 8 at 1.46 m |
| `05f13cf7e` | specs amended from round two |
| `ee8602cb1` | one convention for scripts (root node, extends Node3D); admin "make a new script", "put a script on a node"; the device rule |
| `9099afac2` | chapters 2 to 5 written, their taxonomy patches merged |
| `720bbf194` | chapters 2 to 5 fixed after four student readings |
| `6b5b6f6d1` | lines in a tree |
| `3083866fe` | Palle's words: return, not answer; built-in class; alpha is opacity |

Encyclopedia (`spatial-iterations-gallery`): `af36b31f` the /course/sketch pages, `70791229` two blog posts (2026-10-02 "The Field Was Too Wide", "Text That Compiles"), `297d942c` the tree styling.

Nothing is pushed.

---

## 10. Do not

- Do not re-write a chapter to fix one line.
- Do not paraphrase a standard term.
- Do not relaunch the old kit build (`doc/book/studies/`, `KITS_BRIEF_LONG.md`): Palle stopped it for being too verbose.
- Do not link teaching back; only admin calls link.
- Do not change the bodies-in-code question (6.1) without Palle's answer.
- Do not push.
