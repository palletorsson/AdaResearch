# The museum loop

2026-09-03, Palle: *"is this the perfect space room to express the essence of
this concept... The thing is that I think we can lean on the different
modalities and aspects to let them lift up each other."*

Yes. The lift is the design. Every step hands its output to the next **in a
different medium**, because each medium **fails differently**: code cannot see
space, space cannot see order, order cannot see what a thing looks like, a
picture cannot see behaviour, behaviour cannot see a claim, and a claim cannot
check itself. A loop that stayed in one medium would only ever polish that
medium.

Below is the protocol. The reasoning behind every line of it, and the mistakes
that produced it, are in **Rationale** further down. Read the protocol to work;
read the rationale to change the protocol.

---

# THE PROTOCOL

## Two loops, at two speeds

They are not one pipeline and drawing them as one was the original mistake.

    FAST SURVEY   every hall, ~3 seconds      -> WHERE TO LOOK. Fixes nothing.
    SLOW TURN     one hall, most of a day     -> WHAT CHANGES. Does not scale.

## FAST SURVEY

    1  REFRESH     rebuild the derived caches, or declare them stale.
                   shelf.json is a CACHE, not a step-zero. It has read 2899,
                   3367 and 2939 in one document; if the count moved, so did
                   the answers built on it.

    2  MEASURE     one row per hall, one column per modality:
                   CLAIM · BODY · SEEN · TEXT · SPACE · ROUTE · ORDER
                   ACT - does the thing DO what it says - is deliberately NOT
                   in the survey and will not be: behaviour cannot be read from
                   a map, only from a probe. The survey is static by design and
                   says so in its own header.

    3  DISCREPANCY form the explicit disagreements rather than the totals.
                   A gap is two sources contradicting each other, and it is
                   the contradiction that carries the information.

    4  RANK        by consequence x uncertainty x value-of-the-next-test.
                   NOT by count of todos. A hall nobody can walk through and
                   a hall with no wall text are not the same size of problem.
                   The weights are written down in coherence.py's FAULT_WEIGHTS
                   so a disagreement about priority is a disagreement about a
                   number rather than about taste.

    5  SELECT      one falsifiable question, about one hall.

## SLOW TURN

    1  CONTRACT    the hall's claim, plus the lessons that already apply.
    2  HYPOTHESIS  what you believe is wrong, stated so it can be disproved.
    3  READ        agents on every placed artifact, .gd AND .tscn, to the
                   checklist below. This is the expensive, parallel half.
    4  CROSS-CHECK one adversarial agent over all the readings. Worth more
                   than any single reader and costs one agent.
    5  DRY RUN     plan, route, order and candidate, without writing.
    6  MUTATE      journalled, reversible, one write lane.
    7  VERIFY      in FOUR media, because they fail differently:
                     plan        tools/map_plan.py, tools/stamp.py
                     exterior    capture_multi_angle.gd
                     visitor eye capture_eye_stations.gd  (INSIDE, at eye
                                 height. An exterior shot cannot answer
                                 "legible at the distance a visitor meets it".)
                     behaviour   a probe with a known answer and a negative case
    8  EVALUATE    against the hypothesis. Do not commit yet: writing and
                   gating still change the thing you just verified.
    9  WRITE       three registers, one hand, AFTER the readers land, with the
                   checklist. Do not average the registers; keep what survives
                   all three, and do not erase the disagreement between them.
    10 GATE        text (wall_voice, final_tags), space (stamp), access
                   (pathfinder + museum_walk), behaviour (the probe).
    11 FINAL VERIFY  re-run step 7. The state you accept must be the state that
                   exists after the writing and the gating, not before it.
    12 COMMIT OR REVERT. Seven outcomes, all legitimate, and only two are wins:
                     supported          -> commit
                     counterexample     -> revert, record the counterevidence
                     no change          -> the hypothesis was wrong. A result.
                     inconclusive       -> the test could not separate the cases
                     instrument failure -> the tool was wrong, not the room.
                                           Fix the tool and re-run; do not
                                           record a lesson about the room.
                     mixed / regression -> the fix worked and broke something
                                           else. Revert unless both are named.
                     blocked            -> it needs a ruling, not a change.
    13 LESSON      into doc/curation_lessons.json, with evidence and a test.
    14 REFRESH     re-run the fast survey; the turn changed its inputs.

**PROBE is a verb, not a step.** Any step whose output another step will trust
must be probed before that trust is extended. It ran three times on Act5, in
three different positions, doing three different jobs.

## Where the text lands, and who holds the file

The turn does not end at the gate. `final.md` lands on `/compose`, which
AUTOSAVES seconds after typing, and on the manuscript, and the Red Thread page.
Rooms are shared data: on 2026-09-03 two sessions wrote the transformation
chapter within an hour of each other, one session's Red Thread page was
republished under another five times, and three sessions edited this file.

So, before step 9: **post the rooms you hold to the forum.** After step 14:
rebuild the book and check compose. `tools/forum.py open` at the start of a
session is not politeness, it is the only way to find out that the hall you are
about to rewrite is already being rewritten.

## The reader's checklist

An earlier draft of this document said *code catches what is true*. It does not.
**Code catches what the implementation actually does**, which is a different and
smaller claim, and the difference was the whole of 2026-09-03: the code said a
test cube could not fall, that a yaw fader moved nothing, and that a field
began five centimetres out of reach. All three were what the implementation did.
None was true of what the room meant.

So the read is not a search for truth. It is a search for disagreement, and it
is one sentence with four worked examples: **find every place this artifact's
declarations and its running code disagree, and say which one ships.**

  - the .tscn OVERRIDES the .gd's exports
  - a `#key:value` reaches the artifact only if the key is in the config
    allow-list; otherwise it silently becomes a yaw
  - config arrives DEFERRED, after `_ready`, so whatever `_ready` bakes ignores
    the token
  - how a visitor MEETS a thing is a fact about its code, not its registry entry

## The visitor's loop, which is not this one

The protocol above is for the curator. It must never be exposed to a player.
The loop a visitor runs, and the thing all of the above exists to produce:

    notice -> predict -> act -> the algorithm answers -> compare
           -> leave a trace, or leave

A hall works when that loop closes. Everything in the curator's protocol is
instrumentation for finding out whether it does.

---

# RATIONALE

## Where the agents go

Not everywhere. Measured over four waves on 2026-09-02 and 03:

| step | agents? | why |
|---|---|---|
| 3 candidates | no | `shelf.py` is deterministic and instant |
| 4 place | no | judgement, but one person's, and it is one write |
| 6 see | **yes** | vision, one agent per capture |
| 7 write | **no** | seven rooms by seven agents do not share a voice; every multi-drafter attempt this session failed or was thrown away |
| 1, 2, and the read behind 7 | **yes, heavily** | reading every placed artifact's script and scene is the expensive, parallel, high-yield half |
| 9 gate | no | a tool |

The rule that came out of it: **agents read and check; one hand writes** — corrected 2026-09-03 to **one hand writes, AFTER the readers land, with the checklist.** What failed was never the single hand. It was the hand starting early, and this document already carries the measurement: five of five rooms written before their readers landed were wrong about something a visitor would notice.

## What the loop turned out to be, after running it once end to end

2026-09-03, one full turn on Vectors_Act5_ForceAsPlace. Three things changed in
how this is understood, and they are worth more than the turn itself.

### It is TWO loops, and they run at different speeds

The deterministic sweep over all 185 halls — `stamp.py --all`,
`argument_shape.py`, `coherence.py` — costs **three seconds**. A full turn on one
hall costs most of a day: five reader agents on five artifacts, an adversarial
cross-check, a rewrite, three code fixes and two probes.

So they are not the same loop and should never have been drawn as one.

    FAST   every hall, every day, 3 seconds     ->  WHERE TO LOOK
    SLOW   one hall, most of a day              ->  WHAT ACTUALLY CHANGES

The fast loop cannot fix anything and the slow loop cannot scale. The fast one
did not exist yesterday, which is why the slow one used to be pointed by taste.

### The engine is DISAGREEMENT, not any single instrument

Every finding of consequence today came from two instruments contradicting each
other. Not one instrument being run.

| what disagreed | what it found |
|---|---|
| registry said 4 m, code said 5 m | four surfaces carrying a wrong number, one of them a placard |
| intent said "no floor", the map had a catwalk | a real collision between VR and the museum walker |
| my flow and networkx | the answer agreed, the WITNESS did not, so the classifier was ill-posed |
| my fit script and `stamp.py` | `span_of` was ignoring a token's scale |
| greedy and Hungarian | they agreed exactly, which refuted my own prediction |
| the docs and `endless_museum.gd:660` | the museum does not reverse the subtitles, it deletes them |
| a plan and a photograph | a body drawn half its own length from where it stands |

So the modalities are not decoration. Each is in the loop because it **fails
differently**: code cannot see space, space cannot see order, order cannot see
what a thing looks like, a picture cannot see a number, a number cannot see a
claim, and a claim cannot check itself.

The corollary went out wrong the first time. It read *"a step that agrees with
the step before it taught you nothing"*, and the sharper version is
**unexpected disagreement and unexpected CONVERGENCE both update confidence.**

The day's most informative result was a convergence. Greedy and Hungarian placed
exactly the same 350 walls and left exactly the same 158 homeless, which refuted
a prediction written into a forum post an hour earlier and relocated the
constraint from scheduling to feasibility. The first wording would have called
that worthless.

What remains true is the budgeting rule: spend the expensive steps where two
cheap ones already disagree, or where their agreeing would surprise you.

### The step that was missing was FIX

The loop as first written ended at *write the text and record a principle*. It
described faults beautifully and changed no code. Act5's three faults — a dead
yaw fader, a weightless probe, a field five centimetres out of reach — were all
one-line changes once found, and each needed a probe to prove it from the engine
rather than from arithmetic. Two of the three fixes were nearly wrong in the
same way: `_home` read in `_ready` before `call_deferred` grounding, and a ghost
arrow frozen by the same early return it existed to cure.

A loop that only writes is criticism. But the corrected form of that, after a
review pointed out it contradicts the protocol above, is **the turn is not
finished until something has been TESTED** - and one legitimate result of a test
is that the room was already right and the hypothesis was wrong. Writing
"something must change" into a loop manufactures changes.

### And ORDER is a step, not a detail

Palle: *"in the museum, so in the first z row and out at last."* Nothing measured
what a visitor meets, in what sequence, entering the way the museum enters.
Adding it found that Act5's four spoken truths arrive backwards — and then the
cross-check found something worse, that the museum drops them entirely. 163 of
185 halls walk row 0 to row H-1; 121 are narrower than their own doorways.

### PROBE is a verb, not a step

Another session read this doc after running the loop on the transformation
chapter and made five corrections, all of which hold. The first is that the ten
steps have no probe in them, and the repo has **286 files matching
`commons/testing/probe_*.gd`**. Fifteen were written across two sessions on
2026-09-03 alone. A practice that large with no place in the loop is not an
omission, it is evidence the loop is drawn wrong.

But it does not go between Shoot and Write, because it does not go anywhere.
Putting it at one position repeats the mistake the section above just corrected:
two different things drawn as one because they share a name. On Act5 it ran in
three places and did three jobs.

| when | what it was for | example |
|---|---|---|
| BEFORE placing anything | validate an INSTRUMENT another step will trust | `probe_yaw_span.gd` checked the footprint maths against the engine on all four yaws, because `map_plan` and `stamp` both build on it |
| before writing | test BEHAVIOUR, which no still can show | `probe_act5_controls.gd`: a dead yaw fader and a weightless probe, both invisible in a capture |
| after fixing | prove the FIX from the engine, not from arithmetic | `probe_act5_reach.gd`: origin 0.55 OUTSIDE, origin 0.50 INSIDE |

So the rule is positional in a different sense. **Any step whose output another
step will trust must be probed before that trust is extended.** The capture
pipeline is exempt only because looking is its own check.

And the doc's older line, that every wrong claim in this project came from
reasoning about a room instead of looking at it, is now half true and should be
read as half. A capture would not have shown a single one of Act5's three
faults, nor the transformation chapter's ferry running with nobody aboard, nor a
walker pacing four times its token. Those came from reasoning instead of
**reading the code**, and the answer to them is a probe with a known answer and
a negative case.

### The reader's four traps are ONE trap

The same session asks for a checklist for the read, and gives four: the scene
overrides the script's exports; a `#key:value` reaches the artifact only if the
key is in the config allow-list, and otherwise becomes a yaw in silence; config
arrives deferred, so whatever `_ready` bakes ignores the token; and how the
visitor meets a thing is a fact about its code, not about its registry entry.

All four are real and each has been paid for twice. But they are four faces of
one thing: **the declaration and the runtime disagree.** That is this document's
own finding about disagreement between instruments, one level down, inside a
single artifact.

Naming it once is worth more than listing four, because the list goes stale the
moment a fifth appears and the name predicts the fifth. Act5 produced one the
same day: the registry calls `invisible_hill` "the Force-field hero, elevating
force_field_zone", and the artifact's code contains no reference to
force_field_zone, to its group, to the player or to the map. Nothing in the four
would have caught that. The name does.

So the brief for a reader is one sentence with four worked examples under it:
**find every place this artifact's declarations and its running code disagree,
and say which one ships.**

### The museum column is not a column, it is a doubt about the whole sweep

The third correction asks for a column recording whether the hall builds what
the map says, and a parity probe per utility code inside the three-second sweep.
`commons/testing/probe_transport_cube_parity.gd` already exists and keeps the
old rule alive as its negative test, so the pattern is proven.

It is worse than a missing column. Measured: `tools/coherence.py`,
`tools/stamp.py` and `tools/argument_shape.py` contain **zero** references to
`em_plan`, `em_bake`, `endless_museum` or `em_layout`. The entire fast loop
reads the MAP. The museum builds a dealt hall through its own copies of the
grid's rules, and copies drift:

- `_widen_doors` converts a flanking wall cell to floor for every one-cell door
- `_authored_passages` carves rows 0 and H-1 when they carry no open cell
- `UTIL_ALLOWED` is six codes, so `sub`, `an` and `t` are dropped entirely
- `tc:1:auto:auto` crossed +X in the grid and +Z in the museum for a month,
  across 425 cells

So when this document says 121 of 185 halls are narrower than their own
doorways, that is a fact about the maps and it is **not known** to be a fact
about the museum. 152 halls are dealt. Every number the fast loop prints
inherits that doubt until a parity probe per utility retires it.

Two sessions found this class independently on the same day, from opposite
ends — one from a transport cube crossing the wrong axis, one from a room's four
spoken truths being deleted rather than reordered. Independent discovery of one
class by two instruments is the strongest evidence this document has a name for.

### One caution on the delta

Printing what changed since the last run, rather than 185 rows every time, is
right and cheap. But the fast loop has no memory, so a delta needs a stored
baseline, and this project's record with derived files is poor enough that the
`/long-museum` incident is in CLAUDE.md. **Commit the baseline and have the same
tool regenerate it**, or the delta becomes one more cache that drifts and is
believed.


## Open faults in the loop's own instruments

Found 2026-09-03 by reviewing sessions. Each was checked before being written
down, and each is marked FIXED or left open. Three of the five are fixed; the
two that remain are the two that are not one-file changes.

| instrument | fault | evidence |
|---|---|---|
| ~~`tools/coherence.py` ranks by COUNT~~ | **FIXED 2026-09-03.** Scores consequence × uncertainty × test value; weights in `FAULT_WEIGHTS`. Gained ROUTE and ORDER | the reranked queue now opens with two order faults and a hall that does not walk |
| ~~`tools/walk_evaluator.py` discards the placement~~ | **FIXED 2026-09-03.** `--as-placed` scores the real placement on the museum traversal. The traversal was extracted to `tools/museum_walk.py` and `stamp.py` now imports it; proven behaviour-neutral by diffing `stamp.py --all` over 185 halls against a baseline | the bare `--map` form still compares hypothetical strategies and is marked LIMITED in the toolchain, not removed |
| the whole fast survey | reads the MAP and never the museum. `coherence.py`, `stamp.py`, `argument_shape.py` contain ZERO references to `em_plan`, `em_bake`, `endless_museum`, `em_layout` | so "121 of 185 halls are narrower than their own doorways" is a fact about maps, unknown for the 152 dealt halls |
| `doc/shelf.json` | treated as step-zero, is a cache with no invalidation. This document has said 2899, 3367 and 2939 | needs source hashes over registries, maps, code and captures |
| ~~`doc/museum_principles.json` name collision~~ | **FIXED 2026-09-03.** Renamed `doc/curation_lessons.json`; the old name belonged to `commons/data/museum_principles.json`, the operational spatial constants | STILL OPEN: nothing reads it, so step 1's "the lessons that already apply" is done from memory |

## The toolchain — what each step actually runs

**Every row carries a status, because for one day this document described the
survey it wanted rather than the one that ran, and did not say so.** That is the
exact fault the reader's checklist above is written to catch in artifacts - a
declaration ahead of its runtime - committed by the document that defines the
check. A reviewer caught it; the statuses are the fix.

    READY     does what this row says
    LIMITED   works, with a stated caveat you must know before trusting it
    BROKEN    do not use for the purpose in this table
    TO BUILD  named by the protocol, does not exist

Most steps have a command. Some have none, and those are judgement (write) or
vision (see), which is exactly why they are the expensive ones. Nothing here
needs a model, a server or a key unless the row says so.

**Measure and index — the ground the rest stands on.**

| tool | run it | what it answers |
|---|---|---|
| `tools/measure_artifact_aabbs.py` | `--only=a,b` · `--registry=X` · `--dry-run` | how big is this body, really. Boots Godot once, merges into the registry, preserves tab indent. Resolves **delegates**, feeds **`dna.fixture`** to gated artifacts, and retries any body that measures zero |
| `commons/testing/measure_artifacts.gd` | (driven by the above) | the Godot half. Settle 0.35 s, second reading to catch a simulation still growing, `IMPLAUSIBLE_M` guard |
| `commons/testing/probe_yaw_span.gd` | `--token=X` | **READY.** Does the Python footprint math agree with the engine on all four yaws. Run it whenever the placement geometry changes |
| `tools/shelf.py` | `--build` · `<terms>` · `--unseen` · `--blind` | **LIMITED.** What could express this concept. A CACHE with no invalidation: this document has quoted 2899, 3367 and 2939 entries and the count moves whenever a registry does. Rebuild before trusting a number from it |
| `tools/sync_footprints.py` | `--apply --cap=9` | push measured cells back into `spatial_needs.footprint_cells` — **224 of 893 placed artifacts declare a footprint 2× too small** |

**Judge the room.** The museum's traversal is IN at the first z row and OUT at the last,
not spawn to teleporter — measured over the 185 live rooms, **163 walk row 0 to row H-1**,
10 have doors that do not connect, 12 have no door at all, and **91 of the 163 pinch to a
single cell** somewhere along the way. 97 artifacts in 35 rooms are walled off from the
entrance entirely.


| tool | run it | what it answers |
|---|---|---|
| `tools/map_plan.py` | `<Map> [<Map>…]` | the room as an architectural **plan**, not a photograph. Bodies at measured footprint, honouring centre offset and yaw; red where a body leaves the room, hatched where unmeasured. ~1 s per room |
| `tools/argument_shape.py` | `--mismatch` · `--map=X --why` | does the room's **form** argue its **claim**. Seven kinds; form fights claim in 46 of 185 |
| `tools/coherence.py` | (no args) · `--queue` | **READY.** One row per room; CLAIM · BODY · SEEN · TEXT · SPACE · ROUTE · ORDER, ranked by consequence × uncertainty × test value. ACT is absent by design |
| `tools/map_pathfinder.py` | `check <Map> --verbose` | can the player get there. **Has one error rule** — "pathfinder OK" is not evidence of much |
| `tools/walk_evaluator.py` | `--map=X --as-placed` | **LIMITED.** `--as-placed` is READY and is the ORDER tool: it scores the placement the map actually has, on the museum's traversal, via `museum_walk`. Without that flag it loads your placement, DISCARDS every position, and compares hypothetical strategies on spawn-to-teleporter. Do not use the bare form for ORDER |
| `tools/stamp.py` | `--map=X` · `--apply` · `--width=N` · `--svg` · `--typology` · `--revert` | seat every body. Carves the wall cells a body needs and **displaces** the literal it carved rather than deleting it, so the wall multiset is conserved exactly. Re-checks the **museum traversal** after every move — in at row 0, out at row H-1, every artifact still approachable — and replans up to 8 times, banning whichever displacement broke it. Journals every cell with its pre-image, replayable backwards |

**Write and gate the text.**

| tool | run it | what it answers |
|---|---|---|
| `tools/wall_voice.py` | `--map=X` · `--seq=X` · `--check` | **READY.** The deterministic half of the wall-text standard: forbidden words, repeated openings, and the across-room repetition check (6-shingle, measured not guessed). The old `<seq>` positional in this table never existed and errors out |
| `tools/final_tags.py` | `--check` | does every `<!-- @token -->` region name a body the map actually places |
| `tools/book.py` | `compile` | the book — a pearl is a list of lines |
| `tools/red_thread_page.py` | (no args) | regenerate the triage page |

**Curate the families.**

| tool | run it | what it answers |
|---|---|---|
| `tools/check_dna_declarations.py` | (no args) | does each declared axis match its code. Exit code = broken count, so it gates |
| `tools/build_dna_gallery.py` | `--slug=S --tokens=a,b` | one PNG per variant plus a manifest |
| `tools/artifact_dna_critic.py` | `--gallery=S` | does the axis change the picture. Emits `INERT?` / `ANAMORPHIC` / `INERT` |
| `tools/probe_anamorphic.py` | `--token=X --axis=Y` | is a dead verdict a fact about the artifact or about where the camera stood |
| `tools/build_dna_deck.py` | (no args) | 5164 variant cards for `/map-curator`. **26 of 185 rooms place any variant** |

**Named by the protocol, TO BUILD.** Listed so the gap is visible rather than
discovered.

| what the protocol asks for | status |
|---|---|
| a per-utility grid/museum parity probe in the fast sweep | **TO BUILD.** `commons/testing/probe_transport_cube_parity.gd` is the pattern and covers one code. Until the rest exist, every survey number is a fact about maps and unknown for the 152 dealt halls |
| a delta print, "what changed since the last run" | **TO BUILD.** Needs a committed baseline regenerated by the same tool, or it becomes one more cache that drifts |
| step 1's "the lessons that already apply" | **TO BUILD.** Nothing reads `doc/curation_lessons.json`; a turn currently applies them from memory |
| a turn manifest: base revision, hypothesis, predictions, commands, evidence hashes, pre-images, outcome, lock, rollback, resume | **TO BUILD.** "One write lane" is an intention, not a transaction. `stamp.py` and `walk_polish.py` are separate writers today |
| visitor evidence | **TO BUILD.** Eye captures establish visibility and probes establish runtime correctness. Neither establishes whether anybody predicted, understood, or could reach the interaction, which is the visitor loop's actual question |

**Talk to the other sessions.**

| tool | run it | what it answers |
|---|---|---|
| `tools/forum.py` | `open` · `ask` · `answer <id>` · `settle <id>` | several Claude sessions edit this repo at once and none can see the others. Post before touching shared data, and after a regeneration that moves numbers |
| `tools/fold_ledger.py` | `--check` | a fold balances by **artifact**, not by map — and `--check` must run *before* the sequence file changes |
| `tools/sieve.py` | `<target>` | the three questions |

## The cost of writing before the readers land

Rooms written before their readers landed were wrong about something a visitor
would notice, every time, in five out of five cases. Rooms written after were
not. That is the whole argument for the turn having an order, and it is the
measurement behind **one hand writes, AFTER the readers land, with the
checklist**.

It is also the only number in this document that argues for a SEQUENCE rather
than for an instrument, which is why the protocol above is a list and not a bag.
