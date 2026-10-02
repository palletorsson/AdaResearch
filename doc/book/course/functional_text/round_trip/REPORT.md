# Round trip: what survives when the text gets smaller

Compress, unfold blind, compare claim by claim.
Two lessons, three levels each, 2 October 2026.
Asked by Palle: can we compress the tutorials more, to make them more readable?

## The answer

Yes, a little, and by kind, not by length.
Halving short-speak costs 11 to 21 points of what returns.
A smaller text did not read easier.
The reader's work moved from reading to inferring.
What is kept returns: 480 of 484 claims.
What is cut does not: 2 of 117.
What the reader can derive can go.
What only the author holds must stay: direction, force, connection, evidence.
Those are short. They are the text's entropy.

## 0 Method

| step | what |
|---|---|
| claims | each lesson cut into atomic claims before compression: point-one 118, cellular 175 |
| kinds | fact · step · code · direction (where a thought leads) · force (how strongly, under what condition) · connection (a shortcut and the system it enters) |
| compress | three levels by an agent per SHORT_SPEAK.md: L1 short-speak · L2 about half of L1 · L3 about half of L2, in notation |
| read | each level read blind by a fresh agent: a 16-question quiz, a stuck list, a full unfolding |
| judge | each unfolding judged per claim: in the compressed text (kept · implied · distorted · missing), after unfolding (recovered · guessed · distorted · missing) |

Words: words with a letter or digit, outside fenced code and HTML comments, link URLs dropped.
One counter for all files, so cellular figures differ from the compressor's own (2939 · 1560 · 926).
*Returned* = recovered, not guessed.
*Lost* = distorted or missing after unfolding.
Files, per lesson: `claims.json`, `L1.md`–`L3.md`, `L*.unfolded.md`, `L*.compare.json`.

## 1 The tables

Claim cells read `kept·implied·distorted·missing → recovered·guessed·distorted·missing`. Bold is what returned.

### Point One (chapter 1, `commons/maps/Point_One/tutorial.md`)

| level | prose words | of source | file lines | code lines | quiz | stuck | unfolded words | returned | lost |
|---|---|---|---|---|---|---|---|---|---|
| source | 793 | 100% | 113 | 45 | | | | | |
| L1 | 917 | 116% | 258 | 45 | 0.94 | 20 | 2392 | 104 (88%) | 6 (5%) |
| L2 | 427 | 54% | 119 | 22 | 0.75 | 25 | 1787 | 91 (77%) | 15 (13%) |
| L3 | 184 | 23% | 59 | 15 | 0.75 | 23 | 1897 | 87 (74%) | 18 (15%) |

| kind | n | L1 | L2 | L3 |
|---|---|---|---|---|
| fact | 41 | 31·9·1·0 → **37**·2·2·0 | 24·14·2·1 → **35**·3·1·2 | 17·22·0·2 → **35**·3·1·2 |
| step | 17 | 13·4·0·0 → **13**·1·0·3 | 7·7·1·2 → **13**·2·0·2 | 8·5·0·4 → **13**·0·2·2 |
| code | 22 | 21·1·0·0 → **22**·0·0·0 | 19·2·0·1 → **19**·3·0·0 | 17·3·0·2 → **18**·4·0·0 |
| direction | 11 | 7·4·0·0 → **9**·2·0·0 | 6·2·1·2 → **8**·0·1·2 | 7·1·2·1 → **6**·1·4·0 |
| force | 13 | 8·5·0·0 → **11**·1·0·1 | 3·4·3·3 → **6**·3·3·1 | 1·5·0·7 → **5**·4·2·2 |
| connection | 14 | 8·5·1·0 → **12**·2·0·0 | 7·4·0·3 → **10**·1·1·2 | 4·8·0·2 → **10**·1·0·3 |
| all | 118 | 88·28·2·0 → **104**·8·2·4 | 66·33·7·12 → **91**·12·6·9 | 54·44·2·18 → **87**·13·9·9 |

### Cellular (chapter 13, `doc/book/studies/cellular/TUTORIAL.md`)

| level | prose words | of source | file lines | code lines | quiz | stuck | unfolded words | returned | lost |
|---|---|---|---|---|---|---|---|---|---|
| source | 4217 | 100% | 460 | 148 | | | | | |
| L1 | 2731 | 65% | 734 | 148 | 0.91 | 25 | 5442 | 149 (85%) | 20 (11%) |
| L2 | 1398 | 33% | 382 | 117 | 0.68 | 23 | 4592 | 112 (64%) | 46 (26%) |
| L3 | 780 | 18% | 136 | 23 | 0.73 | 22 | 3330 | 70 (40%) | 66 (38%) |

| kind | n | L1 | L2 | L3 |
|---|---|---|---|---|
| fact | 71 | 57·6·3·5 → **62**·2·2·5 | 39·20·0·12 → **51**·7·3·10 | 35·21·0·15 → **41**·9·6·15 |
| step | 19 | 18·1·0·0 → **18**·1·0·0 | 5·11·1·2 → **12**·2·2·3 | 5·5·1·8 → **7**·3·1·8 |
| code | 29 | 28·1·0·0 → **29**·0·0·0 | 23·6·0·0 → **24**·4·1·0 | 4·16·0·9 → **6**·15·3·5 |
| direction | 10 | 8·1·0·1 → **9**·1·0·0 | 2·7·0·1 → **7**·1·1·1 | 2·4·2·2 → **4**·1·3·2 |
| force | 20 | 13·1·1·5 → **13**·0·1·6 | 8·6·1·5 → **10**·0·1·9 | 7·3·2·8 → **7**·5·1·7 |
| connection | 26 | 14·7·1·4 → **18**·2·1·5 | 6·16·0·4 → **8**·3·0·15 | 2·15·3·6 → **5**·6·3·12 |
| all | 175 | 138·17·5·15 → **149**·6·4·16 | 83·66·2·24 → **112**·17·8·38 | 55·64·8·48 → **70**·39·17·49 |

### What each state becomes, both lessons, all levels

| in the compressed text | returned | guessed | distorted | missing |
|---|---|---|---|---|
| kept (484) | 480 | 0 | 4 | 0 |
| implied (252) | 129 | 67 | 17 | 39 |
| distorted (26) | 2 | 5 | 18 | 1 |
| missing (117) | 2 | 23 | 7 | 85 |

Implied returns 70% in the short lesson, 37% in the long one.

## 2 The knee

| lesson | level | words of source | returned | lost |
|---|---|---|---|---|
| point-one | L1 | 116% | 88% | 5% |
| | L2 | 54% | 77% | 13% |
| | L3 | 23% | 74% | 15% |
| cellular | L1 | 65% | 85% | 11% |
| | L2 | 33% | 64% | 26% |
| | L3 | 18% | 40% | 38% |

Point One loses in a step, not a slope.
The first real cut, to 54%, costs 11 points.
The next halving, to 23%, costs 3.
Its loss is a handful of sentences.
Once they are gone, code and facts remain, and those survive to a quarter.

Cellular loses on a slope that steepens.
65% to 33% costs 21 points; 33% to 18% costs 24.
At L3 its code fails too: 6 of 29 return.
It is no longer buildable.

The fragile set: claims lost at some level.
Point One: 29 of 118 (25%). Cellular: 78 of 175 (45%).
The long lesson holds more that only its author knows: hall facts, measured runs, the course's route.

Short-speak is a reading form, not a compression.
Point One L1 is 116% of its source in words, 2.3 times in lines.
Its Types box, figures and headings cost 242 words; short-speak saved 80.
It still scored best of all six.

The quiz is blind to the knee.
It plateaus (0.75 · 0.75; 0.68 · 0.73) while claims keep falling.
It tests facts and code, and those survive.
The claim list is the instrument.

The reader's load did not fall.
Stuck points stay at 20–25 on every level.
They change kind:
L1, terms used before they are declared.
L2, reasons cut, fragments shown as wholes.
L3, notation to decode (`›`, `·`, `→`, `≠`), referents missing.
Unfolding Point One took 2.3–3.0 times the source's words.
At cellular L3 the reader simulated the automaton to get the counts.

**So: can the tutorials be compressed more, to be more readable?**
Yes, to about half of the source for a short lesson, two thirds for a long one.
Not by cutting more of everything: by cutting what the reader can rebuild.
Can go: code glosses, numbers computable from the code on the page, repeated code.
All of that came back by arithmetic or Godot knowledge.
Must stay: the fragile set, whole.
Kept, a claim returns 99% of the time. Cut, 2%.
Below the knee the text gets shorter and the reading gets longer.

What returned is what the reader already shares: Godot, arithmetic, the code on the page.
What did not is what only the author holds: the route, the evidence, the decisions, the withheld.
That is the text's entropy.
It cannot be compressed, only written short.

## 3 The vectors

Lost (distorted or missing after unfolding), both lessons:

| kind | L1 | L2 | L3 |
|---|---|---|---|
| fact | 9/112 (8%) | 16/112 (14%) | 24/112 (21%) |
| step | 3/36 (8%) | 7/36 (19%) | 13/36 (36%) |
| code | 0/51 (0%) | 1/51 (2%) | 8/51 (16%) |
| direction | 0/21 (0%) | 5/21 (24%) | 9/21 (43%) |
| force | 8/33 (24%) | 14/33 (42%) | 12/33 (36%) |
| connection | 6/40 (15%) | 18/40 (45%) | 18/40 (45%) |

The order:
force first, already at L1;
connection next, half lost at half size;
direction bends at L3;
steps and code fail only when cut;
facts last.

The manner:
force and connection are deleted (27 of 32 failures at L2 are *missing*);
direction is bent (7 of 9 failures at L3 are *distorted*).

### Direction that did not return

Point One, C112, bent at L2 and L3.
Source: "Knowing its construction gives us another way to change the encounter."
L2: "you know how to rebuild it." L3: "yours to rebuild."
The L3 reader added a rebuilding procedure.
A second way to meet the sphere became an assignment to make it.

Cellular, C175, missing at L2 and L3.
Source: "The next stop, *The tree and its mad branch*, keeps the idea of a rule applied to its own result and drops the grid: a function that calls itself."
L1 kept only "a function that calls itself".
Reader: the compressed text never names the next stop.
The chapter no longer points on.

Cellular, C1, bent at L3.
Source: "Until now a body was built once: a loop ran, and the mesh was there. Here the body is a history."
L3: "Body = history".
A turn with two ends became an equation with none.

### Force that did not return

Point One, C93 and C117.
Source: "Restore `sphere_shape.radius = radius`."
L2: "Restore `0.14`."
A link restored became a value; the five restores collapsed into one.
The L3 reader ran the 0.35 test on a mesh of 0.3 carried over from another file, then offered to "keep the mismatch on purpose".

Cellular, C11, missing at all three levels.
Source: "Every message and number on this page comes from running the study in Godot 4.6."
Cut by SHORT_SPEAK's own rule: "No hedging and no measurement reports in the lesson."
With it went C16 (halls read, not walked), C111 ("Our sheet is eleven rows from one seed"), C146 ("no hand was on the keys").
All seven force losses at cellular L1 come from two rules of the form, not from size.

Cellular, C138.
Source: "Both are our decisions; the pattern has no part in them."
L1: "Both are yours". L3: "your line (B → shape) + your threshold (0.1)".
The line and the threshold are supplied. The student made neither decision.

### Connection that did not return

Point One, C37, missing at L3, distorted at L2.
Source: "It belongs to the supplied test, not to the position we have just defined."
Both readers explained the feeler's crossing by another cause: no body there.
True physics, wrong lesson.
Quiz question 3 scored 0 at L2 and L3, the only flat zero.

Cellular, C158.
Source: "a guest may name nothing outside its own folder."
L1–L3: "A guest is a body your room loads from its own folder."
A prohibition became an address; the reason the guest's colour is written out vanished with it.

Cellular, C9.
Source: the CA_Introduction board "shows the loop this lesson is built on, and says what it is for".
L1 moved the quote after the repair; L2 and L3 dropped its hall.
A premise became a confirmation.

### Losses the form made

- **The hedge rule.** It cut evidence and scope as if they were hedges (above).
- **Voice.** "Second person, present tense" and the we/our warning: "our decisions" became "yours" (C138). "We have chosen" (done, right after the edit) became "You choose" (a standing capacity, moved to the end) (C90). "We found out by running them" became "You find out by running them" (C110).
- **Renames.** surface and boundary became *mesh* and *shape*. "Encounter" went with them: the word that tied the boundary to the visitor, and came back in the last paragraph.
- **A type that collides.** *body*: "a node you place" names the `MeshInstance3D` marker, while `StaticBody3D` is a body too. Readers got stuck on it at L1 and L3; the L2 judge flagged it.
- **Hidden declarations.** Signatures sit in HTML comments; the Types box comes last. *feeler* is used from 1.1 and defined in the closing box. Type-safe in the source, not on the page.
- **Captions for steps.** "Open `position.gd`" became "This is all of `position.gd`" (C21, C39, C68). These are the only step losses at Point One L1.
- **Notation.** `→` cannot tell "prepare for" from "make": "prepare two positions for the line" unfolded as "draw a line between them" (C114). `≠` turns an act into an identity: "Remove the light, keep the body" became "Light ≠ body".
- **A green checker.** check.py found no filler, voice or style fault at any level. It passed texts that had lost up to a quarter of their claims. FUNCTIONAL_TEXT.md §6 says it cannot see meaning; this experiment measures what it cannot see.

## 4 The unfolding

### Recovered

Everything kept: 480 of 484.
Half of what was implied: 129 of 252.
Almost nothing cut: 2 of 117.

By work, the readers rebuilt:
- **Arithmetic:** row 1 is ten cells; 6 of 187 border cells; 37 tiles and 33 boxes; 35 and 35 at a dead end; Sierpinski's rows.
- **Godot:** `:=` infers the type; `add_child` with no object attaches to the node itself; static means it does not move; `height = radius * 2.0` keeps the sphere round.
- **Some force words from context:** "only" (Point One L2), "however large" (L1), "should" (cellular L1).

Once, the reader recovered more than the compression carried.
Point One L1 made the edit cause the warning (C35).
The reader saw `point_position` is unused at 1.12 too, and repaired it.

### Guessed

33 guesses in Point One, 62 in cellular. They sit exactly where the text was cut.
The wrong or off-reason ones:

| guess | level | source |
|---|---|---|
| the station's label reports "stopped" | P1 L1 | `contact_probe.gd` makes its own contact label |
| x, y, z, the middle is height | P1 L2, L3 | the source withholds the three numbers for Point Coordinates |
| "keep the mismatch on purpose" | P1 L3 | return both radii to the matching 0.14 |
| the feeler stands in because nobody walks | P1 L1–L3 | the camera is fixed, so another body must move |
| `pace := 0.5` | C L3 | 0.25 |
| Rule 30 drops the walker at row 2, "worked by hand" | C L2 | it climbed six rows to 0.90 m |
| "Press Play" for `diffusion.tscn` | C L2 | F6: Play runs the main scene |
| the board's buttons are 30, 90, 110, 250 | C L2 | 30, 90, 110, 184 |
| the 0.2 m cell is sized to the walker | C L2, L3 | to the marble |
| Rule 110 is the only floor the walker climbs | C L2 | Sierpinski's rows walk by their edge, to 1.46 m |

Two ways to guess wrong.
Silence read as permission: an unmarked withholding gets filled.
A shortcut attached to the wrong system: the 0.2 m cell, the label.
L1 kept "Its three numbers wait for Point Coordinates", and its reader left them alone.
L2 and L3 cut that line, and both readers filled the dark spot.
A marked dark spot survives; an unmarked one is sealed by the next reader (the Sieve's third question).

A better reader will derive more and guess better.
It cannot recover the author's choices, because they are not in the text.
It will guess them more convincingly, which is worse: "worked by hand" was attached to a wrong walk.

### New possibilities

The unfoldings made things that neither the source nor the compression had:
- A station table (station · what you see · what the feeler does) and the Solid node tree: structure shown, not told.
- A hinge: "The mesh and the shape agree only because the script gives them one radius. Now pull them apart."
- A third layer: light changes what is seen, not what is touched. Seen, touched, lit.
- The warning as evidence: it appears in `position.gd` and goes once `visible.gd` reads `point_position`.
- Why 90 sits inside 250: 250 lights a cell when either neighbour lives, 90 when exactly one does.
- Each body measures otherwise: 90 and 250 are twins for the eye and the walker, not for the marble.
- The ring lives in the rule, not the body: a ring gives 37 tiles and 33 boxes, a dead end 35 and 35.
- One invariant for stair and pool: no cell reads a neighbour's answer before it has asked its own question.
- A text picture of the floor (`#` live, `.` dead), checkable by a test or a screen reader.
- The whole file at Stop here, as a checkpoint.
- A type for argument sections: `→ decision`, a section that gives a choice, not a concept.
- A body strip beside the picture strip: the collider step is 0.00% in the picture and visible only to a walker.
- "Keep the mismatch on purpose": wrong as a step, alive as an invitation after the restore (the ghost wall).
- The `[guess]` marks as a diff map: each one marks a place the text underdetermines.

## 5 The next version

Each change is small, says where it goes, and names the lost claims it would carry.
`p` = Point One, `c` = cellular.
The assignment is a prediction, not a measurement.
These are proposals only: SHORT_SPEAK.md and FUNCTIONAL_TEXT.md are untouched.

| # | change | goes into | form | would have carried | n |
|---|---|---|---|---|---|
| 1 | **Direction line** | SHORT_SPEAK | A section's last line starts `→`: what it opens, why the next follows. It keeps its verb. A chapter ends `→ Next: <stop> keeps <a>, drops <b>.` A turn keeps both ends ("Until now… Here…"), never `a = b`. An opening question stays a question. | p109 p111 p112 p113 p114 · c1 c10 c12 c78 c113 c140 c175 | 12 |
| 2 | **Withheld line** | SHORT_SPEAK | `Not yet: <thing>. <stop> opens it.` and `Not here: <thing>.` These mark the dark spot so no reader fills it. | p30 p31 p108 p115 | 4 |
| 3 | **Force words, a closed set** | both | only · all · whole · never · may not · must · before · until · either · optional · should (for a prediction). A force word is a token: compression rewords around it, never drops it. A prediction keeps *should*, and its answer comes after the run. | p5 p84 p116 · c102 c114 c158 | 6 |
| 4 | **Provenance marks; scope stays** | SHORT_SPEAK, rule change | `[run]` measured, `[read]` from files, `[derived]` computable from the page, *(editor)* not watched. "No hedging" stays; "No measurement reports" goes, because scope is part of the claim. `[run]` and `[read]` numbers are never cut. A `[derived]` number may become a `compute:` exercise, with the answer in the key. | c11 c13 c14 c15 c16 c22 c23 c59 c83 c95 c103 c111 c129 c130 c132 c142 c143 c144 c146 c153 c154 c160 c162 c165 | 24 |
| 5 | **`enters:` line** | FUNCTIONAL_TEXT | For a supplied part, a quote or a borrowed rule: `enters: <system>, not <what it seems>; <whose choice>.` Examples: "enters: the supplied test, not your point." "enters: the kit's choice: one collider line, threshold 0.1." A hall quote keeps its hall and its role: premise or verdict. | p37 p107 · c8 c9 c24 c65 c99 c115 c116 c131 c136 c137 c139 c157 c161 | 15 |
| 6 | **Visible `from:` line** | FUNCTIONAL_TEXT | `needs:` is shown on the page with where each item was taught: "from: `_ready` (Point Zero) · `%` (chessboard) · `MultiMesh` (pendulum)". check.py generates it from `introduced_at`, so it costs no writing. | p40 · c5 c38 c39 c69 c167 | 6 |
| 7 | **Restore and State as postconditions** | both | An experiment that changes a value ends with `Restore:`, naming the expression when the value was a link. A session ends with `State:`: the file's shape, or the whole file. The next section's `needs` include the restored state. | p38 p66 p93 p98 p117 · c77 c96 c97 | 8 |
| 8 | **Mood is typed** | SHORT_SPEAK | A do-line is an imperative ("Open `solid.gd`."), never a caption ("This is `solid.gd`."). A report stays a report ("Run twice: the same rows `[run]`"), never an order or a promise. | p21 p39 p68 · c19 c25 c86 c121 | 7 |
| 9 | **World nouns are types, declared on the page** | FUNCTIONAL_TEXT | museum, hall, corridor, label, marble, walker, base scene, `sheet.gd`, `GUESTS` get kind `place` or `supplied`. First use carries the def inline ("a *feeler*, a small pink body that tests contact"). The Types box stays as the index. The `unknown` rule covers them. | p11 p95 p96 · c20 c104 c164 c171 | 7 |
| 10 | **Name the agent** | both | Narrating *we* stays out, but a decider is named: "the kit chose", "the authors' run". A result reached by doing keeps the perfect tense: "You have chosen whether they agree." The voice warning spares a named agent. | c138, plus the bent-but-returned p90 and c110 | 1 |
| 11 | **Code whole, or a marked fragment** | FUNCTIONAL_TEXT | A fragment says where it sits (`# in _ready(), after point_position`) and marks what it omits (`# …`). "All of" and "whole" stand only over a whole file. A line that carries a shared link (`sphere.radius = radius`) is never cut. | p27 · c26 c29 c35 c46 c48 c50 c51 c79 c80 c81 | 11 |
| 12 | **No type inside a class name in another sense** | FUNCTIONAL_TEXT | A text form of a course type may not appear inside a Godot class name that uses it in another sense (*body* and `StaticBody3D`). This is a warning. | no counted claim; one stuck point at L1 and L3 | 0 |

Carried: 101 of the 107 lost claims.
Fit none: p16 (the sweep repeats), p97 (the boundary inside the visible body), c7 (Import), c21 (the scene's two nodes), c55 ("reading a result like this one is ordinary work"), c141 (the walker's keys).

Yield, highest first: provenance 24 · `enters:` 15 · direction 12 · code 11 · restore 8.
The closed set of force words carries only 6.
Here force lives less in modal words than in evidence and scope.

### Three rules to amend, not only add

- SHORT_SPEAK, "No hedging and no measurement reports in the lesson": split hedge from scope. A hedge goes; a measured range stays.
- SHORT_SPEAK, "Second person, present tense": add the named agent, and the perfect tense for a result.
- FUNCTIONAL_TEXT §3, "Signatures sit in HTML comments: the student never sees them": the `needs` line becomes visible (change 6), and the `gives` defs appear at first use (change 9).

### What check.py could verify

- every section has one `→` line, and a chapter ends with keeps and drops;
- force tokens per section, source against compressed: a drop is an error;
- a changed value has a `Restore:` before the section ends;
- a `fragment` block has a location comment, and "all of X.gd" stands over a block that parses whole;
- a world noun is declared before use;
- a number carries a provenance mark;
- a type's form inside a Godot class name is a warning.

### The compression rule this leaves

Cut what the reader can derive.
Keep what was measured, read or decided.
Mark what is withheld.

### Round two, predicted before it runs

Compress both sources again to L2 size, with changes 1–11.
Same claims, same quiz, fresh readers, two unfoldings per level.
Prediction: lost at most 6% for Point One (now 13%) and 12% for cellular (now 26%), at no more than 60% and 45% of source words.
If lost stays near 13% and 26%, the changes carry nothing.
If words pass those ceilings, the changes cost more than they carry.

## 6 Limits

- **Two lessons.** One short (793 words, 118 claims), one long (4217 words, 175 claims). Chapters 1 and 13 only, in two writing styles.
- **Agents as readers.** They know Godot and do arithmetic. A beginner would not simulate an automaton or know that `add_child` attaches to self. Real readers' stuck points may differ in number and kind.
- **One of each.** One compression, one reader and one judge per level, with different agents per level. The noise shows: p5, p97, p109, c5, c140, c142 and c161 were lost at L2 and returned at L3, and cellular's quiz rose from L2 to L3.
- **Judges differ.** Their rubrics differ on partial credit and on derived answers (cellular L2 scores 0.77 if a derived, correct answer counts as sure).
- **The claim list is itself a compression.** One agent cut and typed it. Every claim weighs the same, so one code line counts as much as the chapter's direction.
- **Two variables in one.** L3 changed size and form at once (notation), so its losses mix both.
- **One family.** The same model family compressed, read and judged. Shared priors may raise recovery; the "future AI" here is today's.
- **Nothing ran.** Code was judged by reading. The cellular L3 unfolding would lay rows forever and draw no tiles; this was found by reading, not by Godot.
- **The sources have gaps.** Neither introduces the museum, so those stuck points are inherited, not caused by compression.
- **Coverage is a prediction.** The 101 of 107 above is one reader's assignment; round two tests it.

## Round two: understanding, not reconstruction

The same two lessons, 2 October 2026.
Round one asked readers to rebuild a lesson. Round two asked them to use it.

### 1 Why the measure changed

Round one scored each unfolding against the original, claim by claim. A reader who understood a point but did not restate its sentence counted as a loss.
Palle made two corrections: the reader has the series before the lesson, and "the decompressor should not be forced to recreate the original but to understand the content of the tutorial".
So round two set an exam on what the lesson teaches. It was open book, taken with and without the earlier content.

### 2 The tables

The exam had 12 questions per lesson, written from the original. A critic rewrote every question that rewarded recall. The kinds were explain, diagnose, predict, apply, status, why, connect and transfer.
Seven readers took it. Two blind judges scored each lesson's seven sheets, in different shuffles. The script computed the tallies.

| cell | text | earlier content |
|---|---|---|
| O-noctx · O-ctx | the original | no · yes |
| A · B | round one's L2 | no · yes |
| C · D | L2v2, written with changes 1–11 (D = mean of D1 and D2) | no · yes |

Words were counted with §0's counter. It reproduces round one's 793, 427, 4217 and 1398.
The misunderstandings column is per judge (the mean of the two judges).

**Point One** (source: 793 prose words)

| row | words | understanding | core | direction | force | connection | code | teach-back | misunderstandings | confident-wrong | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|
| O-noctx | 793 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 9 |
| O-ctx | 793 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 12 |
| A | 427 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 13 |
| B | 427 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 12 |
| C | 475 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 15 |
| D | 475 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 (0–0) | 0 (0–0) | 12.5 (12–13) |

| as a share of O-ctx | words | every score column | misunderstandings | stuck |
|---|---|---|---|---|
| O-noctx | 1.00 | 1.00 | 0 against 0 | 0.75 |
| A | 0.54 | 1.00 | 0 against 0 | 1.08 |
| B | 0.54 | 1.00 | 0 against 0 | 1.00 |
| C | 0.60 | 1.00 | 0 against 0 | 1.25 |
| D | 0.60 | 1.00 | 0 against 0 | 1.04 |

**Cellular** (source: 4217 prose words)

| row | words | understanding | core | direction | force | connection | code | teach-back | misunderstandings | confident-wrong | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|
| O-noctx | 4217 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1 | 0 | 8 |
| O-ctx | 4217 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1 | 0 | 9 |
| A | 1398 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 9 |
| B | 1398 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 15 |
| C | 1897 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 | 0 | 10 |
| D | 1897 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0 (0–0) | 0 (0–0) | 14 (13–15) |

| as a share of O-ctx | words | every score column | misunderstandings | stuck |
|---|---|---|---|---|
| O-noctx | 1.00 | 1.00 | 1.00 | 0.89 |
| A | 0.33 | 1.00 | 0.00 | 1.00 |
| B | 0.33 | 1.00 | 0.00 | 1.67 |
| C | 0.45 | 1.00 | 0.00 | 1.11 |
| D | 0.45 | 1.00 | 0.00 | 1.56 |

D1 and D2 are identical on every score column.
Every score in both lessons is 1.00. Only misunderstandings (cellular, the original only) and stuck counts move.
Unsure but right, Point One: O 4 and 3, A 4, B 3, C 4, D 3.5 (5 and 2). Cellular: O 0 and 0, A 1, B 1, C 1, D 0.5 (0 and 1).
One HALF from one judge on one question would lower a sheet by about 0.02. That is the smallest loss this exam can show.

### 3 Judge agreement

There were 168 question pairs, 84 per lesson. Exact agreement was 168 of 168, with a mean difference of 0.
All 336 scores are FULL.
Agreement at a ceiling only says that nothing failed. It cannot show how the judges would split over a HALF.
It allows one claim: no reader of any text, with or without the earlier content, fell below FULL on any question, by either judge.
It allows no ranking of the texts.
The judges' notes agree where their scores cannot show it. In different shuffles, both judges recorded the same single error on the same two sheets (cellular O-noctx and O-ctx), and none anywhere else. Their notes on what went beyond the lesson match sheet for sheet: D2's span of 1.48 to 1.76 m, and O-noctx's point_position "dropped at the end of _ready()".
This section reads the script's tally. The judge sheets, readers' answers and exams are stored in `round2/results.json`.

### 4 The predictions

| | predicted | measured | verdict |
|---|---|---|---|
| P1 | with the earlier content, D ≥ 0.90 × O-ctx in both lessons | 1.00 and 1.00 | met, by at least 10 points. But O-ctx sits at the ceiling, so 1.00 means "all this exam asks", not "as much as the original". The "half-size" text is 60% and 45% of the source in prose words. |
| P2 | the earlier content raises the compressed texts more than the original | +0.00 for O, A and C in both lessons | not met; it cannot be tested at the ceiling. Stuck counts do not rescue it: the earlier content moved stuck by O +3, A −1, C −2.5 (Point One) and O +1, A +6, C +4 (cellular). |
| P3 | C − A is largest on force | 0.00 on every vector, both lessons | not met: there is no difference to rank |
| P4 | D's misunderstandings ≤ O-ctx's + 1 | Point One 0 ≤ 1; cellular 0 ≤ 2 | met. The only misunderstandings recorded were on the original's sheets. |

Round one's size prediction (at most 60% and 45% of source words) was met at the ceiling itself: 59.9% and 44.98%.
The compressor wrote up to the limit, so size was a target, not a result.
Its loss prediction (at most 6% and 12% of claims lost) was not measured. The reconstruction run was stopped, and four unfoldings sit unjudged in `round2/point-one/_stopped_reconstruction/`.

### 5 What each variable did

**The changes** (C against A, D against B)
- Score: no difference in any column.
- Cost: prose +11% (475 against 427) and +36% (1897 against 1398).
- Characters +25% and +57%. Code lines 47 against 22, and 259 against 117. File lines 167 against 119, and 633 against 382.
- The new device lines (`→`, `enters:`, `Restore:`, `State:`, `Not yet`/`Not here`, `from:`) take 120 of Point One's 475 words and 285 of cellular's 1897.
- Without them the new texts would be 45% and 38% of the source.
- In Point One the device lines (120 words) exceed the whole growth (48), so the rest was cut harder than L2 was.
- In cellular, 214 words of the growth lie outside the device lines; by reading, they are mostly restored numbers and hall facts.
- Stuck points did not fall: Point One C 15 against A 13, D 12.5 against B 12; cellular C 10 against A 9, D 14 against B 15.
- They changed kind.
- Gone: *body* in two senses ("Two meanings of body confused me", A). Whether a fragment is the whole file ("'That is all of position.gd' shows no extends line", B). A collapsed restore ("'Restore 0.14' - does that mean restore both the mesh and the shape radius?", A). "by weight / by arrangement" (A, B).
- New: `enters:`, provenance tags left undeclared, "the supplied position", and referents cut away (see 7).

**The earlier content** (O-ctx against O-noctx, B against A, D against C)
- Score: no difference.
- Readers used it for: `_process` runs every frame, y is up, the ping-pong rig as the two-buffer idea, and seeds at 10.2.
- Readers without it took `_process` from the question's own wording, "Point Zero's other function".
- What it did instead was audit the lesson's references into the series. Every reader with the earlier content in cellular (4 of 4) caught the claim that `MultiMesh` comes from chapter 9: "credited to 'ch 9', but they are not in what I was taught" (D2). Chapter 9 in `context.md` has no `MultiMesh`. No reader without the earlier content could see this.
- It also undid a withheld point. The types list gives "y: How far up", so "Not yet: its three numbers" withholds nothing (D1, O-ctx).
- Agent readers bring Godot with them. C on cellular, without the earlier content: "I used only the lesson's own pointers … plus general GDScript knowledge."

**How far a text can be compressed, with the series read in order**
- Measured: down to 54% of the prose (short lesson) and 33% (long lesson), with no loss this exam can see, with or without the series.
- Not measured: anything below that. The knee for understanding lies below a third, or below what this exam can see.
- Round one's L3 (23% and 18%) never sat the exam. At cellular L3 only 6 of its 29 code claims returned, which an apply question would catch.
- For agent readers, the series added no headroom. For a beginner the series would supply the Godot knowledge; that is untested.
- The prose ratio is not the page ratio.
- L2v2 is 148% and 138% of the source in file lines, and 84% and 72% in characters.
- Old L2 is 105% and 83% in file lines, and 67% and 46% in characters, with the same measured understanding.

### 6 Reconstruction against understanding

**Lost in round one, understood in round two.** A and B scored FULL from both judges on each question below.
- Point One C37: "It belongs to the supplied test, not to the position we have just defined."
- It was lost at L2, and round one's quiz question on it scored 0, the only flat zero.
- Round two's Q7 (edit the feeler or edit `visible.gd`?) and Q12 (raise the sphere) were answered in full.
- L2's "Feelers (`contact_probe.gd`), floor, light and camera are supplied. You change the three scripts" was enough to reason from.
- Point One C112: "another way to change the encounter" was bent to "you know how to rebuild it".
- Q10 (what the hall's maker can do with one line) was answered in full.
- Cellular C130: "A second pool run beside the first held the same numbers, to the last digit." It was missing at L2.
- Q10(d) asks for a reason from the step: no random draw, only fixed arithmetic. Answered in full.
- The measured evidence was replaced by an argument from the code on the page.
- Cellular C111: "Our sheet is eleven rows from one seed." It was missing at L2.
- Q7(e) asks how far the claim reaches. Answered in full: readers read the scope off what was run.
- Cellular C175, the next stop, was missing at L2. Q1(d) was answered in full, but the question names the next stop, so it shows the idea was understood, not that the text pointed on.

The pattern: round one lost the sentence that states a reason, and the agent reader rebuilt the reason when a question asked for it.
The catch: the exam handed over its facts. Q8 gives 8%, 0.00%, 14.5% and 13.3%, and Q1 names the next stop.
An exam that supplies the facts cannot see a text that lost them.
Round one's quiz was blind to the knee because facts survive compression. Round two's exam is blind to lost facts because it supplies them.
Round one's rule therefore loses one clause. "Keep what was decided" still holds for facts, which the exam had to supply. It does not hold for reasons an agent can rebuild from the code.

**Every claim present, understanding still failed**
- The original, with every claim present, produced round two's only misunderstanding.
- The source says: "30 and 90 are two answers apart, as 90 and 250 are, and they differ on 46 cells where the closest pair differs on 29."
- O-ctx read it as "30/90 was far apart (46 cells), further than 30/250 at four answers". O-noctx read it as "worse than some pairs three or four answers apart".
- Both readings are false. At 46 cells, 30/90 is the second-closest of the six pairs. 30/250 differs on 49 cells, and the three-answers-apart pairs on 56 to 59.
- The exam's own author made the same error before the critic caught it: "Correction: 30-90 is the second-closest pair".
- The author's chosen contrast, 46 against 29, carried a ranking the table refutes.
- Old L2 keeps only the table and "Answers apart do not tell floors apart". L2v2 asks "equally alike?" and gives the table. No reader of either made the error.
- The new form put claims on the page that the reader could not unpack.
- C37 returns as "enters: the supplied test, not your position." Reader C: "I could not tell what that marker means". A claim judge would mark C37 kept.
- C30 returns as "`point_position` is a `Vector3`, three numbers: the supplied *position*." Reader D2: "I wrote that line myself, so I could not see in what sense the position is 'supplied'."
- The phrase is the source's own ("the supplied position at our station"). Inside a paragraph it reads as "given". In a short line, next to an italic type, it reads as the declared type *supplied*.
- Old L2 kept "Rule 110 leans by weight, Rule 30 by arrangement." A and B: "I cannot tell what 'by weight' and 'by arrangement' mean."
- The source's counts were the meaning: 33 tiles left of the middle and 3 right, and two sides that differ on 48 cells. The line that was kept was only their label.

So a claim's presence on the page is a fact about the text, while its use is a fact about the reader. Each instrument misses what the other sees.

### 7 What still fails

The new text drew no misunderstanding in either lesson, from either judge. There was no confident wrong answer anywhere.
The only misunderstanding (6, above) came from the original's paragraph. It breaks no rule; it is the case for SHORT_SPEAK's "One claim per line": the paragraph's contrast carried a ranking that no single line states.
What fails in the new text is friction:

| fails | quoted | sheets | points at |
|---|---|---|---|
| a device used without declaration | "The 'enters:' lines: I could not tell what that marker means" (C, Point One). "an unexplained notation" (D1, cellular). "The tags [read] and (editor) are not explained" (D1, Point One). | `enters:` on 4 of 6 new-text sheets. Tags on 2 of 3 in Point One, 0 of 3 in cellular, which declares them at its head. | SHORT_SPEAK type-safe: "A term is used only after it is declared." The text's own markers are terms, and change 5 broke this rule. |
| a cut referent | "'Scene 30, script 90 … nothing printed.' I could not see why nothing would print" (D1). "I could not follow what 'via the ring' adds" (D2). "Sent out … I could not tell which body" (D2). "'First label: nothing.' … I read it as 'there is no label'" (C). | "nothing printed" 3 of 3 cellular; "via the ring" 2 of 3; "Counted unrendered …" 3 of 3 | SHORT_SPEAK: "A line is short: aim for seven words." The source said "nothing was printed about it" and "those 3 came round the ring", and the short line cut what each refers to. Change 4 restored the scope line, and the length rule crushed it. |
| a type used in another sense | "the supplied position" | 2 of 3 in Point One (C, D2) | SHORT_SPEAK: "A declared term keeps one meaning for the whole book." FUNCTIONAL_TEXT §6: a form used in the wrong sense passes the checker. |
| code named but never explained | `-> void`, `.new()`, `height = radius * 2.0`, `*` | 6 of 7 Point One sheets | FUNCTIONAL_TEXT §2: "A code element it gives needs a line that names it." Naming is not explaining. L2v2's `gives` lists `-> void` and `.new()`, yet no line says what either does; the source explained `-> void`. |
| a false reference into the series | "`MultiMesh` … credited to 'ch 9'" | 4 of 4 cellular sheets with the earlier content | FUNCTIONAL_TEXT §1: the `missing` value "never invents a teaching place". Change 6 meant `from:` to be generated from `introduced_at`. Here it was typed by hand and repeats the source's error. |
| the series against a withheld point | "'Not yet: its three numbers' sits oddly with knowing that y is up" (D1) | Point One, readers with the earlier content | FUNCTIONAL_TEXT §1: the taxonomy places y and point at 1.2, but the hall lessons never teach them (note in `context_lessons.md`). The course has two orders, and change 2's marker cannot hold against the earlier of them. |
| the source's own gaps | the feeler's height and kind. A shape whose parent is not a body. Why the walker stops on the seed. | 7 of 7, 7 of 7 and 5 of 7 sheets | FUNCTIONAL_TEXT §6: "a writer can claim too little." No text carries these, the original included. The exam asked for them (Q3c, Q12) and accepted conditional answers. |

A reader also found a possible error in the source. Row 8's top is 9 × 0.15 = 1.35 m, yet the edge walk reports feet at 1.46 m. L2v2 carries the 1.46 m.
Check it against a run before the course quotes it.

### 8 Recommendation

- **SHORT_SPEAK.md: amend, narrowly, for truth rather than understanding.** A measured scope stays as a plain line, a decision names its decider, and a cut never removes the referent of what is left.
- **FUNCTIONAL_TEXT.md: amend, narrowly.** A code element a section gives needs a line saying what it does. A visible `from:` appears only if generated from `taxonomy.json`. Every device the text uses is declared on the page before its first use.
- **Changes 1–11 as a set: do not adopt.** They cost 11–36% more prose and 25–57% more characters, and moved no score.
- **Keep two of them.** `Restore:` lines, and whole code where a file is first met and at Stop here: each removed a recorded stuck point.
- **Ratio:** write at about half the source's prose for a short lesson, and 35–45% for a long one. Code is shown whole where needed and not counted.
- **Before going lower:** set one exam with headroom (one that the original's readers do not all pass in full) and one reader without Godot.

### 9 Limits

- **One exam per lesson, at its ceiling.** All 336 scores are FULL. The exam can show a loss of one HALF (about 0.02 of a sheet), nothing finer, and it ranks nothing.
- **The exam supplies facts.** Rewriting out recall put the lesson's numbers into the questions (Q8) and named the next stop (Q1). It tests reasoning, which agents bring, not whether measured facts got through.
- **Agent readers, open book.** They know Godot, do the arithmetic, and run scratch simulations ("I also checked a few predictions … with a small scratch simulation", A, cellular). Every sheet went beyond the lesson in 1 to 5 places. The ceiling may be the readers', not the texts'.
- **One body of earlier content per lesson, the same for every context cell.**
- Point One's earlier content is Day Zero and Point Zero compressed in the new form (changes 1–11), so O-ctx read the original alongside new-form context.
- That context's types list follows the taxonomy, which gives y and point before Point One, although the hall lessons do not teach them.
- Cellular's earlier content is the taxonomy plus the course sketch. Chapters 1–12 appear as outlines, not lessons.
- **One compression per text; a second reader only for D.** D1 and D2 agree on every score. Their stuck counts are 12 and 13, and 13 and 15; unsure-but-right 5 and 2, and 0 and 1. That noise is as large as any difference between texts.
- **Stuck counts are not confusion counts.** A reader with the series notices more to check. Cellular B's 15 against A's 9 is mostly mismatches with the series.
- **The size was a target.** L2v2 landed at 59.9% and 44.98% against ceilings of 60% and 45%.
- **The reconstruction half was stopped.** Round one's loss prediction is untested.
- **The tally is the script's.** A tally fault that wrote FULL everywhere would look like this ceiling. The judges' matching notes argue against that but do not rule it out.
- **One model family.** The same family wrote the compression, the exam and the critique, read the texts and judged them.

### Checked after the report: the 1.46 m on row 8

A round-two reader flagged that row 8's top is 9 × 0.15 = 1.35 m while the cellular lesson reports the edge walker "arrived on row 8 with its feet at 1.46 m". A scratch copy of the kit re-ran the walk (`probe_edge.gd`, Godot 4.6 headless, `--fixed-fps 60`, 2 October 2026):

- The walker climbs one row per step, exactly 0.15 m each: 0.15, 0.30 … 1.35 m at row 8.
- It overshoots onto row 9 (1.50 m at x −3.38, z −1.68), then slides back towards row 8's point.
- It ends `arrived` (it reached the point) at x −3.26, z −1.56, feet 1.465 m, **perched on the front edge of row 9**: its one contact is row 9's tile at y 1.50 with a tilted normal (0, 0.88, 0.47), while a ray down its centre meets row 8's top at 1.35 m.

So the reader was right: "on row 8, its feet at 1.46 m" joins the walker's signal to a perch on the next row's edge. `verify.gd` checks only `y > 9 × RISE − 0.02`, a lower bound that cannot tell row 8 from a perch. The lesson (TUTORIAL.md line 399), FIELD_NOTE.md, sheet.json and verification.json all carry the sentence. Not edited: the fix is Palle's call. One true version: "Sent that way, it climbs a row a step, to row 8 at 1.35 m, overshoots onto row 9 and slides back onto that row's front edge, where it hangs, its feet at 1.46 m."

This is the one fact in round two that neither compression nor the exam could judge and a reader with arithmetic could: a claim's numbers disagreed with each other, and a run settled it.
