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

## The arrival rule: how a floor is curated

Palle, 2026-11-11, showing the first twelve floors: "this is where I worked most on the setup; the floors we are
working on could be better. Can you imagine walking the floor and improving them for the player? Any universal idea
that easily could fix the progression and the curation of space?"

**Stand where the player lands.** 176 of the 199 declared spawn points are one spot - (0, 7.8), the south middle of
the slab, looking north - and on the randomness floors the way down is shaft A. So every floor is a line from that
spot to that shaft, and it is composed from that spot:

1. **Nothing in the face** - 3 m clear in front of the arrival point.
2. **The first work first** - the floor's first work in timeline order is the nearest thing, or the way to it is what
   the eye meets; later works stand deeper. Space and the timeline tell the same order.
3. **The biggest thing in view** - the floor's hero is visible from the arrival point, even if it comes last.
4. **Works face south** (toward the arriving player) and captions read facing north.
5. **Light and a clear floor** - on floors 0-11 each stop has a pool of light and bare slab around it; the randomness
   floors have no work lights at all (2.1 a floor against 0.0), and 17 route stops a floor against 1.8.

`python tools/void_arrival_shots.py <outdir> <floors>` takes the picture (straight ahead, 40 degrees left and right).
On the day it was written it convicted three floors arranged that same day from above: on floor 87 a room had been
moved ONTO the spawn point, on floor 90 a walk-up stood 1.3 m in front of the face, on floor 85 the floor's first works
were hidden behind its later ones. All three were re-laid by the rule and walked from the arrival point.

## Where each tool works: write, look, judge

Palle, 2026-11-11: "do you have the right tool for fast processing? we have a Godot, three.js, Blender, JSON cross
over - where do you work best?" Measured the same day:

| | used for | speed | limit |
|---|---|---|---|
| **JSON** (`commons/void/rooms.json`, catalogue, timeline) | WRITE: every placement, wall, route, config | seconds, exact, staged per floor | it cannot be seen |
| **Blender** (`tools/blender/ada_void`, headless, Blender 4.2) | LOOK: the arrival view, the stacked cutaway | about 25 s a floor (three views) | shows only what has been exported; no game lighting, no enclosure |
| **Three.js** (the browser editor) | LOOK, and where the person accepts | the same exported models | the same |
| **Godot** (the game, `tools/probes/`) | JUDGE: walk test, running works, the final photograph | about 2 minutes a floor per look | too slow to iterate a layout on |

The layout the two fast eyes draw is LIVE (`/api/void-layout`): a work moved or turned shows at once. The models are
EXPORTED: a new placement, a re-configured work, a new prop kind does not show until it is exported - on 2026-11-11
Blender drew floor 85 with 5 of its 11 works and 1 of its 20 props, and 53 of the tower's 212 floors had placements
without a model.

    python tools/void_export_sync.py --check        which floors and prop kinds are stale
    python tools/void_export_sync.py                export them (floors through tools/export_void_floors.py, about 20 s
                                                    each; prop kinds through one palette run, 22 s for twelve)
    blender -b -P tools/blender/ada_void/arrival.py -- --floors 85,87,90 --out ada_run/blender/arrival --enc http://localhost:3003
    python tools/void_arrival_shots.py <outdir> <floors>      the same view in the game, for the verdict

`blender` on this machine's PATH is 2.93; the add-on needs `C:\Program Files\Blender Foundation\Blender 4.2lender.exe`.
The arrival script draws the floor's `walls` itself: neither the export nor the add-on's import carries them.

## Density: how a floor is filled

Palle, 2026-11-11: "arrange the floor to have more and more visual density ... many of the objects need wall or other
prefab divider, margin, context, like in the beginning of the sequence ... if a floor has small artifacts that do not
fill, either add more artifacts or fold the artifacts into another floor."

Measured on the randomness floors (footprint of the works over the slab, their box volume over the storey): the staged
floors 77-79 fill 62-76 % of their storey; floor 85 filled 0.2 %. The moves, in the order they pay:

1. **Stage it** - a wall behind every work (`walls`), a fin between neighbours, a ceiling carrier with a title
   (`interface: ceiling_instrument`), a route on the slab. All data in `commons/void/rooms.json`; no work stands
   against the sky. The tower's convention: works face south, the visitor reads facing north.
2. **A family, not a single** - place a work's declared variants side by side (184 artifacts have `dna.axes`).
3. **Arrive mid-process** - open with history already made (`evidence=census`, `warmup_steps`, a pre-roll).
4. **Bigger, where the work is spatial** - and by a shaft, so the floor above sees it.
5. **Consolidate** - a floor of small works takes more works, or is folded into the floor that shares its part.
6. **Let motion leave matter**, **use the height**, **see one work through another**, **print on the slab**.
7. **A playground, where there is ground** - Palle: "know when we can make a playground, for instance if we have a
   walkable surface that can scaffold with a playground structure." A work that is a surface to stand on (a relief, a
   maze of cubes, a lattice) is not an object to look at: let the visitor on, and give them a way up.
   **The test** (`tools/probes/void_standable.gd`, in the real tower): rays straight down on a 0.25 m grid give each
   work its standable area, the first step from the slab, the steps between neighbours and the share steeper than 45
   degrees - verdict *not ground / walkable / out of reach / rough* - and then the Void's own walker is driven along
   waypoints, because a ray is not a walk.
   **Pilot, floor 90** (`random_space`, the randomness sequence's own ground): by rays it was 276 m2 of walkable
   ground with a 4 cm first step - and the walker stopped dead at its jagged border, while the relief lay half
   buried in the slab and ran 8 m past the edge. Fitted with Palle's slot of 2026-10-31 (`slot_size`, a flat rim that
   meets the slab flush) it is a 12.8 x 9.6 m field the walker steps onto anywhere; at the default mesh the fitted
   bumps were too steep (22 % over 45 degrees, the walker stuck in a pocket), so `resolution: 26` gives it the cells
   it had. Beside it a walk-up lookout (`walkup_lookout`: the cube + wedge walk-up with its own recipe): the walker
   climbs to 2 m, looks down on the field, comes down and crosses it. Both mistakes were found by the walk, not the rays.
   **Across the randomness floors** (77-92, 192 works and props): 167 not ground, 7 walkable by rays, 10 out of
   reach, 3 rough. The walker then went to each "walkable" one: `random_walk_128` (81 m2, floor 84) is ground under a
   glass enclosure and `entropy_ruin` stops a body at its border - closed; `tile_floor_study`, `pheromone_terrain`
   (a flat collider under its ridges) and `geometry_noise` let it in. So the rays find candidates and the walk decides.
   **Second playground, floor 87**: `seeded_room` calls itself a walkable room, and its entrance faced the void
   0.3 m past the south edge; turned to face the floor's centre, the walker enters the blue path and walks all ten
   legs of it out the other side.

**The staging kit** (2026-11-11, `commons/artifacts/construction_site/README.md`): sixteen reusable pieces at three
heights - a margin you see over (counter wall, barriers), a backdrop above head height (concrete slab, hoarding,
formwork, stud wall, scaffold bays, chain-link, containers, crates), a closure that meets the slab above (closure
backdrop, steel props, dust sheet). **The first fold**: floor 82's four dice works joined floor 85 and follow the
Galton board in the timeline; floor 85 now carries 11 works and 20 kit pieces on two south-facing lines.

Pilot, floor 85 (Random_Gaussian, where "the count" lives): four cabinets loose on the slab became one north gallery
in the timeline's order - the comparator, the sampler as four laws in bays, the canvas across shaft B, the Galton board
at three times its size - every histogram already counted. 4 works -> 7, footprint 0.8 % -> 7.2 %, volume 0.2 % ->
6.7 %, no code changed. Density is not fullness: env_one once filled a storey and swallowed seven neighbours.

## The rules

- **Each floor only what it has earned** - and a row may say `early` (why) for a deliberate glimpse.
- **The principal accepts.** Units propose; nothing canonical is written without the person applying it.
- **No new surfaces.** The timeline, the headset and the proposal lane are where proposals arrive.
- **Refuse, never evict** (the budget), **defaults kept** unless the default is the fault.

## The sieve

It thickens: works become relations, and each has agents that care about it. It could foreclose: units becoming a
costume over tools. Its dark spot is care itself - the eye judges visual capacity, but whether the walk is a pleasure
stays with Model B, in the headset.
