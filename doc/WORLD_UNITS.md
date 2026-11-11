# The world, told by its units

*Palle, 2026-11-11: "How do we describe this world with more than 2000 programmatic artifacts? One way to do it is to
describe the robotic units. You explore this world as the misplaced care unit Model B ... then you meet the line robot,
then other robot units. They should share a knowledge tree and the Void tower as an environment they improve. We should
use the multimodal capacity of AI agents to maximize the visual output of the artifacts so it is pleasurable to walk
around the tower. That is again related to algorithms' desire to find visual capacity."*

A world of 2000+ works cannot be described by listing them. It is described by who lives in it: each **unit** is one
way of reading the tower, with a sense, verbs and a place where it is met. The units share one **knowledge tree**, and
the **tower** is the environment they improve. The **principal** - the person - accepts or refuses what they propose.

## Four views

| view | who | where it is in the project |
|---|---|---|
| the tower | the environment: 212 floors, the works | `commons/void/rooms.json`, the Void (`commons/void/`) |
| the units | robots, each a reading of the tower | the units below |
| the player | Model B, the misplaced care unit | the plain body (`commons/void/care_body.gd`), the hand, the prism, the belt (`commons/player/inventory_*`) |
| the principal | the person who rules | `/artifact-timeline` threads, the live-update proposal lane, the headset |

## Model B, the misplaced care unit

Turing's B-type machine (*Intelligent Machinery*, 1948) is an *unorganised* machine that becomes organised by
interference - by being educated. His 1950 paper opens with "Can machines think?" and closes with the child-machine,
built simple and then taught. Model B is the visitor: it arrives unorganised and is organised by what the tower
teaches, in order. **"Each floor only what it has earned"** is its education; what its hand holds is how far it has
been organised. *Misplaced*: it was not built for this tower. *Care*: what it brings is attention.

## The units

| unit | body (registry key) | sense - what of the tower it reads | verbs - what it may do | met |
|---|---|---|---|---|
| **the line unit** | `tape_robot` | routes and traces: the walk, the `#NNNN` on the slab | steer along a guide, leave a line | floor 3, where the line is earned (filed after `line`) |
| **the construction unit** | `construction_robot` | joins: the grammar's terms and their assembly | carry prefabs, build scaffold routes in the grammar | floor 7, the cube hall (filed after `void_primitive_cube`) |
| **The Unit** | `the_unit` (drones) | motion and emergence: kinematic, mechanical, emergent | drive, turn the chassis, turn the hub; draw with the pen | its stations (floors 15, 16, 54, 166, 167) |
| **the eye unit** | (no body yet; a camera drone) | sight: each work photographed where it stands, against its `desire:` | judge whether the picture shows the desire; propose the one change that would | everywhere |
| **the ordering unit** | (no body yet) | the tree's order: each work's form, and what it is made of | propose forms, terms, moves; the earned check | the timeline |

A unit earns its place by **real verbs in the tower** - a unit that only narrates is a costume.

## The knowledge tree they share

| part | file | written by |
|---|---|---|
| the grammar: terms with structural build trees | `commons/modular/terms.json`, `commons/modular/grammar.json` | accepted on the timeline |
| terms waiting for acceptance | `commons/modular/terms_drafts.json` | the ordering unit (Fable 5.2) |
| the order: one numbered track | `commons/data/artifact_timeline.json` | the principal on `/artifact-timeline` |
| the measure: assembly index, copies, pool | `tools/grammar_assembly.py` (`python tools/grammar.py assembly`) | derived |
| the rule: earned | `tools/artifact_timeline.py` `earned_flags` (`check`) | derived |
| the pictures: the works seen in place | `tools/probes/color_survey.gd --floors=`, `survey.json` | the eye unit |
| what was improved and why | `commons/artifacts/improvement_log.json` | every fix |
| what the hand holds, what each floor grants | `commons/data/inventory/items.json`, `space_editor.json`, `/map-capabilities` | authored |

## The loops

**The ordering unit** (pilots 2026-11-10/11: randomness floors 77-92, the root floors 0-25): Fable 5.2 reads each
work's code and proposes its form - an existing term first, else a drafted term with a build tree. The proposals are
posted as one answered instruction on `/artifact-timeline`; applying an operation there confirms the form and accepts
its drafted term into `terms.json`. The earned check then names what breaks the order: a part first shown after a
work that uses it (an order fix), or a shared form the tower never shows on its own.

**Recurrence first** (Palle, 2026-11-11: "the world should find an emergent knowledge tree"; pilot: the randomness
floors): one term per work is a catalogue - of 245 drafted terms, 223 were used by no other. The tree is what the works
*share*. So the ordering unit next reads a sequence's forms together, finds the parts three or more works are made of,
and brings those few to the principal as drafted **cards** (a formula, a motive, an operation, an axis) with the works
that descend from each. A work names its part in its term's `from` - the tree's edge - while its own build stays its own.
On floors 77-92: 87 of 95 works descend from 12 parts; six were new cards (the count, the walk, the generator, order
and shuffle, the thrown body, without replacement), and with them the grammar check on those floors falls from 46 order
faults to 17. Single-use forms are each work's own construction and need no ruling.

**The eye unit** - *the algorithm's desire to find visual capacity*: 1294 scripts state a `desire:` in `@identity`.
The eye reads the desire, sees the work in place, reads the code where the two disagree, and proposes the one change
behind an export that would make the picture show it. The faults found by hand in the improvement pass are its
vocabulary: one-pixel lines, a part hidden inside another, colours written and never read, a work that never runs in
the tower, a simulation that saturates and freezes, a size wrong for its place, staging that hides the subject.
Fixes land one work per commit with a before/after at one camera.

## The rules

- **Each floor only what it has earned** - and a row may say `early` (why) for a deliberate glimpse.
- **The principal accepts.** Units propose; nothing canonical is written without the person applying it.
- **No new surfaces.** The timeline, the headset and the proposal lane are where proposals arrive.
- **Refuse, never evict** (the budget), **defaults kept** unless the default is the fault.

## The sieve

It thickens: works become relations, and each has agents that care about it. It could foreclose: units becoming a
costume over tools. Its dark spot is care itself - the eye judges visual capacity, but whether the walk is a pleasure
stays with Model B, in the headset.
