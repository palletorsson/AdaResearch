# A first complete museum, then deeper versions

## 2026-09-16 — the tutorial as an experiment others can continue

The supplied review helps articulate the method emerging through Point, Line,
Trace and Grid. [Operational inquiry](OPERATIONAL_INQUIRY.md) records a compact
authoring aid: identify a capability, encounter its actual operation, compare a
variation, and give another person enough knowledge to continue the inquiry.
Keep bodily pleasure and desire within this method, and distinguish a visitor's
change of use from an implemented change of rule. The next Grid proposal holds
one released trace fixed while changing its green replay's snap pitch; this is
not yet an installed control. The method strengthens the ongoing pass without
requiring every chapter to be rewritten as a statement of research methodology.

## 2026-09-13 — let the work change the questions

Palle asked whether our guiding questions were removing too much of the work
already developed. The agreed adjustment is to inspect the whole existing hall
before narrowing its argument. A question gives a route through the material;
it can expand or change when an artifact reveals another worthwhile discovery.

One or a few primary artifacts is a way to begin an empty scaffold, not a ceiling
for an existing room. Preserve substantial encounters and supported passages.
Counterexamples, atmosphere, pleasure, and connections to later halls can earn
space in the book too. Secondary status alone does not preserve a contribution
if the visitor and reader can no longer encounter it meaningfully.

Record what each existing work contributes, what was retained, and why anything
was deferred or removed. Repair unsupported claims specifically. Use encounter
order and optional depth to make abundance navigable. The Noise Types galleries
are the first application: spatial samples, illustrated spectral shapes and
filtered sound extend the earlier question about which rules keep acting.

Working strategy, 2026-09-08. Palle asked to begin this scaffold and provide
a page in Ada Encyclopedia to follow it. The first implementation is live at
[Museum Progress](http://localhost:3003/museum-progress).

Palle's authorial steer, 2026-09-08: the text must make discovery and the
strangeness of assumptions felt. A working simulation gives the learner a
capability and a way to notice what its representation cannot carry. Its
remainder can become a question, a useful alternative or beautiful play.
The finite path from point to QFEP carries these questions forward; a room's
completion leaves further inquiry possible. Code passages belong to the
book's rhythm and argument. See [A path with remainders](DISCOVERY_AND_REMAINDERS.md)
for grounded opening encounters, technical distinctions and a prose sketch.
This premise directs selection and writing throughout the process; matching
files and passing interaction checks support it but cannot establish it.

The [voice study](VOICE_STUDY.md) records a reading of the supplied
*Residue: Book One* and two original Ada passages that Palle did not accept.
His subsequent direction is an oscillation between anomalies, desire and
encounters with other systems, and a tutorial grounded in first principles
and code. Technical understanding should change the encounter and invite
further discovery. The study now records that correction and relevant grant
and artifact sources; its earlier passages are not an agreed writing model.

Palle's next instruction is to proceed hall by hall together: recover the
important artifacts and write from the encounter and its existing sources.
[Point One](../../commons/maps/Point_One/final.md) is the first applied voice
trial. Follow its restoration, runtime evidence and open reader questions at
[the room's iteration record](iterations/2026-09-08-point-one/README.md).
Point_Lines is the next room in this pass.

The first milestone is a continuous learning journey through the current
24 sequences and 190 rooms: every room has readable `final.md`, and every
essential encounter described there has a working, reachable expression in
the room. Later versions can deepen the writing, spatial composition, and
experiments. The name `final.md` identifies the reader-facing text; it does
not mean that the room is finished forever.

The initial file census found map data for all 190 rooms, `final.md` for 50,
and `critical.md` for 147. These are presence counts, not acceptance results.
Existing text needs reconciliation as well as missing text needing authorship.

## Manuscript coverage reached: 2026-09-08

All 190 live-spine rooms now have `final.md` and an explicitly selected teaching
core. The focused pass added 140 source-checked chapters and retained the 50
existing chapters, with narrow continuity or factual corrections in 11 of them.
Every map file and physical placement was preserved. The new chapters use one
or two primary artifacts; developed comparisons can retain more. A secondary
role keeps an object and its existing prose available for later development.

The live page records this as manuscript coverage. It still shows zero verified
room baselines. Source inspection cannot establish museum access or independent
learning, and a diagram cannot stand in for a missing computation. Specific
development gaps lead the affected rooms' open questions, including candidates
for recovering structures lost during the museum transition.

The [focused-pass report](iterations/2026-09-08-focused-book/README.md) contains
the full manuscript snapshot, source records, preservation checks and a shortlist
of next improvements with possible reuse. Continue by walking one written core
encounter and resolving its most consequential mismatch, then test the method
in a contrasting room. Keep the remaining collection available as that core grows.

## Started: the outline and its live page

The page reads the current spine on each refresh through
`tools/museum_progress.py --json`. It covers every current room, including
rooms added after this first pass, and distinguishes source scaffolds from
authored proposals. It refreshes every 30 seconds while visible and also has
a manual refresh button. It is served by the existing local Encyclopedia
server on port 3003.

The first ten authored proposals are in
`commons/data/completion_outlines/primitives.json`. They trace prerequisites,
ontology, candidate experiments, critical variations, and specific open
questions through the current primitives sequence. Their candidates and
source references were checked against files; runtime behavior remains
unverified. The other 180 rooms initially receive attributed source extracts
and open authoring prompts, not a claim that their ontology has been written.

The outlines supplement the existing briefs with the learning scaffold;
they do not own room membership, ordering, roles, or Palle's comments.
Those stay in their existing sources. The page links to the current room's
text editor, map viewer, thread, and brief commenting page.

To continue, author the next sequence's proposals in
`commons/data/completion_outlines/<sequence>.json`, using primitives as the
format example. Every outline needs all eight prose fields: inherited,
question, ontology, experiment, observe, limit, variation, and handoff.
Candidate tokens and source paths should name inspected material; put
uncertainties in `open_questions`. The page will pick the additions up on
refresh. A CLI summary is available with `python tools/museum_progress.py`.

Completion requires a separate explicit review record, never a file-count
threshold. Optional records in `commons/data/completion_reviews.json` use
`rooms[map]` with `reviewer`, `reviewed_at`, the current room `fingerprint`
from the live reader, and nonempty evidence for `text`, `behavior`, `access`,
`order`, `critical`, and `continuity`. Record actual checks and evidence
locations. Changed tracked inputs invalidate the review; indirect code
dependencies and runtime changes still require judgment. No room was marked
verified by the initial outline pass.

The first substantive reconciliation questions include Point_Trace's sampled
4096-point scene versus its 200-frame prose, Point_Line_Grid's actual bounded
recording and snap scales, and establishing triangles in
Point_Triangle_Context because the current spine omits Point_Triangle.
Resolve these as paired text/space decisions when the sequence enters the
completion pass.

## A manageable next action

Keep one sequence in focus and one intervention active. The page offers one
next action and a short list behind it; the museum-wide census remains
available as an overview. An intervention joins an existing room, artifact
and learning claim. It can change several registers, but it needs one small
observable result. For example: make two adjacent snapped positions visibly
distinguishable, and make the associated passage teach that distinction.

Choose work in this order: unblock the essential encounter, remove a false
promise that prevents understanding, finish its prose, then deepen a working
encounter. A useful shared fix can move forward when it unblocks the focused
sequence. The number of related rooms is a clue about reach, not a quality
score or a reason to abandon the current sequence.

The authored proposals in `commons/data/museum_improvements.json` name the
pilot, why now, next step, acceptance observations, critical question,
inspected sources, and possible reuse. `tools/museum_actions.py` joins them
to the live spine and actual placed tokens. Other rooms receive explicitly
labelled planning prompts until someone inspects a more concrete action.
Ready means ready to try. None of these records establishes a completed room.

The initial first action is the snap sphere in Point_Line_Grid. Its retained
positions are snapped to a 0.05 m lattice, while its table labels them raw
and prints one decimal place. Fix its feedback and associated prose, then
check the same component in Point_One. The other initial proposals expose
the pen's sampling and memory in Point_Trace and investigate a triangle
fan's assumptions in Point_Triangle_Context. These are source-inspected
proposals; their acceptance walks remain to be done.

Work through a card as follows:

1. **Pilot:** state the prediction, make the smallest paired change, perform
   the gesture, and record the before/after observation and remaining doubt.
2. **Second room:** test transfer where configuration, context or teaching
   purpose differs. A shared script change already affects its consumers;
   check those effects before treating them as benefits.
3. **Scoped lesson:** name the mechanism, conditions, counterexample and
   evidence. Record the resulting lesson in `doc/curation_lessons.json`
   using its existing scope, confidence and falsification-test contract.
4. **Rollout:** apply or inspect the change only at matching placements;
   retain exceptions and revise each room's own question and prose as needed.

The critical opening belongs inside this loop. Learning what a grid keeps
allows a visitor to try movements it merges; learning a fill rule allows
them to press its assumptions. The shared pattern can preserve that invitation
while the particular misuse and interpretation remain local to each room.

## How to recognise a reusable change

| Relationship | What it establishes | What still needs testing |
|---|---|---|
| Same placed artifact / shared script | A component edit has identifiable consumers | Effective settings, readability, access and pedagogical fit at each placement |
| Same mechanism in another implementation | A method or acceptance gesture may transfer | Its own sampling, frame, precision, retention and feedback |
| Similar learning structure | A curatorial pattern is worth trying elsewhere | Whether it teaches a useful distinction in that room and supports its critical question |

For example, “expose the recording contract” can mean making sample trigger,
frame, quantization, retained fields and eviction inspectable. It does not
mean every recorder should have the same values. A pen and a walking trace
can share a question while requiring different gestures and explanations.
Similarity creates a candidate; a contrasting second-room observation
supports a generalization.

## Maintaining the action queue

Authored cards retain their order in the action file; lower `priority`
numbers come first among ready cards. Use `stage` values `proposal`, `pilot`,
`second_room`, `lesson`, `rollout`, `closed` to record the current step.
Use `status` values `ready`, `blocked`, `deferred`, `closed` to distinguish
availability. Name concrete prerequisites in `dependencies` when blocked.
Keep a short `observations` array on the card as work proceeds, with each
entry recording date, room, prediction, observed result and evidence path.
Close an action after its named checks, or defer it with a reason. Do not
mark the whole room accepted merely because a card is closed.

Evidence paths carry SHA-256 hashes from source inspection. If a named file
changes or disappears, a ready card becomes **recheck** in the live view.
Inspect the delta and update the proposal and hashes deliberately. A hash
match says the source is unchanged; it does not prove runtime behavior or
cover unnamed indirect dependencies. Readiness must never be restored by a
background process refreshing hashes blindly.

The page is a read-only view of these records. “Copy work brief” prepares the
bounded intervention for a work session; it does not start a worker or save
an acceptance result. Record accepted room evidence separately using the
completion review contract above.

## What stays steady while text and space move

Use the room's learning question as the temporary shared reference. State
what the visitor brings in, what they should be able to do or distinguish on
leaving, and what observation could support that understanding. The text and
the cast are two ways of developing this question. Neither always leads.

Keep the current room roster and broad sequence order as the working scope
for the completion pass. Reopen them when a prerequisite gap, duplication,
or discovery warrants it. Record the reason and repair the affected links;
do not make every artifact change trigger a new museum-wide reorganisation.

Use the existing room briefs for a short authoring scaffold:

1. **Inherited understanding:** what earlier encounter this room relies on.
2. **Question:** what uncertainty gives the visitor a reason to act.
3. **Ontological proposition:** what kind of thing is being encountered,
   what constitutes it, what relations it needs, and what may change while
   it remains that kind of thing.
4. **Encounters:** the visitor's actions, their observable consequences, and
   the existing works that support or complicate the developing questions.
5. **Limit and variation:** one assumption or omission the visitor can
   question, with a concrete variation where feasible.
6. **Handoff:** what the next room can now assume, plus unresolved work.

These are authoring prompts. The reader-facing prose can take the shape the
room needs. A synthesis room can combine earlier ideas; a threshold room can
establish a question. Every room need not introduce a new primitive.

## Three passes

### 1. Scaffold the whole journey

Read the current sequences and existing briefs. Give every room a concise
account of the six points above, and identify an existing candidate experiment.
Trace prerequisites across sequence boundaries. Mark essential claims without
physical evidence. Reuse existing records rather than introducing another
independent ordering system.

The result is a complete outline of the book and its intended encounters.
It is not yet a completed manuscript or a verified museum. Proposals for
missing mechanisms belong in authoring notes until implemented.

### 2. Complete one sequence at a time

Work in spine order, keeping one sequence under active revision. For each room:

- Inspect the whole room's artifacts, scripts, scenes, configuration, and actual
  behaviour. Establish what the visitor can change and observe.
- Build a coherent route through the worthwhile existing cast. Adapt the
  question where the material warrants it, and keep distinct discoveries even
  when they exceed the initial plan. Related objects still need a clear account
  of what the visitor can encounter through them.
- Assign roles in `commons/data/artifact_roles.json`, including deliberate
  order where the calculated floor order fails the lesson. A counterexample
  may be primary when the room depends on it.
- Write a complete `final.md` through question, action, observation,
  explanation, and a critical opening. Preserve worthwhile existing prose
  where it remains supported. Use the existing artifact tags to connect
  paragraphs to the actual pieces.
- Check access, encounter order, legibility, essential behaviour, and the
  incoming and outgoing route. Read the sequence continuously to catch
  missing premises and explanations arriving before their experiments.
- Capture optional improvements, then move on when the first-version
  criteria are met. Urgent regressions in earlier sequences still get fixed.

An improvement belongs in this pass when it is needed for the essential
experiment, truthful prose, a readable route, or the critical opening.
Richer collections, extensive architectural redesign, and additional
variations can wait unless they are themselves necessary to the lesson.

### 3. Deepen and recombine

Once the continuous first version exists, revisit it through specific
questions: can a learner transfer the idea, what assumption can be changed,
which previously separate concepts become useful together, and what new
possibility appears through their combination?

Keep a small critical opening in the first version. More elaborate misuse
can arrive in later passes, while the learner already has a way to recognise
and question the conventions they are using. An existing strong critical
encounter need not be removed to fit a staged production plan.

## How the two moving targets inform each other

| Situation | Next move | What closes the gap |
|---|---|---|
| Text proposes an essential experiment the room cannot perform | Find, adapt, or build its mechanism; record the proposal in authoring notes | A working encounter, followed by prose checked against it |
| Text proposes an optional extension | Keep it explicitly hypothetical or defer it | No present-tense promise of a nonexistent interaction |
| Space offers a stronger experiment than the text recognises | Observe it, reconsider the brief, revise the explanation and relevant handoffs | A supported learning claim |
| An artifact changes or leaves | Revisit its tagged passages and the concept it was carrying | The lesson survives through a replacement or an explicit revision |
| A disagreement reveals a productive limit | Make the visitor able to encounter and investigate it | A deliberate critical experiment |
| A disagreement comes from a broken implementation or stale description | Decide the intended behaviour, then repair the appropriate side | The unintended mismatch is resolved |

Work in small paired revisions: change a primary encounter and its associated
text together where possible. If one side must lead temporarily, retain a
specific open item naming the unsupported claim and its next resolving action.
Scope the review to the affected lesson and its dependents.

## Ontology and queer misuse

Start locally with questions the visitor can investigate: what is this thing,
what makes two instances the same kind of thing, what relations make it
possible, what does this implementation retain, and what does it leave out?
Distinguish mathematical properties, implementation choices, and social
interpretations. Each needs its own evidence and argument.

For example, a stored position locates something relative to a frame. A
single current-position value does not preserve the route by which it was
reached. The learner can first move a point and read its coordinates; later
compare two movements with the same endpoint; then build a trace that gives
those movements a visible history. This is a design example, not a claim
that all three interactions already ship in Point One.

Queer misuse can change a purpose, category, relation, permitted action, or
criterion of success. It should make a particular convention available for
play and question. A changed parameter becomes critically interesting when
the encounter reveals what that choice allows, excludes, or values. Ground
that interpretation in the actual mechanism and the visitor's experience.

## First-version acceptance

A room is ready for the first complete version when:

- Its `final.md` reads as a complete encounter, without placeholder passages.
- Its essential lesson has a working physical experiment or observable
  spatial relation. Required objects can be reached and used as described.
- Primary roles and encounter order support that lesson.
- The text accurately distinguishes what happens from proposed extensions.
- The learner has a concrete question about an assumption, limit, or alternative.
- The room connects to its neighbours without an unexplained prerequisite.

A sequence also needs a continuous read and walk, including a small transfer
challenge that uses what was learned. A learner unfamiliar with the chapter
is the appropriate later check of whether the guidance works independently
of its author. File checks alone cannot establish educational effectiveness.

Track drafting, physical evidence, and reconciliation separately. Count a
room toward completion only when they meet together; retain unverified
behaviour as unverified. A baseline can be complete and still have a rich
development backlog.

## Existing connections

- [First encounter pilot](iterations/2026-09-08-encounter-pilot/README.md):
  Array, Single, Disco and Random Remove pair working changes with their prose,
  scoped runtime evidence, contrasting-room experiments and open learner checks.
- `doc/MUSEUM_LOOP.md`: the ontological steer, behavioural evidence, and
  deliberate versus unintended disagreement.
- `commons/data/spine_briefs.json`: current room readings and uncertainties.
- `commons/data/artifact_roles.json`: room-relative roles, groups, and order.
- `tools/build_spine_artifact_order.py`: explicit order, then floor order,
  then remaining file order.
- `tools/final_tags.py`: existing artifact-to-prose markers.
- `tools/sequence_drafts.py`: earlier tutorial / anti / alternative-order
  proposals. Its older roster and fixed slot assumptions need checking
  against the current 190-room aim before any reuse.
