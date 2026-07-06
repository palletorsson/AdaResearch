# RULINGS — the book's true source

> The manuscript's prose is compiled output; this file is the source. Palle's decisions,
> in his words, with the forks that were rejected kept visible (what was foreclosed stays
> on the record). My drafts are cheap and regenerable; these rulings are not.
> Protocol: trench report → ruling (here) → draft from rulings → friction pass → ledger + STATE.

---

## R-001 · 2026-07-03 · The ledger (the critical poetic arc)

**Palle:** "we have the point, we want to feel the awe, the weight of nothing, the beginning
the throw-in-ness, then the line the thinking that can not exist with out measuring, then the
hand of the player in VR, the trace it the first really queer artifact, that crosses the edge
to the analogue signal, broken into to bits. What for us the resolution is higher than our
already pixelated screen. This falls in an inbetween, but I can remind us that this is a
growing code debt."

**Ruling:** a second arc runs UNDER the pedagogy — phenomenological and cumulative:
*the throw* (Geworfenheit), *the measure*, *the hand*, *the trace* (first queer artifact,
analogue crossed into bits), *the debt* (every discretization a loan against the continuous,
compounding to Part VI). Rendered as "The Ledger" closing chapters. Voice, not schema —
chapters advance threads unevenly, deliberately.

**Foreclosed:** chapter-local critical readings only; a book with no undertow; motifs as a
five-box checklist (thin water).

**Landed:** `manuscript_frame.json` motifs · `apply_authored` passthrough · primitives pass
(`doc/tutorial_authored/primitives.json`) as proof of the arc.

---

## R-002 · 2026-07-03 · The ghost, the dig, the edge as decision

**Palle:** "it is important that we feel the ghost in the machine since we are working with AI.
What we really are after is an info archaeological excavation of the ghost. … the current model
captures a x density potential of the world. This is the edge. This archaeology of things is
the exploration of the book that always sits on a density of debt. … uncomputable if you so
will. The edge is a decision we have to make not to get over power by information but by doing
so we also cap our possible knowledge."

**Ruling:** the book is an excavation report from a chosen edge, not a survey. The ghost is the
sixth motif (the book written by the kind of thing it describes). The machine files its own
field note in EVERY chapter's ledger — "N of M artifacts excavated; K remain at depth" — from
the builder's own `[:11]` cap, which IS the edge decision sitting in the source. † chapters =
unexcavated strata.

**Foreclosed:** hiding the cap; prose *about* AI instead of the machine's own accounting;
completeness as a goal (uncomputable — entropy attached to becoming).

**Landed:** `excavation_note` ("The Dig") + ghost motif in frame · `dig:{pearls,walked}` in
builder · field notes in all 21 ledgers.

---

## R-003 · 2026-07-03 · Queerness = counter-archiving inside the inheritance

**Palle:** "can we somehow define queerness in this book as deleuze archaeology, or can we do
better, i mean the main feminist argument is that we have to work with what we have, we can not
escape history but we can create our own archives?"

**Ruling:** better than Deleuzian escape — queerness defined by the feminist-archival line
(Ahmed's queer use, Muñoz's disidentification/ephemera, Cvetkovich's archive of feelings,
Barad's agential cut; Foucault supplies "archive = the law of what can be said"; Deleuze keeps
only the density ontology of the virtual). Working definition: *"Queerness is not escape from
the grid… not freedom from history; authorship of the archive that history will have to read
next."* The book's own overlays (`tutorial_authored/`, never clobbered) are the demonstration.

**Foreclosed:** queerness as pure becoming / line of flight / transcendence of structure — the
escape fantasy a book made of grids, caps and samples could not honestly tell.

**Landed:** PENDING — definition block in front matter after The Dig + archival sharpening of
the trace motif (approved in principle, not yet applied). Full argument reserved as the spine
of the `postfoundationscrisis` (Part VI) writing pass.

---

## R-004 · 2026-07-03 · The map of the map

**Palle:** "Since this is a mapping of a map in two can we have the main nodes and the have
child around them the main concept and the artifact and props if you so will?"

**Ruling:** the book projected back into 2D — chapter hubs as main nodes on a MEANDERING spine
(Klee's walk, not shortest path), children ringed around each hub: the primitive (violet, the
main concept carrier), the walked artifacts, the rooms as small squares (the props/stage);
truth + dig field note on the node.

**Landed:** `tools/build_manuscript_map.py` → `public/manuscript-map.html` + map artifact.

---

## R-005 · 2026-07-03 · The trench protocol (the method itself)

**Palle:** "how do we together explore the in-betweens of the pressure points. Mostly you are
having me on with the ride especially when you get upgraded and sometimes we both fall out of
context. In the end we have to create a fantastic work, but what is the method to keep us in
the loop?"

**Ruling:** rulings are the durable layer; prose is compiled. Per chapter: (1) trench report —
pressure points as forks, no draft; (2) rulings here, verbatim; (3) draft FROM rulings, unruled
calls marked; (4) friction pass in the reader — rough rewrites are the voice-delta; (5) ledger +
STATE update. Every 4th–5th chapter is a COLD PASS by Palle (no draft) — the voice-bars that
survive model upgrades. VR walking is Palle's trench (body-scale pressure points the text digs
cannot reach). Divergence is surfaced, never auto-collapsed (harmony-meter constitution).
Disagreements get logged, both directions.

**Foreclosed:** ghost-writes-all-nineteen-tonight (the randomness pass is the flagged example:
written by voice-mimicry with zero rulings — needs a friction pass); Palle as approver instead
of author.

**Landed:** this file + `STATE.md`.

---

## R-006 · 2026-07-03 · The field journal (the site moves under the book)

**Palle:** "how do we keep track of what artifacts change and add and remove in the world."

**Ruling:** the excavation keeps a day-book. `tools/book_drift.py` snapshots the book's view
of the world (per stratum: walked artifacts, captures, truth-claims, pearls at depth, rooms;
plus registry counts) and appends only what moved to `doc/book/FIELD_JOURNAL.md` — machine-
written, append-only, run after every tutorial rebuild. The dig line reports state; the
journal keeps history. Baseline 2026-07-03: 22 strata, 208 walked, 716 pearls, 3041 in the
registry.

---

## R-007 · 2026-07-03 · Blob aesthetics (the 2.5 universe and the export)

**Palle:** "we are stuck in 2,5 universe and noise is the perfect example, or the noise blob
if you so will, it the abject, it signals change and dissolve but it a cheap trick (not always
bad) but it becomes a default esthetic where we do not know where to go, we just slabs it on.
We can call it blob aesthetics and for me it signals the end of the line where we should start
to export."

**Ruling:** the noise chapter carries the concept **blob aesthetics**: the rendered universe is
2.5D — all surface, no interior — and the noise blob is its emblem: the abject (signals change,
dissolution, becoming) produced as a one-line trick. Not always bad, but the *default aesthetic
of not knowing where to go* — noise slapped on when the work stalls. Diagnostic, not only
critique: **the blob is a gauge — when it appears, the current universe's density is exhausted
at that working point, and the honest move is to EXPORT** (leave the sheet for another
substrate: volume, body, world, print). Recurring: metaballs/isosurfaces = the blob given an
interior (the export begun); the book itself = the final export out of the 2.5 universe.

**Foreclosed:** noise as innocently "organic"; blob-as-style celebrated without the gauge
reading; also pure condemnation ("not always bad" stays).

**Trench effect:** rules noise P3 (noise = the debt's cosmetics, held with teeth); reframes P2
(Bernini gets a third fork: knowing performance of blob aesthetics on the canon); strengthens
P4a (voxel threshold = the first export from the sheet).

---

## R-008 · 2026-07-03 · The deep dig (roles, counters, blanks — the co-discovery toolchain)

**Palle:** "in the book the archaeology is superficial, instead of withholding we should try
to find the right artifact and their counters and surroundings. I mean we should not withhold
something we know, we should deepen it with qfep or similar depending on the context. First we
have to find what is load bearing (the central concepts from the int to hilbert curve and
beyond) for the spine and then also the right ornament, side objects, counter object and props.
… The discovery has to develop the book and the game at the same time. So we need space in the
book and the game to fill in the blanks and we need to help these processes help each other.
I mean we have to build a tool chain that can discover the right book and game."

**Ruling:** withholding is replaced by finding. Every walked artifact gets a ROLE —
**load-bearing / counter / side / ornament / prop** — and every load-bearing artifact owes the
book a deepened reading (QFEP or the lens the context calls for) and owes the game a staged
TENSION (its counter facing it). "At depth" becomes an evaluated candidate list with verdicts
(promoted / buried-with-reason), not a count. Where no counter (or side, or right artifact)
exists, a **BLANK is declared in both media at once** — an open slot in the chapter and an
empty plinth in the map — and blanks are the coupling: a book-blank is a game task, a
game-blank is a book task. Spine-level: identify the ~22 load-bearing concepts (the trunk,
"from the int to the Hilbert curve and beyond") one vertebra per chapter.

**Foreclosed:** the dig line as pure scarcity-performance; completeness (blanks are declared,
not all filled); auto-assigning counters without rulings.

**Landed:** PENDING — role grammar + dig-report tooling to build; pilot on randomness/fractals.

---

## R-009 · 2026-07-03 · Fractals dig rulings (first deep-dig promotions + first declared blank)

**Palle:** "promote mandelbrot_dive and box_counting_dimension, declare the hilbert blank"

**Ruling:** `mandelbrot_dive` and `box_counting_dimension` enter the fractals walk (the buried
canon surfaces: the edge itself, and the instrument that measures D = log(N)/log(S)). The
**Hilbert blank is declared** — space-filling curves are an uncovered concept; the chapter and
the map carry an open slot (empty plinth) until it is filled (candidates at depth: Hilbert3D,
space_filling_curve_gallery).

**Ghost's marked calls (pending friction pass):** the page grammar holds 11, so two step down —
`recursive_tree_2` (concept-duplicate of inverted_tree_cloud) and `fractal_scene` (an
environment in an exhibit list); their prose stays in the overlay as visible orphans. Prose for
the two promoted artifacts is ghost-drafted in the chapter's voice-bar register. Walk order:
box_counting_dimension before mandelbrot_dive (measure, then dive), Cantor keeps the coda.
Standing game-task generated: box_counting_dimension has NO CAPTURE — the promoted artifact is
invisible to the book until the capture pipeline reaches it.

---

## R-010 · 2026-07-04 · The generative loop (blanks have a lifecycle)

**Palle:** "filling them will change what the book can say and new text potential gaps will
produce new artifact"

**Ruling:** the blank is not a hole, it is a lifecycle: **declared → candidates → filled |
commissioned**. Filling a blank (capture, promotion) changes what the book can say — new
claims, new illustrations enter the chapter on the next rebuild. New text then exposes new
gaps; a gap that NO registry artifact can fill becomes a **commission** — the birth
certificate of a new artifact, derived from where the hole sits in both media (concept, role,
tier, scale, staging type). The book writes the game's backlog; the game writes the book's
evidence. The field journal is the loop's memory.

---

## R-011 · 2026-07-04 · Noise chapter rulings

**Palle:** "P1a, P2c, P4a, P5c — draft the noise overlay"

**Ruling:** P1a — open with the SPECTRUM (NoiseColors3D; memory as a dial; chapter 8 carried
the atom). P2c — MeltingBernini as KNOWING PERFORMANCE: blob aesthetics exhibited on the canon
as content, the cheap trick staged so it can be seen. P4a — SPEND THE THRESHOLD: voxelnoise +
perlin_terrain_sculptor are the climax; the chapter ends at the export, not in the goo;
isosurfaces industrializes it later. P5c — Palle rules truths for the artifacts that matter,
ghost inscribes them credited; the rest stay honestly mute. (P3 was ruled by R-007: noise =
the debt's cosmetics, held with teeth.)

**Ghost's marked calls (pending friction pass):** overlay drafted from the rulings in the
voice-bar register. **Two truth-sentences are ghost-PROPOSED and NOT yet inscribed in the
.gd files — P5c wants Palle's wording first:**
- NoiseColors3D: *"a noise color is a memory span — character is how long the signal
  remembers itself."*
- MeltingBerniniScene: *"the melt is a quotation, not a destruction — blob aesthetics
  performed knowingly, so the cheap trick can be seen."*
Confirm or replace these and they go into the code as @identity, credited.

---

## R-012 · 2026-07-04 · The counter promoted, the plinth that points

**Palle:** "mc_sculpt_vr as the counter, hilbert stays as pointing plinth"

**Ruling:** `mc_sculpt_vr` fills noise's declared blank as the counter to
`perlin_terrain_sculptor` — the first CROSS-DOMAIN promotion (found registry-wide via
/api/find, not among the stratum's pearls): additive against revealing, the blob given an
interior, the export in artifact form. The fractals Hilbert blank RESOLVES BY ADJACENCY:
the plinth stays empty and POINTS — "the Hilbert curve stands in the next room" — the
book's first forward sightline between chapters.

**Ghost's marked calls (pending friction pass):** the page grammar holds 11, so
`noise_space` steps down (its own prose called it "a rehearsal room"; voxelnoise +
sculptor carry the threshold) — prose kept as visible orphan. Walk order closes on the
confrontation: … voxelnoise → perlin_terrain_sculptor → **mc_sculpt_vr last** — the
chapter now ends with the two ways to commit form facing each other (reveal, then add).
mc_sculpt_vr prose ghost-drafted.

---

## R-013 · 2026-07-04 · The creator's walk (the final map-space generator)

**Palle:** "imagine you start at 0,0 you are the creator of the fantasy space. You have all the
artifacts and the wall works on a rolling tray, like a librarian with necklace order. As you
walk the rolling tray lives 3 by grid and you place the artifact one by one … it stamps the
grid with its footprint so you can continue … you place the wall work on your left or right.
You place it inwards so you can see from your position along z … perfect spacing. When you are
done you walk around in the level and think of the work — do I need to add other stuff here, a
text plate, other props to make it more interesting. Think like this is the perfect room to
describe the concept — an imaginative science lab of the concept, to make it flow of knowledge.
… the walls will be intelligent and we will seed other props — fire extinguishers, info plates,
whiteboards or blackboards, shelves. The floor will likewise be more intelligent with raised
void level for the hero and larger or applied artifacts. Different levels and extra props like
crates or other science props."

**Ruling:** the room generator is a FIRST-PERSON CREATOR WALK, three phases:
(1) THE WALK — start 0,0, advance along z in ~3-cell strides (the corridor stays 3 wide);
the tray holds the walk + curated wall works in necklace order; each placement STAMPS its
footprint into the occupancy grid; wall works go left/right FACING INWARD (visible along z);
spacing derives from footprint + the gaze law; heroes and large/applied get RAISED platforms
(structure levels, void moats — the intelligent floor).
(2) THE WALK-BACK — re-walk and enrich: intelligent walls seeded with the lab vernacular
(fire extinguishers, info plates carrying the chapter's prose, whiteboards/blackboards,
shelves), crates and science props in the empty beats, luminaires over the heroes.
(3) THE READING — pathfinder + gaze_ride fold-back; the ride log judges the flow of knowledge.
The room = the concept's imaginative science laboratory; the generator enacts the librarian.

---

## R-014 · 2026-07-04 · The glue (the room as one thing; agents and a protocol)

**Palle:** "The creator also has to walk the 3d grid space in the same way. Is it good to do
that with agents and a protocol? the grid is really a room. Look at the complexity of these
specimens /surreal-lab-gallery. I think you could do it. The question is really what is the
glue. an object, even a complex one has relation brigades that make it logical to add mesh
together. In one way we want to feel like and think of the room as one thing, grid space held
together by their relation. like imagined cables running between objects like pylons."

**Ruling:** the room is ONE THING, held together by its relations made visible. The glue has
three registers: (1) SEMANTIC — the relation graph already in data (fold-neighbors cosine,
counter-pairs, ladder tiers) decides adjacency; (2) PHYSICAL — the graph rendered as
infrastructure: cables/conduits routed between kin exhibits, pylon chains, SPARK GAPS where
counter-pairs face each other, all power topologically flowing from the load-bearing artifact
(the hero is the room's reactor); (3) the WALK as the spine cable — the corridor is the bus.
The room becomes one apparatus: the surreal lab's ninth mode, at architectural scale.
METHOD: yes to agents + protocol — the surreal_lab recipe lifted a level (fan-out agents each
solving a region/register, distilled into room-DNA), with the trench constitution as the gate:
deterministic where structural (stamping, validation), agentic where aesthetic (composition
search, judged), rulings deciding. The creator walks the 3D grid: floor, walls, and the air —
the cable layer is the volume's occupant.

---

## R-015 · 2026-07-05 · The room is the map, not the chapter

**Palle:** "make the room the map, not the chapter"

**Ruling:** the unit of a room is the MAP, not the chapter. The doll-house study proved
map-scale coheres as "one thing" where the 182-cell chapter corridor could not. So:
- The chapter-hangar (creator_walk's single mega-corridor) is RETIRED as the room. A chapter
  is now a NECKLACE OF ROOMS — the sequence's ~13 maps, each its own composed room, chained by
  the teleporters the real maps already carry.
- The production room composer works at map grain, branching on the hero:roster ratio into the
  three modes the pilot found: MONUMENT (one giant hero = the room is the concept-object),
  SPECIMEN (small roster = tight cluster), CABINET (many small = packed shelves, kill the void).
- Composition is NON-DESTRUCTIVE: composed rooms are Room_<Map> beside the hand-built maps;
  the glue (rigger) and walls apply per room.
- creator_walk / chapter_stage keep their value as the SEQUENCE lens (the necklace order, the
  transitions), not the room. The dig/ledger/walk still run at chapter grain; only the ROOM
  descends to the map.

**Foreclosed:** the chapter-as-one-room corridor (too long to read, too coarse to compose);
one-size composition (heroes and rosters vary too much).

**Landed:** dollhouse.py promoted to the map-room composer (3 modes + --seq); piloted on
randomness (13 maps). Related: [[project_manuscript_synthesis]] doll-house study.

---

## R-016 · 2026-07-05 · Fuse the tools — the room is a hall of workstations

**Palle:** "fuse the tools, make the room a hall of workstations"

**Ruling:** the three tools fuse into one production composer. `tools/hall.py`:
dollhouse (room = the map) + workstation (hero = a cluster of ladder children +
lab-prop cast) + rigger (relations under the floor). A map's roster is grouped
into workstations; each is staged as a TIGHT lab bench (hero on a stage under a
task light, children on flanking plinths, the cast — cylinder/crates/stool/
monitor-shelf/extinguisher — packed at the edges) flanking a walked central
aisle. Floor stays height 1 (walkable, no dais-ramp problem — zero pathfinder
warnings). Piloted: Hall_Random_Cubes (1 workstation), Hall_Random_Definition
(2 workstations flanking the aisle). Tuning queued: hall size should hug the
workstations tighter; rigger needs a --roster mode to glue map-halls (currently
walk-based); lighting/DNA polish toward the reference renders.

---

## R-017 · 2026-07-05 · The modular staging system (slots, size contracts, seeded fills)

**Palle:** "the question is if we can make a modular system we all prop fit in size and we can
seed different object and configuration in to the wall and their surroundings"

**Ruling:** YES — formalized as data + a seeder. `commons/data/station_modules.json` declares
SIZE CLASSES (S/M/L/XL with max base_m + a footing that normalizes the seat), POOLS (instrument
/ art / bench_tool / cylinder / storage / seat / light / screen / safety — the DNA families and
lab cast), and TEMPLATES (named slot layouts; bench_v1 = the reference bench). `tools/modkit.py`
fills a template deterministically per seed: HERO/CHILD slots from the artifact's own
concept-ladder family (classed by measured size), POOL slots drawn per-seed. Every prop fits —
the fit rule routes it to a compatible class and the class's footing seats it. Output is
wall-cluster format, so capture/review/place apply unchanged. PROOF: mk_distribution_sampler
s1/s2/s3 — same slots, three visibly different stations (histogram + green grid-screen + test
tubes vs computer desk + codex glow + crates). Punch: pool items need mount-type checks
(monitor_setup is a desk, not a wall screen); template library wants more layouts (corner,
island, vitrine).

---

## R-018 · 2026-07-05 · The meeting (junctions as a curated layer)

**Palle:** "The world is all about how objects and material meet, how they end before they
stop to exist … A wall meets the floor, a wall meets another floor, a table meets the floor,
a jar meets the table — it endless but so much happens in that meeting, and it can inform the
way we design, we can curate the meeting to make something beautiful. Can we think about that
in the modular design — how things meet and end, to feel natural and beautiful?"

**Ruling:** MEETINGS become a first-class layer of the modular system — a junction taxonomy
with declared treatments, applied automatically wherever two classes touch:
- artifact meets footing  -> the REVEAL (cap_inset — the shadow gap under every exhibit)
- footing meets floor     -> the BASE SKIRT (the stepped foot; stages keep their hazard tape)
- wall meets floor        -> the SKIRTING LINE (floorline#threshold run along the wall base)
- station meets aisle     -> the ZONE EDGE (a lit floorline marking where the station ENDS
                             before it stops existing — the ending made visible)
- wall meets wall         -> the SEAM PILLAR (the reveal between plates)
The kit already knew this in fragments (cap_inset, step tape, the floorline "about between,
not on", grime bands); R-018 declares it as data in station_modules.json so every seeded
station gets curated endings for free. Scarpa's rule adopted: the joint is the generator of
form. NOTE for the book: "the meeting" is a motif candidate — the trace, the threshold, the
spark gap, and the pointing plinth are all meetings; awaiting Palle's ruling to add it.

---

## R-019 · 2026-07-05 · The meeting audit (every part must answer)

**Palle:** "For each part of each object we can ask how it meets the object, for each
object we can ask how does it touch its surroundings and how does this meet look like,
can it be improved. I mean for instance the lamp does not have a foot. … most of the
artifacts are not perfectly aligned. That is a good general rule."

**Ruling:** R-018 curated the meetings we DECLARED; R-019 generalizes it into an audit
question asked at every scale: part→object, object→footing, object→surroundings. Two
standing rules extracted from the named defects:
- **body_on_cell** — artifacts seat by their measured BODY (live AABB centre), never by
  their code origin. The meet is between the thing you SEE and the cap that holds it.
  Implemented in WallHangarEditor `_settle_loaded` (horizontal centring before the
  vertical seat) — every capture and every staged wall gets it for free.
- **pole_on_floor** — no pole enters the floor bare, and a foot that exists but cannot
  be SEEN has not met the floor. The luminaire's flat plate became a stepped pedestal
  with a collar (reads above stage lips and plinth bases).
Both are declared in station_modules.json `junctions` alongside R-018's treatments.
The audit is open-ended: next parts to answer — gooseneck→head knuckle, crate stacks
(box_on_box), screen→wall mounts, seat→floor (stool feet), grime as the record of a
long meeting.

---

## R-020 · 2026-07-06 · The Closing Protocol (the finish line)

**Palle:** "I feel I have too many artifacts and I can not finish what I started. I keep
circling around improving the editor feature … If the book only could be the mixture of
tutorial and critical thinking and the example scene could work as beautiful learning and
explore examples. Can you help me get there? … I think I have all the elements." And, on
scope: "spine has a lot more maps … the book has a lot less content than the spine maps
in the primitive sequence."

**Ruling:** The missing piece is not a feature — it is a stop rule and a countdown.
- **Two objects.** The SEQUENCE (many maps) is the SITE — the game, governed by its own
  7-stage pipeline, alive after the book ships. The CHAPTER ROOM (one room) is the
  EXHIBITION — the dig's pearls staged walkable. The book being smaller than the spine is
  BY DESIGN: a report on a dense site, not a mirror of it. The dig line extends to maps:
  the room shows the excavation; the sequence remains at depth.
- **Chapter lock = writing pass + one room.** Never sequence completion.
- **Scope lock.** The book = 22 chapters x (tutorial + critical pass + one walk-room).
  Everything else is archive — real, kept, at depth.
- **Tool freeze.** No new editors/generators/galleries/templates until 22/22 locked.
  Only tool work a chapter pass actually requires.
- **The chapter loop**, one session each, spine order at the head:
  dig -> walk -> rule -> write -> room (choose or stage) -> LOCK + rebuild.
- **The scoreboard** is doc/book/FINISH_LINE.md — one number, ticked by Palle's hand only.
- **The end object is the PDF** (auto-InDesign) — last, as the reward, not another detour.
Status at ratification: 4/22 passes exist (primitives, randomness, noise, fractals),
0/22 locked. Primitives' room candidates already exist (Walls_Primitives / Hangar_Primitives).

---

## R-021 · 2026-07-06 · The walking scope (amendment to R-020)

**Palle:** "We should and could push the scope and that is what we've been working on.
The archaeology should not be based on the sequence. The sequence is the excavation of
the world ontology of the algorithms with a qfep context. I want to push the book to be
a considered critical tutorial where we walk with the maps and work to develop the .md.
So this is another scope. We already have the in for instance primitives."

**Ruling:** R-020's countdown stands, but the GRAIN moves down and the frame turns:
- **The sequence is the INSTRUMENT, not the table of contents.** It is how the dig
  happens — the excavation of the algorithms' world-ontology under QFEP. The book does
  not report on sequences; it reports on WALKS.
- **The unit of work is the MAP-WALK; the unit of writing is the map's `walked.md`.**
  Walk a map (VR; bridge notes are the pen), and the walk develops that map's page —
  considered, critical, Palle's voice leading, the ghost working the notes in. blurb.md
  says what it is; intent.md says why it was built; **walked.md says what walking it
  taught** — the tutorial and the critique in one page.
- **The book = the considered assembly of walked.md pages.** Chapters remain the
  binding (spine order), but their content GROWS from walked maps — the chapter pass
  becomes curation of its walked pages, not prose written above them.
- **Chapter lock (amended):** its spine maps walked + walked.md developed + the
  considered pass over them. The FINISH_LINE scoreboard gains a walked column.
- The tool freeze stands. The bridge, the rides, the rooms — the apparatus was for
  THIS. Primitives is the in: ten maps, texts in place, walls curated from walks.

---

## R-022 · 2026-07-06 · The compositor (text sets the map)

**Palle:** "walk.md is a way to create the maps too … use the book to auto research the
maps. The book as a tool is to figure out the spine order and order the artifacts in the
maps while making the text beautiful and critical tutorials. Think of NOC — we have the
explaining text and the code. Vectors are ontology, but in Ada Research there is a
critical element, like Alan Turing thinking with qfep."

**Ruling:** The text↔map relation is BIDIRECTIONAL and the text leads. NOC pairs prose
with code; Ada pairs prose with MAPS — the map is the code. walked.md is source: writing
the tutorial well FORCES an order, and the maps compile to it.
- **tools/compositor.py** (freeze-legal: the pass requires it): reads a chapter's text
  (overlay + built tutorial + walked.md), extracts PROSE ORDER (first mention), walks
  the sequence's maps for BODY ORDER (encounter), reports divergences + silences.
  Report-only. Every divergence is a ruling: re-lay the map (creator_walk, tray = prose
  order) or rewrite the text. --spine compares curriculum order against the manuscript
  frame's telling.
- The critical element rides the prose: each concept carries its thinker-figure thought
  WITH QFEP (the vector comes with its Turing) — content for the considered pass, no
  tool needed.
- First run (primitives, 10 maps, 80 artifacts, 0 silent): the prose teaches
  point→trace→drawing→measure early (laser_measure #4, klee_walking_point #8, draw_dot
  #9) while the body holds them to mid-walk (#18/#25/#28); the body front-loads Point_One
  context props (folding_past #3, frame_counter #4, you_are_here #5) that the prose
  treats as asides. CAVEAT: generic-named artifacts (line, sphere, plus, pyramid,
  triangle, origin) collide with ordinary prose words — read their rows with salt;
  specific tokens are the trustworthy signal.

---

## R-023 · 2026-07-06 · The baseline contract (the missing layer)

**Palle:** "The maps are half finished, there are other artifacts that could be included
but how do we know which? Say the VR game was just a tutorial on primitives, color, vector
— it would be easy. We could ask what would be NEEDED in such a context. What is the
baseline. Then there is the critical potential that can turn this into something
interesting."

**Ruling:** Selection was running backwards — "which of 752 deserve in?" has no answer.
FLIP IT. Per chapter, a BASELINE CONTRACT (doc/book/baselines/<seq>.json):
- **Deck 1 — BEATS.** What a PLAIN tutorial on this concept would minimally need,
  derived from the CONCEPT not the inventory (meet the point → it moves → the trace →
  the line → measure → grid → plane → solid → build → prove). Each beat is a ROLE,
  cast with ONE artifact; alts are understudies.
- **Deck 2 — VOLTAGE.** The few pieces a plain tutorial would NEVER include — the
  critical script, the thinker with QFEP (the point as Fontana's cut, the line as
  Klee's walk, Dürer's melancholy solid, the becoming-catalyst). The baseline makes it
  teachable; the voltage makes it Ada.
- **Everything uncast is AT DEPTH:** kept, honored by the dig line, not needed.
- **tools/baseline.py** (freeze-legal) audits: each beat cast & walkable? voltage
  present? — and a chapter is FINISHED when its baseline is met, NOT when the inventory
  is exhausted. This is the definition of "done" the finish line lacked.

First contract (primitives): 10 beats + 5 voltage → 15 in, 49 at depth; auditor reports
10/10 cast & walkable, 5/5 voltage present → **baseline MET.** The chapter can lock on
Palle's walk + hand.

---

<!-- Next: R-024 — walk primitives to confirm the baseline in the body, then LOCK ch.1; draft color + vectors baselines; noise truths; Ignorance settle -->