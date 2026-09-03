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

# THE GOAL

2026-09-03, Palle: *"The whole project is really about ontology, how things
work and where the entropy of creativity and discovery lives on the edge."*

Asked what the loop is for, the honest answer is the one at the end of the
protocol: **a hall works when the visitor's loop closes.** Notice, predict, act,
the algorithm answers, compare. So the goal is not a true room or a tidy room.
It is a room where a person can predict from the wall and be answered by the
body, and where the answer is the algorithm's and not the curator's. Everything
below is instrumentation for finding out whether that happens.

Three sharpenings, each paid for on 2026-09-02 and 03.

**Close the gap in the direction of the claim.** A transport cube ran its cycle
with nobody aboard, three growers stood still, seven walkers had no gaits, and
every one of those halls had wall text, a registry entry and an intent that said
otherwise. A visitor who predicted from any of them was not answered. Each fix
was one of two moves: change the code so the room does what it means, or change
the words so they say what the code does. The loop's job is to make that choice
visible and make it on purpose. Left alone the corpus drifts to the second move,
because prose is cheaper than code, and a museum whose walls describe its bugs
has stopped being a museum.

**Not zero disagreement, chosen disagreement.** The project's thesis is that the
valuable thing is the irreducible, the part that will not compress. A loop that
only removes disagreement sands that off. The best rooms so far kept a fault as
their argument: a row of walkers that cannot fall because gravity is not in the
room, a gap under the axis maze that nothing makes you cross. So every hall
should carry exactly the disagreement it means to carry, and none it does not.
The verification steps find the unmeant ones. The queer question keeps the meant
ones, and it is one step in fifteen doing half the work.

**The loop must make itself cheaper.** At a day per hall and 185 halls the slow
turn never finishes. Every lesson that becomes a tool moves a judgement from a
day to a second, and what remains for a person is only the rulings. The measure
of the loop is not how many halls it has turned. It is how much of the next turn
no longer needs a hand.

## The lineage: The Nature of Code, and how this differs

The format to build on already exists, and the corpus admits it by name: 64
registry tokens are called `example_N_M` or `exercise_N_M` after the chapters
and exercises of Daniel Shiffman's *The Nature of Code*, across seven of its
chapters, and the tutorials cite it as NoC. That book's move is the right one:
a phenomenon, the smallest code that produces it, and an exercise that makes
the reader change the code. Every room in this museum is that move done in a
hall. Where this project differs, in Palle's words: *"our version has more
examples and topics, is in 3D and VR, and is more queer."*

- **More topics.** NoC runs twelve chapters from randomness to neuroevolution.
  The spine here runs twenty-two, and adds what a book of sketches does not
  reach: primitives before vectors, form-finding, isosurfaces, boolean solids,
  graph theory, and three chapters on the foundations crisis and what comes
  after it, where the algorithms stop being tools and become the subject.
- **In 3D and VR.** A sketch is watched. A hall is entered. The reader's body is
  the thing the algorithm acts on, which is why the museum's unit of truth is a
  probe and a walk, not a screenshot, and why a cube that carries nobody is a
  failed chapter rather than a cosmetic fault.
- **More queer.** Queer here means the irreducible: what the encoding cannot
  compress without losing it. NoC teaches how things work. This project asks
  the same question and then asks what the answer forecloses, and keeps the
  remainder in the room as the argument. That is the ontology Palle names: not
  a catalogue of mechanisms but the question of what a thing IS once you know
  how it works, and where, at the edge of the working, the entropy of creativity
  and discovery actually lives.

The loop is how a chapter of that book gets written. A hall is a chapter.

---

# THE STEER

2026-09-03, Palle, after a day of this document growing checks: *"the primary
steering is the ontology or queer ontology of the subject in the map, above
find every place the declarations disagree with the code."*

That is a correction to this file and it is the right way round. Everything
below the line is **hygiene**. Hygiene tells you whether a hall is HONEST. It
cannot tell you whether the hall is about the right thing, or whether standing
in it makes its subject thinkable. A museum can pass every gate in this document
and be worth nothing.

So the question that steers is not *does the text match the code*. It is:

> **What IS this thing, once you know how it works? What does the room make
> thinkable about it that a page could not? And what does the encoding
> foreclose?**

The project already owns the instrument for that and this document had barely
mentioned it: `tools/sieve.py`, the three-question cognitive-water sieve, the
operational form of the Self-Q recursion on QFEP, with seventeen passes already
recorded under `doc/sieve_passes/`.

    1  Does this thicken the cognitive water?
       relational handles, ways of moving through, things made thinkable
    2  What is FORECLOSED?
       what this structure makes harder to think
    3  What lives in the DARK SPOT?
       what the encoding hides: generative habitat, or sterilising seal?

    python tools/sieve.py <target>        /sieve <target>

It is a sieve, not a metric. Q1 stops thin, optimised, scoreboard-shaped rooms.
Q2 stops mistaking thick for good. Q3 stops over-specification.

**The order matters and it is easy to get backwards, because hygiene is
measurable and ontology is not.** A hall that is honest about a subject it has
nothing to say about is a solved hygiene problem and a failed room. A hall with
a real argument and a wrong number in its wall text is a good room with a bug.
The first is harder to see and worse. Spend the judgement there, and let the
tools have the rest.

Two consequences for what follows:

- **The survey cannot rank by ontology.** It ranks by risk, which is a proxy for
  "which hall is broken", not for "which hall is underserved by its own
  subject". Both queues are needed and only one exists. Choosing a hall by the
  risk score alone will keep the museum honest and leave it thin.
- **The reader's checklist is subordinate.** Finding where declarations and code
  disagree is how you earn a TRUSTWORTHY answer to the ontological question. It
  is not the question. A read that returns only a list of contradictions has
  done half its job.

---

> **Every number in this document was measured on 2026-09-03 and will rot.**
> `python tools/check_loop_doc.py` re-measures them and prints what has moved.
> Numbers drifted three times in one day here, twice from this session's own
> commits, which is why the checker exists rather than a promise to be careful.

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
                   TWO things are deliberately absent and will stay absent.
                   ACT - does the thing DO what it says - needs a probe, not a
                   map. And ONTOLOGY - is this hall worth standing in - is not
                   measurable at all, which is exactly why it is the steer and
                   not a column. A survey that ranked it would be lying.

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

    0  THE SIEVE   what IS this subject, what does the room make thinkable
                   about it, what is foreclosed, what lives in the dark spot.
                   Before anything measurable. `tools/sieve.py <map>`.
    1  CONTRACT    the hall's claim, plus the lessons that already apply.
    2  HYPOTHESIS  what you believe is wrong, stated so it can be disproved.
                   It may be ontological ("this room has no argument about its
                   subject, only about its mechanism") and not only technical.
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
    10 THE QUEER QUESTION. Not decoration and not a tag. Queer here means the
                   irreducible: the part the encoding cannot compress without
                   losing it. Ask of the room: WHAT HERE REFUSES TO BE THE
                   DIAGRAM OF ITSELF? A room where everything is legible has no
                   queer content and is usually also a boring room. The
                   verification steps find the disagreements a hall did not
                   mean; this one keeps the ones it did.
    11 GATE        text (wall_voice, final_tags), space (stamp), access
                   (pathfinder + museum_walk), behaviour (the probe).
    12 FINAL VERIFY  re-run step 7. The state you accept must be the state that
                   exists after the writing and the gating, not before it.
    13 COMMIT OR REVERT. Seven outcomes, all legitimate, and only two are wins:
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
    14 LESSON      into doc/curation_lessons.json, with evidence and a test.
    15 REFRESH     re-run the fast survey; the turn changed its inputs.

**PROBE is a verb, not a step.** Any step whose output another step will trust
must be probed before that trust is extended. It ran three times on Act5, in
three different positions, doing three different jobs.

## Where the text lands, and who holds the file

The turn does not end at the gate. `final.md` lands on `/compose`, which
AUTOSAVES seconds after typing, and on the manuscript, and the Red Thread page.
Rooms are shared data: on 2026-09-03 two sessions wrote the transformation
chapter within an hour of each other, one session's Red Thread page was
republished under another five times, and three sessions edited this file.

So, before step 9: **post the rooms you hold to the forum.** After step 15:
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

That is the SECOND half of the brief. The first half is ontological and comes
before it: **what does this code reveal about what the thing IS?** A reader who
returns only contradictions has told you the room is honest and nothing about
whether it is worth standing in. The Act5 read is the example: the contradictions
were the dead fader and the weightless cube, but the finding that changed the
wall text was that the zone never divides by mass at all, which is not a
disagreement with anything. It is what the object turned out to be.

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
cross-check found something worse, that the museum drops them entirely. 164 of
185 halls walk row 0 to row H-1; 123 are narrower than their own doorways.

### PROBE is a verb, not a step

Another session read this doc after running the loop on the transformation
chapter and made five corrections, all of which hold. The first is that the ten
steps have no probe in them, and the repo has **288 files matching
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

So when this document says 123 of 185 halls are narrower than their own
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
| the whole fast survey | reads the MAP and never the museum. `coherence.py`, `stamp.py`, `argument_shape.py` contain ZERO references to `em_plan`, `em_bake`, `endless_museum`, `em_layout` | so "123 of 185 halls are narrower than their own doorways" is a fact about maps, unknown for the 152 dealt halls |
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
| `tools/measure_artifact_aabbs.py` | `--only=a,b` · `--registry=X` · `--dry-run` | **READY.** How big is this body, really. Boots Godot once, merges into the registry, preserves tab indent. Resolves **delegates**, feeds **`dna.fixture`** to gated artifacts, and retries any body that measures zero |
| `commons/testing/measure_artifacts.gd` | (driven by the above) | **READY.** The Godot half. Settle 0.35 s, second reading to catch a simulation still growing, `IMPLAUSIBLE_M` guard |
| `commons/testing/probe_yaw_span.gd` | `--token=X` | **READY.** Does the Python footprint math agree with the engine on all four yaws. Run it whenever the placement geometry changes |
| `tools/shelf.py` | `--build` · `<terms>` · `--unseen` · `--blind` | **LIMITED.** What could express this concept. A CACHE with no invalidation: this document has quoted 2899, 3367 and 2939 entries and the count moves whenever a registry does. Rebuild before trusting a number from it |
| `tools/sync_footprints.py` | `--apply --cap=9` | **READY.** Push measured cells back into `spatial_needs.footprint_cells` — **224 of 893 placed artifacts declare a footprint 2× too small** |

**Judge the room.** The museum's traversal is IN at the first z row and OUT at the last,
not spawn to teleporter — measured over the 185 live rooms, **164 walk row 0 to row H-1**,
10 have doors that do not connect, 11 have no door at all, and **91 of them pinch to a
single cell** somewhere along the way. 97 artifacts in 35 rooms are walled off from the
entrance entirely.


| tool | run it | what it answers |
|---|---|---|
| `tools/map_plan.py` | `<Map> [<Map>…]` | **READY.** The room as an architectural **plan**, not a photograph. Bodies at measured footprint, honouring centre offset and yaw; red where a body leaves the room, hatched where unmeasured. ~1 s per room |
| `tools/argument_shape.py` | `--mismatch` · `--map=X --why` | **READY.** Does the room's **form** argue its **claim**. Seven kinds; form fights claim in 46 of 185 |
| `tools/coherence.py` | (no args) · `--queue` | **READY.** One row per room; CLAIM · BODY · SEEN · TEXT · SPACE · ROUTE · ORDER, ranked by consequence × uncertainty × test value. ACT is absent by design |
| `tools/map_pathfinder.py` | `check <Map> --verbose` | **READY.** Can the player get there. **Has one error rule** — "pathfinder OK" is not evidence of much |
| `tools/walk_evaluator.py` | `--map=X --as-placed` | **LIMITED.** `--as-placed` is READY and is the ORDER tool: it scores the placement the map actually has, on the museum's traversal, via `museum_walk`. Without that flag it loads your placement, DISCARDS every position, and compares hypothetical strategies on spawn-to-teleporter. Do not use the bare form for ORDER |
| `tools/stamp.py` | `--map=X` · `--apply` · `--width=N` · `--svg` · `--typology` · `--revert` | **READY.** Seat every body. Carves the wall cells a body needs and **displaces** the literal it carved rather than deleting it, so the wall multiset is conserved exactly. Re-checks the **museum traversal** after every move — in at row 0, out at row H-1, every artifact still approachable — and replans up to 8 times, banning whichever displacement broke it. Journals every cell with its pre-image, replayable backwards |

**Write and gate the text.**

| tool | run it | what it answers |
|---|---|---|
| `tools/wall_voice.py` | `--map=X` · `--seq=X` · `--check` | **READY.** The deterministic half of the wall-text standard: forbidden words, repeated openings, and the across-room repetition check (6-shingle, measured not guessed). The old `<seq>` positional in this table never existed and errors out |
| `tools/final_tags.py` | `--check` | **READY.** Does every `<!-- @token -->` region name a body the map actually places |
| `tools/book.py` | `compile` | **READY.** The book — a pearl is a list of lines |
| `tools/red_thread_page.py` | (no args) | **READY.** Regenerate the triage page |

**Curate the families.**

| tool | run it | what it answers |
|---|---|---|
| `tools/check_dna_declarations.py` | (no args) | **READY.** Does each declared axis match its code. Exit code = broken count, so it gates |
| `tools/build_dna_gallery.py` | `--slug=S --tokens=a,b` | **READY.** One PNG per variant plus a manifest |
| `tools/artifact_dna_critic.py` | `--gallery=S` | **READY.** Does the axis change the picture. Emits `INERT?` / `ANAMORPHIC` / `INERT` |
| `tools/probe_anamorphic.py` | `--token=X --axis=Y` | **READY.** Is a dead verdict a fact about the artifact or about where the camera stood |
| `tools/build_dna_deck.py` | (no args) | **READY.** 5164 variant cards for `/map-curator`. **26 of 185 rooms place any variant** |

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
| `tools/forum.py` | `open` · `ask` · `answer <id>` · `settle <id>` | **READY.** Several Claude sessions edit this repo at once and none can see the others. Post before touching shared data, and after a regeneration that moves numbers |
| `tools/fold_ledger.py` | `--check` | **READY.** A fold balances by **artifact**, not by map — and `--check` must run *before* the sequence file changes |
| `tools/sieve.py` | `<target>` | **READY.** The three questions |

## The cost of writing before the readers land

Rooms written before their readers landed were wrong about something a visitor
would notice, every time, in five out of five cases. Rooms written after were
not. That is the whole argument for the turn having an order, and it is the
measurement behind **one hand writes, AFTER the readers land, with the
checklist**.

It is also the only number in this document that argues for a SEQUENCE rather
than for an instrument, which is why the protocol above is a list and not a bag.
